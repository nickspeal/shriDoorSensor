# Data Fetching Script
# Fetches remote data and saves to a file

# Notes
# 504 response corresponds to bad token. Actually gateway timeout. Maybe an inappropriate propagated error
# requests.exceptions.ConnectionError can be thrown on HTTP timeout or retries exceeded

from __future__ import print_function
import requests
import json

# Constants
BASE_URL = 'http://things.ubidots.com/api/v1.6/'
DATA_VAR = "state"
COMPLETE_VAR = "complete"
TOKEN_FILENAME = "TOKEN"
MAX_ERRORS = 5

def load_token():
  # Load Token from file
  try:
    f = open(TOKEN_FILENAME, 'r')
    global api_token
    api_token = f.read()
    f.close()

  except IOError:
    print('TOKEN NOT DEFINED')
    print('The Ubudots Access Token needs to be saved alone in a (gitignored) file called {}, saved in the same directory as this script.'.format(TOKEN_FILENAME))
    print('Find the token at https://app.ubidots.com/userdata/api/')
    exit()

def make_get_request(endpoint):
  url = BASE_URL + endpoint
  headers = {'X-Auth-Token': api_token}
  print("Making GET request to: ", url)
  return requests.get(url, headers=headers)
  
def fetch_all_pages_of_results(endpoint):
  results = []
  page_index = 1
  more_data_to_fetch = True
  error_count = 0
  while more_data_to_fetch and error_count < MAX_ERRORS:
    valuesEndpoint = '{}?page={}'.format(endpoint, page_index)
    response = response = make_get_request(valuesEndpoint)
    if response.status_code != 200:
      # Maybe try again? X times
      print("Error response! ", response.status_code, response.text)
      error_count += 1
    else:
      # count previous next results
      print("Got Data for {}".format(valuesEndpoint))
      responseContent = response.json()
      for r in responseContent['results']:
        results.append(r)
      if responseContent['next']:
        print("Next page is ", responseContent['next'])
        page_index += 1
      else:
        print("Last page reached")
        more_data_to_fetch = False

    print("Got all {} pages of results.".format(page_index))
    return results

def fetch_device_list():
  response = make_get_request("datasources")
  if response.status_code != 200:
    # Maybe try again?
    print("Error Fetching Device List: ", response.status_code, response.text)
    exit()
  else:
    responseContent = response.json()
    # count, previous, results, next
    names = []
    for device in responseContent['results']:
      names.append(device['name'])
    print("{} devices are registered under this account:".format(responseContent['count']))
    print(names)
    print("\n\n")
    # return ["nemua-men-2"] # hardcoded during development
    return names

def fetch_event_data(device):
  #Fetch event data for this device
  # Ref: https://ubidots.com/docs/api/#get-values
  # Array of objects with shape: timestamp, created_at, value, context: {}
  results = fetch_all_pages_of_results('devices/{}/{}/values'.format(device, DATA_VAR))  

  ## Write to file
  filename = 'data/{}-{}.json'.format(device, DATA_VAR)
  f = open(filename, "w")
  for r in results:
    print(json.dumps(r), file=f)
  f.close()
  print("Done writing to file", filename)

def fetch_complete_data(device):
  # Fetch Complete Data
  results = fetch_all_pages_of_results('devices/{}/{}/values'.format(device, COMPLETE_VAR))
  timestamps = [r['timestamp'] for r in results]

  ## Write to file
  filename = 'data/{}-{}.json'.format(device, COMPLETE_VAR)
  f = open(filename, "w")
  for r in timestamps:
    print(json.dumps(r), file=f)
  f.close()
  print("Done writing to file", filename)

def main():
  load_token()
  deviceNames = fetch_device_list()
  for device in deviceNames:
    # Fetch and save to file
    fetch_event_data(device)
    fetch_complete_data(device)

main()