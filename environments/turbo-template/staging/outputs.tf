# =============================================================================
# Staging Outputs
# =============================================================================
# Copy these to GitHub → Settings → Environments → staging → Variables
# =============================================================================

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
