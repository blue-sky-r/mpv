-- Channel Survey Simple - periodically switch channels in round-robbin fasion
--
-- Channel survey mode is periodic roundabout style channel switching.
-- Usefull when you want to scan channels for security purposes etc ...
--
-- Channel survey simple configurable options:
--   duration ... how long [in seconds] to show each channel, fractional values supported
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
    duration = 60
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
