-- TinyRobot, a Lua script that makes API calls to panel_gen
-- Sarah Autumn, 2019
require "sjson"
require "gpio"

-- set up some endpoints
server = "http://192.168.0.204:5000/api/app" -- set server URL
run_panel = "http://192.168.0.204:5000/api/app/start/panel?mode=demo&source=key"
stop_panel = "http://192.168.0.204:5000/api/app/stop/panel?source=key"
hv_panel = "http://192.168.0.204:5000/api/switches/panel"

LED_PIN = 2
KEY_PIN = 1
HIGHVOL_PIN = 5
status = gpio.HIGH -- flashes lamp momentarily on startup
running = false --stores a local state as a buffer
flash_countdown = 4 -- allows for a couple of no response before blink
desired_traffic  = "" -- traffic volume controlled by secondary key
last_traffic = "normal"

-- set pin modes
gpio.mode(LED_PIN, gpio.OUTPUT)
gpio.mode(KEY_PIN, gpio.INPUT, gpio.PULLUP)
gpio.mode(HIGHVOL_PIN, gpio.INPUT, gpio.PULLUP)
gpio.write(LED_PIN, status)

function get_app_status()
   http.get(server,'',
   function(code, data)
       -- If no response from HTTP after 3 tries, flash the light.
	if (code < 0) then  -- if response empty
		print("App status HTTP request failed")
		if flash_countdown == 0 then  -- if debouncer has run down
			blinking, mode = t_blink:state()
				print("Blinking " .. tostring(blinking))
				if blinking == false then	-- if timer not already running
					t_blink:start()
					print("Blink start issued!")
	  			end
		else
			flash_countdown = flash_countdown -1
			print("Debounce counter: " .. tostring(flash_countdown))
		end
	else
		flash_countdown = 2
		local tabla = sjson.decode(data)
--		print("API Running " .. tostring(tabla["app_running"]))
--		print("Panel Running " .. tostring(tabla["panel_running"]))

	-- if api is accessible and blinky is still running, stop error blinky
	if tabla["app_running"] == true then
		blinking, mode = t_blink:state()
		if blinking == true then
			t_blink:stop()
			print("Blink *stop* issued!")
		end
		if tabla["panel_running"] == true then
			gpio.write(LED_PIN, gpio.HIGH) -- lamp ON
			running = true
		elseif tabla["panel_running"] == false then
			gpio.write(LED_PIN, gpio.LOW) -- lamp OFF
 			running = false
		end --end switch checking loop
	end --end API running check loop

       end --end data/no data loop
   end) --end callback function
end --end get_app_status()

function change_traffic_load(desired_load)
	http.get(hv_panel,'',
	function(code, data)
		if (code < 0) then -- if response empty
			print("Traffic load HTTP response empty")
		else
			local switchtable = sjson.decode(data)
			current_load = tostring(switchtable[1]["traffic_load"])
			print("Current load " .. current_load)
		end --end if

		if current_load ~= desired_load then
			print("Changing the business!")
			http.request(hv_panel,	-- send kercheep a PATCH!
				'PATCH',
				'Content-Type: application/json\r\n',
				'{"traffic_load": "'.. desired_load ..'"}',
				function(code, data)
					if (code < 0) then
						print("oh boy something fucked up")
					elseif (code == 200) then
						last_traffic = desired_load
						print("Business has been changed heck yeah!")
					end --end if
				end) -- end PATCH callback function
		end -- end main IF block
	end) --end GET callback function
end


function blink() --blink led
   if status == gpio.LOW then
      status = gpio.HIGH
   else
      status = gpio.LOW end

   gpio.write(LED_PIN, status)
end --end blinky function

debouncer = 2
debouncerdeux = 2

poll = function() --poll keys and do actions

   if gpio.read(KEY_PIN) == gpio.LOW then
      debouncer = debouncer - 1
   else
      debouncer = 2
   end

   if debouncer == 0 then
      if running == false then
			http.post(run_panel)
      else
			http.post(stop_panel)
      end
   end

	-- check the traffic volume pin
	if gpio.read(HIGHVOL_PIN) == gpio.HIGH then

		 	desired_load = "normal"
	else
			desired_load = "heavy"
	end
	-- if the now value is different than before value, make an API call
	if desired_load ~= last_traffic then
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
