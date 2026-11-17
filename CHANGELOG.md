# Changelog

Each entry lists breaking changes first. Deployers: read the entry before you apply an update.

## 2026-11-17: Morphic v1.10.0

First release of the template.

- Morphic `v1.10.0` (`ghcr.io/miurla/morphic:ad418f16c5202a5d214eeaefb0293ed89d43720f@sha256:9701c15fb8a3e6cdff8bebf01386b9120db67adaf7c53ad8061ba4f57e9dd9fb`), with built-in Better Auth accounts, invite-only sign-up and the first account limited to `BOOTSTRAP_ADMIN_EMAIL`.
- SearXNG `2026.11.17-b99cf7496` (`ghcr.io/searxng/searxng@sha256:0b9f3ddd85efc8df189e6543d65702abfa8f3ed1c32229a53f7707cd12b554ef`), private, with `settings.yml` on a volume.
- Railway's Postgres and Redis.
- `/api/advanced-search` is not reachable from outside the Morphic container.
