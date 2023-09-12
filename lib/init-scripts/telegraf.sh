#!/bin/bash

PUBLIC_IPV4=`curl -s http://169.254.169.254/latest/meta-data/public-ipv4`
HOSTNAME=`cat /etc/hostname`
PRIVATE_IPV4=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
REGION=`curl -s http://169.254.169.254/latest/meta-data/placement/region`
AVAILABILITY_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone-id`
INTERFACE=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
SUBNET_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${INTERFACE}/subnet-id)
VPC_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${INTERFACE}/vpc-id)
VICTORIA_IP="<VICTORIA_IP>"

function install_repo() {
  wget -q https://repos.influxdata.com/influxdata-archive_compat.key
  echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
  echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | tee /etc/apt/sources.list.d/influxdata.list
}

function update_os() {
  apt-get update -y && apt-get upgrade -y
}

function install_telegraf() {
  apt-get install telegraf -y
  service telegraf stop
}

function clean_defaults() {
  rm -rf /etc/telegraf/conf.d/*
  rm -rf /etc/telegraf/telegraf.conf
}

function get_github_default_config() {
  wget https://raw.githubusercontent.com/worldwide-asset-exchange/wax-aws-cdk/master/lib/config/telegraf/telegraf.conf -O /etc/telegraf/telegraf.conf
}

function search_and_replace() {
    local file="$1"
    local key="$2"
    local new_value="$3"
    sed -i "s/$key/$new_value/g" "$file"
}

install_repo
update_os
install_telegraf
clean_defaults
get_github_default_config
search_and_replace "/etc/telegraf/telegraf.conf" "<HOSTNAME>" "$HOSTNAME"
search_and_replace "/etc/telegraf/telegraf.conf" "<PUBLIC_IPV4>" "$PUBLIC_IPV4"
search_and_replace "/etc/telegraf/telegraf.conf" "<PRIVATE_IPV4>" "$PRIVATE_IPV4"
search_and_replace "/etc/telegraf/telegraf.conf" "<REGION>" "$REGION"
search_and_replace "/etc/telegraf/telegraf.conf" "<AVAILABILITY_ZONE>" "$AVAILABILITY_ZONE"
search_and_replace "/etc/telegraf/telegraf.conf" "<SUBNET_ID>" "$SUBNET_ID"
search_and_replace "/etc/telegraf/telegraf.conf" "<VPC_ID>" "$VPC_ID"
search_and_replace "/etc/telegraf/telegraf.conf" "<VICTORIA_DB_URL>" "$VICTORIA_IP"

mkdir -p /etc/telegraf/monitoring-scripts/
wget https://raw.githubusercontent.com/worldwide-asset-exchange/wax-aws-cdk/master/lib/init-scripts/wax-node-monitoring.sh -O /etc/telegraf/monitoring-scripts/
chmod +x /etc/telegraf/monitoring-scripts/wax-node-monitoring.sh

service telegraf restart
