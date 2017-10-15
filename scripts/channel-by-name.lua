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
	match = "*n*"
}

-- read lua-settings/channel-by-name.conf
options.read_options(cfg, 'channel-by-name')

-- log active config
mp.msg.verbose('cfg = '..utils.to_string(cfg))

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

-- load playlist and create dictionary
local function create_playlist_dict()

    local plist = mp.get_property_native("playlist")

    mp.msg.verbose("playlist -> ".. utils.to_string(plist))

    for plnum,plval in pairs(plist) do
        mp.msg.info("playlist key("..plnum..") -> val("..utils.to_string(plval)..")")
        local chname = title2name(plval.title)
        chname = chname:lower()
        table.insert(chan_name2num, { [chname] = plnum  } )
    end

    mp.msg.verbose("lookup -> ".. utils.to_string(chan_name2num))

end

-- set channel by name
local function channel(name)
    -- lookup name to playlist-pos-1
    -- set playlist-pos-1
end

-- mp.register_event("start-file", create_playlist_dict)
mp.register_event("file-loaded", create_playlist_dict)
-- create_playlist_dict()