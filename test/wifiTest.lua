-- Wifi Test

function connectToWifi (onConnectCb)
  print("Connecting To Wifi...\n")
  wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, onConnectCb)
  --connect to Access Point (TODO save config to flash so it doesnt need to be set each time?)
  wifi.setmode(wifi.STATION, true)
  station_cfg={}
  station_cfg.ssid="nick"
  station_cfg.pwd="sirisiri"
  --station_cfg.ssid="Papa"
  --station_cfg.pwd="tuktuk123"
  --station_cfg.save=false -- TODO make this true
  wifi.sta.config(station_cfg)
  print("connectToWifi function complete. Waiting for callbback")
end

function onWifiConnect()
  print("Wifi connected")
end

print("About to call connection fn")
status = connectToWifi(onWifiConnect)
print("Function called. Status is ", status)