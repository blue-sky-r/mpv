-- Channel Survey - periodically switch channels in round-robbin fasion
--
-- Channel survey mode is periodic roundabout style channel switching.
-- Usefull when you want to scan channels and are lazy pressing 'next-channel' button.
-- Can be used for security iptv cameras around your home or as a quick check for ski resorts in your area.
-- Configurable key (defaylt 'x') toggles active playlist to alternate survey playlist.
--
-- Channel survey configurable options:
--   playlist ... alternate playlist used for channel survey
--   duration ... how long [in seconds] to show each channel, fractional values supported
--   key      ... to bind channel survey mode toggle (false for no binding; default 'x' key)
--
-- To customize configuration place channel-survey.conf template into ~/.config/mpv/lua-settings/ and edit
--
-- Place script into ~/.config/mpv/scripts/ for autoload
--
-- GitHub: https://github.com/blue-sky-r/mpv/tree/master/scripts

local options = require("mp.options")
local utils   = require("mp.utils")

-- defaults
local cfg = {
    playlist = "live-ski-sk.m3u8",
    duration = 60,
    -- start position/channel: 0..x, random, continue, nil
    startpos = 'continue',
    key      = 'x'
}

-- read lua-settings/channel-survey.conf
options.read_options(cfg, 'channel-survey')

-- log active config
mp.msg.verbose('cfg = '..utils.to_string(cfg))

local saved = {
    playlist_pos  = nil,
    playlist_path = nil,
    survey_pos    = nil
}

-- round-robbin channel switching
local function next_channel()
    local key = 'playlist-pos'
    local pos = mp.get_property_native(key)
    -- mp.msg.verbose('next-channel() before inc ' .. key .. '=' .. pos)
    pos = (pos + 1) % mp.get_property_native('playlist-count')
    mp.set_property_native(key, pos)
    mp.msg.verbose('next-channel() '..key..'='..pos)
end

-- start survey position
local function playlist_pos()
    local key = 'playlist-pos'
    local pos = cfg.startpos
    -- random
    if pos == 'random' then
        local last = mp.get_property_native('playlist-count')
        pos = math.random(last)
    end
    -- continue
    if pos == 'continue' then
        pos = saved.survey_pos
    end
    -- valid channel number
    if tonumber(pos) then
        return key .. '=' .. pos
    end
    -- nil or anythung else means no specific start position
    return ''
end

-- periodic timer for channels switching
local timer = mp.add_periodic_timer( cfg.duration, next_channel)

-- just prepare timer and wait for keypress (trigger) so stop timer for now
timer:kill()

-- start channel survey
local function survey_start()
    -- save actual playlist position
    saved.playlist_pos = mp.get_property_native('playlist-pos')
    -- start at this playlist position
    local pos = playlist_pos()
    -- load survey playlist
    mp.commandv("loadfile", cfg.playlist, "replace", pos)
    -- start timer
    timer:resume()
    -- log
    mp.msg.info('survey_start() loadfile:' .. cfg.playlist .. ' ' .. pos)
end

-- end of channel survey
local function survey_stop()
    -- stop timer
    timer:kill()
    -- save survey position
    saved.survey_pos = mp.get_property_native('playlist-pos')
    -- load saved playlist and position
    mp.commandv("loadfile", saved.playlist_path, "replace", "playlist-pos="..saved.playlist_pos)
    -- log
    mp.msg.info('survey_stop() loadfile:' .. saved.playlist_path .. ' playlist-pos=' .. saved.playlist_pos)
end

-- save active playlist to be restored after end of survey
local function on_playlist_change(name, val)
    -- property 'playlist' changed to '{{"filename" = "../tv.m3u8", "playing" = true, "current" = true}}'
    local path = val[1]["filename"]
    -- save valid path
    if path then
        saved.playlist_path = path
        -- stop observing as we now already have playlist path
        mp.unobserve_property(on_playlist_change)
        -- log
        mp.msg.verbose('on_playlist_change() playlist path=' .. path)
    end
end

-- channel survey toggle called on key press
function channel_survey()
    -- only activate if non-zero duration
    if cfg.duration then
    	-- log
	    mp.msg.info('playlist name:'..cfg.playlist..', duration:'..cfg.duration..', timer.is_enabled:'..utils.to_string(timer:is_enabled()) )
        -- toggle run->stop or stop->run
        if timer:is_enabled() then survey_stop() else survey_start() end
    end
end

-- catch active playlist
mp.observe_property('playlist', 'native', on_playlist_change)

-- key to activate channel survey mode
if cfg.key then
    -- bind survey to keypress
    mp.add_forced_key_binding(cfg.key, 'channel-survey', channel_survey)
end
