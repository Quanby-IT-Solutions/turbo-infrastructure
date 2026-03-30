# --- Instance Outputs -----------------------------------------------------

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance (Elastic IP if enabled, otherwise ephemeral)"
  value       = var.enable_elastic_ip ? aws_eip.main[0].public_ip : aws_instance.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.main.private_ip
}

# --- Networking Outputs ---------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id
}

# --- SSH Outputs ----------------------------------------------------------

output "ssh_private_key_pem" {
  description = "SSH private key (only when Terraform creates the key pair). Save this securely."
  value       = var.key_name == "" ? tls_private_key.ec2[0].private_key_openssh : ""
  sensitive   = true
}

output "key_pair_name" {
  description = "Name of the EC2 key pair"
  value       = var.key_name != "" ? var.key_name : aws_key_pair.ec2[0].key_name
}

# --- Connection Info (for deploy workflows) -------------------------------

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_name != "" ? var.key_name : aws_key_pair.ec2[0].key_name}.pem ec2-user@${var.enable_elastic_ip ? aws_eip.main[0].public_ip : aws_instance.main.public_ip}"
}
