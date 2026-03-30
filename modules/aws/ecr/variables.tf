variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "image_retention_count" {
  description = "Number of images to keep per repository"
  type        = number
  default     = 30

  validation {
    condition     = var.image_retention_count > 0
    error_message = "image_retention_count must be greater than 0."
  }
}

variable "force_delete" {
  description = "Allow deleting repositories with images (use for non-production only)"
  type        = bool
  default     = false
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the repositories (MUTABLE or IMMUTABLE). IMMUTABLE recommended for production."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "encryption_type" {
  description = "Encryption type for ECR repositories (AES256 or KMS)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be either AES256 or KMS."
  }
}
