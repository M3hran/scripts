#!/bin/bash

# Ensure an IP argument is provided
if [[ -z "$1" ]]; then
  echo "Usage: $0 <new-ip-address>"
  exit 1
fi
# Find MAC Address
D='/sys/class/net/eth0'

if  grep -q up $D/operstate
then

    MAC=$(cat $D/$nic/address)
else
  echo "Error: Could not find active interface!"
  exit 1
fi

# Assign the first argument to NEW_IP
NEW_IP="$1"
#GATEWAY_IP=$(sed -E 's/ (([0-9]{1,3}\.){3})[0-9]{1,3} / \1x)
#DNS

cat << EOF | tee /etc/netplan/01-netcfg.yaml > /dev/null
network:
  version: 2
  ethernets:
    eth0:
      match:
        macaddress: "$MAC"
      set-name: "eth0"
      dhcp4: false
      addresses: ["$NEW_IP/24"]
      routes:
        - to: default
          via: 192.168.1.1
          metric: 100
      nameservers:
        addresses: [192.168.1.10,192.168.1.1,1.1.1.1]
        search: []
      dhcp6: false
EOF
echo "Updated IP address to $NEW_IP in $NETPLAN_FILE"
# Apply the changes
echo "Applying netplan changes..."
mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.org
chmod 600 /etc/netplan/01-netcfg.yaml
sudo netplan apply
echo "Netplan configuration applied successfully."

