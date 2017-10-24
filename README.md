## mpv scripts

This repository contains Lua scripts for [mpv player](https://github.com/mpv-player/mpv "GitHub project") 
These scripts are completely independent and can be used as such. Just copy whichever scripts you're interested 
in to your `scripts/` directory (see [here](https://mpv.io/manual/master/#lua-scripting) for installation instructions).

Other user mpv scripts can be found in [mpv-wiki-user-scripts](https://github.com/mpv-player/mpv/wiki/User-Scripts "mpv scripts") repository.

#### iPTV

For iPTV mode the playlist is used as an iPTV channel list. Each playlist entry corresponds to one iptv stream and so to one iPTV channel. 
Switching channels is then just moving through playlist up or down.

These are small and usefull improvements for mpv for iPTV live stream watching:
* [Show Stream Title](scripts/show-stream-title.lua) - shows OSD channel title when switching the channels
* [OSD Clock](scripts/osd-clock.lua) - shows periodically OSD clock
* [TV out](scripts/tv.lua) - TV out activation/deactivation on mpv playback
* [Channel by Name](scripts/channel-by-name.lua) - select iPTV channel by name/title (not by index/position)

#### To Do

Possible future improvements and ideas (in arbitrary order):
* handle stream errors
* EPG option
* show channel logo
* somehow handle changing streams in user friendly manner
* streams playlist autoupdate

#### History

version 2017.4 - the initial GitHub release in April 2017

**keywords**: mpv, lua, script

