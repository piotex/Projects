aws_region = "eu-central-1"

project_name = "ecs-task-debugging"
environment  = "test"

vpc_cidr             = "10.30.0.0/16"
public_subnet_cidrs  = ["10.30.1.0/24", "10.30.2.0/24"]

container_port = 5000
task_cpu       = 256
task_memory    = 512
desired_count  = 1
