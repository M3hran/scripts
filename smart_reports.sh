#!/bin/bash

DEVLIST="/tmp/devlist"
LOGFILE="./smart_health_report_$(date -Is).txt"
echo -e "SMART REPORT -- $(date)" > $LOGFILE

smartctl --scan | grep scsi | awk '{print $1}' > $DEVLIST

IFS=$'\n' read -d '' -r -a lines < $DEVLIST
for k in "${lines[@]}"
do
        echo -e "\nDisk $k" >> "$LOGFILE"
        smartctl -a $k | grep 'Serial number\|User Capacity\|SMART Health Status\|Non-medium error count\|Serial Number\|SMART overall-health\|Power_On_Hours\|Media_Wearout_Indicator\|defect\|Hours\|Reallocated\|on time\|Manufactured' >>  "$LOGFILE"
done

