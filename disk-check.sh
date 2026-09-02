#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <threshold> [path]" >&2
    echo "  threshold: integer from 1 to 100" >&2
    echo "  path: filesystem path to check (default: /)" >&2
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage
    exit 2
fi

THRESHOLD="$1"
PATH_ARG="${2:-/}"

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -lt 1 ] || [ "$THRESHOLD" -gt 100 ]; then
    echo "Error: threshold must be an integer from 1 to 100" >&2
    exit 2
fi

if [ ! -e "$PATH_ARG" ]; then
    echo "Error: path '$PATH_ARG' does not exist" >&2
    exit 2
fi

USAGE=$(df -P "$PATH_ARG" | awk 'NR==2 {gsub(/%/,"",$5); print $5}')

if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
    echo "Error: could not determine disk usage for '$PATH_ARG'" >&2
    exit 2
fi

echo "Disk usage for $PATH_ARG: ${USAGE}%"

if [ "$USAGE" -ge "$THRESHOLD" ]; then
    echo "WARNING: usage (${USAGE}%) has reached or exceeded threshold (${THRESHOLD}%)" >&2
    exit 1
fi

exit 0
