module "networking" {
  source = "./modules/networking"

  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
}

module "ecr" {
  source = "./modules/ecr"

  environment  = var.environment
  project_name = var.project_name
}

module "alb" {
  source = "./modules/alb"

  environment    = var.environment
  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.public_subnet_ids
  container_port = var.container_port
}

module "ecs" {
  source = "./modules/ecs"

  environment            = var.environment
  project_name           = var.project_name
  aws_region             = var.aws_region
  vpc_id                 = module.networking.vpc_id
  subnet_ids             = module.networking.public_subnet_ids
  ecr_repository_url     = module.ecr.repository_url
  alb_security_group_id  = module.alb.security_group_id
  target_group_arn       = module.alb.target_group_arn
  container_port         = var.container_port
  task_cpu                = var.task_cpu
  task_memory             = var.task_memory
  desired_count           = var.desired_count

  depends_on = [module.alb]
}
