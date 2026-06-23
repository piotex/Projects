module "networking" {
  source = "./modules/networking"

  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidr_a  = var.public_subnet_cidr_a
  public_subnet_cidr_b  = var.public_subnet_cidr_b
  private_subnet_cidr_a = var.private_subnet_cidr_a
  private_subnet_cidr_b = var.private_subnet_cidr_b
  az_a                  = var.az_a
  az_b                  = var.az_b
}

module "ecr" {
  source = "./modules/ecr"

  environment  = var.environment
  project_name = var.project_name
}

module "rds" {
  source = "./modules/rds"

  environment        = var.environment
  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.private_subnet_ids
  ecs_sg_id          = module.ecs.ecs_tasks_sg_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  instance_class     = var.rds_instance_class
  max_connections    = var.rds_max_connections
}

module "ecs" {
  source = "./modules/ecs"

  environment        = var.environment
  project_name       = var.project_name
  aws_region         = var.aws_region
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  ecr_repository_url = module.ecr.repository_url
  db_host            = module.rds.db_endpoint
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  pool_min           = var.pool_min
  pool_max           = var.pool_max
  desired_count      = var.ecs_desired_count
}
