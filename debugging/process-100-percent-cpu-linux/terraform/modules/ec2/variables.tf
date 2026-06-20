variable "environment" {
  type = string
}



variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}




variable "allowed_ssh_cidr" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "aws_region" {
  type = string
}
