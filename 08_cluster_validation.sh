#!/usr/bin/env bash
set -euo pipefail

echo "STEP 8 / 10 — Cluster Validation"

source ./env.sh

TOKEN=$(curl -s -X POST \
  "https://accounts.cloud.databricks.us/oauth/token" \
  -d "grant_type=client_credentials&client_id=$DBX_CLIENT&client_secret=$DBX_SECRET" \
  | jq -r .access_token)

curl -s "$DBX_HOST/api/2.0/clusters/list" \
  -H "Authorization: Bearer $TOKEN" | jq .
