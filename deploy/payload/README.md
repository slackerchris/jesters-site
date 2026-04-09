# Payload CMS Docker Stack (Self-Hosted)

This stack runs Payload CMS with:

- Postgres database
- Nginx reverse proxy
- Automatic Let's Encrypt TLS certs
- Scheduled Postgres backups

## Prerequisites

- A VPS with Docker Engine + Docker Compose plugin installed
- A DNS `A` record for your CMS host (example: `cms.example.com`) pointing to that VPS
- Ports `80` and `443` open on the VPS firewall

## 1) Prepare the payload app code

Inside `deploy/payload/payload-app`, place your Payload project files (created from `create-payload-app`).

Example flow:

```bash
mkdir -p deploy/payload/payload-app
cd deploy/payload/payload-app
npx create-payload-app@latest .
```

Then return to `deploy/payload` for deployment.

## 2) Configure environment values

```bash
cd deploy/payload
cp .env.example .env
```

Edit `.env` and set:

- `CMS_DOMAIN`
- `LETSENCRYPT_EMAIL`
- `POSTGRES_PASSWORD`
- `PAYLOAD_SECRET`

Generate a strong secret example:

```bash
openssl rand -base64 48
```

## 3) Start services

```bash
docker compose up -d --build
```

## 4) Verify everything is healthy

```bash
docker compose ps
docker compose logs -f payload
```

Open:

- `https://<CMS_DOMAIN>/admin`

Payload will guide first-admin setup/login if your app is configured for that flow.

## 5) Connect Astro frontend to this CMS

In your Astro host/build environment, set:

- `PAYLOAD_API_URL=https://<CMS_DOMAIN>`
- `PAYLOAD_ADMIN_URL=https://<CMS_DOMAIN>/admin`

Then rebuild and redeploy the Astro static site.

## Operations

Tail all logs:

```bash
docker compose logs -f
```

Restart only Payload:

```bash
docker compose restart payload
```

Backups are written to the `backups` named volume. To inspect backup files:

```bash
docker run --rm -v payload_backups:/backups alpine ls -lah /backups
```

## Update workflow

1. Pull latest Payload app code into `payload-app`
2. Rebuild and restart:

```bash
docker compose up -d --build
```

## Security notes

- Keep `.env` out of git and rotate secrets if leaked.
- Restrict SSH to key-based auth only.
- Enable VPS automatic security updates where possible.
