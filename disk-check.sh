#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/disk-check.log"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

usage() {
    echo "Usage: $0 <threshold> [path]" >&2
    echo "  threshold: integer from 1 to 100" >&2
    echo "  path: filesystem path to check (default: /)" >&2
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage
    log "Invalid invocation: expected 1-2 arguments, got $#"
    exit 2
fi

THRESHOLD="$1"
PATH_ARG="${2:-/}"

log "Checking disk usage for path '$PATH_ARG' against threshold ${THRESHOLD}%"

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -lt 1 ] || [ "$THRESHOLD" -gt 100 ]; then
    echo "Error: threshold must be an integer from 1 to 100" >&2
    log "Invalid threshold argument: '$THRESHOLD'"
    exit 2
fi

if [ ! -e "$PATH_ARG" ]; then
    echo "Error: path '$PATH_ARG' does not exist" >&2
    log "Invalid path argument: '$PATH_ARG' does not exist"
    exit 2
fi

USAGE=$(df -P "$PATH_ARG" | awk 'NR==2 {gsub(/%/,"",$5); print $5}')

if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
    echo "Error: could not determine disk usage for '$PATH_ARG'" >&2
    log "Failed to determine disk usage for '$PATH_ARG'"
    exit 2
fi

echo "Disk usage for $PATH_ARG: ${USAGE}%"

if [ "$USAGE" -ge "$THRESHOLD" ]; then
    echo "WARNING: usage (${USAGE}%) has reached or exceeded threshold (${THRESHOLD}%)" >&2
    log "Disk usage ${USAGE}% reached/exceeded threshold ${THRESHOLD}% for '$PATH_ARG'"
    exit 1
fi

log "Disk usage ${USAGE}% is below threshold ${THRESHOLD}% for '$PATH_ARG'"
exit 0
