output "web_repository_url" {
  description = "ECR repository URL for web"
  value       = aws_ecr_repository.web.repository_url
}

output "web_repository_name" {
  description = "ECR repository name for web"
  value       = aws_ecr_repository.web.name
}

output "backend_repository_url" {
  description = "ECR repository URL for backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "backend_repository_name" {
  description = "ECR repository name for backend"
  value       = aws_ecr_repository.backend.name
}
