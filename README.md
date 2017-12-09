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