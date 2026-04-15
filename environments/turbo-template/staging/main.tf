# =============================================================================
# Staging Environment — EC2 + ALB + ASG
# =============================================================================
# Staging uses the same platform shape as production (ALB → ASG → EC2 + Docker)
# with minimal capacity: single instance, brief restarts OK during deploys.
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

# --- Networking -----------------------------------------------------------
# VPC, subnets (public for ALB + EC2, private unused), IGW, no NAT.

module "networking" {
  source = "../../../modules/aws/networking"

  project_name               = var.project_name
  environment                = local.environment
  vpc_cidr                   = var.vpc_cidr
  az_count                   = var.az_count
  enable_nat_gateway         = false
  enable_nat_ha              = false
  enable_flow_logs           = false
  create_ecs_security_groups = false
  services                   = var.services
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

# --- ALB -----------------------------------------------------------------

module "alb" {
  source = "../../../modules/aws/alb"

  project_name               = var.project_name
  environment                = local.environment
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  alb_security_group_id      = module.networking.alb_security_group_id
  services                   = var.services
  target_type                = "instance"
  deregistration_delay       = 60
  certificate_arn            = var.certificate_arn
  enable_deletion_protection = false
}

# --- EC2 ASG --------------------------------------------------------------

module "ec2_asg" {
  source = "../../../modules/aws/ec2-asg"

  project_name          = var.project_name
  environment           = local.environment
  vpc_id                = module.networking.vpc_id
  subnet_ids            = module.networking.public_subnet_ids
  instance_type         = var.ec2_instance_type
  min_size              = var.asg_min_size
  desired_capacity      = var.asg_desired_capacity
  max_size              = var.asg_max_size
  root_volume_size      = var.ec2_root_volume_size
  key_name              = var.ec2_key_name
  allowed_ssh_cidrs     = var.ec2_allowed_ssh_cidrs
  associate_public_ip   = true
  alb_security_group_id = module.networking.alb_security_group_id
  target_group_arns     = values(module.alb.target_group_arns)
  services              = var.services

  # Staging: no instance refresh needed (brief restarts OK)
  enable_instance_refresh = false
}

# --- Monitoring (log groups only, no alarms) ------------------------------

module "monitoring" {
  source = "../../../modules/aws/monitoring"

  project_name       = var.project_name
  environment        = local.environment
  log_retention_days = 14
  enable_alarms      = false
  service_names      = toset(keys(var.services))

  # ALB monitoring (no alarms, but log groups for all services)
  alb_arn_suffix            = module.alb.alb_arn_suffix
  target_group_arn_suffixes = module.alb.target_group_arn_suffixes
}
