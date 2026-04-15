# =============================================================================
# Production Environment — EC2 + ALB + ASG
# =============================================================================
# Production uses ALB → ASG → EC2 + Docker with zero-downtime deployments
# via ASG instance refresh. Minimum 2 instances across 2 AZs.
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
  environment = "production"

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
# VPC, subnets, IGW. No NAT initially (EC2 in public subnets).
# Private subnets created but unused (available for future RDS, etc.).

module "networking" {
  source = "../../../modules/aws/networking"

  project_name               = var.project_name
  environment                = local.environment
  vpc_cidr                   = var.vpc_cidr
  az_count                   = var.az_count
  enable_nat_gateway         = false
  enable_nat_ha              = false
  enable_flow_logs           = true
  flow_log_retention_days    = 90
  create_ecs_security_groups = false
  services                   = var.services
}

# --- ECR -----------------------------------------------------------------

module "ecr" {
  source = "../../../modules/aws/ecr"

  project_name          = var.project_name
  environment           = local.environment
  image_retention_count = 30
  image_tag_mutability  = "IMMUTABLE"
  encryption_type       = "KMS"
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
  deregistration_delay       = 120
  certificate_arn            = var.certificate_arn
  enable_deletion_protection = true
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

  # Production: zero-downtime rolling deployments
  enable_instance_refresh = true
  min_healthy_percentage  = var.instance_refresh_min_healthy
  max_healthy_percentage  = var.instance_refresh_max_healthy
  instance_warmup         = var.instance_warmup
  health_check_grace_period = var.health_check_grace_period
}

# --- Monitoring ----------------------------------------------------------

module "monitoring" {
  source = "../../../modules/aws/monitoring"

  project_name        = var.project_name
  environment         = local.environment
  log_retention_days  = 90
  enable_alarms       = var.enable_alarms
  alarm_sns_topic_arn = var.alarm_sns_topic_arn

  service_names             = toset(keys(var.services))
  target_group_arn_suffixes = module.alb.target_group_arn_suffixes
  alb_arn_suffix            = module.alb.alb_arn_suffix
}
