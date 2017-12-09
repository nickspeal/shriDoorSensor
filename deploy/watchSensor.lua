--
  -- Read sensor open and close events, append to buffer
  -- Depends on global variables:
  -- dataList, timeSynced, SAVE_WITHOUT_KNOWN_TIME, MAX_BUFFER_SIZE, DATA_SAVE_THRESHOLD, saveFile
--

local eventId = 0 -- increment a counter with each rising/falling edge event to detect missed data
local lastState = nil
local GPIO_PIN = 1
local SENSOR_SAMPLE_PERIOD = 100 -- millis. Previously I was using 10, but do we really care about missing data that lasts for such a short time?

local function setupGPIO()
  -- Use pullup so that the value is low when the door and circuit are closed. Default is gpio.FLOAT
  gpio.mode(GPIO_PIN, gpio.INPUT, gpio.PULLUP)
  lastState = gpio.read(GPIO_PIN)
  print("GPIO Ready. Curent state: "..lastState)
end

local function logEvent(edge)
  if edge == 1 then
    print("Door opened")
  else
    print("Door closed")
  end
  doorChangeLED()
end

local function saveData(edge)
  logEvent(edge)
  if not timeSynced and not SAVE_WITHOUT_KNOWN_TIME then
    print("Time is not yet synced. Data will not be saved. Set the flag in credentials to change this behaviour")
    return
  end

  -- Create a data object with the details of one open/close event
  local rsec, rusec, rate = rtctime.get()
  local data = {}
  local ctx = {}
  data["value"] = edge
  data["timestamp"] = rsec*1000 + math.floor((rusec/1000) + 0.5)
  ctx["timeSynced"] = timeSynced
  ctx["eventId"] = eventId
  data["context"] = ctx
  eventId = eventId + 1

  -- Append this data event to the dataList
  if #dataList < MAX_BUFFER_SIZE then
    dataList[#dataList + 1] = data
    print("Added to datalist. Length is now "..#dataList)
    if #dataList >= DATA_SAVE_THRESHOLD then
      saveFile()
    end
  else
    print("ERROR!!!! MAX DATALIST SIZE EXCEEDED. SAVE FILE MECHANISM IS NOT WORKING!")
    print("This event was not saved. Datalist length is: "..#dataList)
    -- This should never happen. The saveFile mechanism is not working. As a failsafe, save a file to clear some breathing room anyway.
    saveFile()
  end
end

function checkGPIO ()
  local newState = gpio.read(GPIO_PIN)
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
tmr.create():alarm(SENSOR_SAMPLE_PERIOD, tmr.ALARM_AUTO, checkGPIO)
