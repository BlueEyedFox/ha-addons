#!/bin/bash
# Home Assistant wrapper for the official OneDev agent image: maps the add-on
# options to the agent's env vars and conf files. /agent/work is the add-on
# config folder, so the agent can resolve host paths for its job containers.
set -e

OPTIONS=/data/options.json
CONF=/agent/conf

option() {
    jq -r --arg k "$1" '.[$k] // empty' "$OPTIONS" 2>/dev/null || true
}

export serverUrl="$(option server_url)"
export agentToken="$(option agent_token)"

if [ -z "$serverUrl" ] || [ -z "$agentToken" ]; then
    echo "[onedev-agent] server_url and agent_token must be set" >&2
    exit 1
fi

if [ -n "$(option agent_name)" ]; then
    export agentName="$(option agent_name)"
fi

max_memory_percent="$(option max_memory_percent)"
export max_memory_percent="${max_memory_percent:-50}"

for var in http_proxy https_proxy no_proxy; do
    if [ -n "$(option "$var")" ]; then
        export "$var=$(option "$var")"
    fi
done

jq -r '.attributes[]? | "\(.name)=\(.value)"' "$OPTIONS" > "$CONF/attributes.properties"

rm -rf "$CONF/trust-certs"
mkdir -p "$CONF/trust-certs"
jq -r '.trust_certs[]?' "$OPTIONS" | while read -r cert; do
    case "$cert" in
        /*) ;;
        *) cert="/ssl/$cert" ;;
    esac
    if [ ! -f "$cert" ]; then
        echo "[onedev-agent] certificate $cert not found" >&2
        exit 1
    fi
    cp "$cert" "$CONF/trust-certs/"
done

if ! mountpoint -q /agent/work; then
    echo "[onedev-agent] /agent/work is not a mount, Docker jobs will fail" >&2
fi
if [ ! -S /var/run/docker.sock ]; then
    echo "[onedev-agent] No Docker socket: disable protection mode for Docker jobs" >&2
fi

echo "[onedev-agent] Connecting to $serverUrl as ${agentName:-$(hostname)}"
exec /root/bin/entrypoint.sh
