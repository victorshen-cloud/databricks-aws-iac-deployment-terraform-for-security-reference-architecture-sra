#!/usr/bin/env bash
set -euo pipefail

echo "STEP 9 / 10 — Optional Spark Test"

read -p "Run test? (yes/no): " RUN
[ "$RUN" != "yes" ] && exit 0

echo "Skipping heavy job to avoid cost"
