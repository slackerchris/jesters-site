# Jester Cards and Games Site

Astro frontend + Payload CMS (owner login with email/password, no Git required for owner).

## Non-Negotiable Owner Rule

- Owner does not use Git.
- Owner does not need GitHub/GitLab account.
- Owner editing flow is: log in, edit, publish.

## Current Architecture

- Frontend website: this Astro project
- CMS: Payload (self-hosted by you)
- Admin entry page in frontend: `/admin/`
  - This page forwards users to your Payload admin URL

## How Owner Edits Content

1. Owner opens `/admin/` on the website.
2. Owner clicks `Open Payload Admin`.
3. Owner logs in with email/password.
4. Owner edits content in Payload.
5. Site is rebuilt/deployed by your hosting workflow.

## Environment Variables (Frontend)

Set these where Astro builds/runs:

- `PAYLOAD_API_URL`
  - Example: `https://cms.example.com`
  - Frontend pulls locations from: `${PAYLOAD_API_URL}/api/locations`
- `PAYLOAD_ADMIN_URL`
  - Example: `https://cms.example.com/admin`
  - Used by `/admin/` launcher page

If `PAYLOAD_API_URL` is missing/unreachable, frontend falls back to local `src/data/locations.json`.

## Self-Hosting Choices (No Git Owner Flow)

### Option A: Single VPS (recommended start)

Run on one VPS with Docker:

1. Payload CMS
2. Postgres
3. Reverse proxy (Caddy or Nginx)

Use this when:

- You want low cost
- You can manage one server

### Option B: Split Services (more robust)

1. Payload + Postgres on one server
2. Frontend static hosting/CDN on another
3. Rebuild webhook from Payload changes

Use this when:

- You expect higher traffic
- You want cleaner separation of concerns

## Frontend Commands

```bash
npm install
npm run dev
npm run build
npm run preview:docker:up
npm run preview:docker:down
```

## Template Workflow For New Customers

Use this repo as your base starter and bootstrap each new customer with one command:

```bash
npm run new:client -- --name "Customer Business" --slug "main"
```

Use `--locations <count>` when a customer has multiple locations:

```bash
npm run new:client -- --name "Customer Business" --slug "main" --locations 3
```

This updates local fallback data files and creates a customer-specific CMS env template under `deploy/payload/customer-presets/`.

Detailed process is documented in `docs/client-template-playbook.md`.

LXC preview and template release flow is documented in `docs/lxc-preview-and-template-release.md`.

Build output:

- `dist`

## Routes

- `/` location picker (landing page)
- `/locations/morrow/`
- `/locations/milford/`
- `/locations/[location]/services`
- `/locations/[location]/events`
- `/locations/[location]/community`
- `/locations/[location]/contact`
- `/locations/[location]/areas/[area]`
- `/admin/` (Payload admin launcher)

## Payload Migration Note

Legacy Decap config is left in `public/admin/config.yml` for reference only.
Active owner CMS flow is Payload.
