#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_ENV="${REPO_ROOT}/.env"
ROOT_ENV_EXAMPLE="${REPO_ROOT}/.env.example"
PAYLOAD_ENV="${REPO_ROOT}/deploy/payload/.env"
PAYLOAD_ENV_EXAMPLE="${REPO_ROOT}/deploy/payload/.env.example"
PREVIEW_ENV="${REPO_ROOT}/deploy/preview/.env"
PREVIEW_ENV_EXAMPLE="${REPO_ROOT}/deploy/preview/.env.example"

log() {
  echo "[env-sync] $*"
}

read_env_value() {
  local file="$1"
  local key="$2"

  if [[ ! -f "${file}" ]]; then
    return 0
  fi

  awk -F= -v k="${key}" '$1==k {sub(/^[^=]*=/, ""); print; exit}' "${file}"
}

upsert_env_value() {
  local file="$1"
  local key="$2"
  local value="$3"

  touch "${file}"

  if grep -q "^${key}=" "${file}"; then
    sed -i "s|^${key}=.*$|${key}=${value}|" "${file}"
  else
    printf '%s=%s\n' "${key}" "${value}" >> "${file}"
  fi
}

if [[ ! -f "${ROOT_ENV}" ]]; then
  if [[ -f "${ROOT_ENV_EXAMPLE}" ]]; then
    cp "${ROOT_ENV_EXAMPLE}" "${ROOT_ENV}"
    log "Created .env from .env.example"
  else
    cat > "${ROOT_ENV}" <<'EOF'
PAYLOAD_API_URL=https://cms.example.com
PAYLOAD_ADMIN_URL=https://cms.example.com/admin
CMS_DOMAIN=cms.example.com
LETSENCRYPT_EMAIL=you@example.com
PREVIEW_PORT=8080
PAYLOAD_BIND_IP=127.0.0.1
EOF
    log "Created .env with default values"
  fi
fi

if [[ ! -f "${PREVIEW_ENV}" && -f "${PREVIEW_ENV_EXAMPLE}" ]]; then
  cp "${PREVIEW_ENV_EXAMPLE}" "${PREVIEW_ENV}"
  log "Created deploy/preview/.env from .env.example"
fi

if [[ ! -f "${PAYLOAD_ENV}" && -f "${PAYLOAD_ENV_EXAMPLE}" ]]; then
  cp "${PAYLOAD_ENV_EXAMPLE}" "${PAYLOAD_ENV}"
  log "Created deploy/payload/.env from .env.example"
fi

payload_api_url="$(read_env_value "${ROOT_ENV}" "PAYLOAD_API_URL")"
payload_admin_url="$(read_env_value "${ROOT_ENV}" "PAYLOAD_ADMIN_URL")"
cms_domain="$(read_env_value "${ROOT_ENV}" "CMS_DOMAIN")"
letsencrypt_email="$(read_env_value "${ROOT_ENV}" "LETSENCRYPT_EMAIL")"
preview_port="$(read_env_value "${ROOT_ENV}" "PREVIEW_PORT")"
payload_bind_ip="$(read_env_value "${ROOT_ENV}" "PAYLOAD_BIND_IP")"

if [[ -z "${cms_domain}" && -n "${payload_api_url}" ]]; then
  cms_domain="$(printf '%s' "${payload_api_url}" | sed -E 's#^https?://([^/]+).*$#\1#')"
fi

if [[ -z "${payload_api_url}" && -n "${cms_domain}" ]]; then
  payload_api_url="https://${cms_domain}"
fi

if [[ -z "${payload_admin_url}" && -n "${payload_api_url}" ]]; then
  payload_admin_url="${payload_api_url%/}/admin"
fi

if [[ -z "${preview_port}" ]]; then
  preview_port="8080"
fi

if [[ -z "${payload_bind_ip}" ]]; then
  payload_bind_ip="127.0.0.1"
fi

if [[ -n "${payload_api_url}" ]]; then
  upsert_env_value "${ROOT_ENV}" "PAYLOAD_API_URL" "${payload_api_url}"
fi

if [[ -n "${payload_admin_url}" ]]; then
  upsert_env_value "${ROOT_ENV}" "PAYLOAD_ADMIN_URL" "${payload_admin_url}"
fi

if [[ -n "${cms_domain}" ]]; then
  upsert_env_value "${ROOT_ENV}" "CMS_DOMAIN" "${cms_domain}"
fi

if [[ -n "${letsencrypt_email}" ]]; then
  upsert_env_value "${ROOT_ENV}" "LETSENCRYPT_EMAIL" "${letsencrypt_email}"
fi

upsert_env_value "${ROOT_ENV}" "PREVIEW_PORT" "${preview_port}"
upsert_env_value "${ROOT_ENV}" "PAYLOAD_BIND_IP" "${payload_bind_ip}"
upsert_env_value "${PREVIEW_ENV}" "PREVIEW_PORT" "${preview_port}"

