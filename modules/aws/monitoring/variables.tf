variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch retention value."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting CloudWatch log groups. Empty string uses default encryption."
  type        = string
  default     = ""
}

variable "enable_alarms" {
  description = "Whether to create CloudWatch alarms"
  type        = bool
  default     = false
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for alarm dimensions"
  type        = string
  default     = ""
}

variable "service_names" {
  description = "Set of service names to create CloudWatch log groups for (one per service)."
  type        = set(string)
  default     = []
}

variable "ecs_service_names" {
  description = "Map of service name \u2192 ECS service name. Used for CPU/memory alarm dimensions."
  type        = map(string)
  default     = {}
}

variable "target_group_arn_suffixes" {
  description = "Map of service name \u2192 ALB target group ARN suffix. Used for unhealthy-target alarms."
  type        = map(string)
  default     = {}
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarms (%)"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alarm_threshold > 0 && var.cpu_alarm_threshold <= 100
    error_message = "cpu_alarm_threshold must be between 1 and 100."
  }
}

variable "memory_alarm_threshold" {
  description = "Memory utilization threshold for alarms (%)"
  type        = number
  default     = 80

  validation {
    condition     = var.memory_alarm_threshold > 0 && var.memory_alarm_threshold <= 100
    error_message = "memory_alarm_threshold must be between 1 and 100."
  }
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications (empty = no notifications)"
  type        = string
  default     = ""
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for 5xx and target health alarms (empty = ALB alarms disabled)"
  type        = string
  default     = ""
}
