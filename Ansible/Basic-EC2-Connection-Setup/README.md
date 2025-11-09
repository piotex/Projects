# Basic-EC2-Connection-Setup
```
cd /home/peter/github/Projects/Ansible/Basic-EC2-Connection-Setup/
```

## 1. Create IAM User 
### 1.1 Asign IAM Role/Policy/Permitions
### 1.2 Generate Access Key
### 1.3 Setup WSL aws cli profile
```
aws configure --profile profile-1
    AWS Access Key ID [None]: 
    AWS Secret Access Key [None]: 
    Default region name [None]: eu-central-1
    Default output format [None]: json

aws s3 ls --profile profile-1
```
### 1.4 Use profile-1 as default profile (to don't repet using --profile flag)
```
export AWS_PROFILE=profile-1
aws s3 ls
```

## 2. Create AWS Security Group, KeyPair and EC2
### 2.1 Create AWS Security Group
```
aws ec2 create-security-group \
  --group-name web-sg \
  --description "Allow SSH and HTTP"
```
### 2.2 Add permitions
```
SG_ID=$(aws ec2 describe-security-groups --group-names web-sg --query "SecurityGroups[0].GroupId" --output text)
echo $SG_ID

aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
```
### 2.3 Create KeyPair
```
aws ec2 create-key-pair \
  --key-name web-ec2-key \
  --query "KeyMaterial" \
  --output text > web-ec2-key.pem

chmod 400 web-ec2-key.pem
```
### 2.4 Create EC2
```
aws ec2 run-instances \
  --image-id ami-0f78f0f0c76cef16f \
  --instance-type t2.micro \
  --key-name web-ec2-key \
  --security-group-ids $SG_ID \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyWebServer}]'

```
### 2.5 Try to connect to EC2
```
PUBLIC_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=MyWebServer" \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text)
echo $PUBLIC_IP

ssh -i web-ec2-key.pem ec2-user@$PUBLIC_IP
```

## 3. Install httpd using Ansible
### 2.1 Config file with credentials to connect to EC2 - KeyPair
    Create `ansible.cfg` file
### 2.1 Ansible inventory
#### 2.1.1 Manual
    Create file `hosts.ini` and add public ip
#### 2.1.2 Automated
```
PUBLIC_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=MyWebServer" \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text)

echo "[web]" > hosts.ini
echo "mywebserver ansible_host=$PUBLIC_IP " >> hosts.ini
```
### 2.2 Create Playbook
    Create file `site.yml`
### 2.2 Run Playbook
```
ansible -i hosts.ini web -m ping
ansible-playbook -i hosts.ini site.yml
```

## 3. Clean up
```
deactivate
rm -rf venv

INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=MyWebServer" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text)
echo $INSTANCE_ID

aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 delete-security-group --group-name web-sg
aws ec2 delete-key-pair --key-name web-ec2-key
rm -f web-ec2-key.pem


```