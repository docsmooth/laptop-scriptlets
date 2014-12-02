#!/bin/bash

echo -n "# Using governor " 
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

DESIGNCAP=`cat /sys/bus/acpi/drivers/battery/PNP0C0A:00/power_supply/BAT0/energy_full_design`
LASTMAXCAP=`cat /sys/bus/acpi/drivers/battery/PNP0C0A:00/power_supply/BAT0/energy_full`
echo "# Battery max design $DESIGNCAP mWh, last $LASTMAXCAP mWh"
echo "# Using last max for percentages." 

cat /sys/bus/acpi/drivers/battery/PNP0C0A:00/power_supply/BAT0/energy_now | \
	awk "{ print (\$0 / $LASTMAXCAP) * 100 }"
while sleep 60;
do 
	cat /sys/bus/acpi/drivers/battery/PNP0C0A:00/power_supply/BAT0/energy_now | \
	awk "{ print (\$0 / $LASTMAXCAP) * 100 }"
done
