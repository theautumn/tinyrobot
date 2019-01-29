-- TinyRobot, a Lua script that makes API calls to panel_gen
-- Sarah Autumn, 2019
require "sjson"
require "gpio"

-- set up some endpoints
server = "http://192.168.0.204:5000/api/app" -- set server URL
r_5xb = "http://192.168.0.204:5000/api/app/start/5xb?mode=demo"
s_5xb = "http://192.168.0.204:5000/api/app/stop/5xb"

led_pin = 2
key_pin = 1
status = gpio.LOW -- start with lamp off
running = false --stores a local state as a buffer
api_dtimer = 3 -- debounces blink state 

-- set pin modes
gpio.mode(led_pin, gpio.OUTPUT)
gpio.mode(key_pin, gpio.INPUT, gpio.PULLUP)
gpio.write(led_pin, status)

function get_from_api()
   http.get(server,'',
   function(code, data)
       -- If no response from HTTP after 3 tries, flash the light.
       if (code < 0) then
          print("HTTP request failed")
	  api_dtimer = api_dtimer - 1
	  if api_dtimer == 0 then
	     t_blink:start()
	  end
       else
	  local tabla = sjson.decode(data)
	  api_dtimer = 3 
	  for k,v in pairs(tabla) do print(k,v) end
	  -- if the app is runing, turn off the light
	  if tabla["app_running"] == true then
	     t_blink:stop()
              if tabla["xb5_running"] == true then	 
                 gpio.write(led_pin, gpio.LOW) -- lamp ON
                 running = true
	      elseif tabla["xb5_running"] == false then
                 gpio.write(led_pin, gpio.HIGH) -- lamp OFF
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
      status = gpio.LOW end
   
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
	 http.post(r_5xb)
      else
	 http.post(s_5xb)
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
