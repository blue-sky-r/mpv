-- Simple script for configurable TV out activation and/or deactivation on mpv playback
--
-- Intended to activate TV on mpv startup and deactivate TV on mpv close if TV is connected.
-- The script executes fully configurable shell sequences (e.g. xrandr on linux)
-- Can also be used for activating ambient lighting while watching etc ...
--
-- Note: There are implicit security issues due to a nature of direct execution
--       of command line tools without any sanitization ...
--
-- TV configurable options:
--   test ... check if TV is connected (result is non empty, exitcode 0)
--   on   ... executed once on mpv player startup  (TV ON)
--   off  ... executed once on mpv player shutdown (TV OFF)
-- 
-- Note: xrandr seems to have problem turning off and on devices on single execution.
-- Therefore it is wise to split execution to multiple commands, for example:
--   problem : xrandr --output LVDS1 --off --output TV1 --auto
--   works ok: xrandr --output LVDS1 --off && xrandr --output TV1 --auto
--
-- To customize configuration place tv.conf into ~/.config/mpv/lua-settings/ and edit
--
-- Place script into ~/.config/mpv/scripts/ for autoload
--
-- GitHub: https://github.com/blue-sky-r/mpv/tree/master/scripts

local options = require("mp.options")
local utils   = require("mp.utils")

-- defaults
local cfg = {
	test = "xrandr | grep 'VGA1 connected'",
	on   = 'xrandr --output LVDS1 --off && xrandr --output VGA1 --mode 720x400 --output TV1 --auto',
	off  = 'xrandr --output LVDS1 --auto'
}

-- string v is empty
local function empty(v)
	return not v or v == '' or string.find(v,"^%s*$")
end

-- evaluate shell condition by executing cmd
local function test(cmd)
	-- return success if there is nothing to test 
	if empty(cmd) then return true end
	-- get only exitcode
	local exitcode = io.popen(cmd..' >/dev/null 2>&1; echo $?'):read('*n')
	-- log	
	mp.msg.info("test '" .. cmd .. "' returned exitcode:"..exitcode)
	-- success if exitcode is zero
	return exitcode == 0
end

-- execute shell cmd
local function exec(cmd)
	-- return if there is nothing to execute
	if empty(cmd) then return end
	-- get stdout and stderr combined
	local stdcom = io.popen(cmd..' 2>&1'):read('*all')
	-- log	
	mp.msg.info("exec '" .. cmd .. "'")
	if stdcom then mp.msg.verbose(stdcom) end	
end

-- read lua-settings/tv.conf
options.read_options(cfg, 'tv')

-- log active config
mp.msg.verbose('cfg = '..utils.to_string(cfg))

-- execute only if test condition
if test(cfg.test) then
	-- optional TV.ON execute now
	if not empty(cfg.on) then exec(cfg.on) end

	-- optional TV.OFF execute on shutdown
	if not empty(cfg.off) then
		mp.register_event("shutdown", 
			function() 
				exec(cfg.off)
			end
		) 
	end
end
