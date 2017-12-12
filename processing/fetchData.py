# Data Fetching Script
# Fetches remote data and saves to a file

import requests
import json

## Fetch Data From Network
# Ref: https://ubidots.com/docs/api/#get-values

DEVICE_LABEL="door-001"
VARIABLE_LABEL="state"
TOKEN="A1E-VPavGWA9IgLsNgRPJ5zOUkuOvWp67j"
endpoint = "http://things.ubidots.com/api/v1.6/devices/{}/{}/values?token={}".format(DEVICE_LABEL, VARIABLE_LABEL, TOKEN)

print("Requesting data...")
# Fetch all pages
results = []
numPages = 0
while True:
  response = requests.get(endpoint)
  if response.status_code != 200:
    # Maybe try again?
    print("Error response! ", response.status_code, response.text)
  else:
    responseContent = response.json()
    results += responseContent['results']
    numPages += 1
    if responseContent['next']:
      print("Next page is ", responseContent['next'])
      endpoint = responseContent['next']
    else:
      print("Last page reached")
      break

print("Got all {} pages of results: {}".format(numPages, results))

## Write to file
f = open('data/tempData.json', "w")
encodedString = json.dumps(results)
f.write(encodedString)
f.close()

# Array of objects with shape: timestamp, created_at, value, context: cnt

