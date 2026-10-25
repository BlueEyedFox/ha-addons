#!/bin/bash
# Home Assistant wrapper for linuxserver/heimdall: HA mounts the add-on config
# folder at /config, which is where the image keeps its data anyway.
set -e

OPTIONS=/data/options.json

option() {
    jq -r --arg k "$1" '.[$k] // empty' "$OPTIONS" 2>/dev/null || true
}

for key in PUID PGID TZ; do
    value=$(option "$key")
    if [ -n "$value" ]; then
        export "$key=$value"
    fi
done

exec /init
