-- Variable Names must be caps!!!
--SSID = "Papa"
--PASSWORD = "tuktuk123"
--SSID = "nick"
--PASSWORD = "sirisiri"
SSID="AndroidAP"
PASSWORD="tuktuk123"

SENSOR_ID = "door-xxx"

--Settings
SAVE_WITHOUT_KNOWN_TIME = false -- Set to false to only save data if global timeSynced is true
WIFI_SLEEP_TIME = 5*60*1000 -- Time between wifi power ups, millis
MAX_BUFFER_SIZE = 46 -- In several tests, I ran out of memory after datalist had length 54, 57, 58 -- TODO measure in bytes not items. Also save to flash instead.
DATA_SAVE_THRESHOLD = 6 -- Might as well make this the same as the maximum JSON blob size, which should be moved here.