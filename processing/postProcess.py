# Data Processing Script

# Fetch Data from network
	# all data, paginated
# Init counter at the first timestamp (round to lower Indian Midnight?)
# For each item in the data:
	# check if its timestamp is < current day + 24hours, > previous timestamp + 1 minute. If so, increment a tally for that day, else move to the next day
	# Somehow constrain open/close pairs to be together. Door could be normally open or normally closed
# Save an array of countedData. Array of objects of shape Date, Count, numRejections
# Create a CSV file with this array
# Print out the data for the last few days

import json
import math

# Load Data From File
f = open("data/tempData.json", "r")
encodedData = f.readlines();
if len(encodedData) > 1:
  print "Error: Expected input file to have only one line"
  exit()

results = json.loads(encodedData[0])

# Tally it up!
results.reverse() # TODO enforce sorted by timestamp instead, but this seems to work for now.
previousTimestamp = results[0]["timestamp"]
tally = [] #Array of objects of shape Date, Count, numRejections 
ONE_DAY = 1*3600*1000 # 24 hrs to Millis # 1 hr for now

# todaysDate = 0 # TODO format as datetime
# todaysCount = 0
# todaysRejections = 0
# for r in results:
#   if r["timestamp"] < previousTimestamp + ONE_DAY:
#     todaysCount += 1
#   else:
#     todaysDictionary = {date: todaysDate, count: todaysCount, numRejections: todaysRejections}
#     tally[todaysDate] = todaysDictionary
#     todaysDate += 1
#     todaysCount = 1 # Reset to 0 but then count this new one (if valid!)
#     todaysRejections = 0
#     previousTimestamp = r["timestamp"]
#     # ERROR - IM PRETTY SURE THIS IS OFF BY ONE AT THE END, NOT PUSHING THE LAST DATE!

# print("Processing completed: ", tally)

# Alternative loop strategy
# For each result, calculate time since start and add it to the tally

firstTimestamp = results[0]["timestamp"]
lastTimestamp = results[-1]["timestamp"]
numIntervals = lastTimestamp - firstTimestamp / MILLIS_PER_INTERVAL

cumulation = [0 for item in results]
for r in results:
  millisSinceStart = r["timestamp"] - previousTimestamp
  chunksSinceStart = int(math.floor(millisSinceStart / ONE_DAY))
  cumulation[chunksSinceStart] += 1



print ("procesing completed", cumulation)