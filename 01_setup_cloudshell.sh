#!/usr/bin/env bash
set -euo pipefail

echo "STEP 1 / 10 — CloudShell Setup"

append_if_missing () {
  LINE="$1"
  FILE="$HOME/.bashrc"
  grep -qxF "$LINE" "$FILE" || echo "$LINE" >> "$FILE"
}

append_if_missing 'export TF_PLUGIN_CACHE_DIR="/tmp/.terraform.d/plugin-cache"'
append_if_missing 'export TF_DATA_DIR="/tmp/.terraform"'
append_if_missing 'export PATH=$HOME/bin:$PATH'

mkdir -p /tmp/.terraform.d/plugin-cache
mkdir -p /tmp/.terraform

echo "CloudSheel .bashrc setup has completed, please source the .bashrc in your home directory or restart a new CloudShell session."
