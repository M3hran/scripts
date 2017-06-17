#!/bin/bash

curl -sSL https://get.docker.com/ | sh
curl -L https://github.com/docker/compose/releases/download/1.12.0-rc1/docker-compose-`uname -s`-`uname -m` > /usr/sbin/docker-compose
chmod +x /usr/sbin/docker-compose
systemctl enable docker
systemctl start docker

