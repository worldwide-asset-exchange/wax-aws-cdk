#!/bin/bash

# Update with optional user data that will run on instance start.
# Learn more about user-data: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
echo "install packages!"
sudo apt-get update -y
apt-get install ca-certificates curl gnupg -y

echo "install docker here!"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sleep 3
sudo apt-get update  -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

echo "Manage Docker as a non-root user"
sudo usermod -aG docker ubuntu

echo "Configure Docker to start on boot with systemd"
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

echo "Pulling wax-node project"
git clone -b export-nodeos-log https://github.com/worldwide-asset-exchange/wax-node.git

echo "Starting wax-node..."
cd wax-node
sudo mkdir /opt/wax
sudo mkdir /var/log/wax
sudo cp -r . /opt/wax/
sudo cp ./wax.service /etc/systemd/system/wax.service
sudo systemctl enable wax
sudo service wax start

echo "setup aws cloudwatch"
mkdir /tmp/cloudwatch-logs && cd /tmp/cloudwatch-logs
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

echo "start aws cloudwatch"
sudo wget https://waxnode-cloudwatch-config.s3.ap-southeast-1.amazonaws.com/config.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/tmp/cloudwatch-logs/config.json -s