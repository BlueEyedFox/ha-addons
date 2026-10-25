#!/bin/bash
# Checks the upstream Docker Hub images listed in .github/upstream.yaml and
# bumps add-ons with a newer release (config.yaml, Dockerfile, CHANGELOG.md).
# Prints a JSON list of updated add-on slugs on stdout, e.g. ["onedev"].
# Requires: curl, yq (mikefarah v4), sed, sort -V. Run from the repo root.
set -euo pipefail

UPSTREAM_FILE=.github/upstream.yaml
updated=()

latest_dockerhub_version() {
    local url="https://hub.docker.com/v2/repositories/$1/tags?page_size=100&ordering=last_updated"
    curl -fsSL "$url" \
        | yq -p json -r '.results[].name' \
        | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
        | sort -V | tail -n 1
}

for addon in $(yq -r 'keys | .[]' "$UPSTREAM_FILE"); do
    repo=$(yq -r ".${addon}.dockerhub" "$UPSTREAM_FILE")
    config="$addon/config.yaml"

    current=$(yq -r '.version' "$config")
    current_upstream=${current%%-*}
    latest=$(latest_dockerhub_version "$repo")

    if [ -z "$latest" ]; then
        echo "[$addon] no release tags found for $repo" >&2
        exit 1
    fi

    newest=$(printf '%s\n%s\n' "$current_upstream" "$latest" | sort -V | tail -n 1)
    if [ "$latest" = "$current_upstream" ] || [ "$newest" != "$latest" ]; then
        echo "[$addon] up to date ($current)" >&2
        continue
    fi

    echo "[$addon] $current -> $latest" >&2
    sed -i -E "s/^version: .*/version: \"$latest\"/" "$config"
    sed -i -E "0,/^(ARG [A-Z_]*VERSION=).*/s//\1$latest/" "$addon/Dockerfile"
    sed -i "0,\|^## |s||## $latest\n\n- Update auf \`$repo:$latest\`\n\n## |" "$addon/CHANGELOG.md"
    updated+=("$addon")
done

json="["
for addon in "${updated[@]}"; do
    json+="\"$addon\","
done
echo "${json%,}]"
