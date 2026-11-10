# Docker image

Prefix: IMG. Covers `Dockerfile`, `nginx/` and `docker-compose.yml`.

- **IMG1:** The base image is `stremio/server` at an exact version tag, and Stremio Web comes from the release zip named by `STREMIO_WEB_VERSION`. Upgrading either changes the `Dockerfile` and is checked with `make test`.
- **IMG2:** The image builds for `linux/amd64` and `linux/arm64` in CI. Do not add a package or download that exists for only one of them.
- **IMG3:** The image copies only `nginx/nginx.conf`, `nginx/default.conf` and `run.sh`. `.dockerignore` keeps `docs/`, `.testing/` and `.telemetry/` out of the build context; a new top-level directory the image does not need goes there too.
- **IMG4:** Every nginx `location` that serves content includes `/etc/nginx/conf.d/auth.conf` and applies `limit_req zone=one`. A new location without both is an unauthenticated hole.
- **IMG5:** `/stremio-server/` strips its prefix before proxying to `127.0.0.1:11470`. The Stremio Web streaming server URL setting depends on that path; renaming it breaks every existing client setup.
- **IMG6:** The container listens on port 80 only. Stremio Server's own ports (11470, 12470) are not published, and nothing should publish them, because they bypass auth and the rate limit.
- **IMG7:** `docker-compose.yml` and the Compose example in `docs/getting-started.md` stay in step.
