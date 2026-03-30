# Infrastructure (Terraform)

AWS infrastructure as code for application projects.
Each project lives under `environments/<project-name>/` and has its own `staging` and `production` environments.

## Repository Structure

```
infrastructure/
├── bootstrap/                        # One-time setup: S3 + DynamoDB for remote state
├── environments/
│   └── <project-name>/               # One folder per project (e.g. turbo-template)
│       ├── staging/                  # ECR + CloudWatch only (app runs on EC2/Docker Compose)
│       └── production/               # Full stack: VPC, ALB, ECS Fargate, ECR, CloudWatch
└── modules/
    └── aws/
        ├── networking/               # VPC, subnets, NAT Gateway, security groups
        ├── ecr/                      # Container registries + lifecycle policies
        ├── alb/                      # Load balancer, target groups, HTTPS listeners
        ├── ecs/                      # ECS cluster, task definitions, Fargate services
        └── monitoring/               # CloudWatch log groups, optional alarms
```

---

## Getting Started

### 1. Install prerequisites

<details>
<summary><strong>Arch Linux</strong></summary>

```bash
sudo pacman -S terraform git
# AWS CLI — install from AUR
paru -S aws-cli-v2
```

</details>

<details>
<summary><strong>Debian / Ubuntu</strong></summary>

```bash
# Terraform
sudo apt update && sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip

# Git
sudo apt install -y git
```

</details>

<details>
<summary><strong>Windows</strong></summary>

```powershell
# Using winget (recommended)
winget install Hashicorp.Terraform
winget install Amazon.AWSCLI
winget install Git.Git

# Or using Chocolatey
choco install terraform awscli git -y
```

After installation, restart your terminal so the commands are available on your PATH.

</details>

Verify everything is installed:

```bash
terraform -version   # >= 1.5
aws --version         # v2.x
git --version
```

### 2. Configure AWS credentials

Create an IAM user (or use SSO) with permissions for: VPC, ECS, ECR, ALB, IAM, CloudWatch, S3, DynamoDB, KMS.

**Option A — AWS CLI profiles (recommended):**

```bash
aws configure --profile quanby
# AWS Access Key ID:     <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region:        ap-southeast-1
# Default output format: json
```

Set the profile for your terminal session:

```bash
# Linux / macOS
export AWS_PROFILE=quanby

# Windows (PowerShell)
$env:AWS_PROFILE = "quanby"

# Windows (CMD)
set AWS_PROFILE=quanby
```

**Option B — Environment variables:**

```bash
# Linux / macOS
export AWS_ACCESS_KEY_ID=<your-access-key>
export AWS_SECRET_ACCESS_KEY=<your-secret-key>
export AWS_REGION=ap-southeast-1

# Windows (PowerShell)
$env:AWS_ACCESS_KEY_ID = "<your-access-key>"
$env:AWS_SECRET_ACCESS_KEY = "<your-secret-key>"
$env:AWS_REGION = "ap-southeast-1"
```

Verify your credentials work:

```bash
aws sts get-caller-identity
```

### 3. Clone the repo

```bash
git clone git@github.com:mjbalcueva/infrastructure.git
cd infrastructure
```

---

## Deploying the turbo-template Project

### Step 1: Bootstrap remote state (one-time only)

