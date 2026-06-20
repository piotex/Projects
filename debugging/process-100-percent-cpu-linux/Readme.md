# Process 100% CPU
Debugging scenario: aplikacja powoduje wysokie użycie CPU.

## KeyPair
```
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

## Deploy
```bash
cd debugging/process-100-percent-cpu-linux/terraform

terraform init -backend-config=environments/test/backend.hcl

terraform plan -var-file=environments/test/terraform.tfvars -out=tfplan
terraform apply tfplan
```

## Connect
```bash
cd debugging/process-100-percent-cpu-linux/terraform
PUBLIC_IP=$(terraform output -raw public_ip)

ssh -i /home/peter/github/S3CR3T\$/lab-key.pem ec2-user@$PUBLIC_IP
```

## Ansible
```
cd debugging/process-100-percent-cpu-linux/terraform
PUBLIC_IP=$(terraform output -raw public_ip)     && echo $PUBLIC_IP

cd ../ansible/inventory
sed -i "s/PUBLIC_IP/$PUBLIC_IP/" test.ini
```
```

```









## Run App

```bash
docker build -t cpu-app .

docker run -d \
  -p 5000:5000 \
  --name cpu-app \
  cpu-app
```

## Test

Healthcheck:

```bash
curl http://<PUBLIC_IP>:5000/
```

CPU intensive endpoint:

```bash
curl http://<PUBLIC_IP>:5000/report
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