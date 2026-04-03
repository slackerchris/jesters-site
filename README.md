# Jesters Site

Astro website for a local game store with Decap CMS editing, Facebook/Google integrations, and multi-page navigation.

## Requirements

- Node.js 22+
- npm 10+

## Development

```bash
npm install
npm run dev
```

Default local site URL: `http://localhost:4321`

## Build

```bash
npm run build
npm run preview
```

Production output is generated in `dist/`.

## Decap CMS

### Admin URL

- `http://localhost:4321/admin/` (during local dev)

### Content Source

- Editable content file: `src/data/store.json`
- App consumes that data through: `src/config/store.ts`

### Local CMS Editing Workflow

Run these in separate terminals:

```bash
npm run dev
npm run cms:proxy
```

Then open `/admin/` and edit content through the CMS form.

### GitHub Backend Setup (required for deployed CMS writes)

Update `public/admin/config.yml`:

- `backend.repo`: set your real `owner/repo`
- `backend.branch`: set your production branch

If you deploy on Netlify with Identity + Git Gateway, switch backend accordingly.

## What Staff Can Edit In CMS

- Store profile (name, tagline, contact info, address)
- Facebook/Google integration links
- Google rating and review count display values
- Opening hours
- Services list
- Service areas (drives `/areas/[slug]` pages)
- FAQ items
- Events list
- Featured review snippets

## Routes

- `/` Home hub
- `/services`
- `/events`
- `/community`
- `/contact`
- `/areas/[area]` dynamic local area pages
- `/admin/` Decap CMS

## Theme System

Theme selector is built into the shared layout and persists via `localStorage`.

Available themes:

- Ember
- Dark
- White
- Tavern
- Arcade

## Deployment

- Netlify: `netlify.toml`
- Vercel: `vercel.json`
- GitHub Pages: `.github/workflows/deploy-pages.yml`
