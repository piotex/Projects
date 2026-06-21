# Process 100% CPU
Debugging scenario: aplikacja powoduje wysokie użycie CPU.

```
HOME=$(pwd)
```

## KeyPair
```bash
cd /home/peter/github/S3CR3T$

aws ec2 create-key-pair \
  --key-name lab-key \
  --region eu-central-1 \
  --query 'KeyMaterial' \
  --output text > lab-key.pem

chmod 400 lab-key.pem

aws ec2 delete-key-pair \
  --key-name lab-key \
  --region eu-central-1
rm lab-key.pem
```


## Deploy Infrastructure
```bash
cd $HOME
cd debugging/process-100-percent-cpu-linux/terraform

terraform init -backend-config=environments/test/backend.hcl

terraform plan -var-file=environments/test/terraform.tfvars -out=tfplan
terraform apply tfplan

PUBLIC_IP=$(terraform output -raw public_ip)              && echo $PUBLIC_IP
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)  && echo $ECR_REPO_URL

sed -i "s/PUBLIC_IP/$PUBLIC_IP/" ../ansible/inventory/test.ini
sed -i "s|ECR_REPO_URL|$ECR_REPO_URL|" ../ansible/group_vars/app.yml

terraform destroy -var-file=environments/test/terraform.tfvars
```


## Build and Push Docker Image to ECR
```bash
cd $HOME
cd debugging/process-100-percent-cpu-linux/terraform
ECR_REPO=$(terraform output -raw ecr_repository_url)   && echo $ECR_REPO
AWS_REGION="eu-central-1"


cd $HOME
cd debugging/process-100-percent-cpu-linux/app
# Login to ECR
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "$ECR_REPO"

docker build -t "$ECR_REPO:latest" .
docker push "$ECR_REPO:latest"
```


## Deploy with Ansible
```bash
cd $HOME
cd debugging/process-100-percent-cpu-linux/ansible
ansible-playbook \
  -i inventory/test.ini \
  playbook.yml \
  --tags "docker,app"
```




## Cleanup

```bash
terraform destroy -var-file=environments/test/terraform.tfvars
```