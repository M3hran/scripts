#!/bin/bash

echo "downloading zabbix-agent 2.2.1"
wget http://repo.zabbix.com/zabbix/2.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_2.2-1+trusty_all.deb
dpkg -i zabbix-release_2.2-1+trusty_all.deb
apt-get update
apt-get install zabbix-agent


echo "changing zabbix-agent conf file"
sed -i 's/LogFileSize=0/LogFileSize=500/' /etc/zabbix/zabbix_agentd.conf
sed -i 's/Server=127.0.0.1/Server=zabbix.scientiamobile.local/' /etc/zabbix/zabbix_agentd.conf
sed -i 's/ServerActive=127.0.0.1/ServerActive=zabbix.scientiamobile.local/' /etc/zabbix/zabbix_agentd.conf
sed -i 's/Hostname=Zabbix server/Hostname='$HOSTNAME'/' /etc/zabbix/zabbix_agentd.conf
service zabbix-agent restart
echo "done"
echo "ATTN: configure Zabbix Server, with hostname below"
grep ^Hostname /etc/zabbix/zabbix_agentd.conf
