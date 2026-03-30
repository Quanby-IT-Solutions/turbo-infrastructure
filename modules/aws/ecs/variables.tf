variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

# --- Networking ---

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "service_security_group_ids" {
  description = "Map of service name → ECS security group ID"
  type        = map(string)
}

# --- Services ---

variable "services" {
  description = "Map of services to deploy. Drives task definitions, ECS services, and autoscaling."
  type = map(object({
    port           = number
    cpu            = string
    memory         = string
    desired_count  = optional(number, 1)
    expose_via_alb = optional(bool, true)
  }))
}

variable "target_group_arns" {
  description = "Map of service name → ALB target group ARN. Only services present in this map get an ALB load_balancer block."
  type        = map(string)
  default     = {}
}

# --- Scaling ---

variable "enable_autoscaling" {
  description = "Enable Application Auto Scaling for ECS services"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks when auto-scaling is enabled"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks when auto-scaling is enabled"
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization (%) for auto-scaling"
  type        = number
  default     = 70
}
