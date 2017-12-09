--
  -- LED flashing utility functions. 
  -- Depends on global variables:
  -- 
--

gpio.mode(0, gpio.OUTPUT)
gpio.write(0, gpio.HIGH)

LED_PIN = 0
state = false -- WIP state maintenance logic isn't quite right yet. WIP. For now assume previousState was always false (off)


function on()
  gpio.write(LED_PIN, gpio.LOW)
end

function off()
  gpio.write(LED_PIN, gpio.HIGH)
end


function blinkLED(duration, repeatCount) 
  off()
  for i = 1, repeatCount, 1 do
    tmr.create():alarm((2 * i - 1) * duration, tmr.ALARM_SINGLE, on)
    tmr.create():alarm(2 * i * duration, tmr.ALARM_SINGLE, off)
  end
end

function internetConnectedLED()
  blinkLED(1000, 5)
end

function doorChangeLED()
  blinkLED(100, 2)
end

function internetDisconnectLED()
  blinkLED(200, 1)
end