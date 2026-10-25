#!/bin/bash
# Usage: smoke-test.sh <image>
exec "$(dirname "$0")/../.github/scripts/smoke-test.sh" "$(dirname "$0")" "$1" 80 \
    "test -f /config/www/app.sqlite"
