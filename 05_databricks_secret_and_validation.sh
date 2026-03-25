#!/usr/bin/env bash
set -euo pipefail

echo "STEP 5 / 10 — Credentials + Secret"

source ./env.sh

read -p "Client ID: " DBX_CLIENT
read -s -p "Client Secret: " DBX_SECRET
echo ""
read -p "Workspace URL: " DBX_HOST

TOKEN=$(curl -s -X POST \
  "https://accounts.cloud.databricks.us/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=$DBX_CLIENT&client_secret=$DBX_SECRET" \
  | jq -r .access_token)

[ "$TOKEN" = "null" ] && exit 1

SECRET_NAME="dbx-secret-$ACCOUNT_ID"

EXISTING=$(aws secretsmanager list-secrets \
  --query "SecretList[?Name=='$SECRET_NAME'].ARN" \
  --output text)

if [ "$EXISTING" != "None" ]; then
  SECRET_ARN=$EXISTING
else
  SECRET_ARN=$(aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --secret-string "{\"client_id\":\"$DBX_CLIENT\",\"client_secret\":\"$DBX_SECRET\"}" \
    --query ARN --output text)
fi

cat >> env.sh <<EOF
export DBX_CLIENT=$DBX_CLIENT
export DBX_SECRET=$DBX_SECRET
export DBX_HOST=$DBX_HOST
export SECRET_ARN=$SECRET_ARN
EOF
