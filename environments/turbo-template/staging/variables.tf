variable "project_name" {
  description = "Project name used for all resource naming (e.g., turbo-template, my-app)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "client_name" {
  description = "Client or organization name for tagging (e.g., Quanby)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "auto_backup" {
  description = "Enable automatic backups via tagging"
  type        = bool
  default     = false
}

variable "extra_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# --- EC2 ------------------------------------------------------------------

variable "ec2_instance_type" {
  description = "EC2 instance type for staging (keep small — t3.small or t3.medium)"
  type        = string
  default     = "t3.small"
}

variable "ec2_key_name" {
  description = "Name of an existing EC2 key pair for SSH access. Leave empty to auto-create."
  type        = string
  default     = ""
}

variable "ec2_root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "ec2_allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH. Restrict to your IP for security."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# --- Services -------------------------------------------------------------
# Each entry creates: ECR repo + CloudWatch log group + opens SG port.
# On staging, Nginx on the EC2 reverse-proxies directly to these ports.

variable "services" {
  description = <<-EOT
    Map of services running on this instance.
    Each key → ECR repo, open SG port, CloudWatch log group.
  EOT

  type = map(object({
    port                 = number
    health_check_path    = string
    cpu                  = optional(string, "256")
    memory               = optional(string, "512")
    desired_count        = optional(number, 1)
    expose_via_alb       = optional(bool, false)
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
