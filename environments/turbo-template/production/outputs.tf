# =============================================================================
# Production Outputs
# =============================================================================
# After `terraform apply`, copy these to:
#   GitHub → Settings → Environments → production → Variables
# =============================================================================

# --- Networking ---

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

# --- ALB ---

output "alb_dns_name" {
  description = "ALB DNS name → CNAME/alias target for production domains"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (for Route53 alias records)"
  value       = module.alb.alb_zone_id
}

# --- ASG ---

output "asg_name" {
  description = "Auto Scaling Group name → GitHub var: ASG_NAME"
  value       = module.ec2_asg.asg_name
}

output "launch_template_id" {
  description = "Launch template ID → GitHub var: LAUNCH_TEMPLATE_ID"
  value       = module.ec2_asg.launch_template_id
}

# --- ECR ---

output "ecr_repository_names" {
  description = "Map of service name → ECR repository name"
  value       = module.ecr.repository_names
}

output "ecr_repository_urls" {
  description = "Map of service name → ECR repository URL"
  value       = module.ecr.repository_urls
}

# Legacy (backward compat)
output "ecr_web_repository_name" {
  description = "→ GitHub var: ECR_REPOSITORY_WEB (legacy — prefer ecr_repository_names[\"web\"])"
  value       = module.ecr.web_repository_name
}

output "ecr_backend_repository_name" {
  description = "→ GitHub var: ECR_REPOSITORY_BACKEND (legacy — prefer ecr_repository_names[\"backend\"])"
  value       = module.ecr.backend_repository_name
}

output "ecr_web_repository_url" {
  description = "Full ECR URL for web images (legacy — prefer ecr_repository_urls[\"web\"])"
  value       = module.ecr.web_repository_url
}

output "ecr_backend_repository_url" {
  description = "Full ECR URL for backend images (legacy — prefer ecr_repository_urls[\"backend\"])"
  value       = module.ecr.backend_repository_url
}
