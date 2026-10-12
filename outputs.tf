output "metabase_url" {
  description = "URL for the Metabase web interface."
  value       = module.alb.url
}

output "alb_dns_name" {
  description = "DNS name of the public Application Load Balancer."
  value       = module.alb.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs_metabase.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.ecs_metabase.service_name
}

output "rds_endpoint" {
  description = "Private RDS endpoint. It is not publicly reachable."
  value       = module.postgres.endpoint
}

output "rds_publicly_accessible" {
  description = "Confirms whether the RDS instance has public accessibility enabled."
  value       = module.postgres.publicly_accessible
}

output "rds_master_user_secret_arn" {
  description = "ARN of the AWS-managed RDS master-user secret."
  value       = module.postgres.master_user_secret_arn
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the created VPC."
  value       = module.network.vpc_id
}
