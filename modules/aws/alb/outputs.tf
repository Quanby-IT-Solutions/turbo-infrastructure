output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix (for CloudWatch alarm dimensions)"
  value       = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  description = "ALB DNS name (use as production URL or CNAME target)"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (for Route53 alias records)"
  value       = aws_lb.main.zone_id
}

output "web_target_group_arn" {
  description = "Target group ARN for web service"
  value       = aws_lb_target_group.web.arn
}

output "web_target_group_arn_suffix" {
  description = "Web target group ARN suffix (for CloudWatch alarm dimensions)"
  value       = aws_lb_target_group.web.arn_suffix
}

output "backend_target_group_arn" {
  description = "Target group ARN for backend service"
  value       = aws_lb_target_group.backend.arn
}

output "backend_target_group_arn_suffix" {
  description = "Backend target group ARN suffix (for CloudWatch alarm dimensions)"
  value       = aws_lb_target_group.backend.arn_suffix
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "HTTPS listener ARN (empty string if HTTPS is not enabled)"
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : ""
}
