#!/bin/bash
#
# crontab -l > mycron
# echo "#" >> mycron
# echo "# At every 2nd minute" >> mycron
# echo "*/2 * * * * /bin/bash /scripts/dell_ipmi_fan_control.sh >> /tmp/cron.log" >> mycron
# crontab mycron
# rm mycron
# chmod +x /scripts/dell_ipmi_fan_control.sh
#
DATE=$(date +%Y-%m-%d-%H%M%S)
echo "" && echo "" && echo "" && echo "" && echo ""
echo "$DATE"
#
IPMI_ADDRESSES=("192.168.1.220" "192.168.1.223")
IDRACUSER="root"
IDRACPASSWORD=""
#STATICSPEEDBASE16="0x0f"
STATICSPEEDBASE16="0x0a"
SENSORNAME="Inlet"
TEMPTHRESHOLD="29"
#
for IDRACIP in "${IPMI_ADDRESSES[@]}"
do
        T=$(ipmitool -I lanplus -H $IDRACIP -U $IDRACUSER -P $IDRACPASSWORD sdr type temperature | grep $SENSORNAME | cut -d"|" -f5 | cut -d" " -f2)
        echo "$IDRACIP: -- current temperature --"
        echo "$T"

        if [[ $T > $TEMPTHRESHOLD ]]
        then
                echo "--> enable dynamic fan control"
                ipmitool -I lanplus -H $IDRACIP -U $IDRACUSER -P $IDRACPASSWORD raw 0x30 0x30 0x01 0x01
        else
                echo "--> disable dynamic fan control"
                ipmitool -I lanplus -H $IDRACIP -U $IDRACUSER -P $IDRACPASSWORD raw 0x30 0x30 0x01 0x00
                echo "--> set static fan speed"
                ipmitool -I lanplus -H $IDRACIP -U $IDRACUSER -P $IDRACPASSWORD raw 0x30 0x30 0x02 0xff $STATICSPEEDBASE16
        fi
done

