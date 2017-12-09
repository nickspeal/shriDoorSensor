--
  -- LED flashing utility functions. 
  -- Depends on global variables:
  -- 
--

gpio.mode(0, gpio.OUTPUT)
gpio.write(0, gpio.HIGH)

local LED_PIN = 0
local STEADY_STATE_ON = false -- WIP state maintenance logic isn't quite right yet. WIP. For now assume previousState was always false (off)


function onLED()
  gpio.write(LED_PIN, gpio.LOW)
end

function offLED()
  gpio.write(LED_PIN, gpio.HIGH)
end


function blinkLED(duration, repeatCount) 
  offLED()
  for i = 1, repeatCount, 1 do
    tmr.create():alarm((2 * i - 1) * duration, tmr.ALARM_SINGLE, onLED)
    tmr.create():alarm(2 * i * duration, tmr.ALARM_SINGLE, offLED)
  end
  if STEADY_STATE_ON then
    tmr.create():alarm(2 * repeatCount * duration, tmr.ALARM_SINGLE, onLED)
  else
    tmr.create():alarm(2 * repeatCount * duration, tmr.ALARM_SINGLE, offLED)
  end
end

function internetConnectedLED()
  STEADY_STATE_ON = true
  onLED()
end

function doorChangeLED()
  blinkLED(100, 2)
end

function internetDisconnectLED()
  STEADY_STATE_ON = false
  blinkLED(200, 1)
end