# Infrastructure (Terraform)

Terraform infrastructure for the **turbo-template** monorepo.
Manages AWS resources that the application deploy workflows depend on.

## Architecture

```
                         ┌──────────────────────────┐
                         │     Route 53 / DNS        │
                         └────────────┬─────────────┘
                                      │
                         ┌────────────▼─────────────┐
                         │   ALB (internet-facing)   │
                         │   HTTP :80 / HTTPS :443   │
                         └──────┬──────────┬────────┘
                     /*         │          │  /api/*
                  ┌─────────────▼──┐  ┌────▼──────────────┐
                  │  Web (Next.js)  │  │ Backend (NestJS)  │
                  │  ECS :3001      │  │ ECS :3000         │
                  └────────────────┘  └───────────────────┘
```

**Staging** uses EC2 + Docker Compose (no ECS). Only ECR repos and log groups are managed here.
**Production** uses ECS Fargate + ALB. Full VPC, networking, and ECS infra is provisioned.

## Repository Structure

```
infra/
├── bootstrap/              # One-time setup: S3 + DynamoDB for remote state
├── environments/
│   ├── staging/            # ECR + monitoring only
│   └── production/         # Full stack (VPC, ALB, ECS, ECR, monitoring)
├── modules/
│   └── aws/
│       ├── networking/     # VPC, subnets, NAT, security groups
│       ├── ecr/            # Container registries + lifecycle policies
│       ├── alb/            # Load balancer, target groups, listeners
│       ├── ecs/            # Cluster, services, IAM roles
│       └── monitoring/     # CloudWatch log groups, optional alarms
└── .github/workflows/
    ├── plan.yml            # terraform plan on PRs
    └── apply.yml           # terraform apply on merge to main
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- AWS CLI configured with credentials
- An AWS account with permissions for VPC, ECS, ECR, ALB, IAM, CloudWatch, S3, DynamoDB

## Quick Start

### 1. Bootstrap Remote State

Run this **once** to create the S3 bucket and DynamoDB table for state storage:

```bash
cd bootstrap
terraform init
terraform apply
```

### 2. Deploy Staging

```bash
cd environments/staging
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project name

terraform init
terraform plan
terraform apply
```

### 3. Deploy Production

```bash
cd environments/production
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project name and settings

terraform init
terraform plan
terraform apply
```

### 4. Copy Outputs to App Repo

After applying, copy the Terraform outputs to your app repo's GitHub Environment variables:

```bash
terraform output
# Copy:
#   ecs_cluster_name         → GitHub var ECS_CLUSTER
#   ecs_web_service_name     → GitHub var ECS_SERVICE_WEB
#   ecs_backend_service_name → GitHub var ECS_SERVICE_BACKEND
#   ecr_web_repository_name  → GitHub var ECR_REPOSITORY_WEB
#   ecr_backend_repository_name → GitHub var ECR_REPOSITORY_BACKEND
```

## CI/CD

| Workflow    | Trigger                  | Action                                           |
| ----------- | ------------------------ | ------------------------------------------------ |
| `plan.yml`  | PR touching `*.tf` files | Runs `terraform plan` and comments on PR         |
| `apply.yml` | Merge to `main`          | Runs `terraform apply` for affected environments |
| `apply.yml` | Manual dispatch          | Apply a specific environment on demand           |

### Required GitHub Secrets

| Secret                  | Description         |
| ----------------------- | ------------------- |
| `AWS_ACCESS_KEY_ID`     | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |

### Required GitHub Variables

| Variable     | Default          | Description |
| ------------ | ---------------- | ----------- |
| `AWS_REGION` | `ap-southeast-1` | AWS region  |

## Environments

### Staging (`environments/staging/`)

Provisions only:

- **ECR** repositories (web + backend) with 15-image retention
- **CloudWatch** log groups with 14-day retention

The staging EC2 host, Nginx, and Docker Compose are managed by the app repo.

### Production (`environments/production/`)

Provisions full infrastructure:

- **VPC** with public/private subnets across 2 AZs
- **ALB** with path-based routing (`/api/*` → backend, `/*` → web)
- **ECS Fargate** cluster with web + backend services
- **ECR** repositories with 30-image retention
- **CloudWatch** log groups (90-day retention) + optional alarms
- **IAM** execution role + task role for ECS
- **NAT Gateway** (single, cost-optimized)

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

Create a new environment directory (e.g., `environments/gcp-production/`) that references `modules/gcp/` modules.

## Key Design Decisions

1. **Placeholder task definitions**: ECS services are created with nginx:alpine. The app deploy workflow registers real task definitions and updates the services.

2. **`ignore_changes` on ECS**: Terraform ignores `task_definition` and `desired_count` changes on ECS services, so app deploys don't get reverted by `terraform apply`.

3. **Separate state per environment**: Each environment has its own state file (`staging/terraform.tfstate`, `production/terraform.tfstate`) for independent lifecycle management.

4. **Single NAT Gateway**: Cost optimization for non-HA workloads. For production HA, add a NAT gateway per AZ in the networking module.

## Destroying Infrastructure

```bash
cd environments/<env>
terraform destroy
```

> **Warning**: Production has `prevent_destroy` on the S3 state bucket. Remove the lifecycle rule before destroying bootstrap resources.
