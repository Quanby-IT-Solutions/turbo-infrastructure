output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of NAT Gateways (for allowlisting in external services)"
  value       = aws_eip.nat[*].public_ip
}

output "alb_security_group_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "ecs_web_security_group_id" {
  description = "Security group ID for ECS web tasks"
  value       = aws_security_group.ecs_web.id
}

output "ecs_backend_security_group_id" {
  description = "Security group ID for ECS backend tasks"
  value       = aws_security_group.ecs_backend.id
}
