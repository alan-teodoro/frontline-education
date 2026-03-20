#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env.rediscloud.test.local"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI 'gh' is required to configure repository secrets." >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}" >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

if [[ -z "${REDISCLOUD_ACCESS_KEY:-}" || -z "${REDISCLOUD_SECRET_KEY:-}" ]]; then
  echo "REDISCLOUD_ACCESS_KEY and REDISCLOUD_SECRET_KEY must be set." >&2
  exit 1
fi

printf '%s' "${REDISCLOUD_ACCESS_KEY}" | gh secret set REDISCLOUD_ACCESS_KEY
printf '%s' "${REDISCLOUD_SECRET_KEY}" | gh secret set REDISCLOUD_SECRET_KEY

echo "Configured GitHub repository secrets:"
echo "- REDISCLOUD_ACCESS_KEY"
echo "- REDISCLOUD_SECRET_KEY"
echo
echo "Still needed before workflow execution:"
echo "- TF_STATE_BUCKET"
echo "- TF_STATE_REGION"
echo "- Optional: REDISCLOUD_PAYMENT_METHOD_ID"
echo "- Repository variables: AWS_GITHUB_ACTIONS_ROLE_ARN_DEV/QA/STAGE/PROD"
