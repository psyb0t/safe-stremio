# Shell style

Prefix: SH. Covers `run.sh` and `scripts/*.sh`.

- **SH1:** `run.sh` keeps `trap cleanup SIGINT SIGTERM ERR`, so any unexpected failure stops every process and exits 1.
- **SH2:** `make lint` runs `shellcheck` and `shfmt -i 4 -d` over `SHELL_SCRIPTS` in the `Makefile`; a new script goes into that list.
- **SH4:** Paths and URLs used by `run.sh` live in the constants block at the top (`VPN_CONFIG_FILE`, `VPN_AUTH_FILE`, `TUN_FILE`, `AUTH_CONF_FILE`, `HTPASSWD_FILE`, `IP_REPORTER_URL`). Add new ones there.
- **SH5:** Background loops started with `&` in `run.sh` see variables as they were at fork time and do not inherit the ERR trap, so PIDs and flags they need must exist before the fork. `monitor_ip` breaks this today; see "Known landmines" in `AGENTS.md`.
- **SH6:** Every long-running process `run.sh` starts gets a PID variable, a check in the watchdog loop and a stop in `cleanup`.
