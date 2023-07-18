# Automating Wax Node deployment on AWS
- If this is your first time using AWS CDK then [follow these bootstrap instructions](https://docs.aws.amazon.com/cdk/v2/guide/bootstrapping.html).

- Install TypeScript globally for CDK
```
$ npm i -g typescript
```
- If you are running these commands in Cloud9 or already have CDK installed, then skip this command
```
$ npm i -g aws-cdk
```
## Select instance type
Edit following line [wax-node-cdk-stack](./lib/wax-node-cdk-stack.ts)

```
instanceType: ec2.InstanceType.of(ec2.InstanceClass.R5N, ec2.InstanceSize.XLARGE2),
```

## Build
- Install
```
$ npm install
```

- Build
```
$ npm run build
```

## Deploy
- Set deploy account, region
```
$ cdk bootstrap aws://account-id/region
```

- Deploy
```
$ cdk deploy
Outputs:
WaxNodeCdkStack.IPAddress = XXX.XXX.XXX.XXX
WaxNodeCdkStack.sshcommand = aws ssm start-session --target i-${instance-id} --document-name SSM-WaxNodeCdkConfiguration
```

## Login to instance
- Login by Session Manager
```
$ aws ssm start-session --target i-${instance-id} --document-name SSM-WaxNodeCdkConfiguration
```

## Check Node Status
* Note: it might take up to 30 minutes for the node to start up and few days for the node to sync to the newest block.

- check log status
```
$ sudo service wax status
Jul 18 03:36:13 ip-10-0-0-46 start.sh[4777]: 1781300K .......... .......... .......... .......... .......... 31%  123M 4m>
Jul 18 03:36:13 ip-10-0-0-46 start.sh[4777]: 1781350K .......... .......... .......... .......... .......... 31%  100M 4m>
Jul 18 03:36:13 ip-10-0-0-46 start.sh[4777]: 1781400K .......... .......... .......... .......... .......... 31% 41.9M 4m>
Jul 18 03:36:13 ip-10-0-0-46 start.sh[4777]: 1781450K .......... .......... .......... .......... .......... 31%  151M 4m>
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
