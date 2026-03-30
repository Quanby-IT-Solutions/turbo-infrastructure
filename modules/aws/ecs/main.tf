# =============================================================================
# ECS Module — Fargate cluster, IAM roles, services
# =============================================================================
# Services are created with placeholder task definitions. The app repo's
# deploy workflow registers real task definitions and updates the services.
# =============================================================================

# --- Data Sources ---------------------------------------------------------

data "aws_region" "current" {}

# --- ECS Cluster ----------------------------------------------------------

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster-${var.environment}"
  }
}

# --- IAM: Task Execution Role --------------------------------------------
# Allows ECS to pull images from ECR and push logs to CloudWatch.

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.project_name}-ecs-execution-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = {
    Name = "${var.project_name}-ecs-execution-role-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Optional: task role for app-level AWS SDK calls (S3, SQS, etc.)
resource "aws_iam_role" "ecs_task" {
  name               = "${var.project_name}-ecs-task-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = {
    Name = "${var.project_name}-ecs-task-role-${var.environment}"
  }
}

# --- Placeholder Task Definitions -----------------------------------------
# Minimal nginx tasks so services can be created. The app deploy workflow
# registers real task definitions and updates the services.

resource "aws_ecs_task_definition" "service" {
  for_each = var.services

  family                   = "${var.project_name}-${each.key}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = each.key
    image     = "nginx:alpine"
    essential = true
    portMappings = [{
      containerPort = each.value.port
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project_name}-${each.key}-${var.environment}"
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
        "awslogs-create-group"  = "true"
      }
    }
  }])

  tags = {
    Name        = "${var.project_name}-${each.key}-${var.environment}"
    service     = each.key
    placeholder = "true"
  }
}

# --- ECS Services ---------------------------------------------------------
# ignore_changes on task_definition so the app deploy workflow can update
# the task definition without Terraform reverting it.

resource "aws_ecs_service" "service" {
  for_each = var.services

  name            = "${var.project_name}-${each.key}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.service_security_group_ids[each.key]]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = (each.value.expose_via_alb && contains(keys(var.target_group_arns), each.key)) ? [1] : []
    content {
      target_group_arn = var.target_group_arns[each.key]
      container_name   = each.key
      container_port   = each.value.port
    }
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    Name    = "${var.project_name}-${each.key}-${var.environment}-service"
    service = each.key
  }
}

# --- Auto Scaling ---------------------------------------------------------
# When enabled, scales ECS services based on CPU utilization.

resource "aws_appautoscaling_target" "service" {
  for_each = var.enable_autoscaling ? var.services : {}

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "service_cpu" {
  for_each = var.enable_autoscaling ? var.services : {}

  name               = "${var.project_name}-${each.key}-cpu-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.service[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.service[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
