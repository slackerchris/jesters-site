# Start-To-Finish Install Guide (LXC + Nginx Proxy Manager)

This guide is the simplest complete path from a fresh host to a working website + CMS.

Use this when:
- You have this repo on an LXC host
- You use Nginx Proxy Manager (NPM) for public HTTPS
- You want Payload CMS + Postgres running in Docker

## One Command Install

If your host already has Docker + Node 22.12.0+ installed, run:

~~~bash
cd ~/jesters-site
npm run install:all
~~~

If NPM runs on a different host and must reach Payload over LAN:

~~~bash
cd ~/jesters-site
PAYLOAD_BIND_IP=0.0.0.0 npm run install:all
~~~

The command will:
- install frontend deps if missing
- build frontend
- start preview container
- sync env files from root .env
- scaffold Payload app if missing
- start Payload + Postgres in NPM mode

## Single Env File (Recommended)

You can edit one file at repo root:

~~~bash
cd ~/jesters-site
cp .env.example .env
~~~

Then keep stack env files in sync with:

~~~bash
npm run env:sync
~~~

This updates:
- deploy/preview/.env
- deploy/payload/.env

---

## 1) Prerequisites on the host

Install these first:
- Docker Engine
- Docker Compose plugin
- curl
- openssl

Check:

~~~bash
docker --version
docker compose version
~~~

If Docker is not running:

~~~bash
sudo systemctl enable docker
sudo systemctl start docker
~~~

---

## 2) Install correct Node version (important)

This project requires Node 22.12.0+.

Install nvm and Node:

~~~bash
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 22.12.0
nvm alias default 22.12.0
nvm use 22.12.0
node -v
npm -v
~~~

---

## 3) Install frontend dependencies and verify build

From repo root:

~~~bash
cd ~/jesters-site
npm ci
npm run build
~~~

---

## 4) Run local preview (website only)

One command to build + start preview container:

~~~bash
npm run preview:docker:build-up
~~~

Find host IP:

~~~bash
hostname -I
~~~

Open on your LAN:

~~~text
http://<HOST_IP>:8080/
~~~

Stop preview when needed:

~~~bash
npm run preview:docker:down
~~~

---

## 5) Create Payload app code (one-time)

This repository includes Payload deployment scaffolding, but you still need the app source in deploy/payload/payload-app.

~~~bash
cd ~/jesters-site/deploy/payload/payload-app
npx create-payload-app@latest .
~~~

When prompted, choose Postgres.

---

## 6) Configure Payload environment

~~~bash
cd ~/jesters-site/deploy/payload
cp .env.example .env
openssl rand -base64 48
~~~

Edit root .env and set at least:
- PAYLOAD_API_URL
- PAYLOAD_ADMIN_URL
- CMS_DOMAIN
- LETSENCRYPT_EMAIL

Then sync stack env files:

~~~bash
npm run env:sync
~~~

---

## 7) Start CMS with Nginx Proxy Manager mode

This stack uses two files together:
- deploy/payload/docker-compose.yml (base services: payload + postgres + backup)
- deploy/payload/docker-compose.npm.yml (NPM-specific overrides)

### Option A: NPM on the same host as Payload

Use loopback bind (default, safest):

~~~bash
cd ~/jesters-site/deploy/payload
docker compose -f docker-compose.yml -f docker-compose.npm.yml up -d --build
~~~

### Option B: NPM on a different host

Expose Payload to LAN, then firewall it tightly:

~~~bash
cd ~/jesters-site/deploy/payload
PAYLOAD_BIND_IP=0.0.0.0 docker compose -f docker-compose.yml -f docker-compose.npm.yml up -d --build
~~~

If using UFW, only allow NPM host IP to port 3001.

---

## 8) Configure Nginx Proxy Manager

In NPM, create a Proxy Host:
- Domain Names: your CMS domain (example: cms.example.com)
- Scheme: http
- Forward Hostname/IP:
  - 127.0.0.1 if NPM and Payload are on same host
  - Payload host LAN IP if NPM is on a different host
- Forward Port: 3001
- Websockets Support: enabled

In SSL tab:
- Request a new SSL certificate
- Force SSL: enabled

Your CMS admin should load at:

~~~text
https://<CMS_DOMAIN>/admin
~~~

---

## 9) Wire frontend to CMS

Create/update root .env in repo root:

~~~bash
cd ~/jesters-site
cat > .env << 'EOF'
PAYLOAD_API_URL=https://<CMS_DOMAIN>
PAYLOAD_ADMIN_URL=https://<CMS_DOMAIN>/admin
EOF
~~~

Rebuild preview site:

~~~bash
npm run preview:docker:build-up
~~~

Now frontend pages fetch CMS location data from Payload.

---

## 10) Health checks and useful commands

Check CMS services:

~~~bash
cd ~/jesters-site/deploy/payload
docker compose -f docker-compose.yml -f docker-compose.npm.yml ps
docker compose -f docker-compose.yml -f docker-compose.npm.yml logs -f payload
~~~

Show merged services list:

~~~bash
docker compose -f docker-compose.yml -f docker-compose.npm.yml config --services
~~~

Expected services include:
- postgres
- payload
- postgres-backup

---

## 11) Common mistakes

- Running npm run build and expecting public hosting
  - Build only creates static files; it does not publish ports.
- Using old Node from apt
  - Use nvm + Node 22.12.0+.
- Running only docker-compose.npm.yml
  - Always run both compose files together.
- Forgetting DNS for CMS_DOMAIN
  - SSL cert issuance needs reachable DNS and port 80/443 path through NPM.

---

## 12) Quick recovery if something breaks

~~~bash
# Website preview reset
cd ~/jesters-site
npm run preview:docker:down
npm run preview:docker:build-up

# CMS reset (keeps data volumes)
cd ~/jesters-site/deploy/payload
docker compose -f docker-compose.yml -f docker-compose.npm.yml down
docker compose -f docker-compose.yml -f docker-compose.npm.yml up -d --build
~~~

If CMS build fails with npm ci lockfile mismatch inside payload-app:

~~~bash
cd ~/jesters-site/deploy/payload/payload-app
NPM_CONFIG_USERCONFIG=/dev/null npm install --no-audit --no-fund
NPM_CONFIG_USERCONFIG=/dev/null npm install --package-lock-only --ignore-scripts --no-audit --no-fund
cd ..
docker compose -f docker-compose.yml -f docker-compose.npm.yml build --no-cache payload
docker compose -f docker-compose.yml -f docker-compose.npm.yml up -d
~~~
