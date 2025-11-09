# Create-EC2-SG
```
cd /home/peter/github/Projects/Terraform/Create-EC2-SG/
```

## 1. Before Terraform 
### 1.1 Create KeyPair
```
aws ec2 create-key-pair \
  --key-name web-ec2-key \
  --query "KeyMaterial" \
  --output text > web-ec2-key.pem

chmod 400 web-ec2-key.pem
```

## 2. Initialize Terraform Project
### 2.1 Folder Structure
```
terraform-project/
├── backend.tf
├── provider.tf
├── variables.tf
├── main.tf
└── outputs.tf
```
### 2.2 Initialize Terraform
```
terraform init
```
### 2.3 Validate Configuration
```
terraform validate
```
### 2.4 Plan Changes
```
terraform plan -out=tfplan
```
### 2.5 Apply Configuration
```
terraform apply "tfplan"
```

## 4. Check Deployed Resources
### 4.1 Check EC2 Instance
```
aws ec2 describe-instances \
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,PublicIP:PublicIpAddress}" \
  --output table
```
### 4.2 SSH to EC2
```
PUBLIC_IP=$(terraform output -raw a1_instance_public_ip)
echo $PUBLIC_IP

ssh -o StrictHostKeyChecking=no -i web-ec2-key.pem ec2-user@$PUBLIC_IP
```
### 4.3 Verify Web Server
Open in browser:
```
curl $PUBLIC_IP
```

## 5. Clean Up
### 5.1 Destroy Resources
```
terraform destroy -auto-approve
```
### 5.2 Optionally Remove KeyPair
```
aws ec2 delete-key-pair --key-name web-ec2-key
```
### 5.2 Optionally Remove Local Files
```
rm -rf .terraform terraform.tfstate terraform.tfstate.backup tfplan .terraform.lock.hcl web-ec2-key.pem
```
