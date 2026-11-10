---
title: "Configuration"
description: "Every safe-stremio setting: WITH_OPENVPN, USERNAME and PASSWORD, the VPN config and auth files, port 80, the data volume, build args and image tags."
nav_order: 3
---

# Configuration

safe-stremio is configured with three environment variables and two optional files. Everything else is fixed in the image. All of it is read by the entrypoint, [run.sh](https://github.com/psyb0t/safe-stremio/blob/master/run.sh), once at start, so a change needs a container restart.

## Environment variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `WITH_OPENVPN` | unset | `true` starts OpenVPN and the public IP log. Any other value, or unset, runs without the VPN. Needs `--cap-add=NET_ADMIN`. |
| `USERNAME` | unset | HTTP basic auth user name. |
| `PASSWORD` | unset | HTTP basic auth password. |

Basic auth turns on only when both `USERNAME` and `PASSWORD` are set and not empty. With either one missing, the container logs `No HTTP basic authentication will be used.` and the UI and the server are open to anyone who can reach the port. There is one user; there is no way to add more.

The base image `stremio/server` also sets `APP_PATH`, `NO_CORS`, `CASTING_DISABLED=1`, `FFMPEG_BIN` and `FFPROBE_BIN`. safe-stremio does not change or read them; they belong to Stremio Server.

## VPN files

| Path in the container | Required | Meaning |
| --- | --- | --- |
| `/vpn-config.ovpn` | when `WITH_OPENVPN=true` | The OpenVPN config, passed as `openvpn --config /vpn-config.ovpn`. Without it the container logs `OpenVPN configuration file not found: /vpn-config.ovpn` and exits. |
| `/vpn-auth.txt` | no | Username on line 1, password on line 2. Added as `--auth-user-pass /vpn-auth.txt` only when the file exists. |

Mount them read-only if you like (`:ro`); the container only reads them. When `/dev/net/tun` does not exist in the container, `run.sh` creates it with `mknod`.

## Port

nginx listens on port 80 inside the container, and that is the only port to publish. Map it to whatever you want on the host, such as `8080:80`. Stremio Server listens on 11470 (and its HTTPS endpoint on 12470) inside the container; do not publish those, because they skip the auth and the rate limit.

| Path | Goes to |
| --- | --- |
| `/` | Stremio Web static files from `/stremio-web/build`. Unknown paths fall back to `/index.html`. |
| `/stremio-server/` | Stremio Server at `http://127.0.0.1:11470`, with the `/stremio-server` prefix removed. |

## Rate limit

Both paths share one limit: 1 request per second per client IP, with a burst of 10. Requests over the rate wait in the burst queue; once 10 are waiting, nginx answers the rest with `503`. The limit is set in [nginx/nginx.conf](https://github.com/psyb0t/safe-stremio/blob/master/nginx/nginx.conf) and [nginx/default.conf](https://github.com/psyb0t/safe-stremio/blob/master/nginx/default.conf) and has no environment variable. Behind the Compose proxy every client has the proxy's IP, so they all share one bucket.

## Data volume

The base image declares `/root/.stremio-server` as a volume. Stremio Server keeps its settings (`server-settings.json`) and its `downloads` directory there. Without a mount, Docker creates an anonymous volume per container, so settings changed in the Stremio Web UI are gone when the container is recreated. To keep them, mount a named volume:

```yaml
services:
  safe-stremio:
    volumes:
      - stremio-data:/root/.stremio-server

volumes:
  stremio-data:
```

## Build argument

| Argument | Default | Meaning |
| --- | --- | --- |
| `STREMIO_WEB_VERSION` | `v5.0.0-beta.38` | The [Stremio Web release](https://github.com/stremio/stremio-web/releases) whose `stremio-web.zip` is baked into the image. |

```sh
docker build \
  --build-arg STREMIO_WEB_VERSION=v5.0.0-beta.38 \
  -t safe-stremio .
```

The Stremio Server version is the base image tag in the [Dockerfile](https://github.com/psyb0t/safe-stremio/blob/master/Dockerfile), currently `stremio/server:v4.21.0`.

## Image tags

| Tag | What it is |
| --- | --- |
| `latest` | The newest build of `master`. |
| `sha-<commit>` | The build of one `master` commit. |
| `vX.Y.Z` | A release, the same image as the `sha-<commit>` of the tagged commit. |

Releases are listed on [GitHub](https://github.com/psyb0t/safe-stremio/releases) and in the [CHANGELOG](https://github.com/psyb0t/safe-stremio/blob/master/CHANGELOG.md).
