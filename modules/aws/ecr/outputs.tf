# --- Map outputs (canonical \u2014 use these in new app deploy workflows) ---

output "repository_urls" {
  description = "Map of service name \u2192 ECR repository URL"
  value       = { for k, repo in aws_ecr_repository.service : k => repo.repository_url }
}

output "repository_names" {
  description = "Map of service name \u2192 ECR repository name"
  value       = { for k, repo in aws_ecr_repository.service : k => repo.name }
}

# --- Legacy individual outputs (backward compat with existing app CI/CD) ---

output "web_repository_url" {
  description = "ECR repository URL for web (legacy \u2014 prefer repository_urls[\"web\"])"
  value       = lookup({ for k, repo in aws_ecr_repository.service : k => repo.repository_url }, "web", "")
}

output "web_repository_name" {
  description = "ECR repository name for web (legacy \u2014 prefer repository_names[\"web\"])"
  value       = lookup({ for k, repo in aws_ecr_repository.service : k => repo.name }, "web", "")
}

output "backend_repository_url" {
  description = "ECR repository URL for backend (legacy \u2014 prefer repository_urls[\"backend\"])"
  value       = lookup({ for k, repo in aws_ecr_repository.service : k => repo.repository_url }, "backend", "")
}

output "backend_repository_name" {
  description = "ECR repository name for backend (legacy \u2014 prefer repository_names[\"backend\"])"
  value       = lookup({ for k, repo in aws_ecr_repository.service : k => repo.name }, "backend", "")
}
