#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PREVIEW_DIR="${REPO_ROOT}/deploy/preview"

cd "${PREVIEW_DIR}"

if [[ ! -f .env && -f .env.example ]]; then
  cp .env.example .env
fi

PREVIEW_PORT_VALUE="${PREVIEW_PORT:-}"
if [[ -z "${PREVIEW_PORT_VALUE}" && -f .env ]]; then
  PREVIEW_PORT_VALUE="$(awk -F= '/^PREVIEW_PORT=/{print $2}' .env | tail -n1)"
fi
PREVIEW_PORT_VALUE="${PREVIEW_PORT_VALUE:-8080}"

docker compose up -d --build

echo
echo "Preview container is running."
echo "Local URL: http://localhost:${PREVIEW_PORT_VALUE}"

HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
if [[ -n "${HOST_IP}" ]]; then
  echo "LAN URL:   http://${HOST_IP}:${PREVIEW_PORT_VALUE}"
fi
