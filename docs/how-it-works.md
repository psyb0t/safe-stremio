---
title: "How it works"
description: "What runs inside the safe-stremio container: the run.sh start order, nginx routes, auth and rate limit, OpenVPN, the process watchdog and the LAN proxy."
nav_order: 4
---

# How it works

One container runs three processes: nginx, Stremio Server and, optionally, OpenVPN. The entrypoint [run.sh](https://github.com/psyb0t/safe-stremio/blob/master/run.sh) starts them in a fixed order, then watches them. If anything goes south, it stops everything and the container exits.

## What is in the image

The [Dockerfile](https://github.com/psyb0t/safe-stremio/blob/master/Dockerfile) starts from `stremio/server:v4.21.0`, which brings Node.js, ffmpeg and Stremio Server at `/stremio/server.js`. On top of that it installs nginx, OpenVPN, `apache2-utils` (for `htpasswd`) and curl, downloads the Stremio Web release zip into `/stremio-web`, and copies in the two nginx config files and `run.sh`. Everything runs as root.

## Start order

`run.sh` runs with `set -euo pipefail`. Right after the public IP lookup in step 1 it traps `SIGINT`, `SIGTERM` and `ERR`. From then on, any of them runs `cleanup`, which sends `SIGTERM` to nginx, OpenVPN and Stremio Server, logs `All processes have been stopped. Exiting.` and exits with status 1.

1. Fetch the public IP from `https://api.ipify.org` and remember it as the real IP. This happens on every start, VPN or not, and before the trap is set. If the request fails, the script exits with curl's exit code and prints nothing.
2. With `WITH_OPENVPN=true`, start the public IP log in the background (see below).
3. Write `/etc/nginx/conf.d/auth.conf`. With both `USERNAME` and `PASSWORD` set, create `/etc/nginx/.htpasswd` with `htpasswd -bc` and turn on `auth_basic`. Otherwise leave the file empty.
4. Start nginx in the foreground mode (`daemon off`) as a background job.
5. With `WITH_OPENVPN=true`: create `/dev/net/tun` if it is missing, exit if `/vpn-config.ovpn` is missing, start OpenVPN (with `--auth-user-pass /vpn-auth.txt` when that file exists), and wait 10 seconds for the tunnel.
6. Start Stremio Server with `node /stremio/server.js`.
7. Start the process watchdog.

Stremio Server starts after the 10 second wait, so its first outbound requests go out once OpenVPN has had time to connect. Nothing checks that the tunnel is actually up by then.

## nginx

[nginx/nginx.conf](https://github.com/psyb0t/safe-stremio/blob/master/nginx/nginx.conf) defines the rate limit zone and hides the nginx version (`server_tokens off`). [nginx/default.conf](https://github.com/psyb0t/safe-stremio/blob/master/nginx/default.conf) has one server on port 80 with two locations:

- `/stremio-server/` removes the prefix and proxies to Stremio Server on `127.0.0.1:11470`. This is the URL you give Stremio Web as its streaming server.
- `/` serves the static Stremio Web build from `/stremio-web/build`, and answers unknown paths with `index.html` so the single-page app handles its own routes.

Both locations include `auth.conf` and apply `limit_req zone=one burst=10` on a zone of 1 request per second per client IP. Without `nodelay`, nginx queues requests over the rate and serves them at 1 per second. When the queue holds 10, the next request gets `503`.

## Process watchdog

A background loop checks once per second that nginx, Stremio Server and, when it was started, OpenVPN are still running. When one is gone, it logs `<name> has terminated unexpectedly.` (`Nginx`, `Stremio Server` or `OpenVPN`) and runs `cleanup`, so the container exits with status 1. With `restart: always` in Compose, Docker starts it again.

This is what protects you when OpenVPN dies: the container goes down with it, and Stremio Server stops instead of carrying on over your normal connection.

## Public IP log

With `WITH_OPENVPN=true`, a background loop fetches the public IP every 10 seconds and logs it as `Public IP: <address>`. Watch these lines to confirm that the address is your VPN's.

The loop was written to stop the container when the public IP equals the real IP from step 1 after OpenVPN started, logging `REAL IP EXPOSED!!!`. In the current `run.sh` that check never fires. The loop is a copy of the script forked in step 2, before OpenVPN starts, and it never sees the flag that says OpenVPN is up. It also stops for good, without a log line, the first time its IP request fails. Do not count on it as a kill switch. The process watchdog above and your OpenVPN config are what keep traffic in the tunnel; see [Security](security.md#vpn).

## The LAN proxy

With the VPN up, the container's default route points into the tunnel. A request from your LAN reaches the container, but the reply follows the default route into the VPN and never comes back. The `proxy` service in [docker-compose.yml](https://github.com/psyb0t/safe-stremio/blob/master/docker-compose.yml) fixes that: it is a plain `nginx:alpine` container outside the VPN that publishes `8080:80` and forwards everything to `safe-stremio:80` over the Docker network. Container-to-container traffic on that network does not go through the tunnel, so the replies make it back. It passes WebSocket upgrade headers and `X-Forwarded-*` headers along.

The proxy adds no auth or rate limit of its own. Those stay in the safe-stremio container.
