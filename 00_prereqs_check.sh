#!/usr/bin/env bash
set -euo pipefail

echo "STEP 0 / 10 — Prerequisites Check"

command -v aws >/dev/null || { echo "AWS CLI missing"; exit 1; }
command -v curl >/dev/null || { echo "curl missing"; exit 1; }
command -v jq >/dev/null || { echo "jq missing"; exit 1; }

aws sts get-caller-identity >/dev/null || {
  echo "AWS CLI not configured"
  exit 1
}

echo "Prerequisites OK"
