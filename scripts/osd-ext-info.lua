-- OSD Show External Info (e.g. info not related to mpv player nor media played)
--
-- Shows OSD various external info (modality) like weather forecast, new emails,
-- traffic conditions, currency exchange rates, clock, server status, etc.
--
-- Modalities currently (jan'18) implemented (stay tuned as more modalities will be added later):
--
-- OSD-CLOCK - periodicaly shows the clock - configurable options:
-- =========
--   interval ... how often to show OSD clock, either seconds or human friendly format like '1h 33m 5s' supported
--   format   ... date format string
--   duration ... how long [in seconds] OSD msg stays, fractional values supported
--   key      ... to bind showing OSD clock on request (false for no binding)
--
-- To customize configuration place osd-clock.conf template into ~/.config/mpv/lua-settings/ and edit
--
-- OSD-EMAIL - periodicaly shows new email count - configurable options:
-- =========
--   url      ... url to connect to imap/pop server
--   userpass ... authentication in login:password format
--   request  ... request to send to get new email count
--   response ... response from email server to parse to get raw new email count
--   cntofs   ... offset compensation of unread email count (will be subtracted before evaluatimg, should be 0)
--   showat   ... at what time to show OSD email status, seconds or human friendly format like '33m 5s' supported
--   interval ... how often to show OSD email status, either seconds or human friendly format like '1h 33m 5s' supported
--   osdpos   ... msg shown if count os new emails is positive (you have xx new emails)
--   osdneg   ... msg shown if count of new emails is negative (warning: fix offset cfg.cntofs)
--   osdzero  ... msg shown if count of new emails is equal zero (no new emails)
--   osderr   ... error message shown in case of any curl error
--   duration ... how long [in seconds] OSD msg stays, fractional values supported
--   key      ... to bind showing OSD email count on request (false for no binding)
--
--   https://debian-administration.org/article/726/Performing_IMAP_queries_via_curl
--   http://www.faqs.org/rfcs/rfc2060.html
--
--   curl --user "login:password" --url "imap://imap.domain" --request "STATUS INBOX (UNSEEN)"
--   * STATUS "INBOX" (UNSEEN 122)
--
--   curl --user "login:password" --url "imap://imap.domain/INBOX" --request 'SEARCH NEW FROM "vip@company.com"'
--   * SEARCH
--   * SEARCH 304 318 342 360 372
--
-- To customize configuration place osd-email.conf template into ~/.config/mpv/lua-settings/ and edit
--
-- OSD-WEATHER - periodicaly shows weather forecast and current condition
-- ===========
-- Header line (hformat) shows time, current temperature and weather icons/pictograms.
-- Then empty separator lines is shown.
-- The forecast data are shown in line per day format (lformat) with day-of-week, date, high temp., low temp.
-- and weather icons/pictograms. To customize icons/pictograms check weather_ico() function table code2ico.
-- The icons/pictograms are composed of commonly available unicode symbols so no special weather font
-- installation is required - configurable options:
--   url      ... url to retrieve forecast data (free yahoo API)
--   location ... textual location description like city, state (use only if you cannot get locid)
--   locid    ... location id (yahoo woeid), preferred over location even if location is provided (unique, faster query)
--   unit     ... units C for celsius, F for farenheit
--   showat   ... at what time to show OSD forecast, seconds or human friendly format like '33m 5s' supported
--   interval ... how often to show OSD forecast, either seconds or human friendly format like '1h 33m 5s' supported
--   hformat  ... OSD header format with current weather conditions
--   lformat  ... OSD weather forecats line (one per day)
--   days     ... how many days to show in forecast (yahoo gives max. 10)
--   duration ... how long [in seconds] OSD msg stays, fractional values supported
--   key      ... to bind showing OSD forecast on request (false for no binding)
--
-- Note to hformat and lformat:
--   single % for date tokens, double %% for string.format tokens as the string passes through two formatters
--
-- curl https://query.yahooapis.com/v1/public/yql -d q="select item from weather.forecast where woeid=4118 and u='c'" -d format=json
-- https://developer.yahoo.com/weather/documentation.html
--
-- To customize configuration place osd-weather.conf template into ~/.config/mpv/lua-settings/ and edit
--
-- Place script into ~/.config/mpv/scripts/ for autoload
--
-- GitHub: https://github.com/blue-sky-r/mpv/tree/master/scripts

local options = require("mp.options")
local utils   = require("mp.utils")

-- defaults per modality
local cfg = {

    ['osd-clock'] = {
	    interval = '15m',
	    format   = "%H:%M",
	    duration = 2.5,
	    key      = 'h'
    },

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
        url      = 'http://query.yahooapis.com/v1/public/yql',
        location = 'Toronto, CA',
        locid    = 4118,
        unit     = 'C',
        showat   = '59m',
        interval = '1h',
        hformat  = 'Weather at %H:%M %%3d°%%s %%s',
        lformat  = '%a %d.%m. %%3d°%%s %%3d°%%s %%s',
        days     = 7,
        duration = 15,
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
	local time = os.time()
	local atout = align * math.ceil(time / align) - time
	return atout
end

-- calc delay till next ts
local function timeout_till(ts)
    -- current min/sec in seconds
    local curminsec = os.time() % 3600
    -- calc delay
    local delay = ts - curminsec
    -- next hour if delay is negative
    if delay < 0 then delay = 3600 + delay end
    return delay
end

-- string v is empty
local function empty(v)
	return not v or v == '' or string.find(v,"^%s*$")
end

-- par is empty string or represents zero value (like 0h 0m 0s)
local function empty_time(par)
    return empty(par) or htime2sec(par) == 0
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
local function curl(url, data, userpass, request)
    -- connection timeout
    local timeout = 3
	local cmd = 'curl -sS --connect-timeout '..timeout..' --url "'..url..'"'
	if userpass then cmd = cmd..' --user "'..userpass..'"' end
	if request  then cmd = cmd.." --request '"..request.."'" end
	if data then
        for key,val in pairs(data) do
            cmd = cmd.." --data "..key.."='"..val.."'"
        end
    end
	local rs = exec(cmd)
	return rs
end

-- get email count via curl and return tuple (count, response)
local function email_cnt(cfg)
    local rs = curl(cfg.url, false, cfg.userpass, cfg.request)
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

-- very simple json -> table
local function json2table(json, startswith)
    if json:len() < startswith:len()
        or json:sub(1,10) ~= startswith then return end
    --mp.msg.verbose('osd-weather'..' json = '..json)
    local s = 'local q='..json:gsub('"(%w+)":', '%1='):gsub('=%[{', '={{'):gsub('}%]', '}}')..'; return q'
    --local s = 'local q='..json:gsub('"(%w+)":', '%1='):gsub('=%[{', '={{'):gsub('}%]', '}}}')..'; return q'
    --mp.msg.verbose('osd-weather'..' s = '..s)
    --local tab = assert(loadstring(s))()
    return assert(loadstring(s))()
end

-- yahoo wearher forecast
local function weather_forecast(cfg)
    -- weather location id
    local woeid
    -- use locid if provided
    if cfg.locid then
        woeid = '='..cfg.locid
    else
        -- otherwise use subquery to get woeid from textual location
        woeid = ' in (select woeid from geo.places(1) where text=\"'..cfg.location..'\")'
    end
    -- yql
    local data = {
        -- q="select item.forecast from weather.forecast where woeid=xxx and u='c'" -d format=json
        q = "select item from weather.forecast where woeid"..woeid.." and u=\""..cfg.unit:lower().."\"",
        format = "json"
    }
    -- execute yahoo query
    local rs = curl(cfg.url, data, false, false)
    -- parse json to table
    local tab = json2table(rs, '{"query":{')
    return tab
end

-- parse yahoo date string to time
local function ydate2time(str)
    -- month 3 letters to integer value
    local m3toi = {Jan=1, Feb=2, Mar=3, Apr=4, May=5, Jun=6, Jul=7, Aug=8, Sep=9, Oct=10, Nov=11, Dec=12 }
    -- long format
    if str:len() > 11 then
        -- Mon, 01 Jan 2018 10:00 PM CET
        local pattern = "%w+, (%d+) (%w+) (%d+) (%d+):(%d+) (%w+) (%w+)"
        local d, m3, y, h, m, ampm, zone = str:match(pattern)
        -- hh AM/PM -> HH
        if h == '12' then
            -- 12:xx AM -> 00:xx
            if ampm == 'AM' then h = 0 end
        else
            -- 1:xx PM -> 13:xx
            if ampm == 'PM' then h = tonumber(h)+12 end
        end
        return os.time({year = y, month = m3toi[m3], day = d, hour = h, min = m})
    end
    -- 02 Jan 2018
    local pattern = "(%d+) (%w+) (%d+)"
    local d, m3, y = str:match(pattern)
    return os.time({year = y, month = m3toi[m3], day = d})
end

-- yahoo code to pictogram/icon
local function weather_ico(codestr)
    -- https://en.wikipedia.org/wiki/Miscellaneous_Symbols
    -- http://xahlee.info/comp/unicode_weather_symbols.html
    -- https://apps.timwhitlock.info/emoji/tables/unicode
    -- http://jrgraphix.net/r/Unicode/2600-26FF

    -- using this limited set of unicode symbols
    local ico = {
        sun       = '☀',
        sun2      = '☼',
        cloud     = '☁',
        umbrella  = '☂',
        rain      = '☔',
        lighting  = '⚡',
        snowflake = '❄',
        fog       = '♒',
        ellipsis  = '…',
        hot       = '♨',
        circle    = '⚪',
        sparkles  = '✨',
        loop      = '➰',
        hottea    = '☕',
        space     = ' ',
        figspace  = ' '
    }
    -- https://developer.yahoo.com/weather/documentation.html
    local code2ico = {
        -- tornado
        ['0'] = ico.loop..ico.loop,
        -- 1 	tropical storm
        ['1'] = ico.umbrella..ico.umbrella,
        -- hurricane
        ['2'] = ico.loop..ico.loop,
        --  severe thunderstorms
        ['3'] = ico.lighting..ico.lighting,
        -- thunderstorms
        ['4'] = ico.cloud..ico.lighting,
        -- mixed rain and snow
        ['5'] = ico.rain..ico.snowflake,
        -- mixed rain and sleet
        ['6'] = ico.rain..ico.snowflake,
        -- mixed snow and sleet
        ['7'] = ico.snowflake..ico.rain,
        -- freezing drizzle
        ['8'] = ico.umbrella..ico.snowflake,
        -- drizzle
        ['9'] = ico.umbrella..ico.snowflake,
        -- freezing rain
        ['10'] = ico.rain..ico.snowflake,
        -- showers
        ['11'] = ico.rain..ico.rain,
        -- showers
        ['12'] = ico.rain..ico.rain,
        -- snow flurries
        ['13'] = ico.snowflake..ico.snowflake,
        -- light snow showers
        ['14'] = ico.snowflake..ico.rain,
        -- blowing snow
        ['15'] = ico.snowflake..ico.snowflake,
        -- snow
        ['16'] = ico.snowflake..ico.space,
        -- hail
        ['17'] = ico.circle..ico.circle,
        -- sleet
        ['18'] = ico.snowflake..ico.rain,
        -- 19 	dust
        -- 20 	foggy
        ['20'] = ico.fog..ico.fog,
        -- 21 	haze
        ['21'] = ico.fog..ico.space,
        -- 22 	smoky
        ['22'] = ico.fog..ico.fog,
        -- 23 	blustery
        ['23'] = ico.loop..ico.loop,
        -- 24 	windy
        ['24'] = ico.loop..ico.loop,
        -- 25 	cold
        ['25'] = ico.sun..ico.hottea,
	    -- cloudy
        ['26'] = ico.cloud..ico.cloud,
        -- mostly cloudy
        ['27'] = ico.cloud..ico.space,
        -- mostly cloudy
        ['28'] = ico.cloud..ico.space,
        -- partly cloudy (night)
        ['29'] = ico.sun2..ico.cloud,
        -- partly cloudy (day)
        ['30'] = ico.sun..ico.cloud,
        -- clear (night)
        ['31'] = ico.space..ico.space,
        -- sunny
        ['32'] = ico.sun..ico.space,
		-- 33 	fair (night)
        ['33'] = ico.sun..ico.cloud,
		-- 34 	fair (day)
        ['34'] = ico.sun..ico.cloud,
		-- mixed rain and hail
        ['35'] = ico.umbrella..ico.circle,
		-- hot
        ['36'] = ico.sun..ico.hot,
		-- isolated thunderstorms
        ['37'] = ico.cloud..ico.lighting,
		-- scattered thunderstorms
        ['38'] = ico.cloud..ico.lighting,
		-- scattered thunderstorms
        ['39'] = ico.cloud..ico.lighting,
		-- scattered showers
        ['40'] = ico.umbrella..ico.cloud,
        -- heavy snow
        ['41'] = ico.snowflake..ico.snowflake, 
		-- scattered snow showers
        ['42'] = ico.snowflake..ico.umbrella,
		-- heavy snow
        ['43'] = ico.snowflake..ico.snowflake,
		-- partly cloudy
        ['44'] = ico.sun..ico.cloud,
		-- thundershowers
        ['45'] = ico.cloud..ico.lighting,
		-- snow showers
        ['46'] = ico.umbrella..ico.snowflake,
		-- 47 	isolated thundershowers
        ['47'] = ico.cloud..ico.lighting
    }
    local ico = code2ico[codestr]
    -- not found, just return raw code
    if ico == nil then return codestr end
    -- composite icon
    return ico
end

-- current conditions - header line
local function weather_current_line(data, cfg)
    local line = os.date(cfg.hformat, ydate2time(data.date))
    return line:format(data.temp, cfg.unit, weather_ico(data.code))
end

-- forecast line
local function weather_forecast_line(data, cfg)
    local line = os.date(cfg.lformat, ydate2time(data.date))
    return line:format(data.high, cfg.unit, data.low, cfg.unit, weather_ico(data.code))
end

-- formatted weather forecast msg or error
local function osd_weather_msg(cfg)
    -- yahoo foreast as table
    local tab = weather_forecast(cfg)
    -- we are interested only in item section
    local item = tab.query.results.channel.item
    -- extract data to msg
    local msg = {}
    -- current values - header
    table.insert(msg, weather_current_line(item.condition, cfg))
    -- separator
    table.insert(msg, '\n')
    -- forecast lines
    for key,val in pairs(item.forecast) do
        if key > cfg.days then break end
        table.insert(msg, weather_forecast_line(val, cfg))
    end
    mp.msg.verbose('msg='..utils.to_string(msg))
    -- join lines
    return table.concat(msg, '\n')
end

-- transform str to unicode fullwidth (monospace) version
local function fullwidth(str)
    -- http://xahlee.info/comp/unicode_full-width_chars.html
    return str:gsub('.',
        function (c)
            if c > ' ' and c <= '_' then
                return '\239\188'..string.char(string.byte(c)+96)
            end
            if c > '_' and c <= '~' then
                return '\239\189'..string.char(string.byte(c)+32)
            end
            return c
        end
    )
end

-- set locale
local function set_locale()
    -- set date/time locale from LC_ALL/LC_TIME/LANG
    local loc = os.setlocale('', 'time')
    -- error msg if fail
    if loc == nil then loc = 'LC_TIME/LC_ALL/LANG failed, check locale' end
    mp.msg.verbose('set date/time locale to:'..loc)
end

-- init timer, startup delay, key binding for specific modality from cfg
local function setup_modality(modality)

    -- modality section
    local conf = cfg[modality]

    -- read lua-settings/key.conf
    options.read_options(conf, modality)

    -- log active config
    mp.msg.verbose(modality..'.cfg = '..utils.to_string(conf))

    -- empty or zero interval disables modality
    if empty_time(conf.interval) then
        -- log modality is disabled
        mp.msg.verbose(modality .. ' modality has been disabled by empty/zero interval')
    else
        -- modality isenabled
        -- function name from modality
        local fname = modality:gsub('-', '_')
        -- call this function in global namespace for OSD
        local osd = _G[fname]

        -- osd timer
        local osd_timer = mp.add_periodic_timer( htime2sec(conf.interval), osd)
        osd_timer:stop()

        -- the 1st delay to start periodic timer
        local delay
        -- optional show_at
        if conf.showat then
            -- delay start till next showat
            delay = timeout_till( htime2sec(conf.showat) )
        else
            -- start osd timer exactly at interval boundary
            delay = aligned_timeout( htime2sec(conf.interval) )
        end

        -- delayed start
        mp.add_timeout(delay,
            function()
                osd_timer:resume()
                osd()
            end
        )

        -- log startup delay for osd timer
        mp.msg.verbose(modality..'.interval:'..conf.interval..' calc.delay:'..delay)

        -- optional key binding
        if conf.key then
            -- mp.add_key_binding(conf.key, fname, osd)
            mp.add_forced_key_binding(conf.key, fname, osd)
            -- log binding
            mp.msg.verbose(modality..".key:'"..conf.key.."' bound to '"..fname.."'")
        end
    end
end

-- following osd_xxx functions (one per modality) have to be in global namespace _G[] --

-- OSD - show email status
function osd_email()
    local msg = osd_email_msg(cfg['osd-email'])
    if msg then
    	mp.osd_message(msg, cfg['osd-email'].duration)
    end
end

-- OSD - show clock
function osd_clock()
    local conf = cfg['osd-clock']
	local msg = os.date(conf.format)
	mp.osd_message(msg, conf.duration)
end

-- OSD - show weather forecast
function osd_weather()
    local msg = osd_weather_msg(cfg['osd-weather'])
    if msg then
    	mp.osd_message(msg, cfg['osd-weather'].duration)
    end
end

-- main --

-- set locale for date
set_locale()

-- OSD-CLOCK
setup_modality('osd-clock')
-- OSD-EMAIL
setup_modality('osd-email')
-- OSD-WEATHER
setup_modality('osd-weather')
