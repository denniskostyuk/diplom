!/bin/bash
sudo apt update -y &&\
sudo apt upgrade -y &&\
shasum -a 512 -c filebeat-7.17.9-amd64.deb.sha512 &&\
sudo dpkg -i filebeat-7.17.9-amd64.deb &&\
sudo mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.old &&\
sudo cp ./filebeat.yml /etc/filebeat/filebeat.yml &&\
sudo sed -i 's/localhost/'$1'/g' /etc/filebeat/filebeat.yml &&\
sudo systemctl daemon-reload &&\
sudo systemctl enable filebeat.service &&\
sudo systemctl start filebeat.service &&\
sudo sed -i 's/Welcome to nginx!/Welcome to nginx!<p>ip='$2'<p>/g' /var/www/html/index.nginx-debian.html &&\
echo "Конец"