#!/bin/bash

set -e

REGION="eu-central-1"
SG_NAME="jenkins-sg"

INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running,pending,stopped" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region $REGION)

if [ -n "$INSTANCE_ID" ]; then
    aws ec2 terminate-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION >/dev/null

  aws ec2 wait instance-terminated \
        --instance-ids $INSTANCE_ID \
        --region $REGION 
    echo "EC2 instance $INSTANCE_ID terminated."
fi


SG_ID=$(aws ec2 describe-security-groups \
    --filters Name=group-name,Values=$SG_NAME \
    --query 'SecurityGroups[0].GroupId' \
    --output text \
    --region $REGION)

if [ "$SG_ID" != "None" ]; then
    aws ec2 delete-security-group \
        --group-id $SG_ID \
        --region $REGION >/dev/null
    echo "Security group $SG_ID deleted."
fi


KEY_NAME=$(aws ec2 describe-key-pairs \
    --query "KeyPairs[?contains(KeyName, 'jenkins-kp')].KeyName" \
    --output text \
    --region $REGION)

if [ -n "$KEY_NAME" ]; then
    aws ec2 delete-key-pair \
        --key-name $KEY_NAME \
        --region $REGION >/dev/null

    if [ -f "$KEY_NAME.pem" ]; then
        rm -rf $KEY_NAME.pem
        echo "Key pair $KEY_NAME and local file deleted."
    fi
    echo "Key pair $KEY_NAME deleted."
fi

echo "Cleanup finished."