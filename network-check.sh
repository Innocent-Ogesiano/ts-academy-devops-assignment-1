#!/usr/bin/env bash
set -uo pipefail

if command -v timeout >/dev/null 2>&1; then
    TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_BIN="gtimeout"
else
    TIMEOUT_BIN=""
fi

run_with_timeout() {
    local secs="$1"; shift
    if [ -n "$TIMEOUT_BIN" ]; then
        "$TIMEOUT_BIN" "$secs" "$@"
        return $?
    fi
    "$@" &
    local pid=$!
    (
        sleep "$secs"
        kill -9 "$pid" 2>/dev/null
    ) &
    local watcher=$!
    local status
    if wait "$pid" 2>/dev/null; then
        status=0
    else
        status=$?
    fi
    kill "$watcher" 2>/dev/null
    wait "$watcher" 2>/dev/null
    return "$status"
}

usage() {
    echo "Usage: $0 <hostname-or-ip> [port]" >&2
    echo "  port: optional, integer from 1 to 65535" >&2
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage
    exit 2
fi

HOST="$1"
PORT="${2:-}"

if [ -z "$HOST" ]; then
    echo "Error: host must not be empty" >&2
    exit 2
fi

if ! [[ "$HOST" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]; then
    echo "Error: invalid hostname or IP: $HOST" >&2
    exit 2
fi

if [ -n "$PORT" ]; then
    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        echo "Error: port must be an integer from 1 to 65535" >&2
        exit 2
    fi
fi

echo "===== Network Check: $HOST ====="

echo "--- DNS Resolution ---"
RESOLVED=""
if command -v dig >/dev/null 2>&1; then
    RESOLVED="$(dig +short "$HOST" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$|^[0-9a-fA-F:]+$' | head -n1)"
elif command -v host >/dev/null 2>&1; then
    RESOLVED="$(host "$HOST" 2>/dev/null | awk '/has address/ {print $NF; exit}')"
elif command -v getent >/dev/null 2>&1; then
    RESOLVED="$(getent hosts "$HOST" 2>/dev/null | awk '{print $1; exit}')"
fi

if [ -z "$RESOLVED" ]; then
    RESOLVED="$(ping -c 1 -t 1 "$HOST" 2>/dev/null | awk -F'[()]' '/PING/ {print $2; exit}')"
fi

if [ -n "$RESOLVED" ]; then
    echo "Resolved address: $RESOLVED"
else
    echo "Could not resolve host: $HOST" >&2
    RESOLUTION_FAILED=1
fi

echo "--- Connectivity Check (ping) ---"
PING_OK=0
if ping -c 2 -W 2 "$HOST" >/dev/null 2>&1 || ping -c 2 -t 2 "$HOST" >/dev/null 2>&1; then
    echo "Host is reachable via ping"
    PING_OK=1
else
    echo "Host is NOT reachable via ping" >&2
fi

echo "--- Network Interfaces ---"
if command -v ip >/dev/null 2>&1; then
    ip -brief addr show 2>/dev/null || ip addr show
elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig | grep -E '^[a-zA-Z0-9]+:|inet |inet6 |status:'
else
    echo "No interface tool (ip/ifconfig) available" >&2
fi

PORT_OK=0
if [ -n "$PORT" ]; then
    echo "--- TCP Port Check ($HOST:$PORT) ---"
    if run_with_timeout 3 bash -c "exec 3<>/dev/tcp/$HOST/$PORT" 2>/dev/null; then
        echo "Port $PORT is open on $HOST"
        PORT_OK=1
        exec 3>&- 2>/dev/null
        exec 3<&- 2>/dev/null
    else
        echo "Port $PORT is closed or unreachable on $HOST" >&2
    fi
fi

echo "==============================="

if [ -n "${RESOLUTION_FAILED:-}" ]; then
    exit 1
fi

if [ -n "$PORT" ]; then
    [ "$PORT_OK" -eq 1 ] && exit 0 || exit 1
fi

[ "$PING_OK" -eq 1 ] && exit 0 || exit 1
