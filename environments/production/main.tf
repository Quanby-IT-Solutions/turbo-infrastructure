# =============================================================================
# Production Environment
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
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

# --- Networking -----------------------------------------------------------

module "networking" {
  source = "../../modules/aws/networking"

  project_name            = var.project_name
  environment             = "production"
  vpc_cidr                = var.vpc_cidr
  az_count                = var.az_count
  enable_nat_ha           = var.enable_nat_ha
  enable_flow_logs        = true
  flow_log_retention_days = 90
  services                = var.services
}

# --- ECR -----------------------------------------------------------------

module "ecr" {
  source = "../../modules/aws/ecr"

  project_name          = var.project_name
  environment           = "production"
  image_retention_count = 30
  image_tag_mutability  = "IMMUTABLE"
  encryption_type       = "KMS"
  services              = var.services
}

# --- ALB -----------------------------------------------------------------

module "alb" {
  source = "../../modules/aws/alb"

  project_name               = var.project_name
  environment                = "production"
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  alb_security_group_id      = module.networking.alb_security_group_id
  services                   = var.services
  certificate_arn            = var.certificate_arn
  enable_deletion_protection = true
}

# --- ECS -----------------------------------------------------------------

module "ecs" {
  source = "../../modules/aws/ecs"

  project_name               = var.project_name
  environment                = "production"
  private_subnet_ids         = module.networking.private_subnet_ids
  service_security_group_ids = module.networking.ecs_service_security_group_ids
  services                   = var.services
  target_group_arns          = module.alb.target_group_arns
}

# --- Monitoring ----------------------------------------------------------

module "monitoring" {
  source = "../../modules/aws/monitoring"

  project_name        = var.project_name
  environment         = "production"
  log_retention_days  = 90
  enable_alarms       = var.enable_alarms
  alarm_sns_topic_arn = var.alarm_sns_topic_arn
  ecs_cluster_name    = module.ecs.cluster_name

  service_names             = toset(keys(var.services))
  ecs_service_names         = module.ecs.service_names
  target_group_arn_suffixes = module.alb.target_group_arn_suffixes

  # ALB alarms
  alb_arn_suffix = module.alb.alb_arn_suffix
}
