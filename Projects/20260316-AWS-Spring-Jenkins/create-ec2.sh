#!/bin/bash
set -e

REGION="eu-central-1"
KEY_NAME="jenkins-kp"
SG_NAME="jenkins-sg"
INSTANCE_TYPE="t2.micro"

aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' \
    --output text > $KEY_NAME.pem
chmod 400 $KEY_NAME.pem

VPC=$(aws ec2 describe-vpcs \
    --query 'Vpcs[0].VpcId' \
    --output text)

SUBNET=$(aws ec2 describe-subnets \
    --filters Name=vpc-id,Values=$VPC \
    --query 'Subnets[0].SubnetId' \
    --output text)

SG_ID=$(aws ec2 create-security-group \
    --group-name $SG_NAME \
    --description "jenkins security group" \
    --vpc-id $VPC \
    --query 'GroupId' \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 >/dev/null

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0 >/dev/null

AMI=$(aws ssm get-parameters-by-path \
    --path "/aws/service/ami-amazon-linux-latest" \
    --region $REGION \
    --query "Parameters[?contains(Name, 'al2023-ami-kernel-default-x86_64')].Value" \
    --output text)

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --subnet-id $SUBNET \
    --associate-public-ip-address \
    --query 'Instances[0].InstanceId' \
    --output text)

aws ec2 wait instance-running \
    --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "EC2 Public IP: $PUBLIC_IP"
echo "SSH Command: ssh -i $KEY_NAME.pem ec2-user@$PUBLIC_IP"
echo "SCP Command: scp -i $KEY_NAME.pem jenkins-user-data.sh ec2-user@$PUBLIC_IP:/home/ec2-user/jenkins-user-data.sh"