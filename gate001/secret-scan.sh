#!/usr/bin/env bash
# Gate 001 pre-push secret scan (fails on match)
set -euo pipefail

if grep -RInE 'PQC_TEST_SEED|STRIPE_SECRET_KEY|STRIPE_WEBHOOK_SECRET|sk_live_|whsec_|AKIA|PRIVATE KEY|BEGIN RSA' \
  formal middleware webhooks verify Dockerfile.verify docker-compose.verify.yml \
  .github/workflows gate001 artifacts 2>/dev/null; then
  echo "Potential secret-like material found"
  exit 1
else
  echo "Secret scan: clean"
fi
