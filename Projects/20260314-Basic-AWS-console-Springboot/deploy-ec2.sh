#!/bin/bash
set -e

### =========================
### To run:
### 1. Create IAM USER and setup AWS CLI with credentials
###    aws configure --profile tech-user
###        AWS Access Key ID [None]: xxx
###        AWS Secret Access Key [None]: xxx
###        Default region name [None]: eu-central-1
###        Default output format [None]: json
### =========================


### =========================
### CONFIG
### =========================
AWS_PROFILE="tech-user"
REGION="eu-central-1"

KEY_NAME="kp-2-$(date +%F)"
SG_NAME="$(date +%F-%H-%M)-sg"

export AWS_PROFILE=$AWS_PROFILE

### =========================
### 5. AWS INFRA
### =========================

echo "===> Creating key pair"
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' \
    --output text > $KEY_NAME.pem

chmod 400 $KEY_NAME.pem

echo "===> Getting default VPC"
VPC=$(aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text)

echo "===> Getting subnet"
SUBNET=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC" \
    --query 'Subnets[0].SubnetId' \
    --output text)

echo "===> Creating security group"
SG_ID=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "demo-sg" \
    --vpc-id $VPC \
    --query 'GroupId' \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0

echo "===> Getting AMI"
AMI=$(aws ssm get-parameters-by-path \
    --path "/aws/service/ami-amazon-linux-latest" \
    --region $REGION \
    --query "Parameters[?contains(Name, 'al2023-ami-kernel-default-x86_64')].Value" \
    --output text)

echo "===> Starting EC2"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI \
    --count 1 \
    --instance-type t2.micro \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --subnet-id $SUBNET \
    --associate-public-ip-address \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance ID: $INSTANCE_ID"

echo "===> Waiting for instance..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Public IP: $PUBLIC_IP"
