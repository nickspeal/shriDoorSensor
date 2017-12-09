--
  -- File Management: Witing and Reading
  -- Depends on global variables:
  -- dataList, MAX_ENCODED_DATA_LENGTH, FILE_SAVE_INTERVAL
--

-- datstructure 1b
--   Writing
--     Write to the lowest number that doesn't exist
--     i.e. loop through numbers checking for file existence until empty is found
--   Reading
--     List all files
--     For each file, if filename contains the magic string, then try to upload it. On success, delete it.
--   Minor potential problem
--     Wacky order could come from stack style where low numbers are read first and written first
--     Maybe could loop through list of files in reverse order, to mostly, but not perfectly, sovle the problem

FILENAME_PREFIX = "saveddata-"
FILENAME_EXTENSION = ".json"

-- Pop the first N items of the datalist list, encode them as a json string, and return it.
function popJson()
  local json = nil
  local subset = {}
  local numberOfEventsSaved

  if #dataList > 0 then
    -- Encode JSON
    if #dataList > MAX_ENCODED_DATA_LENGTH then
      -- Only pop the first N items off the dataList list    
      for i = 1, MAX_ENCODED_DATA_LENGTH, 1 do
        subset[i] = dataList[i]
      end
      --ok, json = pcall(sjson.encode, dataList)
      json = sjson.encode(subset)
      numberOfEventsSaved = #subset
    else
      -- Send all remaining items from the list
      json = sjson.encode(dataList)
      numberOfEventsSaved = #dataList
    end

    -- remove the saved data from the dataList
    local unsavedData = {}
    for i = numberOfEventsSaved + 1, #dataList, 1 do -- TODO does this work if there is only 1 unsaved data? Not sure what happens in: for i = 7, 7, 1
      unsavedData[#unsavedData + 1] = dataList[i]
    end
    dataList = unsavedData
  end
  return json
end

-- Find the lowest number for prefix-N.json that doesn't exist yet and write to it.
function saveFile()
  print("saveFile called")
  local json = popJson() -- TODO maybe this belongs elsewhere, so that two quick events don't call saveFile twice.
  if json ~= nil then
    local count = 1
    while true do
      if file.exists(FILENAME_PREFIX..count..FILENAME_EXTENSION) then
        count = count + 1
      else
        break
      end
    end

    print("Count for first non-existent file is: "..count)
    local f = file.open(FILENAME_PREFIX..count..FILENAME_EXTENSION, 'w')
    f.write(json)
    f.close()
    print("Done writing to file.")
  else
    print("No JSON was found. Nothing to save.")
  end
end

-- Checks the filesystem and returns a list of filenames matching data files.
function getFilenames()
  print("Searching for data files...")
  local filenames = {}
  for filename in pairs(file.list()) do
    if string.find(filename, FILENAME_PREFIX) then
      filenames[#filenames + 1] = filename
    end
  end
  return filenames
end

-- saveFile is called whenever the dataList fills up, but also periodically here to avoid data loss of a partial datalist during a power cycle
tmr.create():alarm(FILE_SAVE_INTERVAL, tmr.ALARM_AUTO, saveFile)