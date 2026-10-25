#!/bin/bash
# Home Assistant wrapper for the official OneDev image:
# persists OneDev in /data and maps add-on options to OneDev env vars.
set -e

OPTIONS=/data/options.json
DATA_DIR=/data/onedev

mkdir -p "$DATA_DIR"

# OneDev installs/upgrades itself into /opt/onedev on every start
if [ ! -L /opt/onedev ]; then
    rm -rf /opt/onedev
    ln -s "$DATA_DIR" /opt/onedev
fi

option() {
    jq -r --arg k "$1" '.[$k] // empty' "$OPTIONS" 2>/dev/null || true
}

if [ "$(option external_db)" = "true" ]; then
    case "$(option db_type)" in
        postgresql)
            export hibernate_dialect=io.onedev.server.persistence.PostgreSQLDialect
            export hibernate_connection_driver_class=org.postgresql.Driver
            ;;
        mariadb)
            export hibernate_dialect=org.hibernate.dialect.MySQL5InnoDBDialect
            export hibernate_connection_driver_class=org.mariadb.jdbc.Driver
            ;;
        mysql)
            export hibernate_dialect=org.hibernate.dialect.MySQL5InnoDBDialect
            export hibernate_connection_driver_class=com.mysql.cj.jdbc.Driver
            ;;
    esac
    export hibernate_connection_url="$(option db_url)"
    export hibernate_connection_username="$(option db_user)"
    export hibernate_connection_password="$(option db_password)"

    if [ -z "$hibernate_connection_url" ]; then
        echo "[onedev] external_db is enabled but db_url is empty" >&2
        exit 1
    fi
    echo "[onedev] Using external $(option db_type) database"
else
    echo "[onedev] Using embedded HSQLDB database in $DATA_DIR"
fi

exec /root/bin/entrypoint.sh
