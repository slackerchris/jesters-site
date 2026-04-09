#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PREVIEW_DIR="${REPO_ROOT}/deploy/preview"
PAYLOAD_DIR="${REPO_ROOT}/deploy/payload"
PAYLOAD_APP_DIR="${PAYLOAD_DIR}/payload-app"

log() {
  echo "[install-all] $*"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "[install-all] Missing required command: ${cmd}"
    exit 1
  fi
}

require_cmd docker
require_cmd node
require_cmd npm
require_cmd npx
require_cmd openssl

if ! docker compose version >/dev/null 2>&1; then
  echo "[install-all] Docker Compose plugin is required."
  exit 1
fi

NODE_VERSION="$(node -v 2>/dev/null || true)"
NODE_MAJOR="$(printf '%s' "${NODE_VERSION}" | sed -E 's/^v([0-9]+).*/\1/')"

if [[ -z "${NODE_MAJOR}" || "${NODE_MAJOR}" -lt 22 ]]; then
  cat <<'EOF'
[install-all] Node.js 22.12.0+ is required.
Use:
  nvm install 22.12.0
  nvm use 22.12.0
Then re-run: npm run install:all
EOF
  exit 1
fi

cd "${REPO_ROOT}"

log "Synchronizing environment files..."
bash "${SCRIPT_DIR}/sync-env.sh"

if [[ ! -d node_modules || ! -x node_modules/.bin/astro ]]; then
  log "Installing frontend dependencies with npm ci..."
  npm ci
else
  log "Frontend dependencies already installed."
fi

log "Building frontend..."
npm run build

log "Starting frontend preview container..."
bash "${SCRIPT_DIR}/start-preview.sh"

cd "${PAYLOAD_DIR}"

if [[ ! -f "${PAYLOAD_APP_DIR}/package.json" ]]; then
  log "Payload app source not found. Running one-time scaffold now..."
  cd "${PAYLOAD_APP_DIR}"
  npx create-payload-app@latest .
fi

cd "${PAYLOAD_DIR}"

if [[ -z "${PAYLOAD_BIND_IP:-}" && -f "${REPO_ROOT}/.env" ]]; then
  PAYLOAD_BIND_IP="$(awk -F= '$1=="PAYLOAD_BIND_IP" {sub(/^[^=]*=/, ""); print; exit}' "${REPO_ROOT}/.env")"
fi

PAYLOAD_BIND_IP="${PAYLOAD_BIND_IP:-127.0.0.1}"
log "Starting CMS stack in NPM mode (PAYLOAD_BIND_IP=${PAYLOAD_BIND_IP})..."
PAYLOAD_BIND_IP="${PAYLOAD_BIND_IP}" docker compose -f docker-compose.yml -f docker-compose.npm.yml up -d --build

HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
PREVIEW_PORT="${PREVIEW_PORT:-8080}"

if [[ -f "${PREVIEW_DIR}/.env" ]]; then
  preview_env_port="$(awk -F= '/^PREVIEW_PORT=/{print $2}' "${PREVIEW_DIR}/.env" | tail -n1)"
  if [[ -n "${preview_env_port}" ]]; then
    PREVIEW_PORT="${preview_env_port}"
  fi
fi

echo
echo "Install complete."
echo "Frontend preview URL: http://${HOST_IP:-localhost}:${PREVIEW_PORT}/"
echo "Payload upstream URL: http://${HOST_IP:-127.0.0.1}:3001"
echo
echo "Nginx Proxy Manager setup:"
echo "- Same host as Payload: forward to 127.0.0.1:3001 (http)"
echo "- Different host: run with PAYLOAD_BIND_IP=0.0.0.0 and forward to ${HOST_IP:-<payload-host-ip>}:3001"
echo "- In NPM SSL tab: request cert + Force SSL"
echo
echo "Reminder: set CMS_DOMAIN and LETSENCRYPT_EMAIL in deploy/payload/.env for production DNS/TLS."
