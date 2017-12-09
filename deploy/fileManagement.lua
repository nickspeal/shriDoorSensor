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

local FILENAME_PREFIX = "saveddata-"
local FILENAME_EXTENSION = ".json"
recentFileIndex = 0 -- Keep track of the file which was most recently read. Chances are the next one is the next one.
local maxFileIndex = 200 -- starting assumption for what the highest file index might be

function formatFilename(number)
  return FILENAME_PREFIX..number..FILENAME_EXTENSION
end

-- Pop the first N items of the datalist list, encode them as a json string, and return it.
local function popJson()
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
      --json = sjson.encode(subset)
      jsonList = {}
      for i, event in pairs(subset) do
        jsonList[i] = sjson.encode(event)
      end
      numberOfEventsSaved = #subset
    else
      -- Send all remaining items from the list
      --json = sjson.encode(dataList)
      jsonList = {}
      for i, event in pairs(dataList) do
        jsonList[i] = sjson.encode(event)
      end
      numberOfEventsSaved = #dataList
    end

    -- remove the saved data from the dataList
    local unsavedData = {}
    for i = numberOfEventsSaved + 1, #dataList, 1 do -- TODO does this work if there is only 1 unsaved data? Not sure what happens in: for i = 7, 7, 1
      unsavedData[#unsavedData + 1] = dataList[i]
    end
    dataList = unsavedData
  end
  return jsonList
end

-- Find the lowest number for prefix-N.json that doesn't exist yet and write to it.
function saveFile()
  print("saveFile called")
  local json = popJson() -- TODO maybe this belongs elsewhere, so that two quick events don't call saveFile twice.
  if json ~= nil and #json > 0 then
    -- Find the lowest available file to write to
    local count = 1
    while true do
      if file.exists(formatFilename(count)) then
        count = count + 1
      else
        break
      end
    end

    print("Writing to data file # "..count)
    local f = file.open(formatFilename(count), 'w+')
    for i, event in pairs(json) do
      f.writeline(event)
    end
    f.close()
    print("Done writing to file.")
  else
    print("No JSON was found. Nothing to save.")
  end
end

-- Checks the filesystem and returns an arbitarily selected filename for a datafile
-- From a memory optimization perspective, first try to loop through the numbers and return those filenames
-- Then if nothing is found, only then check the file list. This avoids saving a huge list to memory, which is crashy.
function getADataFilename()
  -- TODO test and see how long it takes to check if N files exist.
  -- local rsec, rusec, rate = rtctime.get()
  -- print("About to loop, time: "..rsec)
  -- This loop takes 9 seconds per 100 files. Tradeoff time vs crashing. Larger loop takes more time for an empty filesystem, but less likely to crash
  
  if file.exists(formatFilename(recentFileIndex + 1)) then
    recentFileIndex = recentFileIndex + 1
    return formatFilename(recentFileIndex)
  end

  -- WARNING - THIS BLOCKS FOR MANY SECONDS, DOESNT ALLOW SENSOR SAMPLES!
  -- Check every STEP files, (5), to speed up the check and skip over gaps. The first check catches sequences and the last check catches anything missing
  for i = 1, maxFileIndex, 5 do
    if file.exists(formatFilename(i)) then
     recentFileIndex = i
     return formatFilename(i)
   end
  end
  -- rsec, rusec, rate = rtctime.get()
  -- print("looped. Time: "..rsec)
  print("Looped through all the numbers and didn't find any files. Checking file list for stragglers.")

  for filename, size in pairs(file.list()) do
    if string.find(filename, FILENAME_PREFIX) then
      print("Found a stragler! "..filename)
      return filename
    end
  end
  print("Done with 2 loops and no data files found. Returning nil")
  return nil
end

-- saveFile is called whenever the dataList fills up, but also periodically here to avoid data loss of a partial datalist during a power cycle
tmr.create():alarm(FILE_SAVE_INTERVAL, tmr.ALARM_AUTO, saveFile)