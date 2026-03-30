output "web_log_group_name" {
  description = "CloudWatch log group name for web"
  value       = aws_cloudwatch_log_group.web.name
}

output "web_log_group_arn" {
  description = "CloudWatch log group ARN for web"
  value       = aws_cloudwatch_log_group.web.arn
}

output "backend_log_group_name" {
  description = "CloudWatch log group name for backend"
  value       = aws_cloudwatch_log_group.backend.name
}

output "backend_log_group_arn" {
  description = "CloudWatch log group ARN for backend"
  value       = aws_cloudwatch_log_group.backend.arn
}
