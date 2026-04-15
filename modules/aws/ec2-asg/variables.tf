variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources are created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG (public subnets recommended for cost savings)"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances. Leave empty to use the latest Ubuntu 24.04 LTS."
  type        = string
  default     = ""
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 4
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access. Leave empty for SSM-only access."
  type        = string
  default     = ""
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH. Empty list disables SSH ingress (use SSM instead)."
  type        = list(string)
  default     = []
}

variable "associate_public_ip" {
  description = "Associate public IP addresses with instances (required for instances in public subnets without NAT)"
  type        = bool
  default     = true
}

# --- ALB Integration ---

variable "alb_security_group_id" {
  description = "Security group ID of the ALB (for ingress rules)"
  type        = string
}

variable "target_group_arns" {
  description = "List of ALB target group ARNs to attach the ASG to"
  type        = list(string)
  default     = []
}

variable "services" {
  description = "Map of services. Used to configure security group ingress from ALB on each service port."
  type = map(object({
    port           = number
    expose_via_alb = optional(bool, true)
  }))
  default = {}
}

# --- Health & Scaling ---

variable "health_check_grace_period" {
  description = "Time (seconds) after instance launch before health checks begin"
  type        = number
  default     = 300
}

variable "enable_instance_refresh" {
  description = "Enable ASG instance refresh for zero-downtime rolling deployments"
  type        = bool
  default     = false
}

variable "instance_warmup" {
  description = "Instance warmup time (seconds) during instance refresh"
  type        = number
  default     = 300
}

variable "min_healthy_percentage" {
  description = "Minimum healthy percentage during instance refresh (100 = zero-downtime)"
  type        = number
  default     = 90
}

variable "max_healthy_percentage" {
  description = "Maximum healthy percentage during instance refresh (200 = double capacity briefly)"
  type        = number
  default     = 200
}

# --- Custom User Data ---

variable "user_data" {
  description = "Custom user-data script content. Leave empty to use the default Ubuntu + Docker bootstrap."
  type        = string
  default     = ""
}
