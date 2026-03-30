variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (e.g., t3.small, t3.medium)"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance. Leave empty to use the latest Amazon Linux 2023."
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access. Leave empty to create a new one."
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into the EC2 instance. Restrict to your IP for security."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "enable_elastic_ip" {
  description = "Assign an Elastic IP for a stable public address"
  type        = bool
  default     = true
}

variable "services" {
  description = "Map of services. Used to open inbound ports on the security group."
  type = map(object({
    port = number
  }))
  default = {}
}

variable "user_data" {
  description = "User data script to run on instance launch (installs Docker, Nginx, AWS CLI, etc.)"
  type        = string
  default     = ""
}

variable "auto_backup" {
  description = "Whether to enable automatic backups via tags (for AWS Backup or custom solutions)"
  type        = bool
  default     = true
}
