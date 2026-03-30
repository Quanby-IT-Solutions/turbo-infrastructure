variable "project_name" {
  description = "Project name used for all resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "services" {
  description = <<-EOT
    Map of services to deploy. Staging uses service names to provision ECR repos and
    CloudWatch log groups only — ECS, ALB, and networking are not created in staging.
  EOT

  type = map(object({
    port                 = number
    health_check_path    = string
    cpu                  = string
    memory               = string
    desired_count        = optional(number, 1)
    expose_via_alb       = optional(bool, true)
    is_alb_default       = optional(bool, false)
    domain               = optional(string, "")
    health_check_matcher = optional(string, "200-399")
    allow_vpc_egress     = optional(bool, false)
  }))

  validation {
    condition     = length(values(var.services)) == length(distinct([for s in values(var.services) : s.port]))
    error_message = "All services must have unique ports."
  }
}
