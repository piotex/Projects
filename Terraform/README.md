# Terraform

## 1. Install Terraform (WSL)
### 1.1. Update Packages
```
sudo apt update && sudo apt upgrade -y
```
### 1.2. Install Required Packages
```
sudo apt install -y gnupg software-properties-common curl
```
### 1.3. Add HashiCorp GPG Key
```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```
### 1.4. Add HashiCorp Repository
```
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
```
### 1.5. Install Terraform
```
sudo apt update
sudo apt install -y terraform
```
### 1.6. Verify Installation
```
terraform -version
```

## 2. Create IAM User 
### 2.1 Asign IAM Role/Policy/Permitions
### 2.2 Generate Access Key
### 2.3 Setup WSL aws cli profile
```
aws configure --profile profile-1
    AWS Access Key ID [None]: 
    AWS Secret Access Key [None]: 
    Default region name [None]: eu-central-1
    Default output format [None]: json

aws s3 ls --profile profile-1
```
### 2.4 Use profile-1 as default profile (to don't repet using --profile flag)
```
export AWS_PROFILE=profile-1
aws s3 ls
```
### 2.5 Create S3 bucket for tfstate
```
REGION=eu-central-1
aws s3api create-bucket \
  --bucket terraform-state-kubon-tech \
  --region $REGION \
  --create-bucket-configuration LocationConstraint=$REGION

aws s3api put-bucket-versioning \
  --bucket terraform-state-kubon-tech \
  --versioning-configuration Status=Enabled
```
