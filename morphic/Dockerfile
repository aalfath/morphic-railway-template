# Morphic for Railway: the official image of the v1.10.0 release, pinned by
# its commit tag and digest, plus a small wrapper (start script and a
# front proxy). Upstream publishes only commit-SHA tags and `latest`; this
# tag is the "bump version to 1.10.0" commit that v1.10.0 points at.
FROM ghcr.io/miurla/morphic:ad418f16c5202a5d214eeaefb0293ed89d43720f@sha256:9701c15fb8a3e6cdff8bebf01386b9120db67adaf7c53ad8061ba4f57e9dd9fb

COPY railway-start.sh server.mjs /app/railway/
RUN chmod 0755 /app/railway/railway-start.sh

EXPOSE 3000
ENTRYPOINT ["/app/railway/railway-start.sh"]
CMD []
