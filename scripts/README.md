### mpv scripts

This repository contains Lua scripts for [mpv player](https://github.com/mpv-player/mpv "GitHub project") 
These scripts are completely independent and can be used as such. Just copy whichever scripts you're interested 
in to your `scripts/` directory (see [here](https://mpv.io/manual/master/#lua-scripting) for installation instructions).

Other user mpv scripts can be found in [mpv-wiki-user-scripts](https://github.com/mpv-player/mpv/wiki/User-Scripts "mpv scripts") repository.

### [Channel by Name](channel-by-name.lua)

For iPTV mode the playlist is used as an iPTV channel list. Each playlist entry corresponds to one iptv stream and so to one iPTV channel. 
Switching channels is then just moving through playlist up or down.

Files:
* [channel-by-name.lua](channel-by-name.lua) - Lua script
* [channel-by-name.conf](channel-by-name.conf) - default config as template for user config

Example `Assign iPTV channel "CBC News" to the RC (remote controller) button "0"`

* copy channel-by-name.lua to your `scripts/` directory
* add following line to the `input.conf` file:

    ```
    0 script-message-to channel_by_name channel "CBC News"
    ```

* make sure there is a "CBC News" entry in the `playlist` file, something like:

    ```
    #EXTINF:0,CBC News,,0
    https://nn.geo.cbc.ca/hls/cbc-1080.m3u8
    ```
    
* from now on the "0" keypress on the RC the channel "CBC News" will start playing no matter where in the playlist it is located 
(which index/position does it have)

* now you can label the key "0" on the RC as "CBC News" and on update or modify of the playlist the key "0" will stay assigned 
to the channel "CBC News"

### [OSD Clock](osd-clock.lua)

Periodically shows OSD clock with many configurable options:
* interval ... how often to show OSD clock, either seconds or human friendly format like '1h 33m 5s' is supported
* format   ... date format string
* duration ... how long [in seconds] OSD stays, fractional values supported
* key      ... to bind showing OSD clock on request (false for no binding)
* name     ... symbolic name (can be used in input.conf, see mpv doc for details)

Files:
* [osd-clock.lua](osd-clock.lua) - Lua script
* [osd-clock.conf](osd-clock.conf) - default config as template for user config

### [Show Stream Title](show-stream-title.lua)

Shows OSD stream title defined in the playlist on stream change. However, the `media-title` property
gets updated more frequently then the stream changes. Therefore it is important to filter out unwanted updates
which is implemented by configurable validation pattern `valid

Configurable options:    
* format ... OSD text format (default "%N. %t")
* valid  ... validate the title from playlist, ignore invalid title changes (empty for valid all, default "%w+,,0$")

Files:
* [show-stream-title.lua](osd-clock.lua) - Lua script
* [show-stream-title.conf](osd-clock.conf) - default config as template for user config

### [TV](tv.lua)

Activate TV out on mpv player startup and deactivate TV out on mpv player shutdown. 
The script executes fully configurable shell sequences (e.g. xrandr on linux). The scripts
are conditionaly executed based on the result of "test" script. This way the TV out is not activated
in case of disconnected TV etc. The scripts can be used also for activating ambient lighting while watching TV etc ...

Configurable options:
* test ... check if TV is connected (iest if result is non empty, exitcode 0; default "xrandr | grep 'VGA1 connected'")
* on   ... executed once on mpv player startup  (TV ON;  default 'xrandr --output LVDS1 --off && xrandr --output VGA1 --mode 720x400 --output TV1 --auto')
* off  ... executed once on mpv player shutdown (TV OFF; default 'xrandr --output LVDS1 --auto')

Files:
* [tv.lua](tv.lua) - Lua script
* [tv.conf](tv.conf) - default config as template for user config

**keywords**: mpv, lua, script

