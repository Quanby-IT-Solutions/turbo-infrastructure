# =============================================================================
# ALB Module — Application Load Balancer with host-based (subdomain) routing
# =============================================================================

locals {
  enable_https = var.certificate_arn != ""
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
    Name        = "${var.project_name}-alb-${var.environment}"
    Environment = var.environment
  }
}

# --- Target Groups --------------------------------------------------------

resource "aws_lb_target_group" "web" {
  name        = "${var.project_name}-web-${var.environment}"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name        = "${var.project_name}-web-tg-${var.environment}"
    Environment = var.environment
    Service     = "web"
  }
}

resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-api-${var.environment}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/api/v1/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-api-tg-${var.environment}"
    Environment = var.environment
    Service     = "backend"
  }
}

# --- HTTP Listener --------------------------------------------------------
# When HTTPS is enabled, HTTP redirects to HTTPS.
# When HTTPS is disabled, HTTP forwards to web target group (development use).

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
          arn = aws_lb_target_group.web.arn
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
    target_group_arn = aws_lb_target_group.web.arn
  }

  tags = {
    Name = "${var.project_name}-https-listener-${var.environment}"
  }
}

# --- Listener Rules (host-based subdomain routing) -------------------------
# Routes requests to the API subdomain (e.g., api.yourdomain.com) to the
# backend target group. All other traffic goes to the web target group
# via the listener's default action. This avoids path conflicts with
# Next.js API routes (e.g., /api/auth, /api/webhooks).

# HTTP API rule (only when no HTTPS — otherwise HTTP redirects everything)
resource "aws_lb_listener_rule" "api_http" {
  count = local.enable_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    host_header {
      values = [var.api_domain]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  tags = {
    Name = "${var.project_name}-api-rule-http-${var.environment}"
  }
}

# HTTPS API rule (only when certificate is provided)
resource "aws_lb_listener_rule" "api_https" {
  count = local.enable_https ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  condition {
    host_header {
      values = [var.api_domain]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  tags = {
    Name = "${var.project_name}-api-rule-https-${var.environment}"
  }
}
