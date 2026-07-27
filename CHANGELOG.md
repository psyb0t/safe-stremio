# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v0.2.2 — 2026-07-27

Upstream version refresh.

- Upgrade Stremio server `v4.20.16` → `v4.21.0` (base image `stremio/server`).
- Upgrade Stremio Web `v5.0.0-beta.29` → `v5.0.0-beta.38` (`STREMIO_WEB_VERSION`
  build arg in the Dockerfile).
- No changes to `run.sh`, nginx config, or the OpenVPN kill-switch behavior —
  the container serves the newer static Stremio Web build and runs the newer
  server unchanged. Image builds clean and boots (nginx + server) verified.

## v0.2.1 — 2026-01-12

- Remove the `proxy.conf` dependency.

## v0.2.0 — 2026-01-12

LAN Party Edition.

- Add nginx proxy for LAN/external access when VPN is enabled.
- Upgrade Stremio server `v4.20.8` → `v4.20.16`.
- Upgrade Stremio Web `v5.0.0-beta.8` → `v5.0.0-beta.29`.

## v0.1.0 — 2024-05-24

Initial release.
