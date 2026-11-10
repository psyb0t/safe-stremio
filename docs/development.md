---
title: "Development"
description: "Work on safe-stremio: repository layout, the Make targets for lint, smoke test, build and docs, the CI pipeline, and how a release tag ships an image."
nav_order: 7
---

# Development

safe-stremio has no application code of its own. It is a Dockerfile, two nginx config files, a Bash entrypoint and a smoke test. Docker and Make are all you need; every tool runs in a container.

## Layout

| Path | Contents |
| --- | --- |
| [Dockerfile](https://github.com/psyb0t/safe-stremio/blob/master/Dockerfile) | The image: `stremio/server` base, nginx, OpenVPN, Stremio Web. |
| [run.sh](https://github.com/psyb0t/safe-stremio/blob/master/run.sh) | The entrypoint. See [How it works](how-it-works.md). |
| [nginx/](https://github.com/psyb0t/safe-stremio/tree/master/nginx) | `nginx.conf` (rate limit zone) and `default.conf` (routes, auth, rate limit). |
| [docker-compose.yml](https://github.com/psyb0t/safe-stremio/blob/master/docker-compose.yml) | Example deployment with the LAN proxy. |
| [scripts/smoke-test.sh](https://github.com/psyb0t/safe-stremio/blob/master/scripts/smoke-test.sh) | The container smoke test. |
| [Makefile](https://github.com/psyb0t/safe-stremio/blob/master/Makefile) | The targets below. |
| [docs/](https://github.com/psyb0t/safe-stremio/tree/master/docs) | This site. |
| [.github/workflows/](https://github.com/psyb0t/safe-stremio/tree/master/.github/workflows) | CI, mirroring and issue sync. |

## Make targets

```sh
make help    # every target
make lint    # shellcheck, shfmt -i 4 -d and actionlint
make test    # build safe-stremio:test and run the smoke test
make build   # build psyb0t/safe-stremio:latest
make format  # shfmt -i 4 -w on the shell scripts
make docs    # build this site into .testing/docs-site
make clean   # remove the local images
```

`make lint` runs pinned `koalaman/shellcheck`, `mvdan/shfmt` and `rhysd/actionlint` images on `run.sh`, `scripts/smoke-test.sh` and the workflow files. It fails on any finding or formatting diff.

## Smoke test

`make test` builds the image as `safe-stremio:test` and runs [scripts/smoke-test.sh](https://github.com/psyb0t/safe-stremio/blob/master/scripts/smoke-test.sh). The script starts two containers without the VPN, one with basic auth and one without, and checks them from the inside with `docker exec curl`, so it publishes no ports:

- `nginx -t` accepts the config;
- `/` and `/stremio-server/settings` answer `401` without credentials or with a wrong password, and `200` with the right ones;
- both answer `200` with auth off, and an unknown path falls back to `index.html`;
- 30 parallel requests get some `503` answers from the rate limit.

It needs outbound internet, because `run.sh` fetches the public IP on start. The OpenVPN path is not covered: it needs `NET_ADMIN`, a real VPN and credentials.

## Docs

The site is Jekyll with the just-the-docs theme, built by GitHub Pages from `docs/` on `master`. `make docs` builds it with the same image GitHub uses, into `.testing/docs-site`. Page-to-page links use relative `.md` paths; links to repository files use full GitHub URLs.

## CI

[pipeline.yml](https://github.com/psyb0t/safe-stremio/blob/master/.github/workflows/pipeline.yml) runs on every push:

- every branch: `make lint` and `make test`;
- `master`: after both pass, build the image for `linux/amd64` and `linux/arm64`, push `psyb0t/safe-stremio:latest` and `:sha-<commit>`, scan it, and refresh the version and license badges;
- a `v*` tag: wait for the tagged commit's `master` run to succeed, point `:vX.Y.Z` at that commit's `:sha-<commit>` image without rebuilding, then create the GitHub Release.

The other workflows mirror the repository and pull issues from the mirrors, and close pull requests from non-collaborators. They are not part of the build.

## Releases

A release is a `CHANGELOG.md` entry in the existing style and a `vX.Y.Z` tag on a `master` commit whose pipeline passed. The tag pipeline promotes the image already built for that commit, so the release image is the exact one that was tested.
