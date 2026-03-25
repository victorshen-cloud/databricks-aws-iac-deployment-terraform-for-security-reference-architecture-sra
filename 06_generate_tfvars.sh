#!/usr/bin/env bash
set -euo pipefail

echo "STEP 6 / 10 — tfvars"

source ./env.sh

cat > terraform.tfvars <<EOF
aws_account_id = "$ACCOUNT_ID"
region = "$REGION"
vpc_id = "$VPC_ID"
private_subnet_ids = ["$GOOD_SUBNET"]
privatelink_subnet_ids = ["$PL_SUBNET"]
compute_security_group_id = "$COMPUTE_SG"
databricks_secret_arn = "$SECRET_ARN"
EOF
