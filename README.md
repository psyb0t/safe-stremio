# Safe-Stremio

**Your Secure, Pirate-Friendly Streaming Solution**

[![CI](https://github.com/psyb0t/safe-stremio/actions/workflows/pipeline.yml/badge.svg?branch=master)](https://github.com/psyb0t/safe-stremio/actions/workflows/pipeline.yml)
[![version](https://raw.githubusercontent.com/psyb0t/safe-stremio/badges/version.svg)](https://github.com/psyb0t/safe-stremio/releases)
[![license](https://raw.githubusercontent.com/psyb0t/safe-stremio/badges/license.svg)](https://github.com/psyb0t/safe-stremio/blob/master/LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/psyb0t/safe-stremio?style=flat-square)](https://hub.docker.com/r/psyb0t/safe-stremio)

safe-stremio runs Stremio Server and Stremio Web in one Docker container, behind nginx with a password, a rate limit and an optional OpenVPN client. This ain't your grandma's streaming setup. It's for digital pirates and cyberpunks who want privacy and control.

**Note:** If Stremio Web says "Streaming Server is not available", you skipped the last step. See [Point Stremio Web at your server](#point-stremio-web-at-your-server).

## Contents

1. [Features](#features)
2. [Quick start](#quick-start)
3. [Point Stremio Web at your server](#point-stremio-web-at-your-server)
4. [Documentation](#documentation)
5. [Development](#development)
6. [Sponsor](#sponsor)
7. [License](#license)

## Features

- **Basic auth:** nginx asks for one username and password on the UI and the streaming server.
- **Rate limiting:** 1 request per second per IP with a burst of 10. Brute force gets a wall of 503s.
- **VPN:** OpenVPN inside the container sends Stremio's traffic through your provider, and if OpenVPN dies, the container goes down with it.
- **Self-hosted:** your server, your rules. Stream what you want, when you want.

The VPN guard has a known gap: the public IP check in `run.sh` only logs the address and does not stop the container. The [security page](https://psyb0t.github.io/safe-stremio/security/#vpn) has the details. Read it before you trust the VPN with your IP.

## Quick start

```sh
docker pull psyb0t/safe-stremio:latest
```

Put your OpenVPN config in `./openvpn/config.ovpn` (and credentials, if your VPN needs them, in `./openvpn/auth.txt`, username on line 1, password on line 2). Grab [docker-compose.yml](https://github.com/psyb0t/safe-stremio/blob/master/docker-compose.yml), change `USERNAME` and `PASSWORD`, and spin it up:

```sh
docker compose up -d
```

The Compose file runs safe-stremio plus a small nginx proxy that publishes port 8080. You need the proxy for LAN access with the VPN on, because the container's replies would otherwise go out through the tunnel. Running without the VPN, or with plain `docker run`, is in [Getting started](https://psyb0t.github.io/safe-stremio/getting-started/).

## Point Stremio Web at your server

Open `http://yourdomain:8080`, log in, go to Settings, and under Streaming set the server URL to `http://yourdomain:8080/stremio-server/`. That makes Stremio Web talk to your self-hosted server. Now you're ready to stream like a true digital pirate.

## Documentation

The whole manual lives at **[psyb0t.github.io/safe-stremio](https://psyb0t.github.io/safe-stremio/)**.

| Page | What's in it |
| --- | --- |
| [Getting started](https://psyb0t.github.io/safe-stremio/getting-started/) | Compose and `docker run`, VPN files, logs, the server URL |
| [Configuration](https://psyb0t.github.io/safe-stremio/configuration/) | Environment variables, VPN files, ports, the data volume, image tags |
| [How it works](https://psyb0t.github.io/safe-stremio/how-it-works/) | Start order, nginx routes, the process watchdog, the LAN proxy |
| [Security](https://psyb0t.github.io/safe-stremio/security/) | What the auth, rate limit and VPN cover, and what they do not |
| [Troubleshooting](https://psyb0t.github.io/safe-stremio/troubleshooting/) | Every log message and error, and what to do about it |
| [Development](https://psyb0t.github.io/safe-stremio/development/) | Make targets, smoke test, CI and releases |

## Development

```sh
make lint   # shellcheck, shfmt and actionlint in Docker
make test   # build the image and run the container smoke test
make help   # everything else
```

## Sponsor

<a href="https://www.buymeacoffee.com/psyb0t"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me a Coffee" height="60" width="217"></a>

## License

This project is licensed under the [WTFPL](https://github.com/psyb0t/safe-stremio/blob/master/LICENSE). Do whatever the fuck you want. Release notes are in the [CHANGELOG](https://github.com/psyb0t/safe-stremio/blob/master/CHANGELOG.md).

Stay secure. Stay anonymous. Happy streaming! Hack the planet, one stream at a time.