payload_postgres_db_root="$(read_env_value "${ROOT_ENV}" "POSTGRES_DB")"
payload_postgres_user_root="$(read_env_value "${ROOT_ENV}" "POSTGRES_USER")"
payload_postgres_password_root="$(read_env_value "${ROOT_ENV}" "POSTGRES_PASSWORD")"
payload_secret_root="$(read_env_value "${ROOT_ENV}" "PAYLOAD_SECRET")"
backup_schedule_root="$(read_env_value "${ROOT_ENV}" "BACKUP_SCHEDULE")"
backup_keep_days_root="$(read_env_value "${ROOT_ENV}" "BACKUP_KEEP_DAYS")"
backup_keep_weeks_root="$(read_env_value "${ROOT_ENV}" "BACKUP_KEEP_WEEKS")"
backup_keep_months_root="$(read_env_value "${ROOT_ENV}" "BACKUP_KEEP_MONTHS")"

payload_postgres_db="${payload_postgres_db_root:-$(read_env_value "${PAYLOAD_ENV}" "POSTGRES_DB")}"
payload_postgres_user="${payload_postgres_user_root:-$(read_env_value "${PAYLOAD_ENV}" "POSTGRES_USER")}"
payload_postgres_password="${payload_postgres_password_root:-$(read_env_value "${PAYLOAD_ENV}" "POSTGRES_PASSWORD")}"
payload_secret="${payload_secret_root:-$(read_env_value "${PAYLOAD_ENV}" "PAYLOAD_SECRET")}"
backup_schedule="${backup_schedule_root:-$(read_env_value "${PAYLOAD_ENV}" "BACKUP_SCHEDULE")}"
backup_keep_days="${backup_keep_days_root:-$(read_env_value "${PAYLOAD_ENV}" "BACKUP_KEEP_DAYS")}"
backup_keep_weeks="${backup_keep_weeks_root:-$(read_env_value "${PAYLOAD_ENV}" "BACKUP_KEEP_WEEKS")}"
backup_keep_months="${backup_keep_months_root:-$(read_env_value "${PAYLOAD_ENV}" "BACKUP_KEEP_MONTHS")}"

if [[ -z "${payload_postgres_db}" ]]; then
  payload_postgres_db="payload"
fi

if [[ -z "${payload_postgres_user}" ]]; then
  payload_postgres_user="payload"
fi

if [[ -z "${payload_postgres_password}" || "${payload_postgres_password}" == "replace_with_strong_db_password" ]]; then
  payload_postgres_password="$(openssl rand -base64 24 | tr -d '\n' | tr '/+' 'AZ')"
  log "Generated POSTGRES_PASSWORD"
fi

if [[ -z "${payload_secret}" || "${payload_secret}" == "replace_with_long_random_secret" ]]; then
  payload_secret="$(openssl rand -base64 48 | tr -d '\n')"
  log "Generated PAYLOAD_SECRET"
fi

if [[ -z "${backup_schedule}" ]]; then
  backup_schedule="30 3 * * *"
fi

if [[ -z "${backup_keep_days}" ]]; then
  backup_keep_days="7"
fi

if [[ -z "${backup_keep_weeks}" ]]; then
  backup_keep_weeks="4"
fi

if [[ -z "${backup_keep_months}" ]]; then
  backup_keep_months="6"
fi

if [[ -n "${cms_domain}" ]]; then
  upsert_env_value "${PAYLOAD_ENV}" "CMS_DOMAIN" "${cms_domain}"
fi

if [[ -n "${letsencrypt_email}" ]]; then
  upsert_env_value "${PAYLOAD_ENV}" "LETSENCRYPT_EMAIL" "${letsencrypt_email}"
fi

upsert_env_value "${PAYLOAD_ENV}" "POSTGRES_DB" "${payload_postgres_db}"
upsert_env_value "${PAYLOAD_ENV}" "POSTGRES_USER" "${payload_postgres_user}"
upsert_env_value "${PAYLOAD_ENV}" "POSTGRES_PASSWORD" "${payload_postgres_password}"
upsert_env_value "${PAYLOAD_ENV}" "PAYLOAD_SECRET" "${payload_secret}"
upsert_env_value "${PAYLOAD_ENV}" "BACKUP_SCHEDULE" "${backup_schedule}"
upsert_env_value "${PAYLOAD_ENV}" "BACKUP_KEEP_DAYS" "${backup_keep_days}"
upsert_env_value "${PAYLOAD_ENV}" "BACKUP_KEEP_WEEKS" "${backup_keep_weeks}"
upsert_env_value "${PAYLOAD_ENV}" "BACKUP_KEEP_MONTHS" "${backup_keep_months}"

# Keep the root .env as the easiest place to edit values.
upsert_env_value "${ROOT_ENV}" "POSTGRES_DB" "${payload_postgres_db}"
upsert_env_value "${ROOT_ENV}" "POSTGRES_USER" "${payload_postgres_user}"
upsert_env_value "${ROOT_ENV}" "POSTGRES_PASSWORD" "${payload_postgres_password}"
upsert_env_value "${ROOT_ENV}" "PAYLOAD_SECRET" "${payload_secret}"
upsert_env_value "${ROOT_ENV}" "BACKUP_SCHEDULE" "${backup_schedule}"
upsert_env_value "${ROOT_ENV}" "BACKUP_KEEP_DAYS" "${backup_keep_days}"
upsert_env_value "${ROOT_ENV}" "BACKUP_KEEP_WEEKS" "${backup_keep_weeks}"
upsert_env_value "${ROOT_ENV}" "BACKUP_KEEP_MONTHS" "${backup_keep_months}"

log "Environment sync complete"
