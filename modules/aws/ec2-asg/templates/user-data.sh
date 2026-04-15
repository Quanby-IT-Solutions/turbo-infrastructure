#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- Variables (injected by Terraform templatefile) ---
PROJECT="${project_name}"
ENV="${environment}"
REGION="${aws_region}"

# --- System Update ---
apt-get update -y
apt-get upgrade -y

# --- Install Docker CE ---
apt-get install -y ca-certificates curl gnupg jq unzip
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# --- Install AWS CLI v2 ---
if ! command -v aws &> /dev/null; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

# --- Prepare app directory ---
mkdir -p /opt/app
chown ubuntu:ubuntu /opt/app

# --- Deploy script (reads config from SSM Parameter Store) ---
cat > /opt/app/deploy.sh <<'DEPLOY_SCRIPT'
#!/bin/bash
set -euo pipefail

REGION="__REGION__"
PROJECT="__PROJECT__"
ENV="__ENV__"

# ECR login
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region "$REGION")
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# Read docker-compose.yml from SSM (base64-encoded)
COMPOSE_B64=$(aws ssm get-parameter \
  --name "/$PROJECT/$ENV/docker-compose" \
  --with-decryption \
  --query 'Parameter.Value' --output text \
  --region "$REGION" 2>/dev/null || echo "")

if [ -z "$COMPOSE_B64" ]; then
  echo "[deploy] No docker-compose config in SSM (/$PROJECT/$ENV/docker-compose). Skipping."
  exit 0
fi

echo "$COMPOSE_B64" | base64 -d > /opt/app/docker-compose.yml

# Read optional .env from SSM (base64-encoded)
ENV_B64=$(aws ssm get-parameter \
  --name "/$PROJECT/$ENV/env" \
  --with-decryption \
  --query 'Parameter.Value' --output text \
  --region "$REGION" 2>/dev/null || echo "")

if [ -n "$ENV_B64" ]; then
  echo "$ENV_B64" | base64 -d > /opt/app/.env
fi

cd /opt/app
docker compose pull --quiet
docker compose up -d --remove-orphans

echo "[deploy] Deploy complete at $(date)"
DEPLOY_SCRIPT

# Patch placeholders with actual values
sed -i "s|__REGION__|$REGION|g" /opt/app/deploy.sh
sed -i "s|__PROJECT__|$PROJECT|g" /opt/app/deploy.sh
sed -i "s|__ENV__|$ENV|g" /opt/app/deploy.sh
chmod +x /opt/app/deploy.sh
chown ubuntu:ubuntu /opt/app/deploy.sh

# --- Initial deploy (best-effort — SSM params may not exist on first boot) ---
/opt/app/deploy.sh || echo "[user-data] Initial deploy skipped — SSM params not yet configured."
