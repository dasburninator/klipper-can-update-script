#!/bin/bash
# Simple script to handle updating the CAN-BUS based boards for klipper

# Set config info
TOOLHEAD_UUID=088c6c74230b
MCU_UUID=28c0b6ddd306
PROBE_UUID=ad159ac5d83b

# Set Board types
TOOLHEAD_BOARD=ebb36
MCU_BOARD=manta-m8p
PROBE_BOARD=cartographer


# Update system
sudo apt update
sudo apt upgrade -y

# Update Klipper
sudo service klipper stop
cd ~/klipper
git pull

# Flash toolhead board following these steps: https://canbus.esoterical.online/toolhead_klipper_updating.html
echo "menuconfig to flash toolhead board"

# Toolhead board menuconfig
make menuconfig KCONFIG_CONFIG=config.${TOOLHEAD_BOARD}
# Clean build environment
make clean KCONFIG_CONFIG=config.${TOOLHEAD_BOARD}
# Compile firmware
make KCONFIG_CONFIG=config.${TOOLHEAD_BOARD}

read -p "Toolhead firmware built, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"

# Force board to reboot into katapult mode
python3 ~/katapult/scripts/flashtool.py -i can0 -r -u ${TOOLHEAD_UUID}
# Check to see if board is in katapult boot mode
python3 ~/katapult/scripts/flashtool.py -q
# Flash Board
python3 ~/katapult/scripts/flashtool.py -i can0 -f ~/klipper/out/klipper.bin -u ${TOOLHEAD_UUID}
# Check to see if board is in klipper mode
python3 ~/katapult/scripts/flashtool.py -q

# Flash main MCU following these steps: https://canbus.esoterical.online/mainboard_klipper_updating.html
# Main MCU menuconfig
make menuconfig KCONFIG_CONFIG=config.${MCU_BOARD}
# Clean build environment
make clean KCONFIG_CONFIG=config.${MCU_BOARD}
# Compile firmware
make KCONFIG_CONFIG=config.${MCU_BOARD}

read -p "Main MCU firmware built, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"

# Force board to reboot into katapult mode
python3 ~/katapult/scripts/flashtool.py -i can0 -r -u ${MCU_UUID}

# Check to see if device is in Katapult mode
ls /dev/serial/by-id/* | grep katapult

# Set MCU_USBID environment variable
MCU_USBID=$(ls /dev/serial/by-id/* | grep katapult)
python3 ~/katapult/scripts/flashtool.py -f ~/klipper/out/klipper.bin -d ${MCU_USBID}

# Flash RPi related
make menuconfig KCONFIG_CONFIG=config.rpi
make clean KCONFIG_CONFIG=config.rpi
make flash KCONFIG_CONFIG=config.rpi


# Start Klipper Service
sudo service klipper start
