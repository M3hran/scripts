#!/bin/bash

if [ "$#" -ne 1 ]; then
            echo "Usage: $0 <IP>"
                exit 1
fi


NEW_IP=$1

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
    fi
done

if [[ -z $F ]]; then
        echo "Error: Couldn't find active interface."
        exit 1
fi



mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.org

cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    # interface name
    $NIC:
      match:
        macaddress: "$MAC"
      set-name: "$NIC"
      dhcp4: false
      # IP address/subnet mask
      addresses: [$NEW_IP/24]
      # default gateway
      # [metric] : set priority (specify it if multiple NICs are set)
      # lower value is higher priority
      routes:
        - to: default
          via: 192.168.1.1
          metric: 100
      nameservers:
        # name server to bind
        addresses: [192.168.1.10,192.168.1.1,1.1.1.1]
        # DNS search base
        search: []
      dhcp6: false
EOF

chmod 600 /etc/netplan/01-netcfg.yaml

if [[ -z $(grep "net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf) ]]; then

	echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
	sysctl -p
fi

netplan apply
ip a | grep 'init' | grep 'eth0'

