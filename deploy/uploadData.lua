--
  -- Uploads data to ubidots and disconnects from wifi. Assumes wifi is connected.
  -- Depends on global variables:
  -- wifiConnected, SENSOR_ID
--


numDataPublished = 0
uploading = false -- don't try a subsequent upload if already uploading. Instead continue to buffer and send after.
MAX_UPLOAD_ATTEMPTS = 10
upload_trial_count = 0
MAX_ENCODED_DATA_LENGTH = 6 -- Limit the number of datapoints to include in one request so that the JSON string doesn't run out of memory.
currentFilename = nil

--UBIDOTS
TOKEN="A1E-VPavGWA9IgLsNgRPJ5zOUkuOvWp67j" -- TODO regenerate and keep out of public github!
LABEL_DEVICE=SENSOR_ID --defined in credentials
LABEL_VARIABLE="state"
endpoint = string.format(
  "http://things.ubidots.com/api/v1.6/devices/%s/%s/values/?token=%s", 
  LABEL_DEVICE,
  LABEL_VARIABLE,
  TOKEN
)

function onDataSendAck(code, data)
  if code == 200 then
    print("Data Upload Successful. Deleting file "..currentFilename)
    upload_trial_count = 0
    if currentFilename ~= nil then
      file.remove(currentFilename)
    end
    syncWithInternet()
  else
    print("HTTP request failed ", code, data)
    upload_trial_count = upload_trial_count + 1
    if upload_trial_count < MAX_UPLOAD_ATTEMPTS then
      print("Trying again. Attempt #"..upload_trial_count.." of "..MAX_UPLOAD_ATTEMPTS)
      syncWithInternet()
    end
  end
end

-- Checks if there are any files to upload, calls sendData with them or disconnects.
function syncWithInternet()
  print("syncWithInternet called")
  local filenames = getFilenames()
  if #filenames > 0 then
    currentFilename = filenames[1]
    local f = file.open(currentFilename)
    local json = f.read()
    f.close()
    sendData(json)
  else
    -- Consider flushing datalist to a file here. or higher up.
    print("No more files to upload to the net. Disconnecting from wifi")
    wifiDisconnect()
  end
end

function sendData(json)
  print("sendData called")
  print(json)
  uploading = true
  http.post(
    endpoint,
    'Content-Type: application/json\r\n',
    json,
    onDataSendAck
  )
end

function wifiDisconnect()
  wifi.sta.disconnect()
  wifi.setmode(wifi.NULLMODE) -- low power mode
end
