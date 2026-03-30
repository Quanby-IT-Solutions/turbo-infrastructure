# =============================================================================
# Monitoring Module — CloudWatch log groups and alarms
# =============================================================================

locals {
  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  enable_alb_alarms = var.enable_alarms && var.alb_arn_suffix != ""
}

# --- Log Groups -----------------------------------------------------------

resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/${var.project_name}-web-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = {
    Name        = "${var.project_name}-web-logs-${var.environment}"
    Environment = var.environment
    Service     = "web"
  }
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = {
    Name        = "${var.project_name}-backend-logs-${var.environment}"
    Environment = var.environment
    Service     = "backend"
  }
}

# --- ECS CPU Alarms -------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-web-cpu-high"
  alarm_description   = "[${upper(var.environment)}] Web service CPU utilization above ${var.cpu_alarm_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_web_service_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = {
    Environment = var.environment
    Severity    = "warning"
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_cpu_high" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-backend-cpu-high"
  alarm_description   = "[${upper(var.environment)}] Backend service CPU utilization above ${var.cpu_alarm_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_backend_service_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = {
    Environment = var.environment
    Severity    = "warning"
  }
}

# --- ECS Memory Alarms ---------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "web_memory_high" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-web-memory-high"
  alarm_description   = "[${upper(var.environment)}] Web service memory utilization above ${var.memory_alarm_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_web_service_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = {
    Environment = var.environment
    Severity    = "warning"
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_memory_high" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-backend-memory-high"
  alarm_description   = "[${upper(var.environment)}] Backend service memory utilization above ${var.memory_alarm_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_backend_service_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = {
    Environment = var.environment
    Severity    = "warning"
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
    Environment = var.environment
    Severity    = "critical"
  }
}

# --- ALB Target Health Alarms --------------------------------------------

resource "aws_cloudwatch_metric_alarm" "web_unhealthy_targets" {
  count = local.enable_alb_alarms && var.web_target_group_arn_suffix != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-web-unhealthy-targets"
  alarm_description   = "[${upper(var.environment)}] Web target group has unhealthy targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0

  dimensions = {
    TargetGroup  = var.web_target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = {
    Environment = var.environment
    Severity    = "critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_unhealthy_targets" {
  count = local.enable_alb_alarms && var.backend_target_group_arn_suffix != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-backend-unhealthy-targets"
  alarm_description   = "[${upper(var.environment)}] Backend target group has unhealthy targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0

  dimensions = {
    TargetGroup  = var.backend_target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = {
    Environment = var.environment
    Severity    = "critical"
  }
}
