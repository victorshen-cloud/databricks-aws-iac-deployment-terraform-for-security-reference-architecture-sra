#!/usr/bin/env bash
set -euo pipefail

echo "STEP 10 / 10 — CloudShell Backup"

REGION=$(aws configure get region || echo "us-gov-west-1")
BUCKET="cloudshell-backup-$RANDOM-$RANDOM"

# Create the bucket
aws s3 mb "s3://$BUCKET" --region "$REGION" || true

# Enable bucket versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
tar -czf "backup_$DATE.tar.gz" ~/

# Upload the backup
aws s3 cp "backup_$DATE.tar.gz" "s3://$BUCKET/"

echo "Backup complete: s3://$BUCKET"
