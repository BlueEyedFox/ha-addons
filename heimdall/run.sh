#!/bin/bash
# Home Assistant wrapper for linuxserver/heimdall: HA mounts the add-on config
# folder at /config, which is where the image keeps its data anyway.
set -e

OPTIONS=/data/options.json
LEGACY_DIR=/share/heimdall

# One-time import from the old BenoitAnastay add-on, which stored its data in /share
if [ ! -f /config/www/app.sqlite ] && [ -f "$LEGACY_DIR/www/app.sqlite" ]; then
    echo "[heimdall] Migrating data from $LEGACY_DIR to the add-on config folder"
    cp -a "$LEGACY_DIR/." /config/
fi

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
