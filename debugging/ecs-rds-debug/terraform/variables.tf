variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

# Networking
variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidr_a" {
  type = string
}

variable "public_subnet_cidr_b" {
  type = string
}

variable "private_subnet_cidr_a" {
  type = string
}

variable "private_subnet_cidr_b" {
  type = string
}

variable "az_a" {
  type    = string
  default = "eu-central-1a"
}

variable "az_b" {
  type    = string
  default = "eu-central-1b"
}

# RDS
variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "rds_max_connections" {
  type    = number
  default = 25  # celowo mała wartość – łatwiej wyczerpać
  description = "max_connections na RDS (pg_parameter_group)"
}

# ECS / connection pool
variable "pool_min" {
  type    = number
  default = 1
}

variable "pool_max" {
  type    = number
  default = 5  # celowo mała – wyczerpie się po kilku /db/slow lub /db/leak
  description = "maximumPoolSize dla jednego taska ECS"
}

variable "ecs_desired_count" {
  type    = number
  default = 2
  description = "Liczba tasków ECS. max_conn = ecs_desired_count * pool_max"
}
