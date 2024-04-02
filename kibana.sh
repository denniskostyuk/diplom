#!/bin/bash
sudo apt update -y &&\
sudo apt upgrade -y &&\
sudo shasum -a 512 kibana-7.17.9-amd64.deb &&\
sudo dpkg -i kibana-7.17.9-amd64.deb &&\
sudo sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/g' /etc/kibana/kibana.yml &&\
sudo sed -i 's/#elasticsearch.hosts:/elasticsearch.hosts:/g' /etc/kibana/kibana.yml &&\
sudo sed -i 's/localhost:9200/'$1':9200/g' /etc/kibana/kibana.yml &&\
sudo sed -i 's/#server.port: 5601/server.port: 5601/g' /etc/kibana/kibana.yml &&\
sudo systemctl daemon-reload &&\
sudo systemctl enable kibana.service &&\
sudo systemctl start kibana.service &&\
sudo apt install ufw -y &&\
sudo ufw --force enable &&\
sudo ufw allow 5601 &&\
sudo ufw allow 22 &&\
echo "The end"