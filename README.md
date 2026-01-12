# Safe-Stremio: Your Secure, Pirate-Friendly Streaming Solution

Welcome to the future of secure, decentralized streaming! Safe-Stremio is your gateway to running Stremio Server and Stremio Web within a Docker container, wrapped in layers of security, anonymity, and badassery. This ain't your grandma's streaming setup—this is for digital pirates and cyberpunks who value privacy and control.

**Note:** If you encounter the "Streaming Server is not available" error, make sure to check the [Final Steps](#final-steps) section for instructions on how to resolve it.

## Table of Contents

1. [Features](#features)
2. [Get Up and Running](#get-up-and-running)
   - [Docker Pull Command](#docker-pull-command)
   - [Example Docker Compose](#example-docker-compose)
   - [Basic Docker Run Command](#basic-docker-run-command)
3. [Configuration](#configuration)
   - [OpenVPN Setup](#openvpn-setup)
   - [Environment Variables](#environment-variables)
   - [Ports](#ports)
4. [Final Steps](#final-steps)
5. [Nginx Configuration](#nginx-configuration)
6. [Logging and Monitoring](#logging-and-monitoring)
7. [Entrypoint Script: run.sh](#entrypoint-script-runsh)
8. [License](#license)

## Features

- **Basic Authentication:** Protect your streaming kingdom with simple but effective access control.
- **Rate Limiting:** Keep the brute force attacks at bay. Ain't nobody breaking in here!
- **VPN Integration:** Your IP is your identity—keep it hidden from the prying eyes of the net with seamless OpenVPN integration.
- **Self-Hosted Awesomeness:** Your server, your rules. Stream what you want, when you want.

## Get Up and Running

### Docker Pull Command

```sh
docker pull psyb0t/safe-stremio:latest
```

### Example Docker Compose

Spin up your secure streaming fortress with the following Docker Compose file:

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
  # the VPN tunnel. This breaks LAN access because responses to incoming
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
      events { worker_connections 1024; }
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

### Basic Docker Run Command

If you prefer running the containers without Docker Compose (why tho?), here's how:

```sh
# Create a network for the containers
docker network create stremio-net

# Run safe-stremio
docker run -d \
  --name safe-stremio \
  --network stremio-net \
  --cap-add=NET_ADMIN \
  -e WITH_OPENVPN=true \
  -e USERNAME=user \
  -e PASSWORD=pass \
  -v $(pwd)/openvpn/config.ovpn:/vpn-config.ovpn \
  -v $(pwd)/openvpn/auth.txt:/vpn-auth.txt \
  --restart always \
  psyb0t/safe-stremio:latest

# Create nginx proxy config
cat > /tmp/proxy.conf << 'EOF'
events { worker_connections 1024; }
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

# Run the proxy for LAN access
docker run -d \
  --name stremio-proxy \
  --network stremio-net \
  -p 8080:80 \
  -v /tmp/proxy.conf:/etc/nginx/nginx.conf:ro \
  --restart always \
  nginx:alpine
```

### Configuration

1. **OpenVPN Setup:**

   - Place your OpenVPN configuration file at `./openvpn/config.ovpn`.
   - If your VPN requires credentials, save them in `./openvpn/auth.txt`.

2. **Environment Variables:**

   - `WITH_OPENVPN=true`: Enable VPN for anonymous streaming.
   - `USERNAME` and `PASSWORD`: Set these for HTTP basic authentication.

3. **Ports:**
   - The container exposes port 80. Map it to any port on your host, e.g., `8080:80`.

### Final Steps

After firing up your container, head over to your Stremio Web UI and navigate to Settings. Under Streaming, set your server URL to `http://yourdomain:8080/stremio-server/`. This ensures your Stremio Web client talks to your self-hosted server. Now you're ready to stream like a true digital pirate.

## Nginx Configuration

Safe-Stremio comes pre-configured with Nginx to handle HTTP requests, including:

- **Proxying Requests:** Routes `/stremio-server/` to the Stremio server.
- **Serving Static Files:** Direct access to the Stremio Web UI.
- **Auth and Rate Limiting:** Only legit users allowed. No spamming!

## Logging and Monitoring

The container continuously monitors public IP and running processes. If your VPN drops, the container shuts down to prevent exposing your real IP. Logs are your friend; they tell you exactly what's happening.

## Entrypoint Script: run.sh

The entrypoint script orchestrates everything, ensuring all services start correctly and remain protected. If anything goes south, it gracefully shuts everything down.

## License

This project is licensed under the WTFPL. Do whatever the fuck you want.

Stay secure. Stay anonymous. Happy streaming!

---

This is **Safe-Stremio**—streaming for the free spirits of the digital age. Hack the planet, one stream at a time.
