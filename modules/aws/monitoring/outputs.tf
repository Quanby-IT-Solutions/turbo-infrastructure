# --- Map outputs (canonical \u2014 use these in new app deploy workflows) ---

output "log_group_names" {
  description = "Map of service name \u2192 CloudWatch log group name"
  value       = { for k, lg in aws_cloudwatch_log_group.service : k => lg.name }
}

output "log_group_arns" {
  description = "Map of service name \u2192 CloudWatch log group ARN"
  value       = { for k, lg in aws_cloudwatch_log_group.service : k => lg.arn }
}

# --- Legacy individual outputs (backward compat) ---

output "web_log_group_name" {
  description = "CloudWatch log group name for web (legacy \u2014 prefer log_group_names[\"web\"])"
  value       = lookup({ for k, lg in aws_cloudwatch_log_group.service : k => lg.name }, "web", "")
}

output "web_log_group_arn" {
  description = "CloudWatch log group ARN for web (legacy \u2014 prefer log_group_arns[\"web\"])"
  value       = lookup({ for k, lg in aws_cloudwatch_log_group.service : k => lg.arn }, "web", "")
}

output "backend_log_group_name" {
  description = "CloudWatch log group name for backend (legacy \u2014 prefer log_group_names[\"backend\"])"
  value       = lookup({ for k, lg in aws_cloudwatch_log_group.service : k => lg.name }, "backend", "")
}

output "backend_log_group_arn" {
  description = "CloudWatch log group ARN for backend (legacy \u2014 prefer log_group_arns[\"backend\"])"
  value       = lookup({ for k, lg in aws_cloudwatch_log_group.service : k => lg.arn }, "backend", "")
}
