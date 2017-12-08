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
  uploading = false
  if code == 200 then
    print("Data Upload Successful.")
    upload_trial_count = 0
    -- print(data)
    -- Replace DataList array with only the tail of unsent data
    unsentData = {}
    for i = numDataPublished + 1, #dataList, 1 do
      unsentData[#unsentData + 1] = dataList[i]
    end
    dataList = unsentData
    if #dataList > 0 then
      print("Some new data was accumulated while the last request was being sent. Calling sendData again.")
      sendData()
    else
      print("dataList is empty. Disconnecting from wifi")
      wifiDisconnect()
    end
  else
    print("HTTP request failed ", code, data)
    upload_trial_count = upload_trial_count + 1
    if upload_trial_count < MAX_UPLOAD_ATTEMPTS then
      print("Trying again. Attempt #"..upload_trial_count)
      sendData()
    end
  end
end

function sendData()
  print("sendData called")
  --TODO: handle if out of memory
  --ok, json = pcall(sjson.encode, dataList)
  if #dataList > 0 then
    if #dataList > MAX_ENCODED_DATA_LENGTH then
      -- Only pop the first N items off the dataList queue
      subset = {}
      for i = 1, MAX_ENCODED_DATA_LENGTH, 1 do
        subset[i] = dataList[i]
      end
      json = sjson.encode(subset)
      print("Subset is of length "..#subset)
      numDataPublished = MAX_ENCODED_DATA_LENGTH
    else
      -- Send all remaining items from the queue
      json = sjson.encode(dataList)
      numDataPublished = #dataList
    end
    ok = true -- TODO should get feedback from encoding. Handle Error.
    if ok then
      print("sending this data: ")
      print(json)
      uploading = true
      http.post(
        endpoint,
        'Content-Type: application/json\r\n',
        json,
        onDataSendAck)
    else
      print("Failed to encode!!")
    end
  else
    print("No new data. Disconnecting from wifi.")
    wifiDisconnect()
  end
end

function wifiDisconnect()
  wifi.sta.disconnect()
  wifi.setmode(wifi.NULLMODE) -- low power mode
end
