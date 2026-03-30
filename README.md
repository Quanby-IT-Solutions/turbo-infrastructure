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
    domain            = "app.yourdomain.com"
    is_alb_default    = true   # catches all unmatched ALB traffic
    desired_count     = 1
  }
  backend = {
    port                 = 3000
    health_check_path    = "/api/v1/health"
    cpu                  = "512"
    memory               = "1024"
    domain               = "api.yourdomain.com"
    health_check_matcher = "200"
    allow_vpc_egress     = true  # enables DB + Redis egress within VPC
    desired_count        = 1
  }
}
```

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

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- AWS CLI configured (`aws configure`)
- IAM permissions for: VPC, ECS, ECR, ALB, IAM, CloudWatch, S3, DynamoDB

---

## Adding a New Project

### 1. Copy the example project

```bash
cp -r environments/turbo-template environments/<your-project-name>
```

### 2. Update the S3 backend keys in both environment files

`environments/<your-project-name>/staging/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "<your-project-name>-terraform-state"
    key            = "staging/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "<your-project-name>-terraform-locks"
    encrypt        = true
  }
}
```

`environments/<your-project-name>/production/backend.tf` — same but `key = "production/terraform.tfstate"`.

### 3. Bootstrap remote state for the new project

```bash
cd bootstrap
terraform init
terraform apply -var="project_name=<your-project-name>"
```

### 4. Deploy staging

```bash
cd environments/<your-project-name>/staging
cp terraform.tfvars.example terraform.tfvars
# Edit: set project_name and domain values

terraform init
terraform plan
terraform apply
```

### 5. Deploy production

```bash
cd environments/<your-project-name>/production
cp terraform.tfvars.example terraform.tfvars
# Edit: set project_name, domain values, and optionally certificate_arn

terraform init
terraform plan
terraform apply
```

### 6. Copy outputs to the app repo

After `terraform apply`, copy the output values to the app repo's GitHub Environment variables:

```bash
terraform output
```

| Terraform output                  | GitHub variable          |
| --------------------------------- | ------------------------ |
| `ecs_cluster_name`                | `ECS_CLUSTER`            |
| `ecs_service_names["web"]`        | `ECS_SERVICE_WEB`        |
| `ecs_service_names["backend"]`    | `ECS_SERVICE_BACKEND`    |
| `ecr_repository_names["web"]`     | `ECR_REPOSITORY_WEB`     |
| `ecr_repository_names["backend"]` | `ECR_REPOSITORY_BACKEND` |

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
