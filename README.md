# Automating Wax Node deployment on AWS
## Get start
- If this is your first time using AWS CDK then [follow these bootstrap instructions](https://docs.aws.amazon.com/cdk/v2/guide/bootstrapping.html).

- Install TypeScript globally for CDK
```
$ npm i -g typescript
```
- If you are running these commands in Cloud or already have CDK installed, then skip this command
```
$ npm i -g aws-cdk
```

- If you have deleted or don't have the default VPC, create default VPC

```bash
    aws ec2 create-default-vpc
   ```

   **Note:** You may see the following error if the default VPC already exists: `An error occurred (DefaultVpcAlreadyExists) when calling the CreateDefaultVpc operation: A Default VPC already exists for this account in this region.`. That means you can just continue with the following steps.

## Build
- Install
```
$ npm install
```

- Build
```
$ npm run build
```

## Deployment Instructions
### Set the deploy account and region
Before deploying the project, ensure you have the AWS CLI configured with the desired account and region. Use the following command to bootstrap the CDK environment:
```
export AWS_REGION=<your_region> 
export AWS_ACCOUNT_ID=<your_account_id>
cdk bootstrap aws://account-id/region
```

### Deploy
This project relies on [wax-node](https://github.com/worldwide-asset-exchange/wax-node) to start the node. To deploy the API node, execute the following command:
1. Deploy api node
```
AWS_REGION=<your_region> AWS_ACCOUNT_ID=<your_account_id> START_FROM_SNAPSHOT=false ENABLE_SHIP_NODE=false npx cdk deploy
Outputs:
WaxNodeCdkStack.IPAddress = XXX.XXX.XXX.XXX
WaxNodeCdkStack.sshcommand = aws ssm start-session --target i-${instance-id} --document-name SSM-WaxNodeCdkConfiguration
```
1. Deploy api node with snapshot
```
AWS_REGION=<your_region> AWS_ACCOUNT_ID=<your_account_id> START_FROM_SNAPSHOT=true ENABLE_SHIP_NODE=false npx cdk deploy
```
1. Deploy ship node
```
AWS_REGION=<your_region> AWS_ACCOUNT_ID=<your_account_id> START_FROM_SNAPSHOT=false ENABLE_SHIP_NODE=true npx cdk deploy
```
1. Deploy ship node with snapshot
```
AWS_REGION=<your_region> AWS_ACCOUNT_ID=<your_account_id> START_FROM_SNAPSHOT=true ENABLE_SHIP_NODE=true npx cdk deploy
```

### Monitor
- Monitor log in cloudwatch
Go to [CloudWatch](https://console.aws.amazon.com/cloudwatch) > Log groups >/waxnode/ > logs

## Login to instance
- Login by Session Manager
```
$ aws ssm start-session --target i-${instance-id} --document-name SSM-WaxNodeCdkConfiguration
```
- Check Setup status
```
$ sudo tail -f /var/log/cloud-init-output.log
```

## Check Node Status
* Note: it might take up to 30 minutes for the node to start up and few days for the node to sync to the newest block.
- check log status
```
$ tail -f /var/log/wax/logs.log
```
- Monitor the node status inside instance
```
curl http://localhost:8888/v1/chain/get_info
```
- Monitor the node status
```
# Check note status
curl http://{WaxNodeCdkStack.IPAddress}:8888/v1/chain/get_info
```
- More info about Wax Node [here](https://github.com/worldwide-asset-exchange/wax-node/)

## Useful commands
* `npm run build`   compile typescript to js
* `npm run watch`   watch for changes and compile
* `npm run test`    perform the jest unit tests
* `cdk deploy`      deploy this stack to your default AWS account/region
* `cdk diff`        compare deployed stack with current state
* `cdk synth`       emits the synthesized CloudFormation template
