# =============================================================================
# Staging Environment
# =============================================================================
# Staging runs on a single EC2 instance (t3.small) with Docker Compose + Nginx.
# Terraform provisions the EC2 instance, ECR repositories, and CloudWatch log
# groups. The app repo's deploy workflow SSHs in and deploys containers.
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

# --- EC2 -----------------------------------------------------------------

module "ec2" {
  source = "../../../modules/aws/ec2"

  project_name       = var.project_name
  environment        = local.environment
  instance_type      = var.ec2_instance_type
  key_name           = var.ec2_key_name
  root_volume_size   = var.ec2_root_volume_size
  allowed_ssh_cidrs  = var.ec2_allowed_ssh_cidrs
  enable_elastic_ip  = true
  auto_backup        = var.auto_backup
  services           = var.services
}

# --- ECR -----------------------------------------------------------------

module "ecr" {
  source = "../../../modules/aws/ecr"

  project_name          = var.project_name
  environment           = local.environment
  image_retention_count = 15
  force_delete          = true
  services              = var.services
}

# --- Monitoring (log groups only, no alarms) ------------------------------

module "monitoring" {
  source = "../../../modules/aws/monitoring"

  project_name       = var.project_name
  environment        = local.environment
  log_retention_days = 14
  enable_alarms      = false
  service_names      = toset(keys(var.services))
}
