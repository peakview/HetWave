--pinPWM1=12 --SK,SCLK

pinPWM1a=1
pwm.setup(pinPWM1a,500,1023) -- (pin, clock, duty)
pwm.start(pinPWM1a)
pinPWM1b=2
gpio.mode(pinPWM1b,gpio.OUTPUT,gpio.PULLUP)
gpio.write(pinPWM1b, gpio.LOW)

pinPWM2a=3
pwm.setup(pinPWM2a,500,1023) -- (pin, clock, duty)
pwm.start(pinPWM2a)
pinPWM2b=4
gpio.mode(pinPWM2b,gpio.OUTPUT,gpio.PULLUP)
gpio.write(pinPWM2b, gpio.LOW)

pinNSLEEP=0
gpio.mode(pinNSLEEP,gpio.OUTPUT,gpio.PULLUP)
gpio.write(pinNSLEEP, gpio.HIGH)


gpio.write(pinNSLEEP, gpio.LOW)

pwm.setduty(pinPWM1a, 70)
pwm.setduty(pinPWM2a, 70)

pwm.setduty(pinPWM1a, 700)
pwm.setduty(pinPWM2a, 700)

pwm.close(pinPWM1a)
print(string.format("%d",pinPWM1a) .. "close")
pwm.close(pinPWM2a)
