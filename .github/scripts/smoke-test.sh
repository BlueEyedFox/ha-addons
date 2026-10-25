#!/bin/bash
# Smoke test for a locally built add-on image: starts it with empty /data,
# /config and /share (options.json from the add-on's default options) and
# waits for the web UI to answer with HTTP 200.
# Usage: smoke-test.sh <addon-dir> <image> <port> [check-cmd]
#   check-cmd: optional command run in the container once the UI is up
# Requires: docker, curl, yq (mikefarah v4).
set -euo pipefail

ADDON_DIR=$1
IMAGE=$2
CONTAINER_PORT=$3
CHECK=${4:-true}
NAME=smoke-$(basename "$ADDON_DIR")-$$
TMP=$(mktemp -d)
TIMEOUT=180

cleanup() {
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    docker run --rm -v "$TMP":/tmp/smoke --entrypoint sh "$IMAGE" -c 'rm -rf /tmp/smoke/*' >/dev/null 2>&1 || true
    rm -rf "$TMP"
}
trap cleanup EXIT

mkdir -p "$TMP"/{data,config,share}
yq -o json '.options // {}' "$ADDON_DIR/config.yaml" > "$TMP/data/options.json"

docker run -d --name "$NAME" -p "127.0.0.1::$CONTAINER_PORT" \
    -v "$TMP/data":/data -v "$TMP/config":/config -v "$TMP/share":/share \
    "$IMAGE" >/dev/null

for ((i = 0; i < TIMEOUT; i += 5)); do
    if [ -z "$(docker ps -q -f name="$NAME")" ]; then
        echo "Container exited unexpectedly" >&2
        docker logs "$NAME" 2>&1 | tail -n 50 >&2
        exit 1
    fi
    PORT=$(docker port "$NAME" "$CONTAINER_PORT/tcp" 2>/dev/null | head -n 1 | cut -d: -f2) || true
    if [ -n "$PORT" ] && [ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/" || true)" = 200 ]; then
        if docker exec "$NAME" sh -c "$CHECK"; then
            echo "Web UI is up after ${i}s"
            exit 0
        fi
    fi
    sleep 5
done

echo "Web UI did not become ready within ${TIMEOUT}s" >&2
docker logs "$NAME" 2>&1 | tail -n 50 >&2
exit 1
