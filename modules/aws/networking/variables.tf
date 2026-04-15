variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones to use (1-3)"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3."
  }
}

variable "enable_nat_ha" {
  description = "Create one NAT Gateway per AZ for high availability. When false, a single NAT Gateway is used (cost-optimized)."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway(s) for private subnet internet access. Set to false when EC2 instances use public subnets."
  type        = bool
  default     = true
}

variable "create_ecs_security_groups" {
  description = "Create per-service ECS security groups. Set to false when using EC2/ASG compute instead of ECS."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch for network auditing"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention in days for VPC Flow Log group"
  type        = number
  default     = 30
}

variable "services" {
  description = "Map of services. Used to derive per-service ECS security groups and ALB egress rules."
  type = map(object({
    port             = number
    expose_via_alb   = optional(bool, true)
    allow_vpc_egress = optional(bool, false)
  }))
  default = {}
}
