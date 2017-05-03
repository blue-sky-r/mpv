-- Show OSD stream title from playlist on change
--
-- Usefull for iPTV when switching the streams/channels defined in the playlist
--
-- At the moment of jump from stream1 to stream2 the property 'media-title' still contains stream1.title
-- (see mpv doc for more details, lookup playlist/N/current, playlist/N/playing )
-- To display correct stream2.title use this script.
--
-- Place script into ~/.config/mpv/scripts/ for autoload
--
-- OSD options like duration, alignment, border, scale could be set in ~/.config/mpv/mpv.conf
--
-- SMPlayer playlist entry example:
--   #EXTINF:0,RT News,,0
--   http://rt-eng-live.hls.adaptive.level3.net/rt/eng/index1600.m3u8
--
-- GitHub: https://github.com/blue-sky-r/mpv/tree/master/scripts

-- OSD format string tokens:
-- %N ... iPTV channel number (playlist index)
-- %t ... iPTV channel name (user friendly stream title)
-- %T ... iPTV channel name in uppercase

-- defaults
local cfg = {
    format = "%N. %t",
    ignoreurl = true
}

-- quick check if string s is like url
local function likeurl(s)
    return string.match(s, "^%a%a%a+://%w+")
end

-- [show_stream_title] property 'media-title' changed to 'iptv-streams.m3u8'
-- [show_stream_title] property 'media-title' changed to 'CP24,,0'
--
-- [show_stream_title] property 'media-title' changed to 'TA News,,0'
-- [show_stream_title] property 'media-title' changed to 'rtmp://eo1-gts.ta.live.cc:1945/ta-o/_definst_/livem2'
--
-- [show_stream_title] property 'media-title' changed to 'EDU,:/default-theme/openfolder.png,1'
-- [show_stream_title] property 'media-title' changed to 'History,,0'
--
mp.observe_property("media-title", "string",
    function(name, val)
        -- log
        mp.msg.info("property '"..name.."' changed to '"..val.."'")
        -- val can be url (redirects ?)
        if cfg.ignoreurl and likeurl(val) then return end

        -- SMPlayer playlist val = 'Title,,0'
        --          playlist val = 'Title'

        -- get comma position or entire length
        local compos = string.find(val..",", ",")
        -- stream title from val
        local title = string.sub(val, 1, compos-1)
        -- playlist index (0-based)
        local n = 1 + mp.get_property('playlist-pos')
        -- replace tokens
        local txt = string.gsub(cfg.format, '%%N', n):gsub('%%t', title):gsub('%%T', string.upper(title))

        -- osd show
        mp.osd_message(txt)
    end
)

