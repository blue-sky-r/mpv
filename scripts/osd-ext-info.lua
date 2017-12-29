-- OSD Show External Info
--
-- Shows OSD various external (mot mpv/media related) info like weather forecast, new emails,
-- traffic conditions, currency exchange rates, clock, etc.
-- OSD options like duration, alignment, border, scale could be set in ~/.config/mpv/mpv.conf
-- OSD-clock configurable options:
--   interval ... how often to show OSD clock, either seconds or human friendly format like '1h 33m 5s' supported
--   format   ... date format string
--   duration ... how long [in seconds] OSD stays, fractional values supported
--   key      ... to bind showing OSD clock on request (false for no binding)
--   name     ... symbolic name (can be used in input.conf, see mpv doc for details)
--
-- To customize configuration place osd-clock.conf into ~/.config/mpv/lua-settings/ and edit
--
-- Place script into ~/.config/mpv/scripts/ for autoload
--
-- GitHub: https://github.com/blue-sky-r/mpv/tree/master/scripts

local options = require("mp.options")
local utils   = require("mp.utils")

-- https://debian-administration.org/article/726/Performing_IMAP_queries_via_curl
-- http://www.faqs.org/rfcs/rfc2060.html

-- curl --user "login:password" --url "imap://imap.domain" --request "STATUS INBOX (UNSEEN)"
-- * STATUS "INBOX" (UNSEEN 122)

-- curl --user "login:password" --url "imap://imap.domain/INBOX" --request 'SEARCH NEW FROM "vip@company.com"'
-- * SEARCH
-- * SEARCH 304 318 342 360 372

-- defaults
local cfg = {

    ['osd-email'] = {
        url      = 'imap://imap.domain',
        userpass = 'login:pass',
        request  = 'STATUS INBOX (UNSEEN)',
        response = '* STATUS "INBOX" %(UNSEEN (%d+)%)',
        cntofs   = 0,
        showat   = '58m',
        interval = '1h',
        osdpos   = 'You have %d new email(s)',
        osdneg   = 'WRN: fix offset cfg.cntofs:%d',
        osdzero  = 'No New emails',
        osderr   = 'ERR: %s',
        duration = 3.5,
        key      = 'e'
    },

    ['osd-weather'] = {
        showat   = '55',
        interval = '1h',
        format   = 'Today: %d Tomorrow: %s',
        duration = 3.5,
        key      = 'w'
    }
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
    -- special case align=0 => align=60*60 [1h]
    if align == 0 then align = 60*60 end
	local time = os.time()
	local atout = align * math.ceil(time / align) - time
	return atout
end

-- string v is empty
local function empty(v)
	return not v or v == '' or string.find(v,"^%s*$")
end

-- execute shell cmd and return stdout and stderr
local function exec(cmd)
	-- return if there is nothing to execute
	if empty(cmd) then return end
	-- get stdout and stderr combined
	local stdcom = io.popen(cmd..' 2>&1'):read('*all')
	-- log
	mp.msg.info("exec ["..cmd.."]")
	if stdcom then
        mp.msg.verbose(stdcom)
    end
   	return stdcom
end

-- perform curl request and return response
local function curl(url, userpass, request)
    -- connection timeout
    local timeout = 3
	local cmd = 'curl -sS --connect-timeout '..timeout..' --url "'..url..'"'
	if userpass then cmd = cmd..' --user "'..userpass..'"' end
	if request  then cmd = cmd.." --request '"..request.."'" end
	local rs = exec(cmd)
	return rs
end

-- get email count via curl and return tuple (count, response)
local function email_cnt(cfg)
    local rs = curl(cfg.url, cfg.userpass, cfg.request)
    local cnt = tonumber(rs:match(cfg.response))
    return cnt, rs
end

-- formatted mail status msg or error/warning
local function osd_email_msg(cfg)
    local cnt, rs = email_cnt(cfg)
    if cnt then
        cnt = cnt - cfg.cntofs
        if cnt > 0 then
            -- msg for positive count(new)
            return string.format(cfg.osdpos, cnt)
        end
        if cnt < 0 then
            -- msg for negative count(new) [should be warning to update cfg]
            return string.format(cfg.osdneg, cfg.cntofs)
        end
        -- msg for no new emails
        return string.format(cfg.osdzero, cfg.cntofs)
    end
    -- error msg
    return string.format(cfg.osderr, rs)
end

-- show osd email status
function osd_email()
    local msg = osd_email_msg(cfg['osd-email'])
    if msg then
    	mp.osd_message(msg, cfg['osd-email'].duration)
    end
end

-- init timer, startup delay, key binding for specific modality from cfg
local function setup_modality(modality)

    -- modality section
    local conf = cfg[modality]

    -- read lua-settings/key.conf
    options.read_options(conf, modality)

    -- log active config
    mp.msg.verbose(modality..'.cfg = '..utils.to_string(conf))

    -- non empty interval enables osd clock
    if conf.interval then

        -- function name from modality
        local fname = modality:gsub('-', '_')
        -- call this function in global namespace for OSD
        local osd = _G[fname]

        -- osd timer
        local osd_timer = mp.add_periodic_timer( htime2sec(conf.interval), osd)
        osd_timer:stop()

        -- startup delay boundary (default interval)
        local boundary = conf.interval
        -- use optional showat as boundary if specified
        if conf.showat then boundary = conf.showat end

        -- start osd timer exactly at interval boundary
        local delay = aligned_timeout( htime2sec(boundary) )

        -- delayed start
        mp.add_timeout(delay,
            function()
                osd_timer:resume()
                osd()
            end
        )

        -- log startup delay for osd timer
        mp.msg.verbose(modality..'.interval:'..conf.interval..' calc.delay:'..delay..' for boundary:'..boundary)

        -- optional key binding
        if conf.key then
            mp.add_key_binding(conf.key, fname, osd)
            -- log binding
            mp.msg.verbose(modality..".key:'"..conf.key.."' bound to '"..fname.."'")
        end
    end
end

-- main --
setup_modality('osd-email')
