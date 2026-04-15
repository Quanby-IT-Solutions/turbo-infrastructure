variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "services" {
  description = <<-EOT
    Map of services. Services with expose_via_alb = true get a target group.
    Services with domain set get a host-header listener routing rule.
    The service with is_alb_default = true (or the first alphabetical) receives unmatched traffic.
  EOT
  type = map(object({
    port                 = number
    health_check_path    = string
    expose_via_alb       = optional(bool, true)
    is_alb_default       = optional(bool, false)
    domain               = optional(string, "")
    health_check_matcher = optional(string, "200-399")
  }))
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. When set, HTTPS listener is created with HTTP-to-HTTPS redirect."
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB (recommended for production)"
  type        = bool
  default     = false
}

variable "target_type" {
  description = "Target type for ALB target groups. Use 'instance' for EC2/ASG, 'ip' for ECS Fargate."
  type        = string
  default     = "instance"

  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "target_type must be 'instance', 'ip', or 'lambda'."
  }
}

variable "deregistration_delay" {
  description = "Time (seconds) to wait before deregistering targets. Lower values speed up deployments."
  type        = number
  default     = 120
}
