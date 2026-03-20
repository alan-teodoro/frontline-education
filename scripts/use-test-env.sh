#!/usr/bin/env bash

if [[ -n "${BASH_VERSION:-}" ]]; then
  SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  SCRIPT_PATH="${(%):-%N}"
else
  SCRIPT_PATH="$0"
fi

ROOT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env.rediscloud.test.local"

fail() {
  echo "$1" >&2
  return 1 2>/dev/null || exit 1
}

if [[ ! -f "${ENV_FILE}" ]]; then
  fail "Missing ${ENV_FILE}"
fi

set -a
if ! source "${ENV_FILE}"; then
  set +a
  fail "Failed to load ${ENV_FILE}"
fi
set +a

echo "Redis Cloud test credentials exported for the current shell context."
echo "REDISCLOUD_ACCESS_KEY is set."
echo "REDISCLOUD_SECRET_KEY is set."
