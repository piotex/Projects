output "alb_dns_name" {
  value = module.alb.dns_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "log_group_name" {
  value = module.ecs.log_group_name
}

output "task_role_arn" {
  value = module.ecs.task_role_arn
}
