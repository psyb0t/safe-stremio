IMAGE_NAME := psyb0t/safe-stremio
TEST_IMAGE := safe-stremio:test

# Lint tools run from pinned images, so lint needs only Docker.
SHELLCHECK_IMAGE := koalaman/shellcheck:v0.11.0@sha256:61862eba1fcf09a484ebcc6feea46f1782532571a34ed51fedf90dd25f925a8d
SHFMT_IMAGE := mvdan/shfmt:v3.12.0@sha256:307d265ffd25ce832899ae17c93ed5062fc3375c514bba8f52cbf52792735c4d
ACTIONLINT_IMAGE := rhysd/actionlint:1.7.7@sha256:887a259a5a534f3c4f36cb02dca341673c6089431057242cdc931e9f133147e9
JEKYLL_IMAGE := ghcr.io/actions/jekyll-build-pages:v1.0.13@sha256:6791ebfd912185ed59bfb5fb102664fa872496b79f87ff8b9cfba292a7345041

SHELL_SCRIPTS := run.sh scripts/smoke-test.sh
DOCS_SITE := .testing/docs-site

TOOL_RUN = docker run --rm \
	--user "$$(id -u):$$(id -g)" \
	-v "$(CURDIR):/work" \
	-w /work

.PHONY: help build lint format test docs clean

help: ## Show every target
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

build: ## Build the image locally as psyb0t/safe-stremio:latest
	docker build -t $(IMAGE_NAME):latest .

lint: ## shellcheck, shfmt and actionlint in Docker
	$(TOOL_RUN) $(SHELLCHECK_IMAGE) $(SHELL_SCRIPTS)
	$(TOOL_RUN) $(SHFMT_IMAGE) -i 4 -d $(SHELL_SCRIPTS)
	$(TOOL_RUN) $(ACTIONLINT_IMAGE)

format: ## Rewrite the shell scripts with shfmt
	$(TOOL_RUN) $(SHFMT_IMAGE) -i 4 -w $(SHELL_SCRIPTS)

# Builds the image and checks it from inside running containers: nginx
# config, basic auth, the Stremio Server proxy and the rate limit. Needs
# Docker and outbound internet (run.sh looks up the public IP on start).
test: ## Build the image and run the container smoke test
	docker build -t $(TEST_IMAGE) .
	IMAGE=$(TEST_IMAGE) bash scripts/smoke-test.sh

# Builds docs/ with the image GitHub Pages uses, so the local result matches
# the published site. The output directory is gitignored.
docs: ## Build the documentation site into .testing/docs-site
	@mkdir -p "$(DOCS_SITE)"
	docker run --rm \
		--user "$$(id -u):$$(id -g)" \
		-e HOME=/tmp \
		-e GITHUB_WORKSPACE=/work \
		-e GITHUB_REPOSITORY=psyb0t/safe-stremio \
		-e INPUT_SOURCE=docs \
		-e INPUT_DESTINATION="$(DOCS_SITE)" \
		-e INPUT_VERBOSE=false \
		-v "$(CURDIR):/work" \
		$(JEKYLL_IMAGE)

clean: ## Remove the local images
	docker rmi $(IMAGE_NAME):latest 2>/dev/null || true
	docker rmi $(TEST_IMAGE) 2>/dev/null || true
