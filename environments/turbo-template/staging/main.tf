# =============================================================================
# Staging Environment
# =============================================================================
# Staging uses EC2 + Docker Compose (managed by the app repo's deploy workflow),
# so this Terraform config only provisions the ECR repositories and CloudWatch
# log groups that staging needs. No VPC/ECS/ALB required.
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

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "staging"
      ManagedBy   = "terraform"
    }
  }
}

# --- ECR -----------------------------------------------------------------

module "ecr" {
  source = "../../../modules/aws/ecr"

  project_name          = var.project_name
  environment           = "staging"
  image_retention_count = 15
  force_delete          = true
  services              = var.services
}

# --- Monitoring (log groups only, no alarms) ------------------------------

module "monitoring" {
  source = "../../../modules/aws/monitoring"

  project_name       = var.project_name
  environment        = "staging"
  log_retention_days = 14
  enable_alarms      = false
  service_names      = toset(keys(var.services))
}
