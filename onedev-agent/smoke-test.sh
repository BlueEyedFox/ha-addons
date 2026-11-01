#!/bin/bash
# Smoke test for a locally built image: starts the agent against a server URL
# where nothing listens and waits until it has tried to connect, i.e. the
# options were applied and the Java agent is running.
# Usage: smoke-test.sh <image>
set -euo pipefail

IMAGE=$1
NAME=smoke-onedev-agent-$$
TMP=$(mktemp -d)
TIMEOUT=60
EXPECTED="Connection refused. Is server up?"

cleanup() {
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    rm -rf "$TMP"
}
trap cleanup EXIT

mkdir -p "$TMP"/{data,work}
cat > "$TMP/data/options.json" <<JSON
{"server_url": "http://127.0.0.1:1", "agent_token": "smoke-test", "agent_name": "smoke",
 "attributes": [{"name": "smoke", "value": "yes"}], "max_memory_percent": 30, "trust_certs": []}
JSON
chmod 644 "$TMP/data/options.json"

docker run -d --name "$NAME" -v "$TMP/data":/data:ro -v "$TMP/work":/agent/work "$IMAGE" >/dev/null

for ((i = 0; i < TIMEOUT; i += 5)); do
    if [ -z "$(docker ps -q -f name="$NAME")" ]; then
        echo "Container exited unexpectedly" >&2
        docker logs "$NAME" 2>&1 | tail -n 50 >&2
        exit 1
    fi
    if docker logs "$NAME" 2>&1 | grep -qF "$EXPECTED" \
        && docker exec "$NAME" sh -c 'grep -qx smoke=yes /agent/conf/attributes.properties && ps -ef | grep -q "MaxRAMPercentage=[3]0"'; then
        echo "Agent is running after ${i}s"
        exit 0
    fi
    sleep 5
done

echo "Agent did not try to connect within ${TIMEOUT}s" >&2
docker logs "$NAME" 2>&1 | tail -n 50 >&2
exit 1
