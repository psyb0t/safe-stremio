# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v0.2.5 — 2026-08-01

Infrastructure only. No changes to the image or its behavior.

- Mirror the repo to Codeberg alongside GitLab on every branch and tag push,
  and archive it to the Wayback Machine, Software Heritage and archive.org.
  Pull requests are switched off on both mirrors — they are force-pushed from
  GitHub, so anything merged there is destroyed by the next sync; issues and
  forking stay on.
- Pull issues opened on either mirror back into GitHub every six hours, and
  close them here when the original closes. The scheduled run jitters to avoid
  hammering both mirrors at the same minute; a manual run does not.
- Split the mirroring, archiving and issue-pull jobs out of `pipeline.yml` into
  their own workflow files.
- Added `.dockerignore` so the local scratch dir stays out of the build context.
- Ignore `CLAUDE.md`, a container-notes file written by local tooling and not a
  project artifact.

## v0.2.4 — 2026-07-27

- Added a GitHub Actions CI status badge to the README.

## v0.2.3 — 2026-07-27

- Added self-hosted version and license badges plus a Docker Hub pulls badge; wired a badges job into pipeline.yml.

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
