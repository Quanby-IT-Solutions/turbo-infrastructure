# =============================================================================
# Production Outputs
# =============================================================================
# After `terraform apply`, these values are used to configure the app repo's
# GitHub Environment variables. Copy them to:
#   GitHub → Settings → Environments → production → Variables
# =============================================================================

# --- Networking ---

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "nat_gateway_public_ips" {
  description = "NAT Gateway public IPs (for allowlisting in external services)"
  value       = module.networking.nat_gateway_public_ips
}

# --- ECR ---

output "ecr_web_repository_name" {
  description = "→ GitHub var: ECR_REPOSITORY_WEB"
  value       = module.ecr.web_repository_name
}

output "ecr_backend_repository_name" {
  description = "→ GitHub var: ECR_REPOSITORY_BACKEND"
  value       = module.ecr.backend_repository_name
}

output "ecr_web_repository_url" {
  description = "Full ECR URL for web images"
  value       = module.ecr.web_repository_url
}

output "ecr_backend_repository_url" {
  description = "Full ECR URL for backend images"
  value       = module.ecr.backend_repository_url
}

# --- ECS ---

output "ecs_cluster_name" {
  description = "→ GitHub var: ECS_CLUSTER"
  value       = module.ecs.cluster_name
}

output "ecs_web_service_name" {
  description = "→ GitHub var: ECS_SERVICE_WEB"
  value       = module.ecs.web_service_name
}

output "ecs_backend_service_name" {
  description = "→ GitHub var: ECS_SERVICE_BACKEND"
  value       = module.ecs.backend_service_name
}

output "ecs_execution_role_arn" {
  description = "→ GitHub var: ECS_EXECUTION_ROLE_ARN"
  value       = module.ecs.execution_role_arn
}

output "ecs_task_role_arn" {
  description = "→ GitHub var: ECS_TASK_ROLE_ARN"
  value       = module.ecs.task_role_arn
}

# --- ALB ---

output "alb_dns_name" {
  description = "ALB DNS name — point both yourdomain.com and api.yourdomain.com CNAME here"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (for Route53 alias records)"
  value       = module.alb.alb_zone_id
}

# --- Monitoring ---

output "web_log_group_name" {
  description = "CloudWatch log group for web service"
  value       = module.monitoring.web_log_group_name
}

output "backend_log_group_name" {
  description = "CloudWatch log group for backend service"
  value       = module.monitoring.backend_log_group_name
}
