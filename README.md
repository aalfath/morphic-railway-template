[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/morphic?utm_medium=integration&utm_source=button&utm_campaign=morphic)

# Morphic on Railway

A Railway template for [Morphic](https://github.com/miurla/morphic), the open-source AI answer engine with a generative UI. It runs the official Morphic image with built-in accounts, a private SearXNG for web search, Postgres and Redis, so you only need a model key.

**Version:** Morphic `v1.10.0`: `ghcr.io/miurla/morphic:ad418f16c5202a5d214eeaefb0293ed89d43720f@sha256:9701c15fb8a3e6cdff8bebf01386b9120db67adaf7c53ad8061ba4f57e9dd9fb`. Upstream tags its images only by commit; this is the commit that `v1.10.0` points at.
SearXNG `2026.11.17-b99cf7496`: `ghcr.io/searxng/searxng@sha256:0b9f3ddd85efc8df189e6543d65702abfa8f3ed1c32229a53f7707cd12b554ef`.

## What it deploys

| Service | Source | Public | Storage |
|---|---|---|---|
| `Morphic` | `morphic/` in this repo | Railway domain, health check `/auth/login` | none (all data is in Postgres) |
| `SearXNG` | `searxng/` in this repo | private only, health check `/healthz` | volume at `/etc/searxng` (`settings.yml`) |
| `Postgres` | Railway's PostgreSQL | private | Railway volume |
| `Redis` | Railway's Redis | private | Railway volume |

- **Accounts:** Morphic's built-in Better Auth accounts, stored in Postgres. Sign-up is **invite-only**. Only the e-mail address you enter at deploy time (`BOOTSTRAP_ADMIN_EMAIL`) can create the first account, which becomes the admin. The admin then invites others from `/auth/admin`.
- **Search:** the bundled SearXNG, reached over Railway's private network, so no search API key is needed. On first boot its start script writes a `settings.yml` with JSON output (which Morphic needs) on the volume and never overwrites it afterwards.
- **Migrations:** the Morphic container applies its database migrations on every start, before it serves.
- **Hardening:** Morphic's `/api/advanced-search` route runs searches and crawls pages for any caller without a login. A small proxy in the Morphic container (`morphic/server.mjs`) answers 404 for it from outside, and Morphic calls it internally.

## Variables

`Morphic` service:

| Variable | Default | What it does |
|---|---|---|
| `BOOTSTRAP_ADMIN_EMAIL` | *(you enter it)* | Your e-mail address. Only this address can create the first account, which becomes the admin |
| `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GOOGLE_GENERATIVE_AI_API_KEY` | empty, optional | Model provider keys. Set at least one (here or later) |
| `OPENAI_COMPATIBLE_API_KEY`, `OPENAI_COMPATIBLE_API_BASE_URL` | empty, optional | Any OpenAI-compatible provider, for example OpenRouter (`https://openrouter.ai/api/v1`) or DeepSeek |
| `BETTER_AUTH_SECRET` | `${{secret(64,"abcdef0123456789")}}` | Signs sessions, generated at deploy time. Keep it stable |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Postgres connection |
| `LOCAL_REDIS_URL` | `${{Redis.REDIS_URL}}` | Redis cache for deep searches |
| `SEARXNG_API_URL` | `http://${{SearXNG.RAILWAY_PRIVATE_DOMAIN}}:8080` | The private SearXNG service |
| `PORT` | `3000` | Port the app listens on |

`SearXNG` service: `SEARXNG_SECRET` (generated), `SEARXNG_CONTACT_URL` (Morphic's public URL, which the Wikipedia and Wikidata engines require) and `PORT` (`8080`).

Fixed settings live in `morphic/railway-start.sh`, and any of them can be overridden with a service variable of the same name: `AUTH_PROVIDER=better-auth`, `AUTH_SIGNUP_MODE=invite` (set `open` to allow anyone to sign up), `SEARCH_API=searxng`, `DATABASE_SSL_DISABLED=true`. The public URL used by the auth code (`BETTER_AUTH_URL`) is the service's Railway domain. Set `BETTER_AUTH_URL=https://YOUR-DOMAIN` when you add a custom domain.

Optional features, all off until you set their variables on the `Morphic` service (see Morphic's [configuration guide](https://github.com/miurla/morphic/blob/v1.10.0/docs/CONFIGURATION.md)): `OLLAMA_BASE_URL` and `AI_GATEWAY_API_KEY` (more model providers), `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD` and `EMAIL_FROM` (password-reset and invitation e-mails), `OIDC_*` (single sign-on), `R2_*` / `S3_ENDPOINT` (file upload), `ENABLE_SHARE=true` (public chat links), and `TAVILY_API_KEY`, `BRAVE_SEARCH_API_KEY` or `JINA_API_KEY` (other search and extraction providers).

## After deploying

1. Open the `Morphic` service's domain and go to **Sign up**. Use the e-mail address you entered as `BOOTSTRAP_ADMIN_EMAIL` and choose a password. That account is the admin.
2. If you didn't enter a model key at deploy time, add one (for example `OPENAI_API_KEY`) to the `Morphic` service's variables. Railway redeploys it.
3. Pick the model in the model selector and ask a question.
4. To let others in, create invitation links on `/auth/admin`.

## Updates

When this repo's `main` moves to a newer Morphic or SearXNG pin, Railway shows deployers an "update available" notice, and each deployer chooses when to apply it. `CHANGELOG.md` lists every version, breaking changes first. Your data stays in Postgres and your SearXNG `settings.yml` stays on its volume. Morphic applies new database migrations on start.

## Local test

```sh
docker build -t morphic-railway ./morphic
docker build -t searxng-railway ./searxng
```

Run them with the variables above, a Postgres 17 and a Redis.

This is a community template and isn't affiliated with or endorsed by the Morphic or SearXNG projects. Morphic is licensed under Apache-2.0, SearXNG under AGPL-3.0.
