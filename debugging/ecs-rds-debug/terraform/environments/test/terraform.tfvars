aws_region   = "eu-central-1"
environment  = "test"
project_name = "ecs-rds-debug"

# Networking — 4 osobne CIDRy, każdy w innej AZ
vpc_cidr             = "10.30.0.0/16"
public_subnet_cidr_a  = "10.30.1.0/24"   # az_a — ALB + ECS public IP
public_subnet_cidr_b  = "10.30.2.0/24"   # az_b — ALB wymaga 2 AZ
private_subnet_cidr_a = "10.30.10.0/24"  # az_a — RDS
private_subnet_cidr_b = "10.30.11.0/24"  # az_b — RDS subnet group wymaga 2 AZ
az_a                  = "eu-central-1a"
az_b                  = "eu-central-1b"

# RDS — mała instancja, mało połączeń (celowo)
rds_instance_class  = "db.t3.micro"
rds_max_connections = 25
db_name             = "appdb"
db_username         = "appuser"
# db_password — podaj przez env: export TF_VAR_db_password="..."

# ECS + connection pool
pool_min          = 1
pool_max          = 5   # 2 taski * 5 = 10 połączeń; RDS max=25 → 15 zapas
ecs_desired_count = 2
