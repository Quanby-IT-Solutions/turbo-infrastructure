# =============================================================================
# EC2 Module — Single instance for staging environments
# =============================================================================
# Creates: VPC, public subnet, EC2 instance, security group, Elastic IP.
# Designed for staging workloads running Docker Compose + Nginx on one box.
# =============================================================================

# --- Data Sources ---------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

# Latest Amazon Linux 2023 AMI (used when var.ami_id is empty)
data "aws_ami" "amazon_linux" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux[0].id

  default_user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    # Update system
    dnf update -y

    # Install Docker
    dnf install -y docker
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user

    # Install Docker Compose v2 plugin
    mkdir -p /usr/local/lib/docker/cli-plugins
    COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64"
    curl -SL "$COMPOSE_URL" -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    # Install Nginx
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx

    # Install Certbot for SSL
    dnf install -y certbot python3-certbot-nginx

    # Install AWS CLI (already included in AL2023, but ensure latest)
    dnf install -y aws-cli

    # Create app directory
    mkdir -p /opt/staging
    chown ec2-user:ec2-user /opt/staging
  EOF

  user_data = var.user_data != "" ? var.user_data : local.default_user_data
}

# --- VPC ------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

# --- Public Subnet --------------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${var.environment}"
  }
}

# --- Internet Gateway -----------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-${var.environment}"
  }
}

# --- Route Table ----------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Security Group -------------------------------------------------------

resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-ec2-${var.environment}-"
  description = "Security group for ${var.project_name} ${var.environment} EC2 instance"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
    description = "SSH access"
  }

  # HTTP (Nginx)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS (Nginx + Certbot)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-ec2-sg-${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- IAM Role (for ECR access) -------------------------------------------

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-ec2-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.project_name}-ec2-role-${var.environment}"
  }
}

# ECR read-only access (pull images)
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# CloudWatch Logs (push container logs)
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# SSM access (optional — allows Session Manager instead of SSH)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2.name

  tags = {
    Name = "${var.project_name}-ec2-profile-${var.environment}"
  }
}

# --- Key Pair (created only if key_name is empty) -------------------------

resource "tls_private_key" "ec2" {
  count     = var.key_name == "" ? 1 : 0
  algorithm = "ED25519"
}

resource "aws_key_pair" "ec2" {
  count      = var.key_name == "" ? 1 : 0
  key_name   = "${var.project_name}-${var.environment}"
  public_key = tls_private_key.ec2[0].public_key_openssh

  tags = {
    Name = "${var.project_name}-keypair-${var.environment}"
  }
}

# --- EC2 Instance ---------------------------------------------------------

resource "aws_instance" "main" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name != "" ? var.key_name : aws_key_pair.ec2[0].key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  user_data = base64encode(local.user_data)

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens   = "required" # IMDSv2 only (security best practice)
    http_endpoint = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }

  lifecycle {
    ignore_changes = [ami, user_data] # Prevent recreation on AMI updates
  }
}

# --- Elastic IP -----------------------------------------------------------

resource "aws_eip" "main" {
  count    = var.enable_elastic_ip ? 1 : 0
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip-${var.environment}"
  }
}
