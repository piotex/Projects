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

module "ec2" {
  source = "./modules/ec2"

  environment       = var.environment
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.security_group.id

  instance_type = var.instance_type
  key_name      = var.key_name
}
