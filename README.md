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
