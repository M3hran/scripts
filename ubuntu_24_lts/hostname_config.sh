#!/bin/bash

if [ "$#" -ne 1 ]; then
            echo "Usage: $0 <hostname>"
                exit 1
fi


NEW_HOSTNAME=$1


hostnamectl set-hostname $NEW_HOSTNAME
if [[ ! -z $(grep "127.0.1.1" /etc/hosts) ]]; then 
	sed -i "s/.*127\.0\.1\.1.*/127.0.1.1 $NEW_HOSTNAME/" /etc/hosts
else
	sed -i "/127\.0\.0\.1 localhost/a 127.0.1.1 $NEW_HOSTNAME" /etc/hosts
fi
sed -i 's/.*preserve_hostname.*/preserve_hostname: true/' /etc/cloud/cloud.cfg
hostnamectl
