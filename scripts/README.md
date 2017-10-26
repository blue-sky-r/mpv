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

Files:
* [tv.lua](tv.lua) - Lua script
* [tv.conf](tv.conf) - default config as template for user config


**keywords**: mpv, lua, script