This creates the S3 bucket and DynamoDB table used to store Terraform state. Uses local state intentionally (can't store state remotely before the remote backend exists).

```bash
cd bootstrap
terraform init
terraform apply -var="project_name=turbo-template"
```

You only need to do this once per project. If the S3 bucket already exists, skip this step.

### Step 2: Deploy staging

Staging only provisions **ECR repos** and **CloudWatch log groups**. The EC2 instance and Docker Compose deployment are managed by the app repo's deploy workflow.

```bash
cd environments/turbo-template/staging

# Create your tfvars from the example (if not already done)
cp terraform.tfvars.example terraform.tfvars

# Review and edit terraform.tfvars as needed
# Then deploy:
terraform init
terraform plan        # always review the plan first
terraform apply       # type "yes" to confirm
```

### Step 3: Save the staging outputs

After apply, grab the outputs for your app repo:

```bash
terraform output
```

Staging outputs:

| Terraform output                  | What it is                 |
| --------------------------------- | -------------------------- |
| `ecr_repository_urls["web"]`      | ECR URL for web images     |
| `ecr_repository_urls["backend"]`  | ECR URL for backend images |
| `ecr_repository_names["web"]`     | ECR repo name for web      |
| `ecr_repository_names["backend"]` | ECR repo name for backend  |

### Step 4: Deploy production (when ready)

Production provisions the full stack: VPC, ALB, ECS Fargate, ECR, CloudWatch.

```bash
cd environments/turbo-template/production

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars:
#   - Set domains (turbo.quanbyit.com, turbo-be.quanbyit.com)
#   - Optionally set certificate_arn for HTTPS
#   - Optionally set enable_nat_ha = true for HA
#   - Optionally set enable_alarms = true + alarm_sns_topic_arn

terraform init
terraform plan
terraform apply
```

### Step 5: Save the production outputs

```bash
terraform output
```

Production outputs:

| Terraform output                  | GitHub variable                       |
| --------------------------------- | ------------------------------------- |
| `ecs_cluster_name`                | `ECS_CLUSTER`                         |
| `ecs_service_names["web"]`        | `ECS_SERVICE_WEB`                     |
| `ecs_service_names["backend"]`    | `ECS_SERVICE_BACKEND`                 |
| `ecr_repository_names["web"]`     | `ECR_REPOSITORY_WEB`                  |
| `ecr_repository_names["backend"]` | `ECR_REPOSITORY_BACKEND`              |
| `ecs_execution_role_arn`          | `ECS_EXECUTION_ROLE_ARN`              |
| `nat_gateway_public_ips`          | For allowlisting in external services |

---

## GitHub Actions Setup

The app repo's CI/CD workflows need AWS credentials and the Terraform outputs to deploy containers.

### 1. Repository secrets (Settings → Secrets and variables → Actions)

| Secret                  | Value                          | Notes                          |
| ----------------------- | ------------------------------ | ------------------------------ |
| `AWS_ACCESS_KEY_ID`     | IAM access key for deployments | Use a dedicated CI/CD IAM user |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key for deployments | Mark as secret                 |

### 2. Environment variables (Settings → Environments → staging / production)

Create two GitHub environments: **staging** and **production**.

**Staging environment variables:**

| Variable                 | Value (from `terraform output`)          |
| ------------------------ | ---------------------------------------- |
| `AWS_REGION`             | `ap-southeast-1`                         |
| `ECR_REPOSITORY_WEB`     | `ecr_repository_names["web"]` output     |
| `ECR_REPOSITORY_BACKEND` | `ecr_repository_names["backend"]` output |

**Production environment variables (all of staging, plus):**

| Variable                 | Value (from `terraform output`)          |
| ------------------------ | ---------------------------------------- |
| `AWS_REGION`             | `ap-southeast-1`                         |
| `ECR_REPOSITORY_WEB`     | `ecr_repository_names["web"]` output     |
| `ECR_REPOSITORY_BACKEND` | `ecr_repository_names["backend"]` output |
| `ECS_CLUSTER`            | `ecs_cluster_name` output                |
| `ECS_SERVICE_WEB`        | `ecs_service_names["web"]` output        |
| `ECS_SERVICE_BACKEND`    | `ecs_service_names["backend"]` output    |
| `ECS_EXECUTION_ROLE_ARN` | `ecs_execution_role_arn` output          |

### 3. IAM permissions for CI/CD user

The CI/CD IAM user needs these permissions:

- `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:PutImage`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload`
- `ecs:UpdateService`, `ecs:RegisterTaskDefinition`, `ecs:DescribeServices`, `ecs:DescribeTaskDefinition`
- `iam:PassRole` (on the ECS execution and task roles)
- `logs:CreateLogStream`, `logs:PutLogEvents`

---

## Domain Setup (GoDaddy / DNS)

### Staging (EC2 + Docker Compose)

Staging runs on an EC2 instance. Point your domain to the EC2's **Elastic IP**:

| Type | Name       | Value              | TTL |
| ---- | ---------- | ------------------ | --- |
| A    | `turbo`    | `<ec2-elastic-ip>` | 600 |
| A    | `turbo-be` | `<ec2-elastic-ip>` | 600 |

Both subdomains point to the same EC2 — your reverse proxy (Nginx/Caddy) routes by hostname.

> **Tip:** Always use an Elastic IP. Without one, the EC2's public IP changes on stop/start.

### Production (ALB + ECS Fargate)

After `terraform apply` for production, get the ALB DNS name:

```bash
# The ALB DNS name is in the AWS Console: EC2 → Load Balancers
# or via CLI:
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'turbo-template')].DNSName" --output text
```

Point your domain to the ALB using a **CNAME** record:

| Type  | Name       | Value                                                            | TTL |
| ----- | ---------- | ---------------------------------------------------------------- | --- |
| CNAME | `turbo`    | `turbo-template-prod-alb-xxxxx.ap-southeast-1.elb.amazonaws.com` | 600 |
| CNAME | `turbo-be` | `turbo-template-prod-alb-xxxxx.ap-southeast-1.elb.amazonaws.com` | 600 |

Both subdomains point to the same ALB — the ALB routes traffic by host-header to the correct ECS service.

### HTTPS (production)

1. Request a certificate in **AWS Certificate Manager (ACM)** for `turbo.quanbyit.com` and `turbo-be.quanbyit.com` (or `*.quanbyit.com` wildcard)
2. ACM will ask you to add a CNAME record in GoDaddy for domain validation — add it and wait for validation
3. Set the certificate ARN in `terraform.tfvars`:

```hcl
certificate_arn = "arn:aws:acm:ap-southeast-1:123456789012:certificate/abc-123"
```

4. Run `terraform apply` — the ALB will now serve HTTPS and redirect HTTP → HTTPS

---

## Environment Variables for Your App

These are app-level environment variables your services need at runtime (not Terraform variables). Set them according to your deployment method:

### Staging (EC2 + Docker Compose)

Set them in your `.env` file or `docker-compose.yml` on the EC2 instance:

```env
DATABASE_URL=postgresql://user:pass@host:5432/dbname
REDIS_URL=redis://host:6379
NEXT_PUBLIC_API_URL=https://turbo-be.quanbyit.com
```

### Production (ECS Fargate)

Set them in the ECS task definition via your app repo's deploy workflow. Common approaches:

- Inline `environment` block in the task definition JSON
- AWS Systems Manager Parameter Store (`valueFrom` in task definition)
- AWS Secrets Manager for sensitive values

---

## How It Works

### Services Map

Every environment is configured through a `services` map in `terraform.tfvars`. Each key becomes a named service — Terraform automatically provisions the full AWS stack for it (ECR repo, ECS task/service, ALB target group, security group, log group).

```hcl
services = {
  web = {
    port              = 3001
    health_check_path = "/"
    cpu               = "512"
    memory            = "1024"
    domain            = "turbo.quanbyit.com"
    is_alb_default    = true   # catches all unmatched ALB traffic
    desired_count     = 1
  }
  backend = {
    port                 = 3000
    health_check_path    = "/api/v1/health"
    cpu                  = "512"
    memory               = "1024"
    domain               = "turbo-be.quanbyit.com"
    health_check_matcher = "200"
    allow_vpc_egress     = true  # enables DB + Redis egress within VPC
    desired_count        = 1
  }
}
```

#### Service configuration options

| Field                  | Type   | Default     | Description                                         |
| ---------------------- | ------ | ----------- | --------------------------------------------------- |
| `port`                 | number | required    | Container port the service listens on               |
| `health_check_path`    | string | required    | ALB health check endpoint                           |
| `cpu`                  | string | required    | Fargate CPU units (256, 512, 1024, 2048, 4096)      |
| `memory`               | string | required    | Fargate memory in MB (512, 1024, 2048, ...)         |
| `domain`               | string | `""`        | Host-header routing rule on the ALB                 |
| `desired_count`        | number | `1`         | Number of ECS tasks to run                          |
| `is_alb_default`       | bool   | `false`     | Receives all unmatched ALB traffic (max 1 service)  |
| `expose_via_alb`       | bool   | `true`      | Whether to create an ALB target group               |
| `health_check_matcher` | string | `"200-399"` | Expected HTTP status code(s) for health checks      |
| `allow_vpc_egress`     | bool   | `false`     | Allow egress to DB (5432) + Redis (6379) within VPC |

To add a new service (e.g. a background worker), add a new entry to the map and run `terraform apply`. No module changes needed.

### Staging vs. Production

|                       | Staging | Production |
| --------------------- | ------- | ---------- |
| ECR repositories      | ✅      | ✅         |
| CloudWatch log groups | ✅      | ✅         |
| VPC + networking      | ❌      | ✅         |
| ALB + HTTPS           | ❌      | ✅         |
| ECS Fargate services  | ❌      | ✅         |

Staging infrastructure is minimal — the app runs on EC2 + Docker Compose managed by the app repo. Terraform only manages shared AWS resources (ECR, logs) so both environments share the same registry.

---

## Adding a New Project

### 1. Copy the example project

```bash
cp -r environments/turbo-template environments/<your-project-name>
```

### 2. Update the S3 backend keys

Edit `backend.tf` in both `staging/` and `production/`:

```hcl
terraform {
  backend "s3" {
    bucket         = "<your-project-name>-terraform-state"
    key            = "staging/terraform.tfstate"       # or "production/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "<your-project-name>-terraform-locks"
    encrypt        = true
  }
}
```

### 3. Update terraform.tfvars

```bash
cd environments/<your-project-name>/staging
cp terraform.tfvars.example terraform.tfvars
# Edit: set project_name and domain values
```

Repeat for `production/`.

### 4. Bootstrap + deploy

```bash
# Bootstrap remote state
cd bootstrap
terraform init
terraform apply -var="project_name=<your-project-name>"

