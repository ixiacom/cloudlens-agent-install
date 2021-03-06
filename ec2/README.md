# CloudLens Agent installer for AWS

## EC2 Instance "User Data"
This script may be used as "user data" during EC2 instance launch to start
the CloudLens agent.

## EC2 Run via AWS Web Console
Alternately, this script may be run using EC2 Run either by selecting
AWS-RunShellScript and copying the contents of this script, or by running
AWS-RunRemoteScript with the following options:

* **Source Type**: GitHub
* **Source Info**: 
```json
{
   "owner": "ixiacom",
   "repository": "cloudlens-agent-install",
   "path": "ec2/agent_install.sh"
}
```
* **Command Line**: bash agent_install.sh


## EC2 Run via AWS CLI
The AWS CLI command line for this would follow this format:

```bash
aws ssm send-command --document-name "AWS-RunRemoteScript" \
                     --parameters '{"sourceType":["GitHub"],"sourceInfo":["{ \"owner\": \"ixiacom\", \"repository\": \"cloudlens-agent-install\", \"path\": \"ec2/agent_install.sh\" }"],"executionTimeout":["3600"],"commandLine":["bash agent_install.sh"]}' \
                     --timeout-seconds 600
```


## Prerequisites
In order for this script to work the following prerequisites must be met:

* The SSM Parameter store is used to store the CloudLens API Key in a secure way. Ensure the parameter store is 
accessible by the instance's role by adding the AmazonSSMReadOnlyAccess policy to your instance role, or for
more restricted access use a policy like this one:
```json
   "Version": "2012-10-17",
   "Statement": [
       {
           "Effect": "Allow",
           "Action": [
               "ssm:GetParameter"
           ],
           "Resource": "arn:aws:ssm:*:*:parameter/cloudlens_api_key"
       }
   ]
```
* You must store the API Key in AWS SSM's parameter store before using this script:
```bash
aws ssm put-parameter --name cloudlens_api_key --type String --region $REGION --value xxxxxxxxyyyyyyyyzzzzzzzz
```
For more information, see [the AWS Documentation on Parameter Store](http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)

In addition, if using this script with EC2 Run:

* The EC2 Run agent must be present and functional. This agent is present by default on Amazon Linux, however for
it to be functional, be sure to add the AmazonEC2RoleforSSM to your instance role. For more information, see [the AWS Documentation on EC2 Run](http://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent.html)
