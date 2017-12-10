--Settings
SAVE_WITHOUT_KNOWN_TIME = false -- Set to false to only save data if global timeSynced is true
WIFI_SLEEP_TIME = 5*60*1000 -- Time between wifi power ups, millis
MAX_BUFFER_SIZE = 50 -- In several tests, I ran out of memory after datalist had length 54, 57, 58 -- at which point node.heap() got down to ~3000
DATA_SAVE_THRESHOLD = 20 -- Might as well make this the same as the maximum JSON blob size, MAX_ENCODED_DATA_LENGTH.
MAX_ENCODED_DATA_LENGTH = 20 -- Limit the number of datapoints to include in one request so that the JSON string doesn't run out of memory.
FILE_SAVE_INTERVAL = 15*60*1000 -- Save datalist to file every N minutes (millis)
WIFI_CONNECT_MAX_ATTEMPTS = 30 -- How many times to try to connect to wifi
TIME_SAVE_INTERVAL = 11*60*1000 -- How often to save time to file.