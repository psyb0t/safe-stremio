# Shell style

Prefix: SH. Covers `run.sh` and `scripts/*.sh`.

- **SH1:** Scripts start with `#!/bin/bash` and `set -euo pipefail`. `run.sh` keeps `trap cleanup SIGINT SIGTERM ERR`, so any unexpected failure stops every process and exits 1.
- **SH2:** `make lint` must pass: `shellcheck` with no findings and `shfmt -i 4 -d` with no diff. Run `make format` to apply the 4-space style. A new script goes into `SHELL_SCRIPTS` in the `Makefile`.
- **SH3:** Quote every expansion. Read optional variables with a default (`${WITH_OPENVPN-}`, `${nginx_pid-}`) so `set -u` does not abort on an unset one.
- **SH4:** Paths and URLs used by `run.sh` live in the constants block at the top (`VPN_CONFIG_FILE`, `VPN_AUTH_FILE`, `TUN_FILE`, `AUTH_CONF_FILE`, `HTPASSWD_FILE`, `IP_REPORTER_URL`). Add new ones there.
- **SH5:** A function started with `&` runs in a subshell: it sees variables as they were at fork time and does not inherit the ERR trap. State that a background loop needs (PIDs, flags) must exist before the fork, or be passed another way. `monitor_ip` breaks this today; see "Known landmines" in `AGENTS.md`.
- **SH6:** Every long-running process `run.sh` starts gets a PID variable, a check in the watchdog loop and a stop in `cleanup`.
