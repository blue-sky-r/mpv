--
-- Created by IntelliJ IDEA.
-- User: robert
-- Date: 20.01.2018
-- Time: 8:57
-- To change this template use File | Settings | File Templates.
--

-- https://github.com/mpv-player/mpv/blob/master/DOCS/man/lua.rst#events

local options = require("mp.options")
local utils   = require("mp.utils")

-- defaults
local cfg = {
    playlist = "live-ski-sk.m3u8",
    duration = 60,
    key      = 'x'
}

-- read lua-settings/channel-by-name.conf
options.read_options(cfg, 'channel-survey')

-- log active config
mp.msg.verbose('cfg = '..utils.to_string(cfg))

local saved = {
    -- _properties_  = { 'playlist-pos-1', 'osd-duration' },
    playlist_pos  = nil,
    playlist_path = nil
}

--
local function save_properties()
    for idx,name in pairs(saved._properties_) do
        saved[name] = mp.get_property_native(name)
        mp.msg.info('property '..name..'='..utils.to_string(mp.get_property_native(name)))
    end
end

--
local function restore_properties()
    for idx,name in pairs(saved._properties_) do
        mp.set_property_native(name, saved[name])
    end
end

-- round-robbin channel switching
local function next_channel()
    local key = 'playlist-pos'
    local pos = mp.get_property_native(key)
    pos = (pos + 1) % mp.get_property_native('playlist-count')
    mp.set_property_native(key, pos)
    mp.msg.verbose('next-channel() '..key..'='..pos)
end

local timer = mp.add_periodic_timer( cfg.duration, next_channel)
timer:kill()

local function survey_start()
    saved.playlist_pos = mp.get_property_native('playlist-pos')
    --
    mp.commandv("loadfile", cfg.playlist, "replace", "playlist-pos=0")
    timer:resume()
    mp.msg.info('survey_start() loadfile:' .. cfg.playlist)
end

local function survey_stop()
    timer:kill()
    --mp.set_property_native('playlist-pos', saved.playlist_pos)
    mp.commandv("loadfile", saved.playlist_path, "replace", "playlist-pos="..saved.playlist_pos)
    mp.msg.info('survey_stop() loadfile:' .. saved.playlist_path .. ' playlist-pos=' .. saved.playlist_pos)
end

local function on_playlist_change(name, val)
    -- property 'playlist' changed to '{{"filename" = "../tv.m3u8", "playing" = true, "current" = true}}'
    local path = val[1]["filename"]
    if path then
        saved.playlist_path = path
        mp.unobserve_property(on_playlist_change)
        mp.msg.verbose('on_playlist_change() playlist path=' .. path)
    end
end

--
function channel_survey()
    if cfg.duration then
    	-- log
	    mp.msg.info('playlist name:'..cfg.playlist..', duration:'..cfg.duration..', timer.is_enambled:'..utils.to_string(timer:is_enabled()) )

        if timer:is_enabled() then survey_stop() else survey_start() end
    end
end

mp.observe_property('playlist', 'native', on_playlist_change)

if cfg.key then
    mp.add_forced_key_binding(cfg.key, 'channel-survey', channel_survey)
end
