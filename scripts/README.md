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

Example `Assign iPTV channel "CBC News" to RC button "0"`

* copy channel-by-name.lua to your `scripts/` directory
* add following line to `input.conf` file:

    ```
    0 script-message-to channel_by_name channel "CBC News"
    ```

* make sure there is "CBC News" in the `playlist` file like:

    ```
    #EXTINF:0,CBC News,,0
    https://nn.geo.cbc.ca/hls/cbc-1080.m3u8
    ```
    
* now on any "0" keypress on RC the channel "CBC News" will start playing no matter where it is located (which index/position
does it have)

* now you can label key "0" on RC as "CBC News" 

### [OSD Clock](osd-clock.lua)

Periodically shows OSD clock with many configurable options 

Files:
* [osd-clock.lua](osd-clock.lua) - Lua script
* [osd-clock.conf](osd-clock.conf) - default config as template for user config

### [Show Stream Title](show-stream-title.lua)

Shows OSD stream title defined in the playlist on stream change 

Files:
* [show-stream-title.lua](osd-clock.lua) - Lua script
* [show-stream-title.conf](osd-clock.conf) - default config as template for user config

### [TV](tv.lua)

Activate TV out on mpv player startup and deactivate TV out on mpv player shutdown. 
The script executes fully configurable shell sequences (e.g. xrandr on linux). The scripts
are conditionaly executed based on the result of "test" script. This way the TV out is not activated
in case of disconnected TV etc. The scripts can be used also for activating ambient lighting while watching TV etc ...

Files:
* [tv.lua](tv.lua) - Lua script
* [tv.conf](tv.conf) - default config as template for user config


**keywords**: mpv, lua, script

