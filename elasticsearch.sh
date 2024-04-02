!/bin/bash
sudo apt update -y &&\
sudo apt upgrade -y &&\
shasum -a 512 -c elasticsearch-7.17.9-amd64.deb.sha512 &&\
sudo dpkg -i elasticsearch-7.17.9-amd64.deb &&\
sudo sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0 \ndiscovery.type: single-node/g' /etc/elasticsearch/elasticsearch.yml &&\
sudo sed -i 's/#http.port: 9200/http.port: 9200/g' /etc/elasticsearch/elasticsearch.yml &&\
sudo sed -i 's/#cluster.name: my-application/cluster.name: netology/g' /etc/elasticsearch/elasticsearch.yml &&\
sudo systemctl daemon-reload &&\
sudo systemctl enable elasticsearch.service &&\
sudo systemctl start elasticsearch.service &&\
sudo apt install ufw -y &&\
sudo ufw --force enable &&\
sudo ufw allow 9200:9400/tcp &&\
sudo ufw allow 22 &&\
echo "Конец"