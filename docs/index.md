---
title: "Home"
description: "safe-stremio runs Stremio Server and Stremio Web in one Docker container behind nginx, with optional basic auth, a rate limit and an OpenVPN client."
nav_order: 1
permalink: /
seo:
  type: WebSite
---

# Safe-Stremio: Your Secure, Pirate-Friendly Streaming Solution

safe-stremio runs [Stremio Server](https://hub.docker.com/r/stremio/server) and the [Stremio Web](https://github.com/stremio/stremio-web) UI in one Docker container, behind nginx. Your server, your rules. nginx puts HTTP basic auth and a per-IP rate limit in front of both, and an optional OpenVPN client sends the container's traffic through your VPN so your real IP stays out of it.

```text
browser
  │  http://yourdomain:8080
  ▼
proxy container (nginx:alpine, publishes 8080)    only needed for LAN access with the VPN on
  │
  ▼
safe-stremio container, port 80
  nginx: basic auth + 1 request/s per IP, burst 10
    ├─ /                  Stremio Web static files
    └─ /stremio-server/   Stremio Server on 127.0.0.1:11470
  OpenVPN (optional): outbound traffic through your VPN
```

## Quick start

```sh
docker pull psyb0t/safe-stremio:latest
```

Grab [docker-compose.yml](https://github.com/psyb0t/safe-stremio/blob/master/docker-compose.yml), put your OpenVPN config in `./openvpn/config.ovpn`, change the username and password, and start it:

```sh
docker compose up -d
```

Open `http://yourdomain:8080`, log in, and set the streaming server URL in Stremio Web to `http://yourdomain:8080/stremio-server/`. [Getting started](getting-started.md) has every step, including a run without the VPN.

## Where to go next

| You want to | Read |
| --- | --- |
| Go from nothing to streaming | [Getting started](getting-started.md) |
| Know every environment variable, file, port and volume | [Configuration](configuration.md) |
| Understand the startup order, nginx routes and the watchdog | [How it works](how-it-works.md) |
| Know what is protected and what is not | [Security](security.md) |
| Fix "Streaming Server is not available" or a container that keeps exiting | [Troubleshooting](troubleshooting.md) |
| Build, lint and test the image, or cut a release | [Development](development.md) |
