--
  -- Main Program. Runs automatically on start.
  -- Depends on global variables:
  -- sendData
--

--GLOBAL VARIABLES
STARTUP_WAIT = 10 --seconds before startup
dataList = {}
onInternetConnect = nil -- Function to be defined
wifiConnected = false
timeSynced = false

-- TODO should this be in uploadData? Seems kinda hidden though
function onInternetConnect()
  print("Internet is connected!!")
  wifiConnected = true
  sendData() -- defined within uploadData
end

function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed. Application will not be run until you restart the device.")
    else
        print("Running")
        file.close("init.lua")
        -- Global Configuration
        dofile("credentials.lua")
        -- Watch the sensor for door events and save this data:
        dofile("watchSensor.lua")
        -- Periodically upload the data to the internet (and ping also?)
        dofile("wifi.lua")
        dofile("uploadData.lua")
    end
end


print("\n\nDevice Started!")
print("You have "..STARTUP_WAIT.." seconds to delete or replace the init.lua script before startup will continue.")
print("Waiting...")
  tmr.create():alarm(STARTUP_WAIT * 1000, tmr.ALARM_SINGLE, startup)