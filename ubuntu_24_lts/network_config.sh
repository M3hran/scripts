#!/bin/bash
#
mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.org
cat << 'EOF' > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    # interface name
    eth0:
      match:
        macaddress: "bc:24:11:60:32:db"
      set-name: "eth0"
      dhcp4: false
      # IP address/subnet mask
      addresses: [192.168.1.80/24]
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
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
netplan apply
ip a
