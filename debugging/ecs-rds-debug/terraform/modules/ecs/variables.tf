variable "environment"        { type = string }
variable "project_name"       { type = string }
variable "aws_region"         { type = string }
variable "vpc_id"             { type = string }
variable "public_subnet_ids"  { type = list(string) }
variable "ecr_repository_url" { type = string }
variable "db_host"            { type = string }
variable "db_name"            { type = string }
variable "db_username"        { type = string }
variable "db_password"        { 
    type = string
    sensitive = true 
}
variable "pool_min"           { type = number }
variable "pool_max"           { type = number }
variable "desired_count"      { type = number }
