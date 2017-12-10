--
  -- Uploads data to ubidots and disconnects from wifi. Assumes wifi is connected.
  -- Depends on global variables:
  -- wifiConnected, SENSOR_ID, MAX_UPLOAD_ATTEMPTS, wifiDisconnect, getADataFilename
--

currentFilename = nil

--UBIDOTS
local TOKEN=UBIDOTS_TOKEN
local LABEL_DEVICE=SENSOR_ID --defined in credentials
local LABEL_VARIABLE="state"
local LABEL_VARIABLE_COMPLETE="complete"
local endpoint = string.format(
  "http://things.ubidots.com/api/v1.6/devices/%s/%s/values/?token=%s", 
  LABEL_DEVICE,
  LABEL_VARIABLE,
  TOKEN
)
local endpoint_complete = string.format(
  "http://things.ubidots.com/api/v1.6/devices/%s/%s/values/?token=%s", 
  LABEL_DEVICE,
  LABEL_VARIABLE_COMPLETE,
  TOKEN
)
local headers = 'Host: things.ubidots.com\r\nContent-Type: application/json\r\n'

-- Checks if there are any files to upload, calls sendData with them or disconnects.
function syncWithInternet()
  print("syncWithInternet called")
  currentFilename = getADataFilename()
  if currentFilename ~= nil then
    -- Read multiline json file and encode it into one string to call sendData with.
    local f = file.open(currentFilename)
    local jsonString = "["
    local nextLine = f.readline()
    while nextLine ~= nil do
      jsonString = jsonString..nextLine
      nextLine = f.readline() -- This seems to include a newline character at the end of each line, but the API doesn't mind.
      if nextLine ~= nil then
        jsonString = jsonString..", "
      end
    end
    jsonString = jsonString.."]"
    f.close()
    sendData(jsonString)
  else
    -- Consider flushing datalist to a file here. or higher up.
    print("No more files to upload to the net. Sending an upload complete message")
    sendUploadComplete()
  end
end

function sendData(json)
  print("sendData called")
  print(json)

  http.post(
    endpoint,
    headers,
    json,
    onDataSendAck
  )
end

function sendUploadComplete()
  print("sendUploadComplete called")
  local rsec, rusec, rate = rtctime.get()
  local time = rsec*1000 + math.floor((rusec/1000) + 0.5)
  local json = '{"value":1,"timestamp":'..time..'}'
  print(json)

  http.post(
    endpoint_complete,
    headers,
    json,
    onDataUploadCompleteAck
  )
end


function onDataSendAck(code, data)
  if code == 200 or code == 201 then
    print("Data Upload Successful. Deleting file "..currentFilename)
    if currentFilename ~= nil then
      file.remove(currentFilename)
    end
    syncWithInternet()
  else
    print("HTTP request failed. Error code "..code..", and data: ", data)
    -- Keep trying until the wifi is disconnected. (Presumably the user would turn off the hotspot at some point.)
    if wifiConnected then
      syncWithInternet()
    end
  end
end

function onDataUploadCompleteAck(code, data)
  if code == 200 or code == 201 then
    print("Upload Complete Message Sent. Disconnecting From Wifi.")
    wifiDisconnect()
  else
    print("upload complete HTTP request failed. Error code "..code..", and data: ", data)
    -- Keep trying until the wifi is disconnected. (Presumably the user would turn off the hotspot at some point.)
    if wifiConnected then
      syncWithInternet()
    end
  end
end
