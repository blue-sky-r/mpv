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

-- set helper function based on cfg.match
local function cfg_set_fn()
    local m = cfg.match
    -- case sensitivity
    if m:find('s') then cfg.case_fn = case_insensitive end
    if m:find('S') then cfg.case_fn = case_sensitive end
    --
    m = m:lower()
    -- match
    if m == 's' then cfg.match_fn = str_match end
    -- substring
    if m == '*s*' then cfg.match_fn = str_in end
    -- starts with
    if m == 's*' then cfg.match_fn = str_startswith end
    -- ands with
    if m == '*s' then cfg.match_fn = str_endswith end
end

local function case_sensitive(str)
    return str
end

local function case_insensitive(str)
    return str:lower()
end

local function str_match(str, needle)
    return str == needle
end

local function str_in(str, needle)
    return str:find(needle)
end

local function str_startswith(str, needle)
    return str:sub(1, needle:len()) == needle
end

local function str_endswith(str, needle)
    return str:sub(-needle:len()) == needle
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
        local achname = cfg.case_fn(chname)
        -- add to dictionary
        table.insert(chan_name2num, {[achname] = plnum})
    end

    mp.msg.verbose("lookup -> ".. utils.to_string(chan_name2num))
end

local function lookup_name2num(name)
    -- lookup name to playlist-pos-1
    for chname,chnum in ipairs(chan_name2num) do
        if cfg.match_fn(chname, name) then
            return chnum
        end
    end
end

-- set channel by name
local function channel(name)
    -- adjust case
    local aname = cfg.case_fn(name)
    -- lookup playlist position
    local pos1 = lookup_name2num(aname)
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