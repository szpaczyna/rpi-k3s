#!/bin/bash
export LD_LIBRARY_PATH=/opt/vc/lib

# -------------------------------------------------------
cpu=$(</sys/class/thermal/thermal_zone0/temp)
echo "$(date) @ $(hostname)"
echo "-------------------------------------------"
echo "GPU => $(/opt/vc/bin/vcgencmd measure_temp | sed -e 's/temp=//g')"
echo "SSD Disk => $(smartctl -A /dev/sda | awk '/Temperature_Celsius/ {print $10}')'C"
echo "USB Disk => $(smartctl -A /dev/sdb | awk '/Temperature_Celsius/ {print $10}')'C"
echo "CPU => $((cpu/1000))'C"
