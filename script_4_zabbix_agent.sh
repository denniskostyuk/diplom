#!/bin/bash
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu18.04_all.deb &&\
sudo dpkg -i zabbix-release_6.0-4+ubuntu18.04_all.deb &&\
sudo apt update -y &&\
sudo apt install zabbix-agent -y &&\
sudo sed -i 's/Server=127.0.0.1/Server='$1'/g' /etc/zabbix/zabbix_agentd.conf &&\
sudo systemctl restart zabbix-agent &&\
sudo systemctl enable zabbix-agent &&\
sudo ufw --force enable &&\
sudo ufw allow 10050