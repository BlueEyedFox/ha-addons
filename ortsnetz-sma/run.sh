#!/bin/sh
# Home Assistant wrapper for ortsnetz-sma-shm2.py: maps the add-on options to
# the script's ORTSNETZ_* environment variables and starts it via addon.py,
# which adds the optional API fields. Without coordinates in the
# options, the home location from the Home Assistant configuration is used.
set -e

OPTIONS=/data/options.json
SCRIPT=/app/addon.py

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

option() {
    jq -r --arg k "$1" '.[$k] // empty' "$OPTIONS" 2>/dev/null || true
}

ORTSNETZ_LATITUDE=$(option latitude)
ORTSNETZ_LONGITUDE=$(option longitude)
ORTSNETZ_INTERFACE_IP=$(option interface_ip)
ORTSNETZ_METER_SERIAL=$(option meter_serial)

if { [ -z "$ORTSNETZ_LATITUDE" ] || [ -z "$ORTSNETZ_LONGITUDE" ]; } && [ -n "$SUPERVISOR_TOKEN" ]; then
    if ha_config=$(curl -fsS -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/api/config); then
        ORTSNETZ_LATITUDE=$(echo "$ha_config" | jq -r '.latitude // empty')
        ORTSNETZ_LONGITUDE=$(echo "$ha_config" | jq -r '.longitude // empty')
        log "Koordinaten aus der Home-Assistant-Konfiguration: $ORTSNETZ_LATITUDE, $ORTSNETZ_LONGITUDE"
    else
        log "Koordinaten konnten nicht aus Home Assistant gelesen werden."
    fi
fi

export ORTSNETZ_LATITUDE ORTSNETZ_LONGITUDE ORTSNETZ_INTERFACE_IP ORTSNETZ_METER_SERIAL

if [ "$(option dry_run)" != true ]; then
    exec python3 -u "$SCRIPT"
fi

log "Testmodus (dry_run): Messungen werden nur angezeigt, es wird nichts gesendet."
while true; do
    status=0
    python3 -u "$SCRIPT" --dry-run || status=$?
    if [ "$status" -eq 2 ]; then
        exit 2
    fi
    sleep 60
done
