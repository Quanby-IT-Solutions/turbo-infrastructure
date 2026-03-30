# =============================================================================
# Bootstrap: S3 bucket + DynamoDB table for Terraform remote state
# =============================================================================
# Run this ONCE before using any environment (staging/production):
#   cd environments/turbo-template/bootstrap
#   terraform init
#   terraform apply
#
# This uses LOCAL state intentionally (chicken-and-egg: can't store state
# remotely before the remote backend exists).
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name (used in bucket/table naming)"
  type        = string
  default     = "turbo-template"
}

variable "client_name" {
  description = "Client or organization name for tagging"
  type        = string
  default     = "Quanby"
}

variable "auto_backup" {
  description = "Enable automatic backups via tagging"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Provider
# -----------------------------------------------------------------------------

locals {
  environment = "bootstrap"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      environment  = local.environment
      project-name = var.project_name
      client-name  = var.client_name
      managed-by   = "terraform"
      auto-backup  = tostring(var.auto_backup)
    }
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket (state storage)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${var.project_name}-terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# DynamoDB Table (state locking)
# -----------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-terraform-locks"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "S3 bucket ARN for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.terraform_locks.id
}
