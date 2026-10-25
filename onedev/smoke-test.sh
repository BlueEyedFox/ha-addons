#!/bin/bash
# Usage: smoke-test.sh <image>
exec "$(dirname "$0")/../.github/scripts/smoke-test.sh" "$(dirname "$0")" "$1" 6610 \
    "test -f /data/onedev/IN_DOCKER"
