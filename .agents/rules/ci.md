# CI

Prefix: CI. Covers `.github/workflows/pipeline.yml`.

- **CI1:** `pipeline.yml` runs on every push (`on: [push]`) with top-level `permissions: {}`. Each job grants only what its called workflow needs.
- **CI2:** The `code` job runs `make lint` and `make test` through `code-workflow.yml` and is skipped on tags. The image build `needs: [code]` and pushes `:latest` and `:sha-<commit>` on `master`.
- **CI3:** A `v*` tag runs `wait` (the tagged commit's `master` run must succeed), then `docker-promote` (re-points the release tag at the `:sha-<commit>` image, no rebuild, `create_release: false`), then `release`. Keep image name and platforms identical in the build and promote jobs.
- **CI4:** Validate workflow changes with `make lint` (it runs actionlint).
- **CI5:** `mirror-and-archive.yml`, `issue-pull.yml` and `collaborators-only.yml` are separate concerns. Do not fold them into `pipeline.yml`.
