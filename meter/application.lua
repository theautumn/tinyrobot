-- TinyRobot, a Lua script that makes API calls to panel_gen
-- Sarah Autumn, 2020
require "sjson"
require "pwm"

-- set up some endpoints
server = "http://192.168.0.204:5000/api/switches/panel" -- set server URL

-- set some pins
CALL_PIN = 1
DIAL_PIN = 2

-- set some variables
dialing = 0
calls = 0
maxcalls = 8
maxdialing = 6

-- set pwm feelings
PWM_frequency = 1000 -- Set PWM frequency
PWM_duty = 0  -- Set PWM duty cycle in between 0-1023

pwm.setup(CALL_PIN, PWM_frequency, PWM_duty)-- Setup PWM
pwm.start(CALL_PIN)   -- Start PWM on call  pin
pwm.setup(DIAL_PIN, PWM_frequency, PWM_duty)-- Setup PWM
pwm.start(DIAL_PIN)   -- Start PWM on call  pin

function get_app_status()
	print(">>>>>>>  get app status")
	http.get(server,'',
	function(code, data)
		-- If no response from HTTP after 3 tries, flash the light.
		if (code < 0) then  -- if response empty
			print("App status HTTP request failed")
			pwm.setduty(CALL_PIN, 0)
			pwm.setduty(DIAL_PINT, 0)
		else
			switchtable = sjson.decode(data)
			-- the API returns a table of tables so we have to use an index [1]
			calls = switchtable[1]["on_call"]
			callpwm = (calls * 1023) / maxcalls
			dialing = switchtable[1]["is_dialing"]
			dialpwm = (dialing * 1023) / maxdialing

			-- set some duty cycles
			pwm.setduty(CALL_PIN, callpwm)
			pwm.setduty(DIAL_PIN, dialpwm)

			print('Calls:', calls .. ' / ' .. callpwm)
			print('Dialing:', dialing .. ' / ' .. dialpwm)
		end --end switchtable checking loop
	end) --end callback function
end --end get_app_status()

-- HTTP GET function every 1 sec
t_api = tmr.create()
t_api:register(1000, tmr.ALARM_AUTO, get_app_status)
t_api:start()
