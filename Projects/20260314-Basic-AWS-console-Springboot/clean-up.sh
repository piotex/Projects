#!/bin/bash
set -e

### =========================
### CONFIG
### =========================
AWS_PROFILE="tech-user"
REGION="eu-central-1"

export AWS_PROFILE=$AWS_PROFILE

echo "===> Finding running instances"

INSTANCE_IDS=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

if [ -n "$INSTANCE_IDS" ]; then
    echo "===> Terminating instances: $INSTANCE_IDS"
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region $REGION

    echo "===> Waiting for termination..."
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS --region $REGION
else
    echo "No instances found"
fi

echo "===> Finding security groups (custom only)"

SG_IDS=$(aws ec2 describe-security-groups \
    --region $REGION \
    --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
    --output text)

for SG in $SG_IDS; do
    echo "Deleting SG: $SG"
    aws ec2 delete-security-group --group-id $SG --region $REGION || echo "Skip $SG"
done

echo "===> Finding key pairs"

KEYS=$(aws ec2 describe-key-pairs \
    --region $REGION \
    --query 'KeyPairs[*].KeyName' \
    --output text)

for KEY in $KEYS; do
    echo "Deleting key pair: $KEY"
    aws ec2 delete-key-pair --key-name $KEY --region $REGION || echo "Skip $KEY"

    if [ -f "$KEY.pem" ]; then
        rm -f "$KEY.pem"
        echo "Deleted local file: $KEY.pem"
    fi
done

rm -f kp-*.pem

echo "===> Cleanup finished ✅"