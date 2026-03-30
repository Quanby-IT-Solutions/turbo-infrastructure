output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

# --- Map outputs (canonical) ---

output "service_names" {
  description = "Map of service name → ECS service name"
  value       = { for k, svc in aws_ecs_service.service : k => svc.name }
}

# --- Legacy individual outputs (backward compat) ---

output "web_service_name" {
  description = "ECS web service name (legacy — prefer service_names[\"web\"])"
  value       = lookup({ for k, svc in aws_ecs_service.service : k => svc.name }, "web", "")
}

output "backend_service_name" {
  description = "ECS backend service name (legacy — prefer service_names[\"backend\"])"
  value       = lookup({ for k, svc in aws_ecs_service.service : k => svc.name }, "backend", "")
}

output "execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_execution.arn
}

output "task_role_arn" {
  description = "ECS task role ARN (for app-level AWS SDK calls)"
  value       = aws_iam_role.ecs_task.arn
}
