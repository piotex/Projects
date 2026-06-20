module "networking" {
  source = "./modules/networking"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
}

module "security_group" {
  source = "./modules/security_group"

  environment      = var.environment
  vpc_id           = module.networking.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "ecr" {
  source = "./modules/ecr"

  environment  = var.environment
  project_name = var.project_name
}

module "iam" {
  source = "./modules/iam"

  environment = var.environment
}

module "ec2" {
  source = "./modules/ec2"

  environment            = var.environment
  subnet_id              = module.networking.public_subnet_id
  security_group_id      = module.security_group.id
  iam_instance_profile   = module.iam.instance_profile_name

  instance_type         = var.instance_type
  key_name              = var.key_name
  ecr_repository_url    = module.ecr.repository_url
  aws_region            = var.aws_region
}
