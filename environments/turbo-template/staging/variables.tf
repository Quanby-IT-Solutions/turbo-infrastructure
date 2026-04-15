variable "project_name" {
  description = "Project name used for all resource naming (e.g., DMS, turbo-template)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "client_name" {
  description = "Client or organization name for tagging (e.g., DAP, Quanby)"
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
  default     = true
}

variable "extra_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# --- Networking -----------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones (minimum 2 for ALB)"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be between 2 and 3."
  }
}

# --- EC2 / ASG ------------------------------------------------------------

variable "ec2_instance_type" {
  description = "EC2 instance type for staging"
  type        = string
  default     = "t3.medium"
}

variable "ec2_key_name" {
  description = "Name of an existing EC2 key pair. Leave empty for SSM-only access."
  type        = string
  default     = ""
}

variable "ec2_root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "ec2_allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH. Empty list uses SSM-only. Restrict to your IP for security."
  type        = list(string)
  default     = []
}

variable "asg_min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 2
}

# --- SSL ------------------------------------------------------------------

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. When set, HTTPS listener is created with HTTP-to-HTTPS redirect."
  type        = string
  default     = ""
}

# --- Services -------------------------------------------------------------

variable "services" {
  description = <<-EOT
    Map of services to deploy. Each key becomes an ECR repo, ALB target group,
    and CloudWatch log group. The ASG instances run all services via Docker Compose.
  EOT

  type = map(object({
    port                 = number
    health_check_path    = string
    cpu                  = optional(string, "256")
    memory               = optional(string, "512")
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
