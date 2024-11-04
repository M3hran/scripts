#!/bin/bash
#
D='/sys/class/net'
declare NIC MAC F

for nic in $( ls $D )
do
    #echo $nic
    if  grep -q up $D/$nic/operstate
    then
        NIC=$nic
        MAC=$(cat $D/$nic/address)
        F=1
        echo "$NIC   $MAC"
    fi
done

if [[ -z $F ]]; then
        echo "Error: Couldn't find active interface."
        exit 1
fi

