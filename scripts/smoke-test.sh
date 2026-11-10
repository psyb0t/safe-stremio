#!/bin/bash
# Smoke test for a built safe-stremio image. Starts containers without the
# VPN and checks them from the inside with docker exec, so it needs no
# published ports and no credentials. run.sh looks up the public IP on
# start, so the containers need outbound internet.
#
# Usage: IMAGE=safe-stremio:test bash scripts/smoke-test.sh

set -euo pipefail

IMAGE="${IMAGE:-safe-stremio:test}"
AUTH_CONTAINER="safe-stremio-smoke-auth-$$"
OPEN_CONTAINER="safe-stremio-smoke-open-$$"
TEST_USER="smoke-user"
TEST_PASS="smoke-pass"
READY_TIMEOUT_SECONDS=90

fail() {
    echo "FAIL: $1" >&2
    for c in "$AUTH_CONTAINER" "$OPEN_CONTAINER"; do
        echo "--- logs of $c" >&2
        docker logs "$c" 2>&1 | tail -n 40 >&2 || true
    done
    exit 1
}

cleanup() {
    docker rm -f "$AUTH_CONTAINER" "$OPEN_CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# status <container> <path> [curl args...] prints the HTTP status code.
status() {
    local container="$1"
    local path="$2"
    shift 2
    docker exec "$container" \
        curl -s -o /dev/null -w '%{http_code}' "$@" "http://127.0.0.1${path}"
}

expect() {
    local want="$1"
    local got="$2"
    local what="$3"
    if [[ "$got" != "$want" ]]; then
        fail "$what: expected HTTP $want, got $got"
    fi
    echo "ok: $what ($got)"
}

wait_ready() {
    local container="$1"
    shift
    local deadline=$((SECONDS + READY_TIMEOUT_SECONDS))
    while ((SECONDS < deadline)); do
        if [[ "$(docker inspect -f '{{.State.Running}}' "$container")" != "true" ]]; then
            fail "$container exited during startup"
        fi
        if [[ "$(status "$container" /stremio-server/settings "$@" || true)" == "200" ]]; then
            return 0
        fi
        sleep 2
    done
    fail "$container: Stremio Server not reachable through nginx after ${READY_TIMEOUT_SECONDS}s"
}

docker run -d --name "$AUTH_CONTAINER" \
    -e USERNAME="$TEST_USER" \
    -e PASSWORD="$TEST_PASS" \
    "$IMAGE" >/dev/null
docker run -d --name "$OPEN_CONTAINER" "$IMAGE" >/dev/null

wait_ready "$AUTH_CONTAINER" -u "$TEST_USER:$TEST_PASS"
wait_ready "$OPEN_CONTAINER"

docker exec "$AUTH_CONTAINER" nginx -t || fail "nginx -t rejected the config"
echo "ok: nginx -t"

# The rate limit allows 1 request per second with a burst of 10. Each
# container gets at most 5 requests here, and the pause after this block
# refills the bucket before the rate limit check.
expect 401 "$(status "$AUTH_CONTAINER" /)" "web UI without credentials"
expect 401 "$(status "$AUTH_CONTAINER" /stremio-server/settings)" "server proxy without credentials"
expect 401 "$(status "$AUTH_CONTAINER" / -u "$TEST_USER:wrong")" "web UI with a wrong password"
expect 200 "$(status "$AUTH_CONTAINER" / -u "$TEST_USER:$TEST_PASS")" "web UI with credentials"
expect 200 "$(status "$AUTH_CONTAINER" /stremio-server/settings -u "$TEST_USER:$TEST_PASS")" "server proxy with credentials"
expect 200 "$(status "$OPEN_CONTAINER" /)" "web UI with auth off"
expect 200 "$(status "$OPEN_CONTAINER" /stremio-server/settings)" "server proxy with auth off"
expect 200 "$(status "$OPEN_CONTAINER" /some/client/route)" "SPA fallback to index.html"
sleep 12

# 30 parallel requests: about 11 get through (1 plus the burst of 10), the
# rest are rejected with 503.
codes=$(docker exec "$OPEN_CONTAINER" bash -c '
    for i in $(seq 1 30); do
        curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1/ &
    done
    wait
')
rejected=$(grep -c '^503$' <<<"$codes" || true)
if ((rejected == 0)); then
    fail "rate limit: no request out of 30 parallel ones was rejected"
fi
echo "ok: rate limit rejected $rejected of 30 parallel requests with 503"

echo "smoke test passed"
