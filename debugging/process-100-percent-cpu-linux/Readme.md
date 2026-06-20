# Process 100% CPU
Debugging scenario: aplikacja powoduje wysokie użycie CPU.


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
cd debugging/process-100-percent-cpu-linux/terraform

terraform init -backend-config=environments/test/backend.hcl

terraform plan -var-file=environments/test/terraform.tfvars -out=tfplan
terraform apply tfplan

PUBLIC_IP=$(terraform output -raw public_ip)              && echo $PUBLIC_IP
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)  && echo $ECR_REPO_URL

sed -i "s/PUBLIC_IP/$PUBLIC_IP/" ../ansible/inventory/test.ini
sed -i "s/ECR_REPO_URL/$ECR_REPO_URL/" ../ansible/group_vars/app.yml
```


## Build and Push Docker Image to ECR
```bash
cd debugging/process-100-percent-cpu-linux/terraform
ECR_REPO=$(terraform output -raw ecr_repository_url)   && echo $ECR_REPO
AWS_REGION="eu-central-1"


cd debugging/process-100-percent-cpu-linux/app
# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $ECR_REPO

# Build the image
docker build -t $ECR_REPO/cpu-app:latest .

# Push to ECR
docker push $ECR_REPO/cpu-app:latest
```


## Deploy with Ansible
```bash
cd debugging/process-100-percent-cpu-linux/ansible
ansible-playbook \
  -i inventory/test.ini \
  playbook.yml \
  --tags docker, app 
```


## Connect to EC2
```bash
cd debugging/process-100-percent-cpu-linux/terraform
PUBLIC_IP=$(terraform output -raw public_ip)

ssh -i /home/peter/github/S3CR3T\$/lab-key.pem ec2-user@$PUBLIC_IP

# Check running container
docker ps

# View container logs
docker logs cpu-app
```









## Run App

The application is now deployed automatically by Ansible.
It pulls the Docker image from ECR and runs it as a container.

To redeploy after code changes:
1. Build and push new image to ECR
2. Run Ansible playbook again

```bash
# View running container on EC2
docker ps
docker logs cpu-app
```

## Test

Healthcheck:

```bash
PUBLIC_IP=$(cd terraform && terraform output -raw public_ip)
curl http://$PUBLIC_IP:5000/
```

CPU intensive endpoint:

```bash
curl http://$PUBLIC_IP:5000/report
```

## Investigation

```bash
top

htop

ps aux

top -H -p <PID>
```

## Cleanup

```bash
terraform destroy \
  -var-file=env/test.tfvars
```