-- TinyRobot, a Lua script that makes API calls to panel_gen
-- Sarah Autumn, 2019
require "sjson"
require "gpio"

-- set up some endpoints
server = "http://192.168.0.204:5000/api/switches/panel" -- set server URL
run_panel = "http://192.168.0.204:5000/api/app/start/panel?mode=demo&source=key"
stop_panel = "http://192.168.0.204:5000/api/app/stop/panel?source=key"

LED_PIN = 2
KEY_PIN = 1
HIGHVOL_PIN = 5
status = gpio.HIGH -- flashes lamp momentarily on startup
running = false --stores a local state as a buffer
flash_countdown = 4 -- allows for a couple of no response before blink
desired_traffic  = nil -- traffic volume controlled by secondary key
last_traffic = ""

-- set pin modes
gpio.mode(LED_PIN, gpio.OUTPUT)
gpio.mode(KEY_PIN, gpio.INPUT, gpio.PULLUP)
gpio.mode(HIGHVOL_PIN, gpio.INPUT, gpio.PULLUP)
gpio.write(LED_PIN, status)

function get_app_status()
   print(">>>>>>>  get app status")
   http.get(server,'',
   function(code, data)
	 print("evaluating HTTP data")
    -- If no response from HTTP after 3 tries, flash the light.
	if (code < 0) then  -- if response empty
		print("App status HTTP request failed")
		if flash_countdown == 0 then -- if debouncer has run down
			blinking, mode = t_blink:state()
				print("Blinking " .. tostring(blinking))
				-- if timer not already running
				if blinking == false then
					t_blink:start()
					print("Blink start issued!")
	  			end
		else
			flash_countdown = flash_countdown -1
			print("Debounce counter: " .. tostring(flash_countdown))
		end
	else
		-- if api is accessible and blinky is still running, stop error blinky
		-- reset flash_countdown, and grab the table
		flash_countdown = 2
		switchtable = sjson.decode(data)
		blinking, mode = t_blink:state()
		if blinking == true then
			t_blink:stop()
			print("Blink *stop* issued!")
		end
		-- the API returns a table of tables so we have to use an index [1]
		if switchtable[1]["running"] == true then
			gpio.write(LED_PIN, gpio.HIGH) -- lamp ON
			running = true
		elseif switchtable[1]["running"] == false then
			gpio.write(LED_PIN, gpio.LOW) -- lamp OFF
 			running = false
		end --end switchtable checking loop
	end --end API running check loop
   end) --end callback function
end --end get_app_status()

function change_traffic_load(desired_load)
	print("changing traffic load <<<<<<<<<")
	if switchtable == nil or switchtable == {} then
		print("________________switchtable empty")
		return 
	end
	for index, data in ipairs(switchtable) do
    print(index)

    for key, value in pairs(data) do
      print('\t', key, value)
    end
  end
	
	local current_load = tostring(switchtable[1]["traffic_load"])

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
	last_traffic = desired_load
end --end GET callback function


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
