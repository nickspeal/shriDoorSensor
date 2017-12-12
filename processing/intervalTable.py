# Parses JSON event data into a list of event objects
# Considers the time between each event as an interval
# Prints a timeseries of all the events and intervals
# Prints summary info

import json
import math
import os
import sys
import time

# Notes
# In the case of a brief interval, stitch the before and after intervals together (create a new Interval with those events?)


# Define bounds for a period of door closure time that counts as closed.
USAGE_DURATION_MIN = 10 *1000
USAGE_DURATION_MAX = 10*60*1000


class Event:
  def __init__(self, eventDictionary):
    self.timestamp = eventDictionary['timestamp']
    self.value = eventDictionary['value']
    self.event_id = eventDictionary['context']['eventId']
    try:
      self.time_synced = eventDictionary['context']['timeSynced']
    except KeyError:
      self.time_synced = None
    try:
      self.created_at = eventDictionary['created_at']
    except KeyError:
      self.created_at = None

  def print_data(self):
    # Date/Time - TODO format as human readable
    event_type = 'opened' if self.value == 1 else 'closed'
    string = 'id: {}\t{}\t{}'.format(self.event_id, format_time(self.timestamp), event_type)
    # if self.time_synced == False:
    #   string += '  -- Time Not Synced Since Power Failure'
    print(string)

class Interval:
  def __init__(self, previous_event, next_event):
    self.previous = previous_event
    self.next = next_event
    self.duration = next_event.timestamp - previous_event.timestamp
    self.door_position = 'closed' if previous_event.value == 0 else 'open'
    self.occupied = self.check_if_occupied()

  def check_if_occupied(self):
    return self.duration > USAGE_DURATION_MIN and self.duration < USAGE_DURATION_MAX and self.door_position == 'closed'

  def print_data(self):
    string = '\t{} for '.format(self.door_position)
    if self.duration > 60*1000:
      string += '{:.1f} minutes'.format(self.duration / 60000.0)
    else:
      string += '{} seconds'.format(self.duration / 1000)
    if self.occupied:
      string += '\tThis stall is currently occupied?'
    print(string)

  def print_anomolies(self):
    if self.next.event_id == 0:
      print("\tPower Failure. {} minutes since previous event.".format(self.duration / 60000))
    elif self.next.event_id <= self.previous.event_id:
      print("\tNonsequential Event IDs: {}, {}. Maybe Data was missed?".format(self.previous.event_id, self.next.event_id))
    
    if self.next.value == self.previous.value:
      print("\tUnchanged Door State!")

    if self.next.timestamp < self.previous.timestamp:
      print("\tTime went backwards.")

class Usage_Stats:
  def __init__(self, intervals):
    self.usage_durations = []
    self.short_intervals_count = 0
    self.medium_intervals_count = 0
    self.long_intervals_count = 0

    self.compute(intervals)

  def reset(self):
    self.usage_durations = []
    self.short_intervals_count = 0
    self.medium_intervals_count = 0
    self.long_intervals_count = 0

  def compute(self, intervals):
    self.reset()
    for i in intervals:
      if i.door_position == 'closed':
        if i.duration < USAGE_DURATION_MIN:
          self.short_intervals_count += 1
        elif i.duration < USAGE_DURATION_MAX:
          self.usage_durations.append(i.duration)
          self.medium_intervals_count += 1
        else:
          self.long_intervals_count +=1

  def average(self):
    n = len(self.usage_durations)
    if n == 0:
      return 0
    else:
      return sum(self.usage_durations) / float(n)

  def print_data(self):
     print('Total Usage Count: {}'.format(self.medium_intervals_count))
     print('\n')
     print('{} and {} "door closed" intervals were too short and too long, respectively'.format(self.short_intervals_count, self.long_intervals_count))
     print('Average usage time was: {:.1f} minutes'.format(self.average() / 60000.0))


# Load Data From File into a List of Objects
def read_file(filename):
  # TODO Absolute path??
  # script_dir = os.path.dirname(__file__) #<-- absolute dir the script is in
  # abs_file_path = os.path.join(script_dir, filename)

  print("About to open file: {}".format(filename))
  try:
    f = open(filename, "r")
    encodedData = f.readlines();
    f.close()
  except IOError:
    print("Error. Could not open file: {}. Please confirm it exists and is spelt correctly.".format(filename))
    exit()
  print("File contains {} lines (events).".format(len(encodedData)))

  # data is saved with most recent first.
  encodedData.reverse()

  events = []
  for e in encodedData:
    decoded = json.loads(e)
    events.append(Event(decoded))

  return events

# Make human readable
def format_time(millis):
  return time.strftime('%b %d, %H:%M:%S', time.localtime(millis / 1000.0))

def main():
  stall_number = 1
  if len(sys.argv) > 1:
    stall_number = sys.argv[1]
  filename = 'nemua-men-{}-state.json'.format(stall_number)

  VERBOSE = True
  if len(sys.argv) > 2 and sys.argv[2] == 'False':
    # VERBOSE = bool(sys.argv[2])
    VERBOSE = False
  events = read_file('data/{}'.format(filename))
  intervals = []

  for i in range(len(events)):
    if i > 0:
      interval = Interval(events[i-1], events[i])
      intervals.append(interval)
      if VERBOSE:
        interval.print_data()
        interval.print_anomolies()
    if VERBOSE:
      events[i].print_data()


  stats = Usage_Stats(intervals)
  print('\n\n')
  stats.print_data()
main()