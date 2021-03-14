#!/bin/bash
export LD_LIBRARY_PATH=/opt/vc/lib

# -------------------------------------------------------
cpu=$(</sys/class/thermal/thermal_zone0/temp)
echo "$(date) @ $(hostname)"
echo "-------------------------------------------"
echo "GPU => $(/opt/vc/bin/vcgencmd measure_temp | sed -e 's/temp=//g')"
echo "CPU => $((cpu/1000))'C"
