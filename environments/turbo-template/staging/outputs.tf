# =============================================================================
# Staging Outputs
# =============================================================================
# After `terraform apply`, copy these values to:
#   GitHub → Settings → Environments → staging → Variables / Secrets
# =============================================================================

# --- EC2 / Elastic IP ---

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "elastic_ip" {
  description = "Elastic IP address → point your staging DNS A records here"
  value       = module.ec2.instance_public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = module.ec2.instance_private_ip
}

output "ssh_connection_command" {
  description = "SSH command to connect to the staging instance"
  value       = module.ec2.ssh_connection_command
}

output "ssh_private_key_pem" {
  description = "SSH private key PEM (only set when Terraform auto-created the key pair). Save this to GitHub Secrets: EC2_SSH_KEY"
  value       = module.ec2.ssh_private_key_pem
  sensitive   = true
}

output "key_pair_name" {
  description = "Name of the EC2 key pair in use"
  value       = module.ec2.key_pair_name
}

# --- Security / Networking ---

output "vpc_id" {
  description = "VPC ID"
  value       = module.ec2.vpc_id
}

output "security_group_id" {
  description = "EC2 security group ID"
  value       = module.ec2.security_group_id
}

# --- ECR ---

output "ecr_repository_names" {
  description = "Map of service name → ECR repository name → GitHub var: ECR_REPOSITORY_<SERVICE>"
  value       = module.ecr.repository_names
}

output "ecr_repository_urls" {
  description = "Map of service name → full ECR repository URL (for docker push)"
  value       = module.ecr.repository_urls
}

# Legacy (backward compat with existing CI/CD)
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
