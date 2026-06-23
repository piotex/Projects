output "alb_dns_name" {
  value       = module.ecs.alb_dns_name
  description = "ALB endpoint – użyj do testów curl"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "rds_endpoint" {
  value       = module.rds.db_endpoint
  description = "RDS endpoint (bez portu)"
}

output "rds_port" {
  value = 5432
}
