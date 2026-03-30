# =============================================================================
# Staging Outputs
# =============================================================================
# Copy these to GitHub → Settings → Environments → staging → Variables
# =============================================================================

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
