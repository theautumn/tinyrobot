-- TinyRobot, a Lua script that makes API calls to panel_gen
-- Sarah Autumn, 2019
require "sjson"
require "gpio"

server = "http://192.168.0.204:5000/api/app" -- set server URL
p_5xb = "http://192.168.0.204:5000/api/app/start/5xb?mode=demo&source=web"
--server = "http://jsonplaceholder.typicode.com/users/1"
led_pin = 0
key_pin = 1
status = gpio.HIGH
running = false
gpio.mode(led_pin, gpio.OUTPUT)
gpio.mode(key_pin, gpio.INPUT, gpio.PULLUP)
gpio.write(led_pin, status)

function get_from_api()
   http.get(server,'',
    function(code, data)
       -- If no response from HTTP, flash the light.
       if (code < 0) then
	  print("HTTP request failed")
	  t_blink:start()
       else
	  local tabla = sjson.decode(data)
	  
	  for k,v in pairs(tabla) do print(k,v) end
	  if tabla["app_running"] == true then
	     t_blink:stop()
        if tabla["xb5_running"] == true then	 
				gpio.write(led_pin, gpio.LOW)
	     else
				gpio.write(led_pin, gpio.HIGH)
	     end
	  end--end solid LED setting loop
	  
       end--end data/no data loop
   end)--end data handling function
end--end get_from_api()


function blink()
   if status == gpio.LOW then
      status = gpio.HIGH
   else
      status = gpio.LOW end
   
   gpio.write(led_pin, status)
end--end blinky function

debouncer = 4

poll = function()
   if gpio.read(key_pin) == gpio.LOW then
      debouncer = debouncer - 1
   else
      debouncer = 4
   end
   
   if debouncer == 0 then
      http.post(p_5xb)
   end
end

t_poll = tmr.create()
t_poll:register(100, tmr.ALARM_AUTO, poll)
t_poll:start()

t_blink = tmr.create()
t_blink:register(500, tmr.ALARM_AUTO, blink)

-- call get function after each 10 second
-- any code below tmr.alarm only gets run once
t_api = tmr.create()
t_api:register(5000, tmr.ALARM_AUTO, get_from_api)
t_api:start()
