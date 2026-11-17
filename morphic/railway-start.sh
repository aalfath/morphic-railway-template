#!/bin/sh
# Start script for Morphic on Railway.
# - Sets the defaults this template relies on (each can be overridden by a
#   service variable of the same name).
# - Runs upstream's entrypoint, which applies the database migrations, then
#   starts server.mjs: Next.js on 127.0.0.1 behind a small front proxy on $PORT.
set -eu

# Built-in accounts (Better Auth) stored in Morphic's own Postgres.
export AUTH_PROVIDER="${AUTH_PROVIDER:-better-auth}"
# invite: after the first (admin) account, new accounts need an invitation
# that the admin creates on /auth/admin. Set to "open" for public sign-up.
export AUTH_SIGNUP_MODE="${AUTH_SIGNUP_MODE:-invite}"
# Search through the bundled SearXNG service, no search API key needed.
export SEARCH_API="${SEARCH_API:-searxng}"
# Railway's Postgres is reached over the private network without TLS.
export DATABASE_SSL_DISABLED="${DATABASE_SSL_DISABLED:-true}"
export MORPHIC_CLOUD_DEPLOYMENT="${MORPHIC_CLOUD_DEPLOYMENT:-false}"
export NEXT_TELEMETRY_DISABLED=1
export PORT="${PORT:-3000}"
export MORPHIC_INTERNAL_PORT="${MORPHIC_INTERNAL_PORT:-3001}"

# Morphic calls its own /api/advanced-search route for deep SearXNG searches.
# That route has no login check, so the front proxy refuses it from outside,
# and the app reaches it directly on the internal port instead.
unset NEXT_PUBLIC_BASE_URL
export BASE_URL="http://127.0.0.1:${MORPHIC_INTERNAL_PORT}"

# Better Auth would otherwise take BASE_URL as its public origin. Use the
# deployment's public URL: BETTER_AUTH_URL if set (needed for a custom
# domain), else the Railway domain Railway provides.
if [ -z "${BETTER_AUTH_URL:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export BETTER_AUTH_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi

fail() {
  echo "railway-start: $*" >&2
  exit 1
}

[ -n "${DATABASE_URL:-}" ] || fail "DATABASE_URL is not set. Reference your Postgres service, e.g. \${{Postgres.DATABASE_URL}}."
if [ "$AUTH_PROVIDER" = "better-auth" ]; then
  secret="${BETTER_AUTH_SECRET:-}"
  [ "${#secret}" -ge 32 ] || fail "BETTER_AUTH_SECRET must be set to a random value of at least 32 characters."
  [ -n "${BETTER_AUTH_URL:-}" ] || fail "BETTER_AUTH_URL is not set and the service has no Railway domain. Generate a domain or set BETTER_AUTH_URL to https://YOUR-DOMAIN."
fi
if [ "$AUTH_SIGNUP_MODE" = "invite" ] && [ -z "${BOOTSTRAP_ADMIN_EMAIL:-}" ]; then
  echo "railway-start: warning: BOOTSTRAP_ADMIN_EMAIL is empty, so nobody can create the first account in invite mode." >&2
fi

exec /app/docker-entrypoint.sh node /app/railway/server.mjs
