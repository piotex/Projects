
## Wstep
```bash
cd $HOME
cd debugging/process-100-percent-cpu-ecs/terraform
ALB_DNS=$(terraform output -raw alb_dns_name)         && echo $ALB_DNS
CLUSTER=$(terraform output -raw ecs_cluster_name)      && echo $CLUSTER
SERVICE=$(terraform output -raw ecs_service_name)       && echo $SERVICE
LOG_GROUP=$(terraform output -raw log_group_name)        && echo $LOG_GROUP
```

## Wywolanie scenariuszy (przez ALB)
```bash
curl http://$ALB_DNS/

# Scenariusze:
curl http://$ALB_DNS/cpu                          # 100% CPU przez 60s
curl http://$ALB_DNS/allocate                     # ~1GB RAM -> OOMKilled (limit kontenera = 512MB)
curl http://$ALB_DNS/free
curl "http://$ALB_DNS/slow?seconds=20"            # opozniona odpowiedz -> failed health checks
curl http://$ALB_DNS/crash                        # natychmiastowe wyjscie kontenera -> crash loop
curl http://$ALB_DNS/whoami                       # tozsamosc task role (sts get-caller-identity)
curl "http://$ALB_DNS/s3?bucket=dowolny-bucket"   # AccessDenied -> brak uprawnien w task role
```


## Znajdz klaster, serwis i taski
```bash
aws ecs list-clusters
aws ecs list-services --cluster $CLUSTER
aws ecs list-tasks --cluster $CLUSTER --service-name $SERVICE

TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER --service-name $SERVICE --query 'taskArns[0]' --output text) && echo $TASK_ARN
```


## Status i przyczyna zatrzymania taska
```bash
aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK_ARN \
  --query 'tasks[0].{lastStatus:lastStatus,stoppedReason:stoppedReason,containers:containers[*].{name:name,exitCode:exitCode,reason:reason}}'

# Historia ostatnio zatrzymanych taskow
aws ecs list-tasks --cluster $CLUSTER --service-name $SERVICE --desired-status STOPPED
```

### Najczestsze stoppedReason / exitCode
| stoppedReason / exitCode | co oznacza |
|---|---|
| `OutOfMemoryError` / exitCode 137 | kontener przekroczyl limit pamieci (`memory` w task definition) |
| `Essential container in task exited` | aplikacja sama sie zakonczyla (np. nieobsluzony wyjatek, `os._exit`) |
| `CannotPullContainerError` | brak dostepu do ECR (siec / brak `assign_public_ip` / brak uprawnien execution role) |
| `ResourceInitializationError` | execution role nie ma odpowiednich uprawnien (np. `AmazonECSTaskExecutionRolePolicy`) |
| `Task failed container health checks` | `HEALTHCHECK` / `healthCheck` z task definition nie przeszedl (np. po `/slow`) |
| `Task failed ELB health checks` | target group ALB oznaczyl taska jako unhealthy |
| `Scaling activity initiated by (deployment ...)` | normalna wymiana tasku w trakcie deploymentu, nie zawsze problem |


## Logi (CloudWatch Logs)
```bash
aws logs tail "$LOG_GROUP" --follow
aws logs tail "$LOG_GROUP" --since 10m

# Logi konkretnego taska (stream zawiera ID taska)
aws logs tail "$LOG_GROUP" --filter-pattern "$(echo $TASK_ARN | awk -F/ '{print $NF}')"
```


## Interaktywna sesja w kontenerze (ECS Exec)
Wymaga `enableExecuteCommand = true` na serwisie (juz ustawione w `aws_ecs_service`) oraz SSM agenta
w obrazie (warstwa bazowa `python:3.12-slim` go nie ma domyslnie - AWS dostarcza go runtime'owo
dla Fargate >= platform version 1.4.0, wiec zwykle dziala bez dodatkowej instalacji).
```bash
aws ecs execute-command \
  --cluster $CLUSTER \
  --task $TASK_ARN \
  --container cpu-app \
  --interactive \
  --command "/bin/sh"
```
Po wejsciu do kontenera mozna uzyc tych samych narzedzi co przy debugowaniu zwyklego procesu
na Linuxie (zobacz `process-100-percent-cpu-linux/Readme.md`): `ps aux`, `top`, `pmap`, `py-spy`,
`pidstat`. W slim obrazie czesc z nich trzeba doinstalowac w locie, np.:
```bash
pip install py-spy
py-spy top --pid 1
```


## Health check ALB (target group)
```bash
TG_ARN=$(aws elbv2 describe-target-groups \
  --names test-ecs-tg \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

aws elbv2 describe-target-health --target-group-arn $TG_ARN
```


## Wydarzenia i deploymenty serwisu
```bash
aws ecs describe-services --cluster $CLUSTER --services $SERVICE \
  --query 'services[0].events[:10]'

aws ecs describe-services --cluster $CLUSTER --services $SERVICE \
  --query 'services[0].deployments'
```


## Metryki CPU / pamiec (Container Insights)
```bash
aws cloudwatch get-metric-statistics \
  --namespace ECS/ContainerInsights \
  --metric-name CpuUtilized \
  --dimensions Name=ClusterName,Value=$CLUSTER Name=ServiceName,Value=$SERVICE \
  --start-time "$(date -u -d '30 min ago' +%Y-%m-%dT%H:%M:%S)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
  --period 60 \
  --statistics Average Maximum

# analogicznie: MemoryUtilized
```


## Diagnoza problemow z IAM (task role -> AccessDenied)
```bash
TASK_ROLE_ARN=$(terraform output -raw task_role_arn) && echo $TASK_ROLE_ARN
TASK_ROLE_NAME=$(echo $TASK_ROLE_ARN | awk -F/ '{print $NF}')

aws iam get-role --role-name $TASK_ROLE_NAME
aws iam list-role-policies --role-name $TASK_ROLE_NAME
aws iam list-attached-role-policies --role-name $TASK_ROLE_NAME

# Symulacja czy dana akcja przejdzie, bez faktycznego wykonania
aws iam simulate-principal-policy \
  --policy-source-arn $TASK_ROLE_ARN \
  --action-names s3:ListBucket \
  --resource-arns "arn:aws:s3:::dowolny-bucket"
```


## Definicja taska
```bash
aws ecs describe-task-definition \
  --task-definition test-ecs-task-debugging \
  --query 'taskDefinition.containerDefinitions'
```


## Wymuszenie nowego deploymentu / restart
```bash
aws ecs update-service --cluster $CLUSTER --service $SERVICE --force-new-deployment
```


## Cleanup
```bash
cd $HOME
cd debugging/process-100-percent-cpu-ecs/terraform
terraform destroy -var-file=environments/test/terraform.tfvars
```
