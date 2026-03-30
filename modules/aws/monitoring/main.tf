# =============================================================================
# Monitoring Module — CloudWatch log groups and alarms
# =============================================================================

locals {
  alarm_actions     = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  enable_alb_alarms = var.enable_alarms && var.alb_arn_suffix != ""
}

# --- Log Groups -----------------------------------------------------------

resource "aws_cloudwatch_log_group" "service" {
  for_each = var.service_names

  name              = "/ecs/${var.project_name}-${each.key}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = {
    Name    = "${var.project_name}-${each.key}-logs-${var.environment}"
    service = each.key
  }
}

# --- ECS CPU Alarms -------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  for_each = var.enable_alarms ? var.ecs_service_names : {}

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-cpu-high"
  alarm_description   = "[${upper(var.environment)}] ${each.key} service CPU utilization above ${var.cpu_alarm_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = each.value
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = {
    severity = "warning"
  }
}

# --- ECS Memory Alarms ---------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "service_memory_high" {
  for_each = var.enable_alarms ? var.ecs_service_names : {}

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-memory-high"
  alarm_description   = "[${upper(var.environment)}] ${each.key} service memory utilization above ${var.memory_alarm_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = each.value
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = {
    severity = "warning"
  }
}

# --- ALB 5xx Error Rate Alarm --------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = local.enable_alb_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-high"
  alarm_description   = "[${upper(var.environment)}] ALB returning elevated 5xx errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = {
    severity = "critical"
  }
}

# --- ALB Target Health Alarms --------------------------------------------

resource "aws_cloudwatch_metric_alarm" "service_unhealthy_targets" {
  for_each = local.enable_alb_alarms ? var.target_group_arn_suffixes : {}

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-unhealthy-targets"
  alarm_description   = "[${upper(var.environment)}] ${each.key} target group has unhealthy targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0

  dimensions = {
    TargetGroup  = each.value
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = {
    severity = "critical"
  }
}

