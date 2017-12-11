--
  -- Main Program. Runs automatically on start.
  -- Depends on global variables:
  -- syncWithInternet, internetConnectedLED
--

--GLOBAL VARIABLES
STARTUP_WAIT = 10 --seconds before startup
dataList = {}
onInternetConnect = nil -- Function to be defined
wifiConnected = false
timeSynced = false
fakeTimeSynced = false

-- TODO should this be in uploadData? Seems kinda hidden though
function onInternetConnect()
  print("Internet is connected!!")
  internetConnectedLED()
  wifiConnected = true
  saveFile()
  syncWithInternet() -- defined within uploadData
end

function startup()  
  offLED()
  if file.open("init.lua") == nil then
      print("init.lua deleted or renamed. Application will not be run until you restart the device.")
  else
      print("Running")
      file.close("init.lua")
      -- Global Configuration
      dofile("credentials.lua")
      dofile("settings.lua")
      -- Load time from file. Save it periodically
      dofile("time.lua")
      -- Watch the sensor for door events and save this data:
      dofile("watchSensor.lua")
      -- Save data to file, and provide a function for reading it back:
      dofile("fileManagement.lua")
      -- Periodically upload the data to the internet (and ping also?)
      dofile("wifi.lua")
      dofile("uploadData.lua")
    end
end


print("\n\nDevice Started!")
print("You have "..STARTUP_WAIT.." seconds to delete or replace the init.lua script before startup will continue.")
print("Waiting...")
-- Import LED functionality
dofile("led.lua")
onLED()
tmr.create():alarm(STARTUP_WAIT * 1000, tmr.ALARM_SINGLE, startup)