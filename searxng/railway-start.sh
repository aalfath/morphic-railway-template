#!/bin/sh
# Writes settings.yml on first boot only (the volume at /etc/searxng keeps it,
# so later edits are never overwritten), then hands over to the upstream
# entrypoint.
set -eu

conf_dir="${__SEARXNG_CONFIG_PATH:-/etc/searxng}"
settings="$conf_dir/settings.yml"

# Railway injects PORT; the upstream image listens on GRANIAN_PORT (8080).
if [ -n "${PORT:-}" ]; then
    export GRANIAN_PORT="$PORT"
fi

# A Railway service named "searxng" could leak a non-numeric SEARXNG_PORT.
case "${SEARXNG_PORT:-}" in
    *[!0-9]*) unset SEARXNG_PORT ;;
esac

[ -n "${SEARXNG_SECRET:-}" ] || { echo "railway-start: SEARXNG_SECRET is not set" >&2; exit 1; }

mkdir -p "$conf_dir"
if [ ! -f "$settings" ]; then
    echo "railway-start: creating $settings (JSON output enabled)"
    cat > "$settings" <<'YAML'
# Created by the Morphic Railway template on first boot. Edit freely: it is
# kept on the volume and never overwritten. Full reference:
# https://docs.searxng.org/admin/settings/index.html
use_default_settings: true

# general.contact_url (needed by Wikipedia, Wikidata and OpenStreetMap) comes
# from the SEARXNG_CONTACT_URL variable; the template sets Morphic's public URL.

server:
  # The secret key comes from the SEARXNG_SECRET variable.
  # Private service: only Morphic reaches it, so the bot limiter stays off.
  limiter: false
  public_instance: false
  image_proxy: false
  method: "GET"

search:
  formats:
    - html
    - json
YAML
fi

exec /usr/local/searxng/entrypoint.sh "$@"
