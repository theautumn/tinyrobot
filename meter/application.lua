-- TinyRobot, a Lua script that makes API calls to panel_gen
-- Sarah Autumn, 2020
require "sjson"
require "pwm"

-- set up some endpoints
server = "http://192.168.0.204:5000/api/switches/panel" -- set server URL

-- set some pins
CALL_PIN = 2
DIAL_PIN = 1

-- set some variables
dialing = 0
calls = 0
maxcalls = 8
maxdialing = 8
apidebounce = 2

-- set pwm feelings
-- pwm.function(pin, frequency, duty cycle)
pwm.setup(CALL_PIN, 1000, 0)
pwm.start(CALL_PIN)
pwm.setup(DIAL_PIN, 1000, 0)
pwm.start(DIAL_PIN)

function get_app_status()
	print(">>>>>>>  get app status")
	http.get(server,'',
	function(code, data)
		-- If no response from HTTP after 3 tries, flash the light.
		if (code < 0) then  -- if response empty
			print("App status HTTP request failed")
			if apidebounce == 0 then
					print("No response from API. Setting meters to 0.") 
					pwm.setduty(CALL_PIN, 0)
					pwm.setduty(DIAL_PIN, 0)
			else
				apidebounce = apidebounce - 1
				print("Debounce counter:", apidebounce)
			end
		else
			apidebounce = 2
			switchtable = sjson.decode(data)
			-- the API returns a table of tables so we have to use an index [1]
			-- lets figure out the PWM setting for the busy-ness factor
			calls = switchtable[1]["on_call"]
			callpwm = (calls * 1023) / maxcalls
--			dialing = switchtable[1]["is_dialing"]
--			dialpwm = (dialing * 1023) / maxdialing

			-- set some duty cycles
			pwm.setduty(CALL_PIN, callpwm)
--			pwm.setduty(DIAL_PIN, dialpwm)

			print('Calls:', calls .. ' / ' .. callpwm)
--			print('Dialing:', dialing .. ' / ' .. dialpwm)
		end --end switchtable checking loop
	end) --end callback function
end --end get_app_status()

-- HTTP GET function every 1 sec
t_api = tmr.create()
t_api:register(1000, tmr.ALARM_AUTO, get_app_status)
t_api:start()
