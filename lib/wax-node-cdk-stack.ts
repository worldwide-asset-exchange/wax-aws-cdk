import * as cdk from 'aws-cdk-lib';
import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as iam from 'aws-cdk-lib/aws-iam'
import { aws_ssm as ssm } from 'aws-cdk-lib';
import { aws_logs as logs } from 'aws-cdk-lib';
import { NagSuppressions } from "cdk-nag";

import { Construct } from 'constructs';
import { readFileSync } from 'fs';

export class WaxNodeCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);
    console.log('AWS_REGION 👉', process.env.AWS_REGION);
    console.log('AWS_ACCOUNT_ID 👉', process.env.AWS_ACCOUNT_ID);
    console.log('START_FROM_SNAPSHOT 👉', process.env.START_FROM_SNAPSHOT);
    console.log('ENABLE_SHIP_NODE 👉', process.env.ENABLE_SHIP_NODE);
    const cfnDocument = new ssm.CfnDocument(this, 'WaxNodeCdkSessionManagerDocument', {
      content: {
        "schemaVersion": "1.0",
        "description": "WaxNodeCdk Session Manager Configurations",
        "sessionType": "Standard_Stream",
        "inputs": {
          "runAsEnabled": true,
          "runAsDefaultUser": "ubuntu",
          "idleSessionTimeout": "20",
          "shellProfile": {
            "linux": "cd ~ && bash"
          }
        }
      },
      name: 'SSM-WaxNodeCdkConfiguration',
      documentFormat: 'JSON',
      documentType: 'Session'
    });

    // We re-use the default VPC that AWS accounts have
    const vpc = ec2.Vpc.fromLookup(this, "Vpc", { isDefault: true });

    // Allow outbound access
    // No port 22 access, connections managed by AWS Systems Manager Session Manager
    // Inbound access rules for Waxnode set below

    const securityGroup = new ec2.SecurityGroup(this, 'SecurityGroup', {
      vpc,
      description: 'WaxNode security group.',
      allowAllOutbound: true
    });

    securityGroup.addIngressRule(
      ec2.Peer.ipv4(vpc.vpcCidrBlock),
      ec2.Port.tcp(443),
      'Allow HTTPS traffic only from within the VPC',
    );

    securityGroup.addIngressRule(
      ec2.Peer.ipv4(vpc.vpcCidrBlock),
      ec2.Port.tcp(8888),
      'Allow api nodeos port: 8888 from within the VPC',
    );

    securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.udp(9876),
      'Allow Peer to peer nodeos port: 9876 from anywhere',
    );

    if(process.env.ENABLE_SHIP_NODE === 'true'){
      securityGroup.addIngressRule(
        ec2.Peer.ipv4(vpc.vpcCidrBlock),
        ec2.Port.tcp(8080),
        'allow ship nodeos port: 8080 from within the VPC',
      );
    }

    const role = new iam.Role(this, 'ec2Role', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com')
    })
    role.addManagedPolicy(iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'))
    role.addManagedPolicy(iam.ManagedPolicy.fromAwsManagedPolicyName('CloudWatchAgentServerPolicy'))

    const machineImage = ec2.MachineImage.fromSsmParameter(
      '/aws/service/canonical/ubuntu/server/focal/stable/current/amd64/hvm/ebs-gp2/ami-id',
      {
        os: ec2.OperatingSystemType.LINUX
      })
    const rootVolume: ec2.BlockDevice = {
      deviceName: '/dev/sda1', // Use the root device name
      volume: ec2.BlockDeviceVolume.ebs(512, { // Override the volume size in Gibibytes (GiB) - 512GB for RPL
        deleteOnTermination: true,
        encrypted: true,
        iops: 5000,
        volumeType: ec2.EbsDeviceVolumeType.GP3,
    }),
    };

    // Create the instance using the Security Group, AMI, and KeyPair defined in the VPC created
    const ec2Instance = new ec2.Instance(this, 'Instance', {
      vpc,
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.R6A, ec2.InstanceSize.XLARGE2),
      machineImage: machineImage,
      securityGroup: securityGroup,
      role: role,
      blockDevices: [rootVolume]
    });

    const cfnLogGroup = new logs.CfnLogGroup(this, 'CfnLogGroup', {
      logGroupName: '/waxnode/'
    });

    const cfnLogStream = new logs.CfnLogStream(this, 'CfnLogStream', {
      logGroupName: cfnLogGroup.logGroupName as string,
      logStreamName: 'logs',
    });
    cfnLogStream.node.addDependency(cfnLogGroup);

    // 👇 load user data script
    const userDataScript = readFileSync('./lib/init-scripts/user-data.sh', 'utf8');
    const apiNodeScript = readFileSync('./lib/init-scripts/api-node.sh', 'utf8');
    const apiNodeSnapshotScript = readFileSync('./lib/init-scripts/api-node-snapshot.sh', 'utf8');
    const shipNodeScript = readFileSync('./lib/init-scripts/ship-node.sh', 'utf8');
    const shipNodeSnapshotScript = readFileSync('./lib/init-scripts/ship-node-snapshot.sh', 'utf8');
    const cloudWatchScript = readFileSync('./lib/init-scripts/cloud-watch.sh', 'utf8');
    // 👇 add user data to the EC2 instance
    ec2Instance.addUserData(userDataScript);
    if(process.env.ENABLE_SHIP_NODE !== 'true'){
      if(process.env.START_FROM_SNAPSHOT  !== 'true'){
        ec2Instance.addUserData(apiNodeScript);
      }else{
        ec2Instance.addUserData(apiNodeSnapshotScript);
      }
    }else{
      if(process.env.START_FROM_SNAPSHOT !== 'true'){
        ec2Instance.addUserData(shipNodeScript);
      }else{
        ec2Instance.addUserData(shipNodeSnapshotScript);
      }
    }
    ec2Instance.addUserData(cloudWatchScript);

    // Create outputs for connecting
    new cdk.CfnOutput(this, 'IP Address', { value: ec2Instance.instancePublicIp });
    new cdk.CfnOutput(this, 'ssh command', { value: 'aws ssm start-session --target ' + ec2Instance.instanceId + ' --document-name ' + cfnDocument.name });

    // Add a nag suppressions.
    NagSuppressions.addResourceSuppressions(
      this,
      [
          {
              id: "AwsSolutions-IAM4",
              reason: "AmazonSSMManagedInstanceCore and CloudWatchAgentServerPolicy have acceptable level of restrictions",
          },
          {
            id: "AwsSolutions-EC28",
            reason: "WAX nodes don't require detaild monitoring to be enabled to save costs",
          },
          {
            id: "AwsSolutions-EC29",
            reason: "These nodes are ment to be managed manually and don't require termination protection",
          },
      ],
      true
  );
  }
}
