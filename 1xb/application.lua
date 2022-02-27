
-- TinyRobot, a Lua script that makes API calls to panel_gen
-- Sarah Autumn, 2019
require "sjson"
require "gpio"

-- set up some endpoints
server = "http://192.168.0.204:5000/api/switches/1xb" -- set server URL
r_1xb = "http://192.168.0.204:5000/api/app/start/1xb?source=key"
s_1xb = "http://192.168.0.204:5000/api/app/stop/1xb?source=key"

-- define some pins
ST_KEY_PIN = 1 -- stary key
ST_LAMP_PIN = 2 -- start lamp
HT_KEY_PIN = 5 -- high traffic key
HT_LAMP_PIN = 6 -- high traffic lamp


down = gpio.HIGH -- for the lever key
up = gpio.LOW  -- for the lever key
st_status = gpio.LOW -- status of start lamp
ht_status = gpio.LOW -- status of high traffic lamp
running = false --stores a local state as a buffer
countdown = 4 -- allows for a couple of no response before blink
desired_load  = "" -- traffic volume controlled by key
current_load  = "normal" -- traffic volume reported from API

-- set key pin modes
gpio.mode(ST_KEY_PIN, gpio.INPUT, gpio.PULLUP)
gpio.mode(HT_KEY_PIN, gpio.INPUT, gpio.PULLUP)
-- set LAMP pin modes
gpio.mode(ST_LAMP_PIN, gpio.OUTPUT)
gpio.mode(HT_LAMP_PIN, gpio.OUTPUT)
-- flash momentarily before first successful GET
gpio.write(ST_LAMP_PIN, st_status)
gpio.write(HT_LAMP_PIN, ht_status)


function get_app_status()
	print(">>>>>>>  get app status")
	http.get(server,'',
	function(code, data)
		print("evaluating HTTP data")
		-- If no response from HTTP after 3 tries, flash the light.
		if (code < 0) then  -- if response empty
			print("App status HTTP request failed")
            print('Countdown '.. tostring(countdown))
			if countdown == 0 then -- if debouncer has run down
				blinking, mode = t_blink:state()
				print("Blinking " .. tostring(blinking))
				-- if timer not already running
				if blinking == false then
					t_blink:start()
					print("Blink start issued!")
				end
			else
				countdown = countdown -1
				print("Debounce counter: " .. tostring(countdown))
			end
		else
			-- if api is accessible and blinky is still running, stop error blinky
			-- reset countdown, and grab the table
			countdown = 4
			api_response = sjson.decode(data)
			blinking, mode = t_blink:state()
			if blinking == true then
				t_blink:stop()
				print("Blink *stop* issued!")
			end

			-- the API returns a table of tables so we have to use an index [1]
            print(tostring(api_response[1]["running"]))
			if api_response[1]["running"] == true then
				gpio.write(ST_LAMP_PIN, gpio.LOW) -- lamp ON
				running = true
			elseif api_response[1]["running"] == false then
				gpio.write(ST_LAMP_PIN, gpio.HIGH) -- lamp OFF
				running = false
			end --end running  checking loop

			if api_response[1]["traffic_load"] == "heavy" then
				gpio.write(HT_LAMP_PIN, gpio.LOW) -- lamp on
				current_load = "heavy"
			else
				gpio.write(HT_LAMP_PIN, gpio.HIGH) -- lamp off
				current_load = "normal"
			end -- end traffic load checking loop

		end --end API running check loop
	end) --end callback function
end --end get_app_status()

function change_traffic_load(desired_load)
	print("changing traffic load <<<<<<<<<")
	if api_response == nil or api_response == {} then
		print("________________api_response empty")
		return 
	end
	for index, data in ipairs(api_response) do
		print(index)

		for key, value in pairs(data) do
			print('\t', key, value)
		end
	end
	
	if current_load ~= desired_load then
		print("Changing the business!")
		http.request(server,	-- send kercheep a PATCH!
			'PATCH',
			'Content-Type: application/json\r\n',
			'{"traffic_load": "'.. desired_load ..'"}',
			function(code, data)
				if (code < 0) then
					print("oh boy something fucked up")
				elseif (code == 200) then
					print("Business has been changed heck yeah!")
				end --end if
			end) -- end PATCH callback function
	end -- end main IF block
end --end GET callback function


function blink() --blink led
	if st_status == gpio.LOW then
		st_status = gpio.HIGH
	else
		st_status = gpio.LOW
	end

	gpio.write(ST_LAMP_PIN, st_status)
end --end blinky function

st_debouncer = 2
ht_debouncer = 15

poll = function() --poll keys and do actions

	if gpio.read(ST_KEY_PIN) == gpio.LOW then
		st_debouncer = st_debouncer - 1
	else
		st_debouncer = 2
	end

	if st_debouncer == 0 then
		if running == false then
			http.post(r_1xb)
		else
			http.post(s_1xb)
		end
	end

	-- check the traffic volume pin
	if gpio.read(HT_KEY_PIN) == down then
		ht_debouncer = ht_debouncer + 1
	else
		ht_debouncer = ht_debouncer - 1
	end

	if ht_debouncer > 17 then
			ht_debouncer = 17
	end

	if ht_debouncer < 13 then
			ht_debouncer = 13
	end

	if ht_debouncer == 17 then
		desired_load = "normal"
	elseif ht_debouncer == 13 then
		desired_load = "heavy"
	end

	-- if the now value is different than before value, make an API call
	if desired_load ~= current_load then
		print("Traffic load changing to: " .. tostring(desired_load))
		change_traffic_load(desired_load)
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
t_api:register(1000, tmr.ALARM_AUTO, get_app_status)
t_api:start()
