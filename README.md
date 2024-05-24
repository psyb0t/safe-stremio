# Safe-Stremio: Your Secure, Pirate-Friendly Streaming Solution

Welcome to the future of secure, decentralized streaming! Safe-Stremio is your gateway to running Stremio Server and Stremio Web within a Docker container, wrapped in layers of security, anonymity, and badassery. This ain't your grandma's streaming setup—this is for digital pirates and cyberpunks who value privacy and control.

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
version: "3.8"

services:
  safe-stremio:
    image: psyb0t/safe-stremio:latest
    cap_add:
      - NET_ADMIN
    environment:
      - WITH_OPENVPN=true
      - USERNAME=user
      - PASSWORD=pass
    ports:
      - "8080:80"
    volumes:
      - ./openvpn/config.ovpn:/vpn-config.ovpn
      - ./openvpn/auth.txt:/vpn-auth.txt
    restart: always
```

### Basic Docker Run Command

If you prefer running the container without Docker Compose, here's an example using basic Docker commands:

```sh
docker run -d \
  --cap-add=NET_ADMIN \
  -e WITH_OPENVPN=true \
  -e USERNAME=user \
  -e PASSWORD=pass \
  -p 8080:80 \
  -v $(pwd)/openvpn/config.ovpn:/vpn-config.ovpn \
  -v $(pwd)/openvpn/auth.txt:/vpn-auth.txt \
  --restart always \
  psyb0t/safe-stremio:latest
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
