#!/bin/sh

# This script may be used as "user data" during EC2 instance launch to start
# the CloudLens agent.
#
# Alternately, this script may be run using EC2 Run either by selecting
# AWS-RunShellScript and copying the contents of this script, or by running
# AWS-RunRemoteScript with the following options:
#
# Source Type: GitHub
# Source Info: {
#    "owner": "kraney",
#    "repository": "cloudlens_install",
#    "path": "ec2/agent_install.sh"
# }
# Command Line: bash agent_install.sh
#
#
# The AWS CLI command line for this would follow this format:
#
# aws ssm send-command --document-name "AWS-RunRemoteScript" \
#                      --parameters '{"sourceType":["GitHub"],"sourceInfo":["{ \"owner\": \"kraney\", \"repository\": \"cloudlens_install\", \"path\": \"ec2/agent_install.sh\" }"],"executionTimeout":["3600"],"commandLine":["bash agent_install.sh"]}' \
#                      --timeout-seconds 600
#
# In order for this EC2 Run script to work, the following prerequisites must be met:
#
# The EC2 Run agent must be present and functional. This agent is present by default on Amazon Linux, however for
# it to be functional, be sure to add the AmazonEC2RoleforSSM to your instance role.
#
# The SSM Parameter store is used to store the CloudLens API Key in a secure way. Ensure the parameter store is 
# accessible by the instance's role by adding the AmazonSSMReadOnlyAccess policy to your instance role, or for
# more restricted access use a policy like this one:
# 
#{
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Action": [
#                "ssm:GetParameter"
#            ],
#            "Resource": "arn:aws:ssm:*:*:parameter/cloudlens_api_key"
#        }
#    ]
#}
#
# You must store the API Key in AWS SSM's parameter store before using this script:
#
# aws ssm put-parameter --name cloudlens_api_key --type String --region $REGION --value xxxxxxxxyyyyyyyyzzzzzzzz


REGION=us-east-1

# install docker if it's not already present, for popular distros
if ! which docker 2> /dev/null > /dev/null; then
    # get.docker.com needs tweaking to support Amazon Linux
    curl https://get.docker.com/ | sed 's/fedora)/amzn|fedora)/' | sed 's/fedora-26/&\nx86_64-amzn-2017.09/' | bash
fi

# start docker for rpm-based distros
sudo systemctl start docker 2> /dev/null || true
sudo service docker start 2> /dev/null || true

# obtain the API key from SSM
apikey=$(aws ssm get-parameter --name cloudlens_api_key --region us-east-1 | sudo docker run --rm -i paasmule/curl-ssl-jq jq -r .Parameter.Value)

if sudo docker run --name cloudlens-agent \
                -v /:/host \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -d \
                --restart=always \
                --net=host \
                --device=/dev/mem \
                --cap-add=SYS_RAWIO \
                --cap-add=SYS_ADMIN \
                --cap-add=NET_ADMIN \
                --cap-add=NET_RAW \
                ixiacom/cloudlens-agent \
                --accept_eula y \
                --apikey "$apikey"; then
    echo "CloudLens Agent started"
fi
