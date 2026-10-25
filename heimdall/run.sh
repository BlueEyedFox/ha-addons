#!/bin/bash
# Home Assistant wrapper for linuxserver/heimdall: HA mounts the add-on config
# folder at /config, which is where the image keeps its data anyway.
set -e

OPTIONS=/data/options.json
LEGACY_DIR=/share/heimdall
MARKER=/config/.heimdall-migrated

option() {
    jq -r --arg k "$1" '.[$k] // empty' "$OPTIONS" 2>/dev/null || true
}

for key in PUID PGID TZ; do
    value=$(option "$key")
    if [ -n "$value" ]; then
        export "$key=$value"
    fi
done

# One-time import from the old BenoitAnastay add-on, which kept a plain Heimdall
# install (database/, .env, storage/) in /share/heimdall. The marker is written
# on every start so legacy data never overwrites a running installation later.
if [ ! -f "$MARKER" ] && [ -f "$LEGACY_DIR/database/app.sqlite" ]; then
    echo "[heimdall] Migrating data from $LEGACY_DIR to the add-on config folder"
    mkdir -p /config/www
    suffix=bak-$(date +%Y%m%d%H%M%S)
    for f in app.sqlite .env; do
        if [ -e "/config/www/$f" ]; then
            echo "[heimdall] Keeping existing /config/www/$f as $f.$suffix"
            mv "/config/www/$f" "/config/www/$f.$suffix"
        fi
    done
    cp -a "$LEGACY_DIR/database/app.sqlite" /config/www/app.sqlite
    if [ -f "$LEGACY_DIR/.env" ]; then
        cp -a "$LEGACY_DIR/.env" /config/www/.env
    fi
    for dir in icons backgrounds avatars; do
        if [ -d "$LEGACY_DIR/storage/app/public/$dir" ]; then
            mkdir -p "/config/www/$dir"
            cp -a "$LEGACY_DIR/storage/app/public/$dir/." "/config/www/$dir/"
        fi
    done
    chown -R "${PUID:-1001}:${PGID:-1001}" /config/www
    echo "[heimdall] Migration finished"
fi
touch "$MARKER"

exec /init
