-- Show OSD clock
--
-- Shows OSD sclock periodicaly with many configurable options,
-- OSD options like duration, alignment, border, scale could be set in ~/.config/mpv/mpv.conf
-- OSD-clock configurable options:
--   interval ... how often to show OSD clock, either seconds or human friendly format like '1h 33m 5s' is supported (default '15m')
--   format   ... date format string (default "%H:%M")
--   duration ... how long [in seconds] OSD stays, fractional values supported (default 1.2)
--   key      ... to bind show OSD clock on request (false for no binding; default 'h' key)
--   name     ... symbolic name (can be used in input.conf, see mpv doc for details; default 'show-clock')
--
-- To customize configuration place osd-clock.conf into ~/.config/mpv/lua-settings/ and edit
--
-- Place script into ~/.config/mpv/scripts/ for autoload
--
-- GitHub: https://github.com/blue-sky-r/mpv/tree/master/scripts

local options = require("mp.options")
local utils   = require("mp.utils")

-- defaults
local cfg = {
	interval = '15m',
	format   = "%H:%M",
	duration = 2.5,
	key      = 'h',
	name     = 'show-clock'
}

-- human readable time format to seconds: 15m 3s -> 903
local function htime2sec(hstr)
	local s = tonumber(hstr)
	-- only number withoout units
	if s then return s end
	-- human units h,m,s to seconds
	local hu = {h=60*60, m=60, s=1}
	s = 0
	for unit,mult in pairs(hu) do
		local _,_,num = string.find(hstr, "(%d+)"..unit)
		if num then 
			s = s + tonumber(num)*mult
		end
	end
	return s
end

-- calc aligned timeout in sec
local function aligned_timeout(align)
	local time = os.time()
	local atout = align * math.ceil(time / align) - time
	return atout
end

-- read lua-settings/osd-clock.conf
options.read_options(cfg, 'osd-clock')

-- log active config
mp.msg.verbose('cfg = '..utils.to_string(cfg))

-- OSD show clock
local function osd_clock()
	local s = os.date(cfg.format)
	mp.osd_message(s, cfg.duration)
end 

-- non empty interval enables osd clock
if cfg.interval then
	-- log
	mp.msg.info('interval:'..cfg.interval..', format:'..cfg.format)

	-- osd timer
	local osd_timer = mp.add_periodic_timer( htime2sec(cfg.interval), osd_clock)
	osd_timer:stop()

	-- start osd timer exactly at interval boundary
	local delay = aligned_timeout( htime2sec( cfg.interval))

	-- delayed start
	mp.add_timeout(delay, 
		function() 
			osd_timer:resume()
			osd_clock()
		end
	)

	-- log startup delay for osd timer
	mp.msg.verbose('for osd_interval:'..cfg.interval..' calculated startup delay:'..delay)

	-- optional bind to the key
	if cfg.key then
		mp.add_key_binding(cfg.key, cfg.name, osd_clock)
		-- log binding
		mp.msg.verbose("key:'"..cfg.key.."' bound to '"..cfg.name.."'")
	end
end

