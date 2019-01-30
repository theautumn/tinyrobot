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
n_resp = 2 -- allows for a couple of no response before blink

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
	  n_resp = n_resp - 1
	  if n_resp == 0 then
	     t_blink:start()
	     print("...blinking...")
	  end
       else
	  local tabla = sjson.decode(data)
	  n_resp = 2 
	  print("API Running " .. tostring(tabla["app_running"]))
	  print("5XB Running " .. tostring(tabla["xb5_running"]))
	  -- if api is accessible, stop error blinky
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
