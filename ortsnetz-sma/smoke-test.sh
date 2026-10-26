#!/bin/bash
# Smoke test for a locally built image: starts it in the host network with
# test coordinates and waits until the script has joined the multicast group
# and timed out waiting for a telegram (nothing is ever sent to the API).
# Usage: smoke-test.sh <image>
set -euo pipefail

IMAGE=$1
NAME=smoke-ortsnetz-sma-$$
TMP=$(mktemp -d)
TIMEOUT=60
EXPECTED="Kein gültiges EMETER-Telegramm"

cleanup() {
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    rm -rf "$TMP"
}
trap cleanup EXIT

cat > "$TMP/options.json" <<JSON
{"latitude": 52.520008, "longitude": 13.404954, "interface_ip": "0.0.0.0", "dry_run": false}
JSON
chmod 644 "$TMP/options.json"

docker run -d --name "$NAME" --network host -v "$TMP":/data:ro "$IMAGE" >/dev/null

for ((i = 0; i < TIMEOUT; i += 5)); do
    if [ -z "$(docker ps -q -f name="$NAME")" ]; then
        echo "Container exited unexpectedly" >&2
        docker logs "$NAME" 2>&1 | tail -n 50 >&2
        exit 1
    fi
    if docker logs "$NAME" 2>&1 | grep -q "$EXPECTED"; then
        echo "Multicast receiver is up after ${i}s"
        exit 0
    fi
    sleep 5
done

echo "Receiver did not report within ${TIMEOUT}s" >&2
docker logs "$NAME" 2>&1 | tail -n 50 >&2
exit 1
