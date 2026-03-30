variable "project_name" {
  description = "Project name used for all resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "az_count" {
  description = "Number of availability zones (1-3)"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3."
  }
}

variable "services" {
  description = <<-EOT
    Map of services to deploy. Each key becomes the service name used in all resource names.
    Adding a new service here is the only change needed to provision its full AWS stack:
    ECR repo, ECS task/service, ALB target group, security group, and CloudWatch log group.
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

  validation {
    condition     = length([for k, s in var.services : k if s.is_alb_default]) <= 1
    error_message = "At most one service can have is_alb_default = true."
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. When set, HTTPS listener is created with HTTP-to-HTTPS redirect."
  type        = string
  default     = ""
}

variable "enable_nat_ha" {
  description = "Create one NAT Gateway per AZ for high availability (more expensive)"
  type        = bool
  default     = false
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications (required if enable_alarms = true)"
  type        = string
  default     = ""
}
