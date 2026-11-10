---
title: "Getting started"
description: "Run safe-stremio with Docker Compose or docker run, with or without OpenVPN, and point Stremio Web at the self-hosted streaming server."
nav_order: 2
---

# Getting started

This page takes you from nothing to a working Stremio Web UI that talks to your own Stremio Server. You need Docker, and for the VPN route an OpenVPN config from your provider.

## 1. Pull the image

```sh
docker pull psyb0t/safe-stremio:latest
```

The image is built for `linux/amd64` and `linux/arm64`. The available tags are listed in [Configuration](configuration.md#image-tags).

## 2. Put the VPN files in place

Skip this step if you run without the VPN.

```text
openvpn/
├── config.ovpn   your provider's OpenVPN config
└── auth.txt      optional: username on line 1, password on line 2
```

The container reads them as `/vpn-config.ovpn` and `/vpn-auth.txt`. `auth.txt` is passed to OpenVPN with `--auth-user-pass` only when it exists.

## 3. Start it with Docker Compose

This is the [docker-compose.yml](https://github.com/psyb0t/safe-stremio/blob/master/docker-compose.yml) from the repository. Change `USERNAME` and `PASSWORD` before you start it.

```yaml
services:
  safe-stremio:
    image: psyb0t/safe-stremio:latest
    cap_add:
      - NET_ADMIN
    environment:
      - WITH_OPENVPN=true
      - USERNAME=user
      - PASSWORD=pass
    volumes:
      - ./openvpn/config.ovpn:/vpn-config.ovpn
      - ./openvpn/auth.txt:/vpn-auth.txt
    restart: always

  # Proxy for LAN/external access.
  # When VPN is enabled, the safe-stremio container routes all traffic through
  # the VPN tunnel. This breaks LAN access because responses to incoming LAN
  # requests try to route back through the VPN instead of the local network.
  # This proxy runs outside the VPN container but on the same Docker network,
  # so container-to-container traffic bypasses VPN routing entirely.
  proxy:
    image: nginx:alpine
    ports:
      - "8080:80"
    configs:
      - source: proxy_conf
        target: /etc/nginx/nginx.conf
    depends_on:
      - safe-stremio
    restart: always

configs:
  proxy_conf:
    content: |
      events {
          worker_connections 1024;
      }
      http {
          server {
              listen 80;
              location / {
                  proxy_pass http://safe-stremio:80;
                  proxy_http_version 1.1;
                  proxy_set_header Host $$host;
                  proxy_set_header Upgrade $$http_upgrade;
                  proxy_set_header Connection "upgrade";
                  proxy_set_header X-Real-IP $$remote_addr;
                  proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $$scheme;
              }
          }
      }
```

```sh
docker compose up -d
docker compose logs -f safe-stremio
```

The `configs.content` block needs a Docker Compose version that supports inline config content. The `$$` doubles stop Compose from reading `$host` and friends as its own variables.

Without the VPN, drop `cap_add`, the `volumes` and `WITH_OPENVPN`. You can then also drop the proxy service and publish the port on safe-stremio itself with `ports: ["8080:80"]`.

## 3b. Or start it with docker run

The same setup without Compose: one network, the safe-stremio container, and the proxy.

```sh
docker network create stremio-net

docker run -d \
  --name safe-stremio \
  --network stremio-net \
  --cap-add=NET_ADMIN \
  -e WITH_OPENVPN=true \
  -e USERNAME=user \
  -e PASSWORD=pass \
  -v "$(pwd)/openvpn/config.ovpn:/vpn-config.ovpn" \
  -v "$(pwd)/openvpn/auth.txt:/vpn-auth.txt" \
  --restart always \
  psyb0t/safe-stremio:latest
```

Write the proxy config:

```sh
cat > proxy.conf <<'EOF'
events {
    worker_connections 1024;
}
http {
    server {
        listen 80;
        location / {
            proxy_pass http://safe-stremio:80;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF
```

Run the proxy:

```sh
docker run -d \
  --name stremio-proxy \
  --network stremio-net \
  -p 8080:80 \
  -v "$(pwd)/proxy.conf:/etc/nginx/nginx.conf:ro" \
  --restart always \
  nginx:alpine
```

## 4. Check the logs

A healthy start without the VPN looks like this (the Stremio Server lines vary by version):

```text
2026-11-10 07:29:13 Setting up HTTP basic authentication...
Adding password for user user
2026-11-10 07:29:14 Starting Nginx...
OpenVPN will not be started.
2026-11-10 07:29:14 Starting Stremio Server
...
EngineFS server started at http://127.0.0.1:11470
```

With `WITH_OPENVPN=true` you also get `Starting OpenVPN...`, OpenVPN's own output, and a `Public IP: ...` line every 10 seconds. Check that the IP it prints is your VPN's, not yours.

## 5. Point Stremio Web at your server

Open `http://yourdomain:8080` and log in with your username and password. Go to Settings, and under Streaming set the server URL to:

```text
http://yourdomain:8080/stremio-server/
```

Keep the trailing slash. Until you set this, Stremio Web looks for a streaming server on its default address and shows "Streaming Server is not available". Now you're ready to stream like a true digital pirate.

## Next

- Every variable and file: [Configuration](configuration.md).
- What runs inside the container: [How it works](how-it-works.md).
- Before you open the port to the internet: [Security](security.md).
