#!/usr/bin/env bash
set -euo pipefail

echo "STEP 2 / 10 — CloudShell Prepare + Terraform Setup"

############################################
# 1. Disk Status BEFORE
############################################

echo "Disk usage BEFORE:"
df -h
echo ""

############################################
# 2. Cleanup Terraform + Temp Junk
############################################

echo "Cleaning Terraform artifacts..."

rm -rf .terraform 2>/dev/null || true
rm -f .terraform.lock.hcl 2>/dev/null || true

echo "Cleaning temp directories..."

rm -rf /tmp/.terraform 2>/dev/null || true
rm -rf /tmp/.terraform.d 2>/dev/null || true

echo "Cleaning logs..."

rm -rf ~/tf-logs/* 2>/dev/null || true

############################################
# 3. Setup Terraform Runtime (critical)
############################################

echo "Setting Terraform runtime to /tmp..."

export TF_PLUGIN_CACHE_DIR="/tmp/.terraform.d/plugin-cache"
export TF_DATA_DIR="/tmp/.terraform"

mkdir -p $TF_PLUGIN_CACHE_DIR
mkdir -p $TF_DATA_DIR

############################################
# 4. Persist to .bashrc (safe append)
############################################

append_if_missing () {
  LINE="$1"
  FILE="$HOME/.bashrc"
  grep -qxF "$LINE" "$FILE" || echo "$LINE" >> "$FILE"
}

append_if_missing 'export TF_PLUGIN_CACHE_DIR="/tmp/.terraform.d/plugin-cache"'
append_if_missing 'export TF_DATA_DIR="/tmp/.terraform"'

############################################
# 5. Install Terraform if missing
############################################

if ! command -v terraform >/dev/null 2>&1; then
  echo "Terraform not found — installing..."

  TF_VERSION="1.6.6"

  curl -s -o /tmp/terraform.zip \
    https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip

  unzip -o /tmp/terraform.zip -d /tmp

  chmod +x /tmp/terraform
  mv /tmp/terraform ~/bin/terraform || true

  echo "Terraform installed to ~/bin/terraform"
else
  echo "Terraform already installed"
fi

############################################
# 6. Verify Terraform
############################################

echo ""
terraform version || echo "Terraform not in PATH yet (restart shell may be needed)"

############################################
# 7. Disk Status AFTER
############################################

echo ""
echo "Disk usage AFTER:"
df -h

echo ""
echo "CloudShell environment ready"
