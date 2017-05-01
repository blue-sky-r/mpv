-- Simple script for showing current stream Title OSD when moving through playlist
-- Note: show-text "${media-title}" displays playing title and not the current title
-- /see mpv doc for details between playing title and current title/
-- All OSD config options (duration, align, border, scale, ...) could be set in mpv.conf
--
-- place in ~/.config/mpv/scripts/ for autoload

-- convert stream names to upper-case
local upcase = false

-- [observe] property 'media-title' changed to '"Title,,0"'
mp.observe_property("media-title", "native", function(name, val)
        -- log
        mp.msg.log("info", "property '"..name.."' changed to '"..val.."'")
        -- comma position
        local compos = string.find(val, ",")
        -- comma found
        if compos then
        	--  stream title from val / the first part: title,icon,0
           	local txt = string.sub(val, 1, compos-1)
           	if upcase then txt = string.upper(txt) end
           	mp.osd_message(txt)
	end
end)
