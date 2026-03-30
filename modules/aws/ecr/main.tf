# =============================================================================
# ECR Module — Container registries with lifecycle policies
# =============================================================================

resource "aws_ecr_repository" "service" {
  for_each = var.services

  name                 = "${var.project_name}-${each.key}-${var.environment}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = var.encryption_type
  }

  tags = {
    Name        = "${var.project_name}-${each.key}-${var.environment}"
    Environment = var.environment
    Service     = each.key
  }
}

# --- Lifecycle Policies (keep last N images) ---

resource "aws_ecr_lifecycle_policy" "service" {
  for_each = var.services

  repository = aws_ecr_repository.service[each.key].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.image_retention_count
      }
      action = {
        type = "expire"
      }
    }]
  })
}
