#!/bin/bash

# Update with optional user data that will run on instance start.
# Learn more about user-data: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
echo "Pulling wax-node project"
git clone https://github.com/worldwide-asset-exchange/wax-node.git

echo "Starting api-node..."
cd wax-node
sudo mkdir /opt/wax
sudo mkdir /var/log/wax
sudo cp -r . /opt/wax/
sudo cp ./services/apinode.service /etc/systemd/system/wax.service
sudo systemctl enable wax
sudo service wax start
