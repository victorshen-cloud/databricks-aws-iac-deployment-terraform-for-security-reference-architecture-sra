#!/usr/bin/env bash
set -euo pipefail

############################################
# GLOBALS
############################################

STEP=1
TOTAL=7

log_step() {
  echo ""
  echo "========================================="
  echo "STEP $STEP / $TOTAL — $1"
  echo "========================================="
  ((STEP++))
}

############################################
# STEP 1 — PREREQS + CLOUDSHELL SETUP
############################################

log_step "Environment Setup"

command -v aws >/dev/null || { echo "AWS CLI missing"; exit 1; }
command -v curl >/dev/null || { echo "curl missing"; exit 1; }
command -v jq >/dev/null || { echo "jq missing"; exit 1; }

aws sts get-caller-identity >/dev/null || {
  echo "AWS not configured"
  exit 1
}

echo "Disk before:"
df -h

rm -rf .terraform /tmp/.terraform /tmp/.terraform.d ~/tf-logs/* 2>/dev/null || true

export TF_PLUGIN_CACHE_DIR="/tmp/.terraform.d/plugin-cache"
export TF_DATA_DIR="/tmp/.terraform"

mkdir -p $TF_PLUGIN_CACHE_DIR $TF_DATA_DIR

############################################
# STEP 2 — TERRAFORM INSTALL
############################################

log_step "Terraform Setup"

if ! command -v terraform >/dev/null; then
  echo "Installing Terraform..."

  curl -s -o /tmp/terraform.zip \
    https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip

  unzip -o /tmp/terraform.zip -d /tmp
  chmod +x /tmp/terraform
  mkdir -p ~/bin
  mv /tmp/terraform ~/bin/terraform
  export PATH=$HOME/bin:$PATH
fi

terraform version

############################################
# STEP 3 — AWS NETWORK BOOTSTRAP
############################################

log_step "AWS Network Setup"

REGION=$(aws configure get region || echo "us-gov-west-1")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

PREFIX="dbx-$(date +%s)"
BASE=$(( (RANDOM % 200) + 10 ))

COMPUTE_CIDR="10.${BASE}.0.0/24"
PL_CIDR="10.${BASE}.1.0/26"

aws ec2 describe-vpcs \
  --query "Vpcs[*].[VpcId,CidrBlock]" \
  --output table

read -p "Enter VPC ID: " VPC_ID

GOOD_SUBNET=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $COMPUTE_CIDR \
  --query Subnet.SubnetId --output text)

PL_SUBNET=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PL_CIDR \
  --query Subnet.SubnetId --output text)

COMPUTE_SG=$(aws ec2 create-security-group \
  --group-name "${PREFIX}-compute-sg" \
  --vpc-id $VPC_ID \
  --query GroupId --output text)

VPCE_SG=$(aws ec2 create-security-group \
  --group-name "${PREFIX}-vpce-sg" \
  --vpc-id $VPC_ID \
  --query GroupId --output text)

############################################
# STEP 4 — DATABRICKS INPUT
############################################

log_step "Databricks Credentials"

echo "Go to Databricks → Service Principals → Create + Secret"
echo "Client ID format: aa8e736a-xxxx-443b-892e-0ee5xxxxxba0b"

read -p "Client ID: " DBX_CLIENT
read -s -p "Client Secret: " DBX_SECRET
echo ""
read -p "Workspace URL: " DBX_HOST

TOKEN=$(curl -s -X POST \
  "https://accounts.cloud.databricks.us/oauth/token" \
  -d "grant_type=client_credentials&client_id=$DBX_CLIENT&client_secret=$DBX_SECRET" \
  | jq -r .access_token)

[ "$TOKEN" = "null" ] && { echo "Invalid credentials"; exit 1; }

############################################
# STEP 5 — SECRETS MANAGER
############################################

log_step "Secrets Manager"

SECRET_NAME="dbx-secret-$ACCOUNT_ID"

SECRET_ARN=$(aws secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --secret-string "{\"client_id\":\"$DBX_CLIENT\",\"client_secret\":\"$DBX_SECRET\"}" \
  --query ARN --output text 2>/dev/null || \
  aws secretsmanager list-secrets \
  --query "SecretList[?Name=='$SECRET_NAME'].ARN" \
  --output text)

############################################
# STEP 6 — TERRAFORM DEPLOY (RESILIENT)
############################################

log_step "Terraform Deploy"

read -p "Enter Terraform directory: " TF_PATH
cd "$TF_PATH"

run_tf () {
  CMD=$1
  for i in 1 2 3; do
    echo "terraform $CMD attempt $i"
    if terraform $CMD; then return 0; fi
    rm -rf .terraform || true
    sleep 5
  done
  exit 1
}

run_tf init
run_tf "apply -auto-approve"

############################################
# STEP 7 — VALIDATION
############################################

log_step "Cluster Validation"

curl -s "$DBX_HOST/api/2.0/clusters/list" \
  -H "Authorization: Bearer $TOKEN" | jq '.clusters[] | {cluster_name,state}'

echo ""
echo "Deployment complete"
