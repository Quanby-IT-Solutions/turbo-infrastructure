# =============================================================================
# Staging Environment — EC2 + Elastic IP (minimal)
# =============================================================================
# Staging uses a single EC2 instance with an Elastic IP for a stable public
# address. Docker Compose + Nginx run directly on the box. No ALB, no ASG.
# Copy this folder to environments/<project-name>/staging/ and update tfvars.
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

locals {
  environment = "staging"

  default_tags = merge(
    {
      environment  = local.environment
      project-name = var.project_name
      client-name  = var.client_name
      managed-by   = "terraform"
      auto-backup  = tostring(var.auto_backup)
    },
    var.extra_tags,
  )
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.default_tags
  }
}

# --- ECR ------------------------------------------------------------------
# One repo per service — push images here, EC2 pulls via IAM role.

module "ecr" {
  source = "../../../modules/aws/ecr"

  project_name          = var.project_name
  environment           = local.environment
  image_retention_count = 10
  force_delete          = true
  services              = var.services
}

# --- EC2 + Elastic IP -----------------------------------------------------
# Single instance running Docker Compose + Nginx.
# Elastic IP keeps DNS stable across stop/start cycles.

module "ec2" {
  source = "../../../modules/aws/ec2"

  project_name      = var.project_name
  environment       = local.environment
  instance_type     = var.ec2_instance_type
  key_name          = var.ec2_key_name
  root_volume_size  = var.ec2_root_volume_size
  allowed_ssh_cidrs = var.ec2_allowed_ssh_cidrs
  enable_elastic_ip = true
  services          = var.services
  auto_backup       = var.auto_backup
}

# --- Monitoring (log groups only — no alarms on staging) ------------------

module "monitoring" {
  source = "../../../modules/aws/monitoring"

  project_name       = var.project_name
  environment        = local.environment
  log_retention_days = 14
  enable_alarms      = false
  service_names      = toset(keys(var.services))

  # No ALB on staging — pass empty strings
  alb_arn_suffix            = ""
  target_group_arn_suffixes = {}
}
