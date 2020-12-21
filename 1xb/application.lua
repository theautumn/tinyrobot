-- TinyRobot, a Lua script that makes API calls to panel_gen
-- Sarah Autumn, 2019
require "sjson"
require "gpio"

-- set up some endpoints
server = "http://192.168.0.204:5000/api/app" -- set server URL
r_1xb = "http://192.168.0.204:5000/api/app/start/1xb?source=key"
s_1xb = "http://192.168.0.204:5000/api/app/stop/1xb?source=key"

led_pin = 2
key_pin = 1
status = gpio.HIGH -- flashes lamp momentarily on start
running = false --stores a local state as a buffer
countdown = 4 -- allows for a couple of no response before blink

-- set pin modes
gpio.mode(led_pin, gpio.OUTPUT)
gpio.mode(key_pin, gpio.INPUT, gpio.PULLUP)
gpio.write(led_pin, status)

function get_from_api()
   http.get(server,'',
	function(code, data)
	-- If no response from HTTP after 3 tries, flash the light.
	if (code < 0) then	-- if response empty
		print("HTTP request failed")
		if countdown == 0 then	-- if debounce counter has run down
			blinking, mode = t_blink:state()
			if blinking == false then	-- if timer not already running
				t_blink:start()
				print("Blink start issued!")
			end
		else
			countdown = countdown - 1
			print("Debounce counter: " .. tostring(countdown))
	  	end
	else
		countdown = 2
		t_blink:stop()
		local api_response = sjson.decode(data)
		print("API Running " .. tostring(api_response["app_running"]))
		print("1XB Running " .. tostring(api_response["xb1_running"]))

		-- if api is accessible and blinky is still running, stop error blinky
		if api_response["app_running"] == true then
			blinking, mode = t_blink:state()
			if blinking == true then
				t_blink:stop()
				print("Blink *stop* issued")
			end
			if api_response["xb1_running"] == true then
				gpio.write(led_pin, gpio.HIGH) -- lamp ON
				running = true
			elseif api_response["xb1_running"] == false then
				gpio.write(led_pin, gpio.LOW) -- lamp OFF
				running = false
			end --end switch checking loop
		end --end API running check loop

	end --end data/no data loop
  end) --end data handling function
end --end get_from_api()


function blink() --blink led
	if status == gpio.LOW then
		status = gpio.HIGH
	else
		status = gpio.LOW
	end

	gpio.write(led_pin, status)
end --end blinky function

debouncer = 2

poll = function() --poll button and do action
	if gpio.read(key_pin) == gpio.LOW then
		debouncer = debouncer - 1
	else
		debouncer = 2
	end

	if debouncer == 0 then
		if running == false then
			http.post(r_1xb)
		else
			http.post(s_1xb)
		end
	end
end

-- key polling function every .1 sec
t_poll = tmr.create()
t_poll:register(100, tmr.ALARM_AUTO, poll)
t_poll:start()

-- blink timer function call every .5 sec
t_blink = tmr.create()
t_blink:register(500, tmr.ALARM_AUTO, blink)

-- HTTP GET function every 1 sec
t_api = tmr.create()
t_api:register(1000, tmr.ALARM_AUTO, get_from_api)
t_api:start()
