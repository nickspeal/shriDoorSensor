--
  -- Periodically connects to wifi network & internet and calls callback on success
  -- Depends on global variables:
  -- onInternetConnect, WIFI_SLEEP_TIME, wifiConnected, WIFI_CONNECT_MAX_ATTEMPTS
--

TIME_SYNC_WAIT_TIME = 5000 -- How long to wait before trying to time sync again, millis
TIME_SYNC_MAX_ATTEMPTS = 10 -- Max number of attempts before giving up
time_sync_count = 0
disconnect_ct = 0
WIFI_CONFIG = {
  ssid=SSID,
  pwd=PASSWORD,
  save=false,
}
tryingTimeSync = false

-- Define WiFi station event callbacks
onWifiConnect = function(T)
  print("Connection to AP("..T.SSID..") established!")
  print("Waiting for IP address...")
  disconnect_ct = 0
end

onIPAssignment = function(T)
  -- Note: Having an IP address does not mean there is internet access!
  -- Internet connectivity can be determined with net.dns.resolve().
  print("IP address is: "..T.IP)
  print("Waiting for Internet connectivity and NTP Time...")
  time_sync_count = 0
  tryTimeSync()
end

onTimeSyncSuccess = function(T)
  print("Time Synced!")
  timeSynced = true
  tryingTimeSync = false
  onInternetConnect()
end


onTimeSyncFail = function(T)
  time_sync_count = time_sync_count + 1
  print('Time Sync Failure #'..time_sync_count)
  tryingTimeSync = false
  -- Try again later
  tmr.create():alarm(TIME_SYNC_WAIT_TIME, tmr.ALARM_SINGLE, tryTimeSync)
end

onWifiDisconnect = function(T)
  print("\nDisconnected from WiFi with SSID: "..T.SSID)
  internetDisconnectLED()
  wifiConnected = false
  
  if T.reason == wifi.eventmon.reason.ASSOC_LEAVE then
    --the station has disassociated from a previously connected AP
    return
  end

  --There are many possible disconnect reasons, the following iterates through
  --the list and returns the string corresponding to the disconnect reason.
  for key,val in pairs(wifi.eventmon.reason) do
    if val == T.reason then
      print("Disconnect reason: "..val.."("..key..")")
      break
    end
  end

 
  disconnect_ct = disconnect_ct + 1
  if disconnect_ct < WIFI_CONNECT_MAX_ATTEMPTS then
    print("Retrying connection...(attempt "..(disconnect_ct+1).." of "..WIFI_CONNECT_MAX_ATTEMPTS..")")
  else
    wifi.sta.disconnect()
    print("Aborting connection to AP and resetting count!")
    disconnect_ct = 0
  end
end

function tryTimeSync()
  if time_sync_count < TIME_SYNC_MAX_ATTEMPTS then
    if not tryingTimeSync then
      tryingTimeSync = true
      sntp.sync("pool.ntp.org", onTimeSyncSuccess, onTimeSyncFail, nil)
    else
      tmr.create():alarm(TIME_SYNC_WAIT_TIME, tmr.ALARM_SINGLE, tryTimeSync)
    end
  else
    print("Time Sync Max Attempts Exceeded: "..time_sync_count)
  end
end

function connectToWifi()
  if wifiConnected then
    print("connectToWifi called but Wifi is already connected.")
  else
    print("Connecting to WiFi access point "..SSID.."...")
    -- wifi.sta.disconnect() -- is this needed?
    wifi.setmode(wifi.STATION)
    wifi.sta.autoconnect(0) -- Disable autoconnecting. I want power control.
    wifi.sta.config(WIFI_CONFIG)
    wifi.sta.connect()
  end
end

-- Register WiFi Station event callbacks
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, onWifiConnect)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, onIPAssignment)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, onWifiDisconnect)

connectToWifi()
tmr.create():alarm(WIFI_SLEEP_TIME, tmr.ALARM_AUTO, connectToWifi)
