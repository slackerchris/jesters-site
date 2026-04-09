# Jester Cards and Games Site

Astro frontend plus Payload CMS, built for owner editing without Git.

## Core Rule

- Owner does not use Git.
- Owner does not need a GitHub account.
- Owner workflow is: log in, edit, publish.

## Stack Overview

- Frontend: Astro static site in this repository.
- CMS: Self-hosted Payload with Postgres.
- Admin launcher: /admin route in the frontend points to your Payload admin URL.

## Quick Start

```bash
npm install
npm run dev
```

Production build:

```bash
npm run build
```

Build output is written to:

- dist

## Local Customer Preview In Docker

Run a shareable preview from your local LXC Docker host:

```bash
npm run preview:docker:up
```

Build and start preview in one command:

```bash
npm run preview:docker:build-up
```

Stop preview:

```bash
npm run preview:docker:down
```

Preview stack files:

- deploy/preview/docker-compose.yml
- deploy/preview/Dockerfile
- deploy/preview/nginx.conf

## Owner Editing Flow

1. Owner opens /admin on the website.
2. Owner clicks Open Payload Admin.
3. Owner logs in with email and password.
4. Owner edits content in Payload.
5. Site is rebuilt and redeployed by your workflow.

## Frontend Environment Variables

Set these where Astro builds or runs:

- PAYLOAD_API_URL
  Example: https://cms.example.com
  Frontend fetches from: PAYLOAD_API_URL/api/locations
- PAYLOAD_ADMIN_URL
  Example: https://cms.example.com/admin
  Used by the /admin launcher page

If PAYLOAD_API_URL is missing or unavailable, frontend falls back to local data in src/data/locations.json.

## New Customer Bootstrap

Create a single-location customer baseline:

```bash
npm run new:client -- --name "Customer Business" --slug "main" --locations 1
```

Create a multi-location baseline:

```bash
npm run new:client -- --name "Customer Business" --slug "main" --locations 3
```

Bootstrap command updates:

- src/data/locations.json
- src/data/store.json
- deploy/payload/customer-presets/<slug>.env.example

## Deployment Options

Recommended start:

- One VPS with Docker
- Payload CMS
- Postgres
- Reverse proxy and TLS

Payload stack files:

- deploy/payload/docker-compose.yml
- deploy/payload/.env.example
- deploy/payload/README.md

## Template and Release Docs

- Start-to-finish install guide: docs/start-to-finish-install-guide.md
- Client template runbook: docs/client-template-playbook.md
- LXC preview and template release guide: docs/lxc-preview-and-template-release.md

## Main Routes

- /
- /locations/[location]/
- /locations/[location]/services
- /locations/[location]/events
- /locations/[location]/community
- /locations/[location]/contact
- /locations/[location]/areas/[area]
- /admin

## Migration Note

Legacy Decap config is kept for reference at public/admin/config.yml.
Active owner CMS flow is Payload.
