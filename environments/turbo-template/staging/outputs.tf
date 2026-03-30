# =============================================================================
# Staging Outputs
# =============================================================================
# Copy these to GitHub → Settings → Environments → staging → Variables
# =============================================================================

# --- EC2 Outputs ----------------------------------------------------------

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Public IP of the staging EC2 instance → GitHub secret: EC2_HOST"
  value       = module.ec2.instance_public_ip
}

output "ec2_private_ip" {
  description = "Private IP of the staging EC2 instance"
  value       = module.ec2.instance_private_ip
}

output "ec2_ssh_command" {
  description = "SSH command to connect to the staging instance"
  value       = module.ec2.ssh_connection_command
}

output "ec2_ssh_private_key" {
  description = "SSH private key (only when Terraform generates the key pair) → GitHub secret: EC2_SSH_KEY"
  value       = module.ec2.ssh_private_key_pem
  sensitive   = true
}

output "ec2_key_pair_name" {
  description = "Name of the EC2 key pair"
  value       = module.ec2.key_pair_name
}

# --- ECR Outputs ----------------------------------------------------------

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
