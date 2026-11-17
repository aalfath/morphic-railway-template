# SearXNG for Morphic on Railway: the official image, pinned by version and
# digest, plus a start script that writes a settings.yml with JSON output
# (which Morphic needs) on first boot.
FROM ghcr.io/searxng/searxng:2026.11.17-b99cf7496@sha256:0b9f3ddd85efc8df189e6543d65702abfa8f3ed1c32229a53f7707cd12b554ef

COPY railway-start.sh /usr/local/searxng/railway-start.sh
RUN chmod 0755 /usr/local/searxng/railway-start.sh

ENTRYPOINT ["/usr/local/searxng/railway-start.sh"]
