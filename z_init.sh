#!/bin/bash
#
apt-get update
apt-get install freeipa-client htop iotop iftop ncdu pv

#sed static nic
ipaclient-install
sed "session     optional      pam_mkhomedir.so skel=/etc/skel umask=077" /etc/pam.d/common-auth
curl -sSL https://get.docker.com/ | sh
curl -L https://github.com/docker/compose/releases/download/1.12.0-rc1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
systemctl enable docker
systemctl start docker


