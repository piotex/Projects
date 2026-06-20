module "networking" {
  source = "./modules/networking"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
}

module "ecr" {
  source = "./modules/ecr"

  environment  = var.environment
  project_name = var.project_name
}

module "ec2" {
  source = "./modules/ec2"

  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  subnet_id              = module.networking.public_subnet_id
  allowed_ssh_cidr       = var.allowed_ssh_cidr

  instance_type         = var.instance_type
  key_name              = var.key_name
  ecr_repository_url    = module.ecr.repository_url
  aws_region            = var.aws_region
}
