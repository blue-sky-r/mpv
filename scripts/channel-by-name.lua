--
-- Created by IntelliJ IDEA.
-- User: robert
-- Date: 15.10.2017
-- Time: 1:05
-- To change this template use File | Settings | File Templates.
--

local options = require("mp.options")
local utils   = require("mp.utils")

-- defaults
local cfg = {
    -- *s* ... case insensitive substring
    -- *s  ... case insensitive endswith
    -- s*  ... case insensitive startswith
    -- s   ... case insebsitive string match
    -- *S* ... case sensitive substring
    -- *S  ... case sensitive endswith
    -- S*  ... case sensitive startswith
    -- S   ... case sensitive string match
	match    = "*s*",
    -- helper function will bet
    case_fn  = nil,
    match_fn = nil
}

-- read lua-settings/channel-by-name.conf
options.read_options(cfg, 'channel-by-name')

-- log active config
mp.msg.verbose('cfg = '..utils.to_string(cfg))

local function match_case_insensitive()
    return cfg.match:find("s")
end

local function match_pattern(str)
    return "^"..cfg.match:gsub("*", ".*"):gsub("[Ss]",str).."$"
end

-- channel name to number lookup
local chan_name2num = {}

-- playlist title to channel name
-- "title" = "RT News,,0" -> "channel-name" = "RT News"
local function title2name(title)
    -- add sentinel to title
    local compos = string.find(title..",", ",")
    -- slice substring from beginning up to the first comma
    local name = string.sub(title, 1, compos-1)

    return name
end

-- create dictionary from playlist
local function create_playlist_dict()

    local playlist = mp.get_property_native("playlist")

    mp.msg.verbose("playlist -> ".. utils.to_string(playlist))

    for plnum,plval in ipairs(playlist) do
        mp.msg.info("playlist key("..plnum..") -> val("..utils.to_string(plval)..")")
        local chname = title2name(plval.title)
        -- adjust case
        if match_case_insensitive() then chname = chname:lower()
        -- add to dictionary
        table.insert(chan_name2num, {[chname] = plnum})
    end

    mp.msg.verbose("lookup -> ".. utils.to_string(chan_name2num))
end

local function lookup_name2num(name)
    -- lookup name to playlist-pos-1
    local pattern = match_pattern(name)
    for chname,chnum in ipairs(chan_name2num) do
        if chname:match(pattern) then
            return chnum
        end
    end
end

-- set channel by name
local function channel(name)
    -- adjust case
    if match_case_insensitive() name = name:lower()
    -- lookup playlist position
    local pos1 = lookup_name2num(name)
    --
    mp.msg.verbose("channel:".. name .." -> ".. pos1)
    -- set playlist-pos-1
    if pos1 then
        mp.set_property("playlist-pos-1", pos1)
    end
end

-- after playlist has been loaded
mp.register_event("file-loaded", create_playlist_dict)
-- create_playlist_dict()