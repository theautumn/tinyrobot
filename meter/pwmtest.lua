require "pwm"

CALL_PIN = 1

PWMfrequency = 1000 -- Set PWM frequency
PWMDutyCycle = 512  -- Set PWM duty cycle in between 0-1023

pwm.setup(CALL_PIN, PWMfrequency, PWMDutyCycle)-- Setup PWM
pwm.start(CALL_PIN)   -- Start PWM on LED pin

lastpwm = 0
thispwm = 0

while(1)
do
		thispwm = lastpwm + 20
		if thispwm <= 1023 then --set a max before we go back down again
			lastpwm = thispwm
    		pwm.setduty(CALL_PIN, thispwm)-- set PWM duty cycle to LED brightness
    		print('Duty Cycle:',math.floor(100*thispwm/1000))-- print LED brightness
		else
			lastpwm = 0
			thispwm = 0
		end
    tmr.delay(100000)   -- timer delay of 100000 us
end
