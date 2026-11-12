# safe-stremio

Instructions for AI coding agents (Codex, Claude Code and others) working in this repository. Human contributors can read it too; the user documentation is the site under `docs/`.

## Agent setup

`AGENTS.md` is the source of these instructions. `CLAUDE.md` is a committed symlink to `AGENTS.md`, and `.claude` is a committed symlink to `.agents`, so Claude Code reads the same instructions, rules and skills as Codex. Claude's Edit and Write tools refuse to write through a symlink, so edit `AGENTS.md` and `.agents/rules/*.md` directly.

## What it is

`psyb0t/safe-stremio` is a Docker image that runs Stremio Server and the Stremio Web UI in one container behind nginx. nginx adds optional HTTP basic auth and a per-IP rate limit, and an optional OpenVPN client sends the container's outbound traffic through a VPN. There is no application code of its own: the repository is a `Dockerfile`, two nginx config files, the `run.sh` entrypoint and a Compose example.

## Architecture

- `Dockerfile` starts `FROM stremio/server:v4.21.0` (Node.js Stremio Server at `/stremio/server.js`, listening on 11470), installs nginx, OpenVPN, `apache2-utils` (for `htpasswd`) and curl with apt, and unzips the Stremio Web release named by the `STREMIO_WEB_VERSION` build argument (default `v5.0.0-beta.38`) into `/stremio-web`, so the static UI ends up in `/stremio-web/build`. It exposes port 80 and sets `/run.sh` as the entrypoint. The container runs as root.
- `run.sh` runs with `set -euo pipefail` and installs `trap cleanup SIGINT SIGTERM ERR` after the first IP lookup. In order it:
  1. fetches the public IP from `https://api.ipify.org` into `REAL_IP`, before the trap is installed, so a failed fetch exits through `set -e` with curl's code (6 for DNS, 7 for connect) and no log line;
  2. when `WITH_OPENVPN=true`, starts `monitor_ip` in the background, which logs the public IP every 10 seconds;
  3. writes `/etc/nginx/conf.d/auth.conf`: empty, or, when both `USERNAME` and `PASSWORD` are set, an `auth_basic` block pointing at `/etc/nginx/.htpasswd` created with `htpasswd -bc`;
  4. starts `nginx -g 'daemon off;'`;
  5. when `WITH_OPENVPN=true`, creates `/dev/net/tun` if missing, exits if `/vpn-config.ovpn` is missing, starts `openvpn --config /vpn-config.ovpn`, adding `--auth-user-pass /vpn-auth.txt` when that file exists, then sleeps 10 seconds;
  6. starts `node /stremio/server.js`;
  7. runs a background loop that checks every second that nginx, Stremio Server and OpenVPN are alive and calls `cleanup` (stop everything, exit 1) when one is gone.
- `nginx/nginx.conf` defines the rate limit zone (`limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s`), turns `server_tokens` off and includes `/etc/nginx/sites/*.conf`.
- `nginx/default.conf` (installed as `/etc/nginx/sites/default.conf`) listens on 80. `/stremio-server/` strips the prefix and proxies to `http://127.0.0.1:11470`; `/` serves `/stremio-web/build` with an SPA fallback to `/index.html`. Both locations include `auth.conf` and apply `limit_req zone=one burst=10` (no `nodelay`, so excess requests queue and anything past the burst gets 503).
- `docker-compose.yml` runs the image without published ports plus an `nginx:alpine` proxy service that publishes `8080:80` and forwards to `safe-stremio:80`. The proxy exists because with the VPN up, replies to LAN clients would leave through the tunnel.

Request flow: client -> (Compose proxy :8080) -> nginx :80 -> static UI from `/stremio-web/build`, or `/stremio-server/*` -> Stremio Server :11470.

## Known landmines

