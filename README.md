SHRI Door Sensor

# Purpose

Logging Door open/close events to keep track of SHRI facility usage. Learn more at sanrights.org

# Instalation

Install Firmware:
* `C:\Python27\Scripts\esptool.py --port COM8 write_flash -fm dio 0x00000 C:\doorsensor\shriDoorSensor\firmware\latest.bin`

Install Software
* Open ESP Cut program
* Copy all files in the deploy folder to the device.
* Restart the device. 

# LED Behaviour

* On first startup, the LED goes on solid, a welcome message is printed, and the processor does nothing else for 10 seconds.
* When attempting to connect to wifi and failing, the LED will blink once per second for as long as it is trying
* Once connected to wifi, the LED will go dark
* Once connected to Internet (This takes about 10 or 20 seconds after Wifi), the LED will go solid ON until it disconnects.
* Each time the door opens or closes, the LED will double-blink.

# Post Processing

* Use Python v2.7
* Make sure you create a file called TOKEN in the processing directory, with the ubidots access token. You can find this token at https://app.ubidots.com/userdata/api/
* It's intentionally ignored from git. Please don't commit the token!

## Load data to file
* From the processing directory, run this command to fetch remote data and save to file/: `python fetchData.py`

## View the interpreted data in tabular form
* From the processing directory, run this command: `python intervalTable.py n`  (but replace n with the number (1-8) of the stall you are interested in)
* Add False if you just want to see the final number: `python intervalTable.py 6 False`
