-- TinyRobot, a Lua script that makes API calls to panel_gen
-- Sarah Autumn, 2019
require "sjson"
require "gpio"

server = "http://192.168.0.204:5000/api/app" -- set server URL
--server = "http://jsonplaceholder.typicode.com/users/1"
pin = 0
status = gpio.HIGH
gpio.mode(pin, gpio.OUTPUT)
gpio.write(pin, status)

function get_from_api()
	http.get(server,'',
	function(code, data)
	-- If no response from HTTP, flash the light.
	    if (code < 0) then
				print("HTTP request failed")
				tmr.alarm(0, 500, 1, function ()
				if status == gpio.LOW then
					status = gpio.HIGH
				else
					status = gpio.LOW end

				gpio.write(pin, status)
end)--End flashy function

	    else
				local tabla = sjson.decode(data)

				for k,v in pairs(tabla) do print(k,v) end
				if tabla["app_running"] == true then
					tmr.stop(0)
					gpio.write(0, gpio.LOW)
				end--end solid LED setting loop

	    end--end data/no data loop
	  end)--end data handling function
end

-- call get function after each 10 second
-- any code below tmr.alarm only gets run once
tmr.alarm(1, 10000, 1, function() get_from_api() end)
