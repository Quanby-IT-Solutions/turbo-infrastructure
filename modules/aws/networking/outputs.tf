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

# --- Map outputs (canonical) ---

output "ecs_service_security_group_ids" {
  description = "Map of service name \u2192 ECS security group ID"
  value       = { for k, sg in aws_security_group.ecs_service : k => sg.id }
}

# --- Legacy individual outputs (backward compat) ---

output "ecs_web_security_group_id" {
  description = "Security group ID for ECS web tasks (legacy \u2014 prefer ecs_service_security_group_ids[\"web\"])"
  value       = lookup({ for k, sg in aws_security_group.ecs_service : k => sg.id }, "web", "")
}

output "ecs_backend_security_group_id" {
  description = "Security group ID for ECS backend tasks (legacy \u2014 prefer ecs_service_security_group_ids[\"backend\"])"
  value       = lookup({ for k, sg in aws_security_group.ecs_service : k => sg.id }, "backend", "")
}
