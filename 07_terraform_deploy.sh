#!/usr/bin/env bash
set -euo pipefail

echo "STEP 7 / 10 — Terraform Deploy (Resilient)"

read -p "Enter Terraform path: " TF_PATH
cd "$TF_PATH"

############################################
# Retry wrapper
############################################

run_tf () {
  CMD=$1

  MAX_RETRIES=3
  COUNT=0

  until [ $COUNT -ge $MAX_RETRIES ]
  do
    echo "Running: terraform $CMD (attempt $((COUNT+1)))"

    if terraform $CMD; then
      return 0
    fi

    echo "Terraform failed — attempting recovery..."

    ############################################
    # Attempt lock recovery
    ############################################

    LOCK_ID=$(grep -o 'Lock Info:.*ID:.*' -A 5 .terraform/terraform.tfstate 2>/dev/null | grep ID | awk '{print $2}' || true)

    if [ -n "$LOCK_ID" ]; then
      echo "Attempting force unlock..."
      terraform force-unlock -force "$LOCK_ID" || true
    fi

    ############################################
    # Cleanup temp issues
    ############################################

    rm -rf .terraform || true

    COUNT=$((COUNT+1))
    sleep 5
  done

  echo "Terraform failed after retries"
  exit 1
}

############################################
# Execute
############################################

run_tf "init"
run_tf "apply -auto-approve"

echo "Terraform deployment complete"
