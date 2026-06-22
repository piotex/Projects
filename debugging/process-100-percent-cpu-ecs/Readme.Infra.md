# ECS Task Debugging
Debugging scenario: aplikacja na ECS Fargate sprawiajaca problemy 
(OOMKilled, crash loop, failed health checks, AccessDenied z IAM).

```bash
HOME=$(pwd)
```

## Deploy Infrastructure
```bash
cd $HOME
cd debugging/process-100-percent-cpu-ecs/terraform

terraform init -backend-config=environments/test/backend.hcl

terraform plan -var-file=environments/test/terraform.tfvars -out=tfplan
terraform apply tfplan

ALB_DNS=$(terraform output -raw alb_dns_name)               && echo $ALB_DNS
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)    && echo $ECR_REPO_URL
CLUSTER=$(terraform output -raw ecs_cluster_name)            && echo $CLUSTER
SERVICE=$(terraform output -raw ecs_service_name)             && echo $SERVICE
LOG_GROUP=$(terraform output -raw log_group_name)              && echo $LOG_GROUP

terraform destroy -var-file=environments/test/terraform.tfvars
```


## Build and Push Docker Image to ECR
```bash
cd $HOME
cd debugging/process-100-percent-cpu-ecs/terraform
ECR_REPO=$(terraform output -raw ecr_repository_url)   && echo $ECR_REPO
AWS_REGION="eu-central-1"


cd $HOME
cd debugging/process-100-percent-cpu-ecs/app
# Login to ECR
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "$ECR_REPO"

docker build -t "$ECR_REPO:latest" .
docker push "$ECR_REPO:latest"
```


## Deploy new image (force new deployment)
Serwis ECS uzywa tagu `:latest`, wiec po kazdym `docker push` trzeba wymusic nowy deployment
(inaczej taski dalej beda korzystac ze starego obrazu pobranego przy poprzednim uruchomieniu):
```bash
cd $HOME
cd debugging/process-100-percent-cpu-ecs/terraform
CLUSTER=$(terraform output -raw ecs_cluster_name)
SERVICE=$(terraform output -raw ecs_service_name)

aws ecs update-service \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --force-new-deployment \
  --region eu-central-1
```


## Cleanup

```bash
terraform destroy -var-file=environments/test/terraform.tfvars
```
