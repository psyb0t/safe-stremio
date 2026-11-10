# Security

Prefix: SEC.

- **SEC1:** Basic auth turns on only when both `USERNAME` and `PASSWORD` are set; otherwise `auth.conf` is empty and the UI and server are open. Keep that behavior documented in `docs/security.md` and `docs/configuration.md` if it is not changed.
- **SEC2:** Do not claim protection the code does not give. The public IP check in `run.sh` does not stop the container today (see `AGENTS.md`); the docs describe what the watchdog does, and the owner decides on any fix.
- **SEC3:** No real credentials, VPN configs or IP addresses in code, docs, tests or examples. Use placeholders such as `user` / `pass` and `yourdomain`. `openvpn/` is gitignored; never read or commit it.
- **SEC4:** Do not publish Stremio Server's ports or add a location that skips auth (IMG4, IMG6).
- **SEC5:** The smoke test uses throwaway credentials only and runs without the VPN, so it needs no secrets.
