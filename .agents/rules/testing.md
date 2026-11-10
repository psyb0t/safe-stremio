# Testing

Prefix: TEST.

- **TEST1:** `make test` builds `safe-stremio:test` and runs `scripts/smoke-test.sh`. It starts two containers without the VPN (one with basic auth, one without) and checks from inside them with `docker exec curl`: `nginx -t`, 401 and 200 for the UI and `/stremio-server/settings`, the SPA fallback, and 503 from the rate limit. It needs Docker and outbound internet, because `run.sh` fetches the public IP on start. No credentials, no published ports.
- **TEST2:** CI runs `make lint` and `make test` on every push. Both must stay green and must fail on a real error; never add `|| true` to them.
- **TEST3:** A change to `run.sh`, `nginx/` or the `Dockerfile` runs `make test` before it is done. A behavior change adds a check to `scripts/smoke-test.sh`.
- **TEST4:** The OpenVPN path needs `NET_ADMIN`, a real VPN config and credentials, so it is not covered by the smoke test. Test it by hand and say so in the change.
