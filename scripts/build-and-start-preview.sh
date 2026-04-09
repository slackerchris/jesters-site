#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required but was not found in PATH."
  exit 1
fi

NODE_VERSION="$(node -v | sed 's/^v//')"
NODE_MAJOR="${NODE_VERSION%%.*}"

if [[ -z "${NODE_MAJOR}" || "${NODE_MAJOR}" -lt 22 ]]; then
  echo "Node.js 22.12.0 or newer is required. Current version: v${NODE_VERSION}"
  echo "Use nvm to install and switch: nvm install 22.12.0 && nvm use 22.12.0"
  exit 1
fi

if [[ ! -d node_modules || ! -x node_modules/.bin/astro ]]; then
  echo "Installing dependencies..."
  npm ci
fi

echo "Building site..."
npm run build

echo "Starting preview container..."
bash "${SCRIPT_DIR}/start-preview.sh"
