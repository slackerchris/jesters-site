#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PREVIEW_DIR="${REPO_ROOT}/deploy/preview"

cd "${PREVIEW_DIR}"
docker compose down

echo "Preview container stopped."
