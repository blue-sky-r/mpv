-- Channel Survey - periodically switch channels in round-robbin fasion
--
-- Channel survey mode is periodic roundabout style channel switching.
-- Usefull when you want to scan channels and are lazy pressing 'next-channel' button.
-- Can be used for security iptv cameras around your home or as a quick check for ski resorts in your area.
-- Configurable key (defaylt 'x') toggles active playlist to alternate survey playlist.
--
-- Channel survey configurable options:
--   duration       ... how long [in seconds] to show each channel, fractional values supported
--   listsep        ... channel names seperator for the list (default ,)
--   playlistmatch  ... validate playlist name (default any alphanum string ending with .m3u8 ^%w.+%.m3u8$)
--   loadmode       ... optional playlist mode append/replace (default append)
--   continuesurvey ... continue survey on next start (true) or always start from the begining (default true)
--   delay          ... survey start delay in sec (default 1.5) while showing OSD message
--   osd_range_msg  ... start range survey OSD msg (survey %t sec / range mode)
--   osd_list_msg   ... start list  survey OSD msg (survey %t sec / list mode)
--
-- Requires:
--   channel-by-name.lua [ channel(), next_channel() ]
--
-- To customize configuration place channel-survey.conf template into
-- dir ~/.config/mpv/script-opts/ [~/.config/mpv/lua-settings/] and edit
--
-- Place script into ~/.config/mpv/scripts/ for autoload
--
-- GitHub: https://github.com/blue-sky-r/mpv/tree/master/scripts

local options = require("mp.options")
local utils   = require("mp.utils")

-- defaults
local cfg = {
    -- time in sec showing channel
    duration = 15,
    -- channel names separator for the list
    listsep = ',',
    -- validate playlist name
    playlistmatch = '^%w.+%.m3u8$',
    -- optional playlist mode append/replace
    loadmode = 'append',
    -- continue survey on next start (true) or always start from the begining
    continuesurvey = true,
    -- survey start delay in sec while osd_xxx_msg is shown
    delay = 1.5,
    -- start survey OSD msg (tokens %t = duration time), empty for no message
    osd_range_msg = 'survey %t sec / range mode',
    osd_list_msg  = 'survey %t sec / list mode'
}

-- read lua-settings/channel-survey.conf
options.read_options(cfg, 'channel-survey')

-- log active config
mp.msg.verbose('cfg = '..utils.to_string(cfg))

-- local storage
local saved = {
    playlist = {
        path = nil,
        pos1 = nil
    },
    channel = {
        first   = nil,
        last    = nil,
        list    = nil,
        survey_pos1  = nil
    }
}

-- string v is empty
local function empty(v)
    return not v or v == '' or string.find(v, "^%s*$")
end

-- human readable time format to seconds: 15m 3s -> 903
local function htime2sec(hstr)
    local s = tonumber(hstr)
    -- only number withoout units
    if s then return s end
    -- human units h,m,s to seconds
    local hu = { h = 60 * 60, m = 60, s = 1 }
    s = 0
    for unit, mult in pairs(hu) do
        local _, _, num = string.find(hstr, "(%d+)" .. unit)
        if num then
            s = s + tonumber(num) * mult
        end
    end
    return s
end

-- par is empty string or represents zero value (like 0h 0m 0s)
local function empty_time(par)
    return empty(par) or htime2sec(par) == 0
end

-- split list to array by separator sep
local function split(list, sep)
    -- result array
    local arr = {}
    -- split
    list:gsub('([^' .. sep .. ']+)',
        function(token)
            table.insert(arr, token)
        end)
    return arr
end

-- return either optional txt or default if optional is nil/empty
local function txt_def(optional, default)
    -- default
    local txt = default
    -- use optional if not empty
    if optional then
        txt = optional
    end
    -- replace tokens
    return txt:gsub('%%t', cfg.duration)
end

-- round-robbin channel switching - sends message to channel-by-name script to switch channel
local function switch_channel()
    -- more covenient access
    local channel = saved.channel
    -- channel list supplied
    if channel.list then
        -- inc survey_pos1 to be from range <1 .. #channel.list>
        channel.survey_pos1 = channel.survey_pos1 + 1
        if channel.survey_pos1 > #channel.list then channel.survey_pos1 = 1 end
        -- call channel switch
        mp.commandv('script-message-to', 'channel_by_name', 'channel', channel.list[channel.survey_pos1])
    elseif channel.first and channel.last then
        -- range supplied first .. last
        mp.commandv('script-message-to', 'channel_by_name', 'next_channel', channel.first, channel.last)
    end
    -- log
    mp.msg.verbose('switch_channel() saved.channel=' .. utils.to_string(channel))
