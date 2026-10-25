#!/bin/bash
# Smoke test for a locally built OneDev add-on image: starts it with an empty
# /data and waits for the web UI. Usage: smoke-test.sh <image>
set -euo pipefail

IMAGE=$1
NAME=onedev-smoke-$$
DATA=$(mktemp -d)
TIMEOUT=180

cleanup() {
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    docker run --rm -v "$DATA":/data --entrypoint sh "$IMAGE" -c 'rm -rf /data/*' >/dev/null 2>&1 || true
    rm -rf "$DATA"
}
trap cleanup EXIT

echo '{"external_db":false,"db_type":"postgresql","db_url":"","db_user":"","db_password":""}' > "$DATA/options.json"
docker run -d --name "$NAME" -p 127.0.0.1::6610 -v "$DATA":/data "$IMAGE" >/dev/null

for ((i = 0; i < TIMEOUT; i += 5)); do
    if [ -z "$(docker ps -q -f name="$NAME")" ]; then
        echo "Container exited unexpectedly" >&2
        docker logs "$NAME" 2>&1 | tail -n 50 >&2
        exit 1
    fi
    PORT=$(docker port "$NAME" 6610/tcp 2>/dev/null | head -n 1 | cut -d: -f2) || true
    if [ -n "$PORT" ] && [ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/" || true)" = 200 ]; then
        if docker exec "$NAME" test -f /data/onedev/IN_DOCKER; then
            echo "OneDev web UI is up after ${i}s"
            exit 0
        fi
    fi
    sleep 5
done

echo "OneDev did not become ready within ${TIMEOUT}s" >&2
docker logs "$NAME" 2>&1 | tail -n 50 >&2
exit 1
