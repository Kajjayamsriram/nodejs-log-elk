#!/bin/bash
set -e  #Exit script on any error

public_ip=$(curl -s ifconfig.me)

echo "###################"
echo "Installing pre-requisites"
sudo apt update -y
sudo apt install wget default-jre default-jdk apt-transport-https -y

echo "###################"
echo "Adding Elastic Search GPG keys"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "###################"
echo "Adding Elastic Search repo"
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/9.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-9.x.list

echo "###################"
echo "Installing Elastic Search"
sudo apt-get update && sudo apt-get install elasticsearch -y

echo "###################"
echo "Adding config changes in elasticsearch.yml"
sudo bash -c "cat <<EOF >> /etc/elasticsearch/elasticsearch.yml
network.host: "$public_ip"
http.port: 9200
discovery.type: single-node
EOF"

echo "###################"
echo "Adding max heap size 512mb in jvm.options"
sudo echo -e "-Xmx512m\n-Xmx512m" | sudo tee -a /etc/elasticsearch/jvm.options > /dev/null

echo "###################"
echo "Restarting and Enabling Elastic Search"
sudo systemctl restart elasticsearch
sudo systemctl enable elasticsearch

echo "###################"
echo "Verifying Elastic Search response"
curl -s http://$public_ip:9200 || echo "ElasticSearch might still be starting..."

echo "###################"
echo "Installing and Starting Logstash"
sudo apt install logstash -y
sudo systemctl start logstash
sudo systemctl enable logstash

echo "###################"
echo "Installing Kibana"
sudo apt install kibana -y

echo "###################"
echo "Adding config changes in kibana.yml"
sudo bash -c "cat <<EOF >> /etc/kibana/kibana.yml
server.host: "$public_ip"
elasticsearch.hosts: [\"http://$public_ip:9200\"]
EOF"

echo "###################"
echo "Restarting and Enabling Kibana"
sudo systemctl restart kibana
sudo systemctl enable kibana

echo "Visit http://$public_ip:5601 to access Kibana UI"
