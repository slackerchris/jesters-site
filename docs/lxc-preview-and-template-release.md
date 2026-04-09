# LXC Preview and Template Release Workflow

This workflow gives you two outcomes:

- Run the current customer site in your local LXC Docker host for review.
- Publish a reusable template repository on GitHub.

## Part A: Run current site in local LXC Docker

## 1) Start preview stack

From repository root:

~~~bash
npm run preview:docker:up
~~~

This builds the current site and serves it from Nginx in Docker.

Default URL:

- http://localhost:8080

If your customer is on your LAN, share:

- http://<lxc-ip>:8080

## 2) Stop preview stack

~~~bash
npm run preview:docker:down
~~~

## 3) Optional preview port change

Edit [deploy/preview/.env.example](deploy/preview/.env.example) or copy to deploy/preview/.env and set:

~~~text
PREVIEW_PORT=8090
~~~

## Part B: Push your current customer site to GitHub

Commit and push your current project state:

~~~bash
git add .
git commit -m "Add customer-ready docker preview and template workflow"
git push origin main
~~~

## Part C: Publish a reusable template repository

Recommended approach: separate template repo.

## 1) Create a clean template branch

~~~bash
git checkout -b template-base
npm run new:client -- --name "Business Name" --slug "main" --locations 1 --website "example.com" --facebook "facebook.com"
git add .
git commit -m "Create generic reusable template baseline"
~~~

## 2) Push to a new GitHub repository

Example:

~~~bash
git remote add template https://github.com/<your-user>/local-store-template.git
git push template template-base:main
~~~

Then in GitHub repo settings for local-store-template:

- Enable Template repository

Now each new customer starts from Use this template.

## Part D: New customer onboarding from template

For each customer repository:

1. Run bootstrap with customer details.
2. Run docker preview and send review URL.
3. Deploy Payload stack from deploy/payload.
4. Set PAYLOAD_API_URL and PAYLOAD_ADMIN_URL in frontend hosting.

Bootstrap example:

~~~bash
npm run new:client -- --name "Acme Games" --slug "main" --locations 1 --domain "acmegames.com" --cms-domain "cms.acmegames.com"
~~~
