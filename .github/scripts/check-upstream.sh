#!/bin/bash
# Checks the upstream sources listed in .github/upstream.yaml and bumps add-ons
# with a newer release (config.yaml, Dockerfile, CHANGELOG.md). Sources:
#   dockerhub: <repo>             newest x.y.z tag -> ARG …_VERSION
#   github: <owner/repo>, path:   newest commit touching path -> ARG UPSTREAM_COMMIT;
#                                 version from VERSION = "…x.y.z" in that file,
#                                 or a bumped -N suffix if it did not change
# Prints a JSON list of updated add-on slugs on stdout, e.g. ["onedev"].
# Requires: curl, yq (mikefarah v4), sed, sort -V. Run from the repo root.
# GITHUB_TOKEN is used for GitHub API requests if set.
set -euo pipefail

UPSTREAM_FILE=.github/upstream.yaml
updated=()

upstream() {
    yq -r ".\"$1\".$2 // \"\"" "$UPSTREAM_FILE"
}

add_changelog() {
    sed -i "0,\|^## |s||## $2\n\n- $3\n\n## |" "$1/CHANGELOG.md"
}

latest_dockerhub_version() {
    local url="https://hub.docker.com/v2/repositories/$1/tags?page_size=100&ordering=last_updated"
    curl -fsSL "$url" \
        | yq -p json -r '.results[].name' \
        | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
        | sort -V | tail -n 1
}

github_api() {
    local auth=()
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
    fi
    curl -fsSL "${auth[@]}" "https://api.github.com/$1"
}

# Returns 0 and bumps the add-on if Docker Hub has a newer release.
update_dockerhub() {
    local addon=$1 repo=$2 config="$1/config.yaml"
    local current current_upstream latest newest

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
        return 1
    fi

    echo "[$addon] $current -> $latest" >&2
    sed -i -E "s/^version: .*/version: \"$latest\"/" "$config"
    sed -i -E "0,/^(ARG [A-Z_]*VERSION=).*/s//\1$latest/" "$addon/Dockerfile"
    add_changelog "$addon" "$latest" "Update auf \`$repo:$latest\`"
}

# Returns 0 and bumps the add-on if the file in the GitHub repo has a newer commit.
update_github() {
    local addon=$1 repo=$2 path=$3 config="$1/config.yaml"
    local current current_upstream current_commit latest script_version version

    current=$(yq -r '.version' "$config")
    current_upstream=${current%%-*}
    current_commit=$(sed -nE 's/^ARG UPSTREAM_COMMIT=//p' "$addon/Dockerfile")
    latest=$(github_api "repos/$repo/commits?path=$path&per_page=1" | yq -p json -r '.[0].sha // ""')

    if [ -z "$latest" ]; then
        echo "[$addon] no commits found for $repo/$path" >&2
        exit 1
    fi
    if [ "$latest" = "$current_commit" ]; then
        echo "[$addon] up to date ($current, ${current_commit:0:7})" >&2
        return 1
    fi

    script_version=$(curl -fsSL "https://raw.githubusercontent.com/$repo/$latest/$path" \
        | grep -E '^VERSION *=' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)
    if [ -n "$script_version" ] && [ "$script_version" != "$current_upstream" ]; then
        version=$script_version
    elif [ "$current" = "$current_upstream" ]; then
        version="$current-1"
    else
        version="$current_upstream-$((${current##*-} + 1))"
    fi

    echo "[$addon] $current -> $version (${latest:0:7})" >&2
    sed -i -E "s/^version: .*/version: \"$version\"/" "$config"
    sed -i -E "s/^(ARG UPSTREAM_COMMIT=).*/\1$latest/" "$addon/Dockerfile"
    add_changelog "$addon" "$version" "Update auf Upstream-Commit \`${latest:0:7}\`"
}

for addon in $(yq -r 'keys | .[]' "$UPSTREAM_FILE"); do
    dockerhub=$(upstream "$addon" dockerhub)
    github=$(upstream "$addon" github)

    if [ -n "$dockerhub" ]; then
        update_dockerhub "$addon" "$dockerhub" && updated+=("$addon")
    elif [ -n "$github" ]; then
        update_github "$addon" "$github" "$(upstream "$addon" path)" && updated+=("$addon")
    else
        echo "[$addon] no upstream source configured" >&2
        exit 1
    fi
done

json="["
for addon in "${updated[@]}"; do
    json+="\"$addon\","
done
echo "${json%,}]"
