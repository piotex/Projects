variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "container_port" {
  type    = number
  default = 5000
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type        = number
  default     = 512
  description = "Celowo niski limit pamieci kontenera - /allocate go przekroczy i zabije task (OOMKilled)."
}

variable "desired_count" {
  type    = number
  default = 1
}
