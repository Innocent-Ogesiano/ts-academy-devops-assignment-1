#!/usr/bin/env bash
set -euo pipefail

echo "===== System Information ====="

echo "Hostname: $(hostname)"

echo "Current User: $(whoami)"

echo "Date/Time: $(date)"

if [ "$(uname)" = "Darwin" ]; then
    OS_NAME="$(sw_vers -productName) $(sw_vers -productVersion)"
elif [ -f /etc/os-release ]; then
    OS_NAME="$(. /etc/os-release && echo "$PRETTY_NAME")"
else
    OS_NAME="$(uname -s)"
fi
echo "Operating System: $OS_NAME"

echo "Kernel Version: $(uname -r)"

if [ "$(uname)" = "Darwin" ]; then
    UPTIME_INFO="$(uptime | sed -E 's/.*up ([^,]*(,[[:space:]]*[0-9]+:[0-9]+)?).*/\1/')"
else
    UPTIME_INFO="$(uptime -p 2>/dev/null || uptime)"
fi
echo "Uptime: $UPTIME_INFO"

if [ "$(uname)" = "Darwin" ]; then
    CPU_MODEL="$(sysctl -n machdep.cpu.brand_string)"
    CPU_CORES="$(sysctl -n hw.ncpu)"
elif [ -f /proc/cpuinfo ]; then
    CPU_MODEL="$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
    CPU_CORES="$(nproc)"
else
    CPU_MODEL="Unknown"
    CPU_CORES="Unknown"
fi
echo "CPU: $CPU_MODEL ($CPU_CORES cores)"

if [ "$(uname)" = "Darwin" ]; then
    MEM_TOTAL_BYTES="$(sysctl -n hw.memsize)"
    MEM_TOTAL_GB=$(( MEM_TOTAL_BYTES / 1024 / 1024 / 1024 ))
    PAGE_SIZE="$(sysctl -n hw.pagesize)"
    VM_STAT="$(vm_stat)"
    PAGES_FREE="$(echo "$VM_STAT" | awk '/Pages free/ {gsub(/\./,"",$3); print $3}')"
    MEM_FREE_MB=$(( PAGES_FREE * PAGE_SIZE / 1024 / 1024 ))
    echo "Memory: Total: ${MEM_TOTAL_GB}GB, Free: ${MEM_FREE_MB}MB"
elif [ -f /proc/meminfo ]; then
    MEM_TOTAL_KB="$(grep MemTotal /proc/meminfo | awk '{print $2}')"
    MEM_AVAIL_KB="$(grep MemAvailable /proc/meminfo | awk '{print $2}')"
    MEM_TOTAL_MB=$(( MEM_TOTAL_KB / 1024 ))
    MEM_AVAIL_MB=$(( MEM_AVAIL_KB / 1024 ))
    echo "Memory: Total: ${MEM_TOTAL_MB}MB, Available: ${MEM_AVAIL_MB}MB"
else
    echo "Memory: Unknown"
fi

echo "Current Working Directory: $(pwd)"

echo "==============================="
