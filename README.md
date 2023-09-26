The following commands provide a step-by-step guide for installing and configuring a Wax Node along with other necessary tools and dependencies. The process also includes the installation and setup of AWS CLI and the AWS Systems Manager (SSM) plugin for managing AWS resources, as well as the deployment of the Wax Node infrastructure using the AWS Cloud Development Kit (CDK).

1. Switch to superuser mode:
```
   sudo su
```
## Requirements
2. Update and upgrade the system packages:
```
   apt update -y && apt upgrade -y
```

3. Install essential utilities: curl and unzip:
```
    apt install -y curl unzip jq
```

4. Add Node.js 18.x repository and install Node.js:
```
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   apt-get install -y nodejs
```

5. Check the installed versions of Node.js and npm:
```
   npm -v
   node --version
```

6. Install AWS CLI:
```
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
```

7. Install AWS Systems Manager (SSM) plugin:
```
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
    dpkg -i session-manager-plugin.deb
    session-manager-plugin
```

8. Install the AWS Cloud Development Kit (CDK) globally:
```
   npm install -g aws-cdk
```

9. Install a specific version of npm (10.1.0): (if prompted)
```
   npm install -g npm@10.1.0
```

10. Check the installed version of the CDK:
```
   cdk version
```

11. Install TypeScript globally:
```
   npm i -g typescript
```

12. Install AWS CDK globally (again, for redundancy):
```
    npm i -g aws-cdk
```

13. Configure AWS access keys:
- Provide aws access keys For better results please have access key with following permissions policies  "AdministratorAccess"

- Note : provide region while configuring to avoid any conflicts
```
   aws configure
```

14. Clone the Wax AWS CDK repository:
```
    git clone https://github.com/worldwide-asset-exchange/wax-aws-cdk.git
    cd wax-aws-cdk
```
### Deploy :
15. This project relies on wax-node to start the node. To deploy the API node, execute the following command.
    Choose any one of the desired the set of environment variables from the below to execute.
## Deploy api node with snapshot
```
    export AWS_ACCOUNT_ID=`aws sts get-caller-identity | jq -r .Account`
    export AWS_REGION=eu-central-1
    export START_FROM_SNAPSHOT=true
```

## Deploy ship node
```
    export AWS_ACCOUNT_ID=`aws sts get-caller-identity | jq -r .Account`
    export AWS_REGION=eu-central-1
    export ENABLE_SHIP_NODE=true
```

## Deploy ship node with snapshot
```
    export AWS_ACCOUNT_ID=`aws sts get-caller-identity | jq -r .Account`
    export AWS_REGION=eu-central-1
    export START_FROM_SNAPSHOT=true
    export ENABLE_SHIP_NODE=true
```

16. Install project dependencies:
```
    npm install
```

17. Generate CloudFormation templates:
```
    cdk synth
```

18. Bootstrap the AWS environment:
```
    cdk bootstrap aws://$AWS_ACCOUNT_ID/$AWS_REGION
```

19. Build the project:
```
    npm run build
```

20. Deploy the Wax Node infrastructure using CDK:
```
    npx cdk deploy
```

These commands provide a comprehensive guide for setting up a Wax Node, configuring AWS CLI and SSM, and deploying the necessary infrastructure for the Wax Node using CDK. Be sure to replace the provided access key and secret access key with your own credentials, and adapt any other parameters to your specific use case as needed.

### Monitor
- Monitor log in cloudwatch
  Go to [CloudWatch](https://console.aws.amazon.com/cloudwatch) > Log groups >/waxnode/ > logs
```
echo Link: https://$AWS_REGION.console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#logsV2:log-groups/log-group/\$252Fwaxnode\$252F/log-events/logs
```
- For Grafana dashboards

```
export INSTANCE_ID=`aws ec2 describe-instances --filters "Name=tag:aws:cloudformation:stack-name,Values=WaxNodeCdkStack" | jq -r '.[]|.[] |.Instances[].InstanceId'`
export GRAFANA_IP=`aws ec2 describe-instances --instance-ids $INSTANCE_ID | jq -r ".[]|.[]|.Instances[]|.NetworkInterfaces[].Association.PublicIp"`
```
# To open the grafana ip publicly use the below command
```
aws ec2 authorize-security-group-ingress --group-id `aws ec2 describe-instances --instance-ids $INSTANCE_ID | jq -r ".[]|.[]|.Instances[]|.SecurityGroups[].GroupId"` --ip-permissions IpProtocol=tcp,FromPort=3001,ToPort=3001,IpRanges='[{CidrIp='0.0.0.0/0',Description="wideopen"}]'
echo http://$GRAFANA_IP:3000 
```
## Default credentials of grafana
user : admin
password : admin

## Login to instance
- Login by Session Manager
```
  aws ssm start-session --target i-$INSTANCE_ID --document-name SSM-WaxNodeCdkConfiguration
```
- Check Setup status
```
  sudo tail -f /var/log/cloud-init-output.log
```

## Check Node Status
* Note: it might take up to 30 minutes for the node to start up and few days for the node to sync to the newest block.
- check log status
```
  tail -f /var/log/wax/logs.log
```
- Monitor the node status inside instance
```
curl http://localhost:8888/v1/chain/get_info | jq 
```
- Monitor the node status
```
# Check note status
curl http://`wget -q -O - http://169.254.169.254/latest/meta-data/public-ipv4`:8888/v1/chain/get_info | jq
```
- More info about Wax Node [here](https://github.com/worldwide-asset-exchange/wax-node/)

## Useful commands
* `npm run build`   compile typescript to js
* `npm run watch`   watch for changes and compile
* `npm run test`    perform the jest unit tests
* `cdk deploy`      deploy this stack to your default AWS account/region
* `cdk diff`        compare deployed stack with current state
* `cdk synth`       emits the synthesized CloudFormation template
