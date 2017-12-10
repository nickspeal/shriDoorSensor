--
  -- Periodically save the time to a file. Load it on startup so an approximate time can be used until the internet is connected.
  -- Global Variables Needed:
  -- TIME_SAVE_INTERVAL, fakeTimeSynced
--

local TIME_FILE = "lasttime.txt"
local lastTime = 0
local OFFSET = 10 -- At a minimum account for the offset from the init startup time. 

if file.exists(TIME_FILE) then
  local f = file.open(TIME_FILE, 'r')
  lastTime = f.read()
  f.close()
  rtctime.set(lastTime + OFFSET, 0)
  fakeTimeSynced = true
  print("last time from file was "..lastTime)
else
  print("No time file exists.")
end

function saveTime()
  local secondsFromEpoch = rtctime.get()
  local f = file.open(TIME_FILE, 'w+')
  f.write(secondsFromEpoch)
  f.close()
  print("Saved time to file "..secondsFromEpoch)
end

tmr.create():alarm(TIME_SAVE_INTERVAL, tmr.ALARM_AUTO, saveTime)