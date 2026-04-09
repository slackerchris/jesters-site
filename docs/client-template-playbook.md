# Client Template Playbook

Use this repository as your base template for new customer websites.

## Recommended model

- Keep this repo as your master starter template.
- For each customer, create a new repo from this codebase.
- Run the bootstrap command once per new customer.
- Deploy Astro frontend + Payload CMS using the Docker stack in `deploy/payload`.

## 1) Bootstrap a new customer

Run from repo root:

```bash
npm run new:client -- \
  --name "Acme TCG and Games" \
  --slug "main" \
  --locations 1 \
  --city "Morrow" \
  --state "OH" \
  --street "10 Miranda St." \
  --postal "45152" \
  --phone "(513) 000-0000" \
  --email "owner@acmegames.com" \
  --website "acmegames.com" \
  --facebook "facebook.com/acmegames" \
  --domain "acmegames.com" \
  --cms-domain "cms.acmegames.com" \
  --letsencrypt-email "ops@acmegames.com"
```

For multi-location customers, increase `--locations` (example: `--locations 3`).
The script creates placeholder secondary locations so you can fill in final details quickly.

This command updates:

- `src/data/locations.json`
- `src/data/store.json`
- `deploy/payload/customer-presets/<slug>.env.example`

## 2) Build and QA

```bash
npm install
npm run build
npm run dev
npm run preview:docker:up
```

Check:

- Homepage brand and location data
- Contact details and map links
- `/admin/` launcher page

When review is complete:

```bash
npm run preview:docker:down
```

## 3) Deploy Payload CMS

Use:

- `deploy/payload/docker-compose.yml`
- `deploy/payload/.env.example`

Quick flow:

1. Copy `deploy/payload/.env.example` to `.env`
2. Merge in customer values from `deploy/payload/customer-presets/<slug>.env.example`
3. Add actual Payload app code into `deploy/payload/payload-app`
4. Run `docker compose up -d --build`

## 4) Connect frontend to CMS

Set frontend env vars in your Astro hosting pipeline:

- `PAYLOAD_API_URL=https://cms.customer-domain.com`
- `PAYLOAD_ADMIN_URL=https://cms.customer-domain.com/admin`

Then rebuild and redeploy the frontend.

## 5) Scale process for many customers

- Keep one Git branch or repository per customer.
- Keep one CMS domain per customer (example: `cms.customer.com`).
- Reuse the same deployment stack and onboarding checklist.
- Standardize DNS naming so setup stays predictable.
