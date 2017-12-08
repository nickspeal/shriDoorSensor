--
  -- Read sensor open and close events, append to buffer
  -- Depends on global variables:
  -- dataList, timeSynced, SAVE_WITHOUT_KNOWN_TIME, 
--

eventId = 0 -- increment a counter with each rising/falling edge event to detect missed data
lastState = nil
GPIO_PIN = 1
MAX_BUFFER_SIZE = 100 -- In one test, I ran out of memory after datalist had length 113 -- TODO measure in bytes not items. Also save to flash instead.

function setupGPIO()
  mode = gpio.INPUT
  -- Use pullup so that the value is low when the door and circuit are closed. Default is gpio.FLOAT
  pullup = gpio.PULLUP
  gpio.mode(GPIO_PIN, mode, pullup)
  lastState = gpio.read(GPIO_PIN)
  print("GPIO Ready. Curent state: "..lastState)
end

function logEvent(edge)
  if edge == 1 then
    print("Door opened")
  else
    print("Door closed")
  end
  -- TODO Flash LED
end

function saveData(edge)
  logEvent(edge)
  if not timeSynced and not SAVE_WITHOUT_KNOWN_TIME then
    print("Time is not yet synced. Data will not be saved. Set the flag in credentials to change this behaviour")
    return
  end

  --TODO check and set limit to datalist length?
  rsec, rusec, rate = rtctime.get()
  data = {}
  ctx = {}
  data["value"] = edge
  data["timestamp"] = rsec*1000 + math.floor((rusec/1000) + 0.5)
  ctx["timeSynced"] = timeSynced -- TODO retroactively sync up old data
  ctx["eventId"] = eventId
  data["context"] = ctx
  eventId = eventId+1
  if #dataList < MAX_BUFFER_SIZE then
    dataList[#dataList + 1] = data
    print("Added to datalist. Length is now "..#dataList)
  else
    print("Maximum dataList size exceeded. This event was not saved. Datalist length is: "..#dataList)
  end
end

function checkGPIO ()
  newState = gpio.read(GPIO_PIN)
  if lastState ~= newState then
    if lastState == 0 then
      saveData(1) --Rising Edge Detected
    else
      saveData(0) --Falling edge Detected
    end
    lastState = newState
  end
end


setupGPIO()
tmr.create():alarm(10, tmr.ALARM_AUTO, checkGPIO)

