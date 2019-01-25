-- TinyRobot, a Lua script that makes API calls to panel_gen
-- Sarah Autumn, 2019
require "sjson"
require "gpio"

--server = "http://192.168.0.204:5000/api/app" -- set server URL
server = "http://jsonplaceholder.typicode.com/users/1"
pin = 0
gpio.mode(pin, gpio.OUTPUT)
gpio.write(pin, gpio.HIGH)

function get_from_api()-- callback function for get data
	http.get(server,'',
	function(code, data)
	    if (code < 0) then
	     print("HTTP request failed")
	    else
		local t = sjson.decode(data)
		for k,v in pairs(t) do print(k,v) end

		local z = t["phone"] ~= nil
		print(z)
		if z == true then 
		   gpio.write(pin, gpio.LOW) end

		return t
	    end
	  end)
end

-- call get function after each 10 second
tmr.alarm(1, 10000, 1, function() get_from_api() end)