# Deploy staging
cd ../environments/<your-project-name>/staging
terraform init && terraform plan && terraform apply

# Deploy production (when ready)
cd ../production
terraform init && terraform plan && terraform apply
```

---

## Adding a Service to an Existing Project

1. Add a new entry to the `services` map in `terraform.tfvars`
2. Run `terraform plan` to preview, then `terraform apply`

That's it — the modules use `for_each` so new services are provisioned automatically.

---

## Common Operations

### Plan changes (preview without applying)

```bash
cd environments/<project>/<env>
terraform plan
```

### Apply changes

```bash
terraform apply
```

### Pause a service (scale to zero)

In `terraform.tfvars` set `desired_count = 0` for the service, then apply. ECS stops the tasks but the service and resources remain.

### Destroy an environment

```bash
cd environments/<project>/<env>
terraform destroy
```

> **Warning**: This removes all AWS resources for that environment including ECR images. For production, ALB deletion protection is enabled — run `terraform apply -var='...'` to disable it first, or remove it via the console.

---

## Key Design Decisions

1. **Placeholder task definitions**: ECS services are initially created with `nginx:alpine`. The app repo's deploy workflow registers the real image and updates the service. Terraform never touches it again.

2. **`ignore_changes` on ECS**: Terraform ignores `task_definition` and `desired_count` after initial creation, so app deploys are never reverted by a `terraform apply`.

3. **Separate state per environment**: Each environment has its own S3 state file (`staging/terraform.tfstate`, `production/terraform.tfstate`) for independent lifecycle management.

4. **Single NAT Gateway by default**: Cost-optimized. For high-availability production, set `enable_nat_ha = true` in `terraform.tfvars` to provision one NAT Gateway per AZ.

5. **Services map pattern**: All per-service AWS resources are driven by a single `services` map. Adding or removing a service requires only a `terraform.tfvars` change — no module edits.

## Expanding to GCP

The module structure is designed for multi-cloud expansion:

```
modules/
├── aws/           # ← current
│   ├── networking/
│   ├── ecr/
│   ├── ecs/
│   ├── alb/
│   └── monitoring/
└── gcp/           # ← future
    ├── networking/
    ├── gar/       # Google Artifact Registry
    ├── cloud-run/
    ├── lb/
    └── monitoring/
```

Create a new environment directory (e.g., `environments/<project>/gcp-production/`) that references `modules/gcp/` modules.
