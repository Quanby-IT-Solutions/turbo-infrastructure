# =============================================================================
# ALB Module — Application Load Balancer with host-based routing
# =============================================================================

locals {
  enable_https = var.certificate_arn != ""

  # Only services that should be reachable via the ALB
  alb_services = { for k, v in var.services : k => v if v.expose_via_alb }

  # Service that receives all unmatched (default) ALB traffic.
  # Use the explicitly marked service, or fall back to first alphabetical key.
  explicit_defaults   = [for k, v in local.alb_services : k if v.is_alb_default]
  default_service_key = length(local.explicit_defaults) > 0 ? local.explicit_defaults[0] : tolist(sort(keys(local.alb_services)))[0]

  # Services that need a listener routing rule (have a domain set)
  routed_services = { for k, v in local.alb_services : k => v if v.domain != "" }

  # Assign priorities alphabetically for determinism (avoids manual management)
  routed_service_priorities = { for idx, k in tolist(sort(keys(local.routed_services))) : k => 100 + idx }
}

# --- ALB ------------------------------------------------------------------

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  tags = {
    Name = "${var.project_name}-alb-${var.environment}"
  }
}

# --- Target Groups --------------------------------------------------------

resource "aws_lb_target_group" "service" {
  for_each = local.alb_services

  # TG names are limited to 32 chars; truncate safely
  name        = substr("${var.project_name}-${each.key}-${var.environment}", 0, 32)
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = each.value.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = each.value.health_check_matcher
  }

  tags = {
    Name    = "${var.project_name}-${each.key}-tg-${var.environment}"
    service = each.key
  }
}

# --- HTTP Listener --------------------------------------------------------
# When HTTPS is enabled, HTTP redirects to HTTPS.
# When HTTPS is disabled, HTTP forwards to the default service target group.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = local.enable_https ? "redirect" : "forward"

    # Forward action (HTTP-only mode)
    dynamic "forward" {
      for_each = local.enable_https ? [] : [1]
      content {
        target_group {
          arn = aws_lb_target_group.service[local.default_service_key].arn
        }
      }
    }

    # Redirect action (HTTPS mode)
    dynamic "redirect" {
      for_each = local.enable_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-http-listener-${var.environment}"
  }
}

# --- HTTPS Listener (created only when certificate_arn is provided) -------

resource "aws_lb_listener" "https" {
  count = local.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[local.default_service_key].arn
  }

  tags = {
    Name = "${var.project_name}-https-listener-${var.environment}"
  }
}

# --- Listener Rules (host-based routing) ----------------------------------
# Each service with a domain set gets a rule routing by host-header.
# Routes requests to that service's target group; all other traffic goes to
# the default service via the listener's default action.

resource "aws_lb_listener_rule" "service_http" {
  for_each = local.enable_https ? {} : local.routed_services

  listener_arn = aws_lb_listener.http.arn
  priority     = local.routed_service_priorities[each.key]

  condition {
    host_header {
      values = [each.value.domain]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  tags = {
    Name = "${var.project_name}-${each.key}-rule-http-${var.environment}"
  }
}

resource "aws_lb_listener_rule" "service_https" {
  for_each = local.enable_https ? local.routed_services : {}

  listener_arn = aws_lb_listener.https[0].arn
  priority     = local.routed_service_priorities[each.key]

  condition {
    host_header {
      values = [each.value.domain]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  tags = {
    Name = "${var.project_name}-${each.key}-rule-https-${var.environment}"
  }
}
