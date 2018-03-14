-- Channel Survey Simple - periodically switch channels in round-robbin fashion
--
-- Channel survey mode is periodic roundabout style channel switching.
-- There is an option key trigger to start/stop survey. If no key is defined the survey mode starts
-- upon loading the script. Each channel stays on configurable duration. Then it will switch
-- to the next channel up. After reaching the last channel it starts again from beginning.
--
-- Usefull when you want to scan channels or for security purposes (CCTV) etc ...
--
-- Channel survey simple configurable options:
--   duration  ... how long [in seconds] to show each channel, fractional values supported
--   osd_start ... optional OSD message shown on survey mode start (%t token expands to duration)
--   osd_stop  ... optional message shown on survey mode stop
--   key       ... optional key to toggle survey mode (empy/nil for instant survey mode upnon load)
--
-- To customize configuration place channel-survey-simple.conf template into ~/.config/mpv/lua-settings/ and edit
--
-- Place script into ~/.config/mpv/scripts/ for autoload
--
-- GitHub: https://github.com/blue-sky-r/mpv/tree/master/scripts

local options = require("mp.options")
local utils   = require("mp.utils")

-- defaults
local cfg = {
    duration = 10,
    osd_start = 'survey start %ts',
    osd_stop  = 'survey stop',
    key = '/'
}

-- read lua-settings/channel-survey-simple.conf
options.read_options(cfg, 'channel-survey-simple')

-- log active config
mp.msg.verbose('cfg = '..utils.to_string(cfg))

-- round-robbin channel switching
local function next_channel()
    local key = 'playlist-pos'
    local pos = mp.get_property_native(key)
    pos = (pos + 1) % mp.get_property_native('playlist-count')
    mp.set_property_native(key, pos)
    mp.msg.verbose('next-channel() '..key..'='..pos)
end

-- periodic timer for channels switching
local timer = mp.add_periodic_timer(cfg.duration, next_channel)

-- toggle survey mode
local function toggle_survey()
    -- toggle logic
    if timer:is_enabled() then
        -- running -> stop
        timer:kill()
        -- osd message
        if cfg.osd_stop then mp.osd_message(cfg.osd_stop) end
    else
        -- stop -> start
        timer:resume()
        -- osd message
        if cfg.osd_start then mp.osd_message(cfg.osd_start:gsub('%%t', cfg.duration)) end
    end
    -- log
    mp.msg.verbose('toggle_survey() ' .. 'survey active=' .. utils.to_string(timer:is_enabled()))
end

-- optional key to activate channel survey mode
if cfg.key then
    -- if the toggle key is defined wait for key to start survey
    timer:kill()
    -- start survey only on keypress
    mp.add_forced_key_binding(cfg.key, 'channel-survey-simple', toggle_survey)
end
