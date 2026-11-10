---
title: "Security"
description: "What safe-stremio protects and what it does not: basic auth over HTTP, the per-IP rate limit, the VPN and its limits, root and NET_ADMIN, outbound calls."
nav_order: 5
---

# Security

safe-stremio puts a password and a rate limit in front of Stremio, and can push Stremio's traffic through a VPN. This page lists what that covers, what it does not, and what to set up before the port is reachable from the internet.

## Before you expose it

- Set both `USERNAME` and `PASSWORD`. With either one missing, auth is off and anyone who reaches the port gets the UI and the streaming server. See [Configuration](configuration.md#environment-variables).
- Put TLS in front. nginx in the container speaks plain HTTP on port 80, and basic auth sends the username and password on every request, base64-encoded, not encrypted. Over the internet, run it behind a reverse proxy that terminates HTTPS.
- Publish only port 80 of the container (or the proxy's port). Stremio Server's ports 11470 and 12470 skip both the auth and the rate limit.

## Basic auth

When both variables are set, `run.sh` writes the user to `/etc/nginx/.htpasswd` with `htpasswd -bc`, which stores an Apache MD5 (`$apr1$`) hash. There is one user. Both `/` and `/stremio-server/` require it. The password is an environment variable, so anyone who can run `docker inspect` on the container can read it.

## Rate limit

nginx allows 1 request per second per client IP, with a burst of 10 queued requests, on both paths. Past that it answers `503`. It slows down password guessing; it does not lock anyone out. Behind the Compose proxy every request comes from the proxy's IP, so the limit is shared by all clients instead of applied per client.

## VPN

With `WITH_OPENVPN=true`, OpenVPN runs inside the container with your config, and the container needs `NET_ADMIN`. Know what it does and does not do:

- If the OpenVPN process exits, the process watchdog stops the whole container within about a second, Stremio Server included. See [How it works](how-it-works.md#process-watchdog).
- If OpenVPN keeps running but the tunnel is down, for example while it reconnects, safe-stremio does nothing. The image adds no firewall rules. Whether traffic can leave outside the tunnel then depends on your `.ovpn` config.
- The public IP check does not stop the container in the current `run.sh`. It only logs the address every 10 seconds, and stops logging after its first failed request. See [How it works](how-it-works.md#public-ip-log).
- Stremio Server starts 10 seconds after OpenVPN, whether or not the tunnel is up by then.

Check the `Public IP: ...` log lines after every start.

## What the container reaches

- `https://api.ipify.org` once on every start, and every 10 seconds with the VPN on. With the VPN on, the startup request goes out before OpenVPN starts, so ipify sees your real IP once per start.
- Whatever Stremio Server and the addons you install in Stremio Web connect to.
- Your VPN server, with the VPN on.

## Privileges

The container runs every process as root. With the VPN on it also needs `NET_ADMIN`, and `run.sh` creates `/dev/net/tun` with `mknod` when it is missing. Do not run it with `--privileged`; `NET_ADMIN` is enough.

## Keep secrets out of Git

The repository ignores the `openvpn/` directory, so `config.ovpn` and `auth.txt` stay local. Keep it that way if you fork it, and keep real passwords out of committed Compose files.
