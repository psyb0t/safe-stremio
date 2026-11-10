---
title: "Troubleshooting"
description: "Fixes for safe-stremio failures: Streaming Server is not available, a container that exits on start, OpenVPN errors, 401 and 503 answers, no LAN access."
nav_order: 6
---

# Troubleshooting

Start with the logs: `docker compose logs safe-stremio`, or `docker logs safe-stremio`. `run.sh` prefixes its own lines with a timestamp; the rest comes from nginx, OpenVPN and Stremio Server.

## "Streaming Server is not available" in Stremio Web

Stremio Web does not know where your server is yet. In Stremio Web, open Settings, and under Streaming set the server URL to `http://yourdomain:8080/stremio-server/`, with your host, your published port and the trailing slash. See [Getting started](getting-started.md#5-point-stremio-web-at-your-server).

If the URL is right and the error stays, check that the server answers through nginx:

```sh
curl -u user:pass http://yourdomain:8080/stremio-server/settings
```

A JSON answer means the server is fine and the URL in Stremio Web is wrong. `401` means wrong credentials. No answer at all means the container is down; read the logs.

## The container exits on start without a single log line

The first thing `run.sh` does is fetch the public IP from `https://api.ipify.org`, before it sets up its error handling. When that request fails, the script exits right there with curl's exit code and prints nothing. `docker ps -a` shows the code: `Exited (6)` means the name did not resolve, `Exited (7)` means the connection failed. Check that the container has outbound internet access and DNS, and that nothing blocks `api.ipify.org`. A request that hangs, instead of failing, blocks the start the same silent way, because it has no timeout.

## OpenVPN configuration file not found: /vpn-config.ovpn

`WITH_OPENVPN=true` is set but nothing is mounted at `/vpn-config.ovpn`. Check the volume path in your Compose file or `docker run` command. A missing source file in a bind mount makes Docker create an empty directory in its place, which fails the same check.

## OpenVPN has terminated unexpectedly.

OpenVPN started and then exited, and the watchdog stopped the container. The lines just above come from OpenVPN and name the reason. The usual ones:

- The container lacks `NET_ADMIN`. Add `cap_add: [NET_ADMIN]` or `--cap-add=NET_ADMIN`.
- Wrong VPN credentials, or a config that expects credentials when `/vpn-auth.txt` is not mounted. The file holds the username on line 1 and the password on line 2.
- The VPN server is unreachable or the config is broken. Test the same config with OpenVPN on the host.

## Nginx has terminated unexpectedly. / Stremio Server has terminated unexpectedly.

The named process exited and the watchdog stopped the container. Read the lines above for that process's own error. With `restart: always`, Docker restarts the container; a loop of restarts means the error comes back on every start.

## Every request asks for a password again, or answers 401

The username or password is wrong, or they changed. Auth uses the `USERNAME` and `PASSWORD` the container started with, so restart it after changing them. If you never set them, auth is off and you see no prompt at all.

## 503 Service Temporarily Unavailable

The rate limit rejected the request. nginx allows 1 request per second per client IP with 10 more queued; everything past that gets `503`. Behind the Compose proxy all clients share one IP, so one busy client can push others over the limit. Wait a few seconds and reload. The limit is fixed in [nginx/default.conf](https://github.com/psyb0t/safe-stremio/blob/master/nginx/default.conf); changing it means building your own image.

## Works from the host, not from other machines on the LAN

With the VPN on, replies to LAN clients leave through the tunnel. Reach the container through the `proxy` service from [docker-compose.yml](https://github.com/psyb0t/safe-stremio/blob/master/docker-compose.yml) and publish the port on the proxy, not on safe-stremio. See [How it works](how-it-works.md#the-lan-proxy).

## Settings are gone after recreating the container

Stremio Server stores its settings in `/root/.stremio-server`, which is an anonymous volume unless you mount one. Mount a named volume there; see [Configuration](configuration.md#data-volume).

## The Public IP lines stopped

The IP log loop ends for good the first time its request to `api.ipify.org` fails, without a log line. The container keeps running. Restart it to get the log back. See [How it works](how-it-works.md#public-ip-log).
