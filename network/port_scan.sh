#!/usr/bin/env bash
# port_scan.sh – Lightweight TCP port scanner using /dev/tcp.
#
# Usage: port_scan.sh [-t <timeout>] [-h] <host> <port-range>
#   host         Hostname or IP address to scan
#   port-range   Single port (80), comma-separated (22,80,443),
#                or range (1-1024)
#   -t           Connection timeout in seconds (default: 2)
#   -h           Show this help message
#
# Examples:
#   port_scan.sh 192.168.1.1 22,80,443
#   port_scan.sh -t 1 example.com 1-1024
#
# Requires: bash (uses built-in /dev/tcp)
# Privileges: none

set -euo pipefail

TIMEOUT=2

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

while getopts ":t:h" opt; do
    case $opt in
        t) TIMEOUT="$OPTARG" ;;
        h) usage ;;
        *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done
shift $(( OPTIND - 1 ))

if [[ $# -ne 2 ]]; then
    echo "Error: host and port-range arguments are required." >&2
    echo "Run with -h for usage." >&2
    exit 1
fi

HOST="$1"
PORT_ARG="$2"

# Build list of ports
ports=()
IFS=',' read -ra parts <<< "$PORT_ARG"
for part in "${parts[@]}"; do
    if [[ "$part" == *-* ]]; then
        start="${part%-*}"
        end="${part#*-}"
        for p in $(seq "$start" "$end"); do
            ports+=("$p")
        done
    else
        ports+=("$part")
    fi
done

echo "Scanning $HOST | ${#ports[@]} port(s) | timeout ${TIMEOUT}s"
echo ""

OPEN=()
CLOSED=0

for port in "${ports[@]}"; do
    if (echo >/dev/tcp/"$HOST"/"$port") &>/dev/null & pid=$!
       sleep "$TIMEOUT" &>/dev/null & sleep_pid=$!
       wait "$pid" 2>/dev/null; rc=$?
       kill "$sleep_pid" 2>/dev/null || true
       [[ $rc -eq 0 ]]; then
        echo "  OPEN   $HOST:$port"
        OPEN+=("$port")
    else
        (( CLOSED++ )) || true
    fi
done

echo ""
echo "Results: ${#OPEN[@]} open, ${CLOSED} closed/filtered."
