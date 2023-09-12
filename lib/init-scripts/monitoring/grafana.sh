#!/bin/bash

sudo mkdir -p /etc/apt/keyrings/

wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

apt-get update -y && apt-get install grafana nginx -y

rm -rf /etc/nginx/nginx.conf
rm -rf /etc/nginx/sites-enabled/*
rm -rf /etc/nginx/sites-available/*

wget https://raw.githubusercontent.com/worldwide-asset-exchange/wax-aws-cdk/master/lib/config/nginx/nginx.conf -O /etc/nginx/nginx.conf
wget https://raw.githubusercontent.com/worldwide-asset-exchange/wax-aws-cdk/master/lib/config/nginx/grafana.conf -O /etc/nginx/sites-enabled/grafana.conf

service grafana-server stop

wget https://raw.githubusercontent.com/grafana/grafana/main/conf/sample.ini -O /etc/grafana/grafana.ini

sed -i "s/;provisioning/provisioning/g" /etc/grafana/grafana.ini
sed -i "s/;http_addr = /http_addr = 127.0.0.1/g" /etc/grafana/grafana.ini
sed -i "s/;http_port = /http_port = /g" /etc/grafana/grafana.ini

wget https://raw.githubusercontent.com/worldwide-asset-exchange/wax-aws-cdk/master/lib/config/grafana/provisioning/dashboards/wax-nodes.yml \
-O /etc/grafana/provisioning/dashboards/wax-nodes.yml
wget https://raw.githubusercontent.com/worldwide-asset-exchange/wax-aws-cdk/master/lib/config/grafana/provisioning/datasources/prometheus.yml \
-O /etc/grafana/provisioning/datasources/prometheus.yml
wget https://raw.githubusercontent.com/worldwide-asset-exchange/wax-aws-cdk/master/lib/config/grafana/provisioning-data/dashboards/default.json \
-O /var/lib/grafana/dashboards/default.json

service grafana-server start

service nginx restart
