-- Channel by Name - script for user friendly selection of the iPTV channels by name/title
--
-- Intended to swicth iPTV playlist channels by name (string) and not by playlist posiition (number)
--
-- Playlist channel position might change on each playlist update or/and any modification.
-- Instead of always keeping playlist and input.conf synchronized we can select channel by name (title)
-- and let the script to find correct position in the playlist (index) and switch to required stream.
-- The script builds up local lookup table (dictionary) name2num.channels -> channel_number (playlist position)
-- To detect playlist changes it observes playlist-count property and compares the new value to the size of name2num
-- table/dictionary. As Lua language does not support length/sizeof for tables the name2num size is also
-- kept locally in name2num.count for performance reasons. This playlist changes detection would fail if you
-- load the new playlist with exactly the same number of entries as the previous playlist has. In such a cases
-- simply set config option cfg.forcerefresh to true. This will force refresh even if the playlist size is the same.
-- Can also be used for alternate way to switch channels like voice recognition, web page etc.
--
-- Configurable options:
--   match         ... glob style pattern to match channel name (default is case insensitive substring "*s*")
--                     token "s" represents channel name string (see bellow for more glob patterns)
--   forcedrefresh ... autorefresh playlist on each playlist-count change (default false)
--
-- To customize configuration place channel-by-name.conf into ~/.config/mpv/script-opts/ [~/.config/mpv/lua-settings/ ] and edit
--
--
-- Place script into ~/.config/mpv/scripts/ for autoload
--
-- GitHub: https://github.com/blue-sky-r/mpv/tree/master/scripts

-- input.conf excerpt
-- # key to channel -> name assignment
-- c script-message-to channel_by_name channel CNN
-- d script-message-to channel_by_name channel Discovery
-- # also works with channel numbers
-- a script-message-to channel_by_name channel 37

-- includes
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
	match    = "s",
    -- refresh channel lookup table on each playlist-count change
    forcerefresh  = false
}

-- read optional lua-settings/channel-by-name.conf
options.read_options(cfg, 'channel-by-name')

-- log active config
mp.msg.verbose('cfg = '..utils.to_string(cfg))

-- true if channel matching is case insensitive
local function match_case_insensitive()
    return cfg.match:find("s")
end

-- cache match case sensitivity
local case_insensitive = match_case_insensitive()

-- escape special pattern chars
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

-- pattern to match channel name
local function match_pattern(str)
    return "^"..cfg.match:gsub("%*", ".*"):gsub("[Ss]", escape(str)).."$"
end

-- channel name to number table/dictionary and table size/count
local name2num = {
    channels = {}, count = 0
}

-- lookup channel number by channel name
local function lookup_name2num(name, notfound)
    mp.msg.info("lookup_name2num(".. name ..")")
    -- adjust case
    if case_insensitive then name = name:lower() end
    -- lookup name to playlist-pos-1
    local pattern = match_pattern(name)
    for chname,chnum in pairs(name2num.channels) do
        if chname:match(pattern) then
            return chnum
        end
    end
    return notfound
end

-- set channel by name/number
local function channel(name)
    -- lookup playlist position
    local num = lookup_name2num(name, tonumber(name))
    -- set playlist-pos-1
    if num then
        mp.msg.info("channel(".. name ..") set playlist-pos-1:".. num)
        mp.set_property("playlist-pos-1", num)
    end
end

-- switch to next channel in round-robbin fashion for surveys
local function next_channel(first, last)
    -- new channel number is actual + 1
    local newch = mp.get_property_number("playlist-pos-1") + 1
    -- start from the first channel if new channel is over the last one
    if newch > lookup_name2num(last, tonumber(last)) then
        return channel(first)
    end
    -- log
    mp.msg.info("next_channel(" .. first .. ", ".. last .. ")  playlist-pos-1:" .. newch)
    -- switch next channel
    mp.set_property("playlist-pos-1", newch)
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
local function refresh_name2num(playlist)

    -- get playlist as parameter of from property
    if not playlist then
        playlist = mp.get_property_native("playlist")
    end

    -- get the 1st title from {{"filename" = "http://url.m3u8", "title" = "ABC,,0"}}
    -- do not refresh if there is no title for whatever reason
    if not playlist[1].title then return end

    -- init table
    name2num = {
        channels = {},
        count = 0
    }

    for chnum,val in ipairs(playlist) do
        mp.msg.verbose("refresh_name2num() channel num:".. chnum .." -> ".. utils.to_string(val))
        -- break if there is no title
        if not val.title then return end
        -- channel name from playlist title
        local chname = title2name(val.title)
        -- adjust case
        if case_insensitive then chname = chname:lower() end
        -- add to dictionary
        name2num.channels[chname] = chnum
        -- count
        name2num.count = name2num.count + 1
    end

    mp.msg.info("refresh_name2num() name2num = ".. utils.to_string(name2num))
end

-- create dictionary from playlist on playlist-count changes
local function create_playlist_dict(name, count)
    -- log
    mp.msg.verbose('create_playlist_dict(' .. name .. ', ' .. count .. ') name2num.count='.. name2num.count)

    -- if playlist-count has not changed -> no playlist update neccessary
    if not cfg.forcerefresh and count == name2num.count then return end

    refresh_name2num()
end

-- monitor playlist-count changes to rebuild lookup table
mp.observe_property('playlist-count', 'number', create_playlist_dict)

-- switch channel by name/number
mp.register_script_message("channel",      channel)

-- for channel-survey
mp.register_script_message("next_channel", next_channel)