- `monitor_ip` runs in a background subshell started before OpenVPN, so it keeps its own copy of `OPENVPN_STARTED=0` and of the unset PIDs. The "REAL IP EXPOSED" branch can never fire, and if it did, `cleanup` in the subshell would stop nothing. A failed `curl` inside it ends the subshell silently through `set -e` (the ERR trap is not inherited). The process watchdog in step 7 is what stops the container when OpenVPN exits. Do not describe the IP check as a working kill switch in docs; fixing it is a behavior change that needs the owner's go.
- `get_public_ip` uses `curl -s` with no timeout and no `-f`, so a hung request blocks startup and an HTTP error body is taken as the IP.
- The rate limit is keyed on the client address nginx sees. Behind the Compose proxy every client has the proxy's address, so all clients share one bucket.
- `/root/.stremio-server` is a volume declared by the base image (Stremio Server settings and cache). Without a named volume it is an anonymous volume per container.
- The README is mirrored to Docker Hub by the image workflow, so README links must be full URLs.

## Stack

- Base image `stremio/server:v4.21.0` (Debian, Node.js 14.21.3, jellyfin-ffmpeg). Stremio Web from the GitHub release zip.
- nginx, OpenVPN and `apache2-utils` from the base image's apt repositories, unpinned.
- Bash for `run.sh` and `scripts/smoke-test.sh`.
- Images for `linux/amd64` and `linux/arm64`, published to Docker Hub as `psyb0t/safe-stremio`.
- Docs: Jekyll with the just-the-docs remote theme, built by GitHub Pages from `docs/` on `master`.

## Layout

| Path | Contents |
| --- | --- |
| `Dockerfile` | The image. |
| `run.sh` | Entrypoint: auth setup, process start order, watchdog, IP logging. |
| `nginx/nginx.conf` | Main nginx config: rate limit zone, `server_tokens off`. |
| `nginx/default.conf` | The server block: UI, `/stremio-server/` proxy, auth include, rate limit. |
| `docker-compose.yml` | Example deployment with the LAN proxy. |
| `scripts/smoke-test.sh` | Container smoke test run by `make test`. |
| `Makefile` | Lint, test, build and docs targets. |
| `docs/` | The documentation site, published at https://psyb0t.github.io/safe-stremio/. |
| `.agents/rules/` | Rules for every change, loaded every session. |
| `.agents/rule-details/` | Area rules, read before touching the paths listed under Rules. |
| `.github/workflows/pipeline.yml` | CI: lint and smoke test, image build, tag promotion, release, badges. |
| `.github/workflows/mirror-and-archive.yml`, `issue-pull.yml`, `collaborators-only.yml` | Mirroring and archiving, issue sync from the mirrors, and closing pull requests from non-collaborators. Not part of the build. |
| `openvpn/` | Local VPN config and credentials. Gitignored; never commit or read it. |

## Commands

Docker and Make are enough for everything.

```bash
make help    # every target
make lint    # shellcheck + shfmt -i 4 -d + actionlint, in pinned containers
make test    # build safe-stremio:test and run scripts/smoke-test.sh (needs internet)
make build   # build psyb0t/safe-stremio:latest
make format  # shfmt -i 4 -w on the shell scripts
make docs    # build the site into .testing/docs-site
```

## Rules

Rules for every change: `.agents/rules/` (loaded every session). Area rules live in `.agents/rule-details/`; read the matching file before touching its paths:

| File | Read before touching |
| --- | --- |
| `.agents/rule-details/docker-image.md` | `Dockerfile`, `nginx/`, `docker-compose.yml` |
| `.agents/rule-details/shell-style.md` | `run.sh`, `scripts/*.sh` |
| `.agents/rule-details/testing.md` | `scripts/smoke-test.sh`, `Makefile` test targets |
| `.agents/rule-details/ci.md` | `.github/workflows/` |
| `.agents/rule-details/docs-and-releases.md` | `README.md`, `docs/`, `CHANGELOG.md`, release tags |
