# ECS-RDS Debug Lab — Infrastruktura

## Struktura projektu

```
ecs-rds-debug/
├── app/
│   ├── code/
│   │   ├── main.py          # Flask app z pulą połączeń (scenariusze debugowania)
│   │   └── main.basic.py    # Wersja bez puli (do porównania)
│   ├── Dockerfile
│   └── requirements.txt
├── terraform/
│   ├── environments/test/
│   │   ├── backend.hcl
│   │   └── terraform.tfvars
│   ├── modules/
│   │   ├── networking/      # VPC, subnety (public + 2× private), IGW
│   │   ├── ecr/             # ECR repository
│   │   ├── rds/             # PostgreSQL + parameter group (max_connections)
│   │   └── ecs/             # Fargate cluster, ALB, task definition, service
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── backend.tf
├── ansible/                 # Opcjonalny deploy na EC2 (zamiast ECS)
├── scripts/
│   └── debug_ecs_rds.sh    # Narzędzie diagnostyczne
└── Readme.md
```

## Zmienne kluczowe

| Zmienna              | Domyślnie | Cel                                      |
|----------------------|-----------|------------------------------------------|
| `rds_max_connections`| 25        | Celowo niska — łatwiej wyczerpać         |
| `pool_max`           | 5         | Połączenia per task ECS                  |
| `ecs_desired_count`  | 2         | Liczba tasków                            |
| **Wynik**            | 10        | 2×5 = 10 połączeń aktywnych (25 = limit) |

## Kluczowe polecenia

```bash
# Deploy
terraform init -backend-config=environments/test/backend.hcl
terraform plan -var-file=environments/test/terraform.tfvars -out=tfplan
terraform apply "tfplan"

# Outputs
terraform output -raw alb_dns_name
terraform output -raw rds_endpoint
terraform output -raw ecr_repository_url

# Destroy
terraform destroy -var-file=environments/test/terraform.tfvars
```
