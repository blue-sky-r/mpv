--
-- Created by IntelliJ IDEA.
-- User: robert
-- Date: 15.10.2017
-- Time: 1:05
-- To change this template use File | Settings | File Templates.
--

-- Script for user friendly selection of the iPTV channel by name
--
-- Intended to swicth iPTV playlist channels by name (string) and not by playlist posiition (number)
-- Playlist channel position might change on each playlist update or/and modification.
-- Instead of always keeping playlist and input.conf synchronized
-- otherwise you have to modify input.conf an each playlist change
-- but you want to switch to channel name and not to remomber floating channel number
-- The script builds up local lookup table (dictionary) channel_name -> channel_number (playlist position)
-- Can also be used for activating ambient lighting while watching etc ...
--
-- Configurable options:
--   match   ... glob style pattern to match channel name (default case insensitive substring "*s*")
--               token "s" represents channel name string (see bellow for more glob patterns)
--   refresh ... autirefresh playlist on each channel change (default false)
--
-- To customize configuration place channel-by-name.conf into ~/.config/mpv/lua-settings/ and edit
--
-- Place script into ~/.config/mpv/scripts/ for autoload
--
-- GitHub: https://github.com/blue-sky-r/mpv/tree/master/scripts

-- input.conf excerpt
-- # key to channel name assignment
-- c script-message-to channel_by_name channel CNN
-- d script-message-to channel_by_name channel Discovery

--
local options = require("mp.options")
local utils   = require("mp.utils")

-- defaults
local cfg = {
    -- Glob patterns for matching:
    -- *s* ... case insensitive substring
    -- *s  ... case insensitive endswith
    -- s*  ... case insensitive startswith
    -- s   ... case insebsitive string equality
    -- *S* ... case sensitive substring
    -- *S  ... case sensitive endswith
    -- S*  ... case sensitive startswith
    -- S   ... case sensitive string equality
	match    = "*s*",
    -- refresh channel lookup table on each channel change
    refresh  = false
}

-- read lua-settings/channel-by-name.conf
options.read_options(cfg, 'channel-by-name')

-- log active config
mp.msg.verbose('cfg = '..utils.to_string(cfg))

local function match_case_insensitive()
    return cfg.match:find("s")
end

local case_insensitive = match_case_insensitive()

-- escape special chars
local function escape(str)
  local esc = {
    ["("] = "%%(",
    [")"] = "%%)",
    ["%"] = "%%%%",
    ["."] = "%%.",
    ["["] = "%%[",
    ["]"] = "%%]",
    ["*"] = "%%*",
    ["+"] = "%%+",
    ["-"] = "%%-"
  }
  return str:gsub(".", esc)
end

local function match_pattern(str)
    return "^"..cfg.match:gsub("%*", ".*"):gsub("[Ss]", escape(str)).."$"
end

-- channel name to number lookup
local chan_name2num = {}

local function lookup_name2num(name)
    -- lookup name to playlist-pos-1
    local pattern = match_pattern(name)
    for chname,chnum in pairs(chan_name2num) do
        if chname:match(pattern) then
            return chnum
        end
    end
end

-- set channel by name
local function channel(name)
    -- adjust case
    if case_insensitive then name = name:lower() end
    -- lookup playlist position
    local num = lookup_name2num(name)
    --
    -- set playlist-pos-1
    if num then
        mp.msg.info("channel name:".. name .." -> num:".. num)
        mp.set_property("playlist-pos-1", num)
    end
end

-- playlist title to channel name
-- "title" = "RT News,,0" -> "channel-name" = "RT News"
local function title2name(title)
    -- add sentinel to title
    local compos = string.find(title..",", ",")
    -- slice substring from beginning up to the first comma
    local name = string.sub(title, 1, compos-1)
    --
    return name
end

-- create dictionary from playlist
local function create_playlist_dict(event)

    local playlist = mp.get_property_native("playlist")

    for num,val in pairs(playlist) do
        mp.msg.verbose("playlist channel num:"..num.." -> "..utils.to_string(val))
        if not val.title then return end
        -- channel name from playlist title
        local chname = title2name(val.title)
        -- adjust case
        if case_insensitive then chname = chname:lower() end
        -- add to dictionary
        chan_name2num[chname] = num
    end

    mp.msg.info("lookup chan_name2num -> ".. utils.to_string(chan_name2num))

    -- do not recreate lookup dictionary if refresh not required
    if not cfg.refreh then mp.unregister_event(create_playlist_dict) end
end

-- after playlist has been loaded
mp.register_event("file-loaded", create_playlist_dict)
--
mp.register_script_message("channel", channel)