end

-- start survey position - either continue or default
local function survey_start_pos1(default)
    -- if continue requested and have valid saved position, use it
    if cfg.continuesurvey and tonumber(saved.channel.survey_pos1) then
        return saved.channel.survey_pos1
    end
    return default
end

-- periodic timer for channels switching
local timer = mp.add_periodic_timer(htime2sec(cfg.duration), switch_channel)

-- just prepare timer and wait for trigger to start so stop timer for now
timer:kill()

-- check if survey is running
local function survey_running()
    return timer:is_enabled()
end

-- load playlist if playlist is valid, return false on invalid playlist
local function load_playlist(playlist, mode)
    -- validate playlist: not empty and match againg cfg.playlistmatch pattern
    --if not playlist or playlsit:len() < 6 or playlist:subs(-5):lower() ~= '.m3u8' then return false end
    if not playlist or not playlist:match(cfg.playlistmatch) then return false end
    -- log
    mp.msg.verbose('load_playlist(' .. playlist .. ', ' .. mode .. ')')
    -- load playlist
    mp.commandv('loadlist', playlist, mode)
    return true
end

-- end of survey
local function survey_stop(splaylist)
    -- stop switching channels
    timer:kill()
    -- save survey position for potential continuation
    saved.channel.survey_pos1 = mp.get_property_number('playlist-pos-1')
    -- restore original playlist if survey playlist splaylist is valid
    if splaylist then load_playlist(saved.playlist.path, 'replace') end
    -- restore playlist-pos1
    mp.set_property_number('playlist-pos-1', saved.playlist.pos1)
end

-- start survey at channel channel with configurable delay needed to process playlist to lookup table
local function delayed_start(delay, msg, channel)
    -- osd message
    if msg then
        mp.osd_message(msg, delay)
    end
    -- delayed channel switch and start survey timer
    mp.add_timeout(delay,
        function()
            mp.commandv('script-message-to', 'channel_by_name', 'channel', channel)
            -- start timer
            timer:resume()
        end
    )
end

-- survey range sfrom..sto from optional splaylist, optional start survey osd message sosd
local function survey_range_playlist(sfrom, sto, splaylist, sosd)
    -- log
    mp.msg.info('survey_range_playlist('.. sfrom ..', '.. sto ..', '.. utils.to_string(splaylist)
                ..', '.. utils.to_string(sosd) ..')')
    -- toggle run->stop or stop->run
    if survey_running() then
        survey_stop(splaylist)
        return
    end
    -- do not activate with empty/zero duration
    if empty_time(cfg.duration) then return end
    -- save actual playlist position
    saved.playlist.pos1 = mp.get_property_number('playlist-pos-1')
    -- save survey parameters
    saved.channel = {
        first = sfrom,
        last = sto,
        list = nil
        --survey_pos1 = 1
    }
    -- load optional survey playlist
    load_playlist(splaylist, cfg.loadmode)
    -- start survey after small delay while showing optional osd msg
    delayed_start(cfg.delay, txt_def(sosd, cfg.osd_range_msg), survey_start_pos1(sfrom))
end

-- survey list of channels (comma separated) from optional splaylist, optional start survey osd message sosd
local function survey_list_playlist(list, splaylist, sosd)
    -- log
    mp.msg.info('survey_list_playlist('.. list ..', '.. utils.to_string(splaylist)
                ..', '.. utils.to_string(sosd) ..')')
    -- toggle run->stop or stop->run
    if survey_running() then
        survey_stop(splaylist)
        return
    end
    -- do not activate  with empty/zero duration
    if empty_time(cfg.duration) then return end
    -- save actual playlist position
    saved.playlist.pos1 = mp.get_property_number('playlist-pos-1')
    -- save survey parameters
    saved.channel = {
        first = nil,
        last = nil,
        list =  split(list, cfg.listsep),
        survey_pos1 = survey_start_pos1(1)
    }
    -- load optional survey playlist
    load_playlist(splaylist, cfg.loadmode)
    -- start survey after small delay while showing optional osd msg
    delayed_start(cfg.delay, txt_def(sosd, cfg.osd_list_msg), saved.channel.list[saved.channel.survey_pos1])
end

-- script-message-to channel_survey survey_range_playlist "chan 1" "chan 10" "playlist.m3u8" "OSD message"
mp.register_script_message("survey_range_playlist", survey_range_playlist)

-- script-message-to channel_survey survey_list_playlist "chan 1,chan 2,chan 3" "playlist.m3u8" "OSD message"
mp.register_script_message("survey_list_playlist",  survey_list_playlist)
