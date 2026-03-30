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

variable "ecs_web_security_group_id" {
  description = "Security group ID for web ECS tasks"
  type        = string
}

variable "ecs_backend_security_group_id" {
  description = "Security group ID for backend ECS tasks"
  type        = string
}

# --- ALB ---

variable "web_target_group_arn" {
  description = "ALB target group ARN for web"
  type        = string
}

variable "backend_target_group_arn" {
  description = "ALB target group ARN for backend"
  type        = string
}

# --- Task sizing ---

variable "web_cpu" {
  description = "CPU units for web task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "512"

  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.web_cpu)
    error_message = "web_cpu must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "web_memory" {
  description = "Memory (MB) for web task"
  type        = string
  default     = "1024"
}

variable "backend_cpu" {
  description = "CPU units for backend task"
  type        = string
  default     = "512"

  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.backend_cpu)
    error_message = "backend_cpu must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "backend_memory" {
  description = "Memory (MB) for backend task"
  type        = string
  default     = "1024"
}

# --- Scaling ---

variable "web_desired_count" {
  description = "Desired number of web tasks"
  type        = number
  default     = 1
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 1
}

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
