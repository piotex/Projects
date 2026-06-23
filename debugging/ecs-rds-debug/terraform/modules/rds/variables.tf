variable "environment"    { type = string }
variable "project_name"   { type = string }
variable "vpc_id"         { type = string }
variable "subnet_ids"     { type = list(string) }
variable "ecs_sg_id"      { type = string }
variable "db_name"        { type = string }
variable "db_username"    { type = string }
variable "db_password"    { type = string; sensitive = true }
variable "instance_class" { type = string }
variable "max_connections" {
  type        = number
  description = "Wartość max_connections w parameter group – celowo niska dla scenariusza lab"
}
