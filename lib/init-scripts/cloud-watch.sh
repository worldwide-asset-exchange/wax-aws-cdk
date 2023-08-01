#!/bin/bash

# Update with optional user data that will run on instance start.
# Learn more about user-data: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html

echo "setup aws cloudwatch"
mkdir /tmp/cloudwatch-logs && cd /tmp/cloudwatch-logs
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

echo "start aws cloudwatch"
sudo wget https://waxnode-cloudwatch-config.s3.ap-southeast-1.amazonaws.com/config.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/tmp/cloudwatch-logs/config.json -s