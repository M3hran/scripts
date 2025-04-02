#!/bin/bash

# Ensure a hostname argument is provided
if [[ -z "$1" ]]; then
  echo "Usage: $0 <new-hostname>"
  exit 1
fi

# Assign the first argument to NEW_HOSTNAME
NEW_HOSTNAME="$1"

# Set the system hostname
hostnamectl set-hostname "$NEW_HOSTNAME"

# Update /etc/hosts with the new hostname
if grep -q "127.0.1.1" /etc/hosts; then
  sed -i "s/.*127\.0\.1\.1.*/127.0.1.1 $NEW_HOSTNAME/" /etc/hosts
else
  sed -i "/127\.0\.0\.1 localhost/a 127.0.1.1 $NEW_HOSTNAME" /etc/hosts
fi

echo "Hostname successfully updated to: $NEW_HOSTNAME"
