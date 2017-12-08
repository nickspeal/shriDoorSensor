dataList = {}
cnt=0
wifiConnected = true -- assume connected is true because init handles wifi.
networkAvail = true
lastState = nil
pin=1
numDataPublished = 0
timeSynced = false
tryingTimeSync = false

function connectToWifi (onConnectCb)
  print("Connecting To Wifi...\n")
  wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, onConnectCb)
  --connect to Access Point (TODO save config to flash so it doesnt need to be set each time?)
  wifi.setmode(wifi.STATION, true)
  station_cfg={}
  --station_cfg.ssid="nick"
  --station_cfg.pwd="sirisiri"
  station_cfg.ssid="Papa"
  station_cfg.pwd="tuktuk123"
  station_cfg.save=false -- TODO make this true
  wifi.sta.config(station_cfg)
  print("connectToWifi function complete. Waiting for callbback")
end

function init()
--  connectToWifi(
--    function()
--      wifiConnected = true
--      print("Wifi Connected...")
--    end
--  )

  -- SET UP GPIO PIN
  mode=gpio.INPUT
  -- Use pullup so that the value is low when the door and circuit are closed
  pullup=gpio.PULLUP -- default is gpio.FLOAT
  gpio.mode(pin, mode, pullup)
  lastState = gpio.read(pin)
end

function pushData(edge)
  --Set limit to datalist length
  rsec, rusec, rate = rtctime.get()
  data = {}
  ctx = {}
  data["value"] = edge
  data["timestamp"] = rsec*1000 + math.floor((rusec/1000) + 0.5)
  print("Timestamp",rsec, rusec)
  ctx["cnt"] = cnt
  data["context"] = ctx
  cnt = cnt+1
  dataList[#dataList + 1] = data
end


function onDataSendAck(code, data)
  networkAvail = true
  if code == 200 then
    print("Acked network request:")
    print(data)
    -- Replace DataList array with only the tail of unsent data
    unsentData = {}
    for i = numDataPublished + 1, #dataList, 1
    do
      print("In loop: ", numDataPublished, #dataList, i)
      unsentData[#unsentData + 1] = dataList[i]
    end
    dataList = unsentData
  else
    print("HTTP request failed ", code, data)
  end
end

function sendData()
  --TODO: handle if out of memory
  --ok, json = pcall(sjson.encode, dataList)
  if #dataList == 0 then
    networkAvail = true
    return
  end
  json = sjson.encode(dataList)
  ok = true
  if ok then
    networkAvail = false
    numDataPublished = #dataList
    --TODO: Send Network Request!
    print("sending this data: ")
    print(json)
    TOKEN="A1E-VPavGWA9IgLsNgRPJ5zOUkuOvWp67j"
    LABEL_DEVICE="door-001"
    LABEL_VARIABLE="state"
    endpoint = string.format("http://things.ubidots.com/api/v1.6/devices/%s/%s/values/?token=%s", 
    LABEL_DEVICE, LABEL_VARIABLE, TOKEN)
    http.post(
      endpoint,
      'Content-Type: application/json\r\n',
      json,
      onDataSendAck)
  else
    print("Failed to encode!!")
  end
end

function checkGPIO ()
  newState = gpio.read(pin)
  if lastState ~= newState then
    if lastState == 0 then
      pushData(1) --Rising Edge Detected
    else
      pushData(0) --Falling edge Detected
    end
    lastState = newState
  end
end

function checkGPIOTrampoline ()
  if timeSynced then
    checkGPIO()
  end
end

function sendDataTrampoline()
  if timeSynced and wifiConnected and networkAvail then
      print("Calling SendData")
      sendData()
  end
end

function tryTimeSync()
  if not timeSynced and not tryingTimeSync and wifiConnected then
    tryingTimeSync = true
    sntp.sync("pool.ntp.org",
    function()
      print("Time Synced...")
      timeSynced = true
      tryingTimeSync = true
    end
    ,
    function()
      tryingTimeSync = false
      print('Time Sync Failed...')
    end,
    1)
  end
end
function main ()
  init()
  tmr.create():alarm(10, tmr.ALARM_AUTO, checkGPIOTrampoline)
  tmr.create():alarm(2000, tmr.ALARM_AUTO, sendDataTrampoline)
  tmr.create():alarm(1000, tmr.ALARM_AUTO, tryTimeSync)
end
main()
