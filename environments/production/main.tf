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

  project_name   = var.project_name
  environment    = "production"
  vpc_cidr       = var.vpc_cidr
  az_count       = var.az_count
  enable_nat_ha  = var.enable_nat_ha
  enable_flow_logs       = true
  flow_log_retention_days = 90
}

# --- ECR -----------------------------------------------------------------

module "ecr" {
  source = "../../modules/aws/ecr"

  project_name          = var.project_name
  environment           = "production"
  image_retention_count = 30
  image_tag_mutability  = "IMMUTABLE"
  encryption_type       = "KMS"
}

# --- ALB -----------------------------------------------------------------

module "alb" {
  source = "../../modules/aws/alb"

  project_name               = var.project_name
  environment                = "production"
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  alb_security_group_id      = module.networking.alb_security_group_id
  api_domain                 = var.api_domain
  certificate_arn            = var.certificate_arn
  enable_deletion_protection = true
}

# --- ECS -----------------------------------------------------------------

module "ecs" {
  source = "../../modules/aws/ecs"

  project_name                  = var.project_name
  environment                   = "production"
  private_subnet_ids            = module.networking.private_subnet_ids
  ecs_web_security_group_id     = module.networking.ecs_web_security_group_id
  ecs_backend_security_group_id = module.networking.ecs_backend_security_group_id
  web_target_group_arn          = module.alb.web_target_group_arn
  backend_target_group_arn      = module.alb.backend_target_group_arn

  web_cpu        = "512"
  web_memory     = "1024"
  backend_cpu    = "512"
  backend_memory = "1024"
}

# --- Monitoring ----------------------------------------------------------

module "monitoring" {
  source = "../../modules/aws/monitoring"

  project_name             = var.project_name
  environment              = "production"
  log_retention_days       = 90
  enable_alarms            = var.enable_alarms
  alarm_sns_topic_arn      = var.alarm_sns_topic_arn
  ecs_cluster_name         = module.ecs.cluster_name
  ecs_web_service_name     = module.ecs.web_service_name
  ecs_backend_service_name = module.ecs.backend_service_name

  # ALB alarms
  alb_arn_suffix                 = module.alb.alb_arn_suffix
  web_target_group_arn_suffix    = module.alb.web_target_group_arn_suffix
  backend_target_group_arn_suffix = module.alb.backend_target_group_arn_suffix
}
