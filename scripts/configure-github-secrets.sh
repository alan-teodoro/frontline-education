#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env.rediscloud.test.local"
TARGET_ENVIRONMENT="${1:-dev}"
TARGET_ENVIRONMENT_UPPER="$(printf '%s' "${TARGET_ENVIRONMENT}" | tr '[:lower:]' '[:upper:]')"

case "${TARGET_ENVIRONMENT}" in
  dev|qa|stage|prod)
    ;;
  *)
    echo "Usage: $0 [dev|qa|stage|prod]" >&2
    exit 1
    ;;
esac

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

printf '%s' "${REDISCLOUD_ACCESS_KEY}" | gh secret set "REDISCLOUD_ACCESS_KEY_${TARGET_ENVIRONMENT_UPPER}"
printf '%s' "${REDISCLOUD_SECRET_KEY}" | gh secret set "REDISCLOUD_SECRET_KEY_${TARGET_ENVIRONMENT_UPPER}"

if [[ -n "${REDISCLOUD_ACCOUNT_ID:-}" ]]; then
  printf '%s' "${REDISCLOUD_ACCOUNT_ID}" | gh variable set "REDISCLOUD_ACCOUNT_ID_${TARGET_ENVIRONMENT_UPPER}"
fi

echo "Configured GitHub repository credentials for ${TARGET_ENVIRONMENT}:"
echo "- REDISCLOUD_ACCESS_KEY_${TARGET_ENVIRONMENT_UPPER}"
echo "- REDISCLOUD_SECRET_KEY_${TARGET_ENVIRONMENT_UPPER}"
if [[ -n "${REDISCLOUD_ACCOUNT_ID:-}" ]]; then
  echo "- REDISCLOUD_ACCOUNT_ID_${TARGET_ENVIRONMENT_UPPER}"
fi
echo
echo "Still needed before workflow execution:"
echo "- TF_STATE_BUCKET"
echo "- TF_STATE_REGION"
echo "- Repository variables: AWS_GITHUB_ACTIONS_ROLE_ARN_DEV/QA/STAGE/PROD"
echo
echo "The workflow resolves credit-card billing from config/catalog.yaml."
