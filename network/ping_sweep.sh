#!/usr/bin/env bash
# ping_sweep.sh – Ping all hosts in a given subnet and report which are up.
#
# Usage: ping_sweep.sh [-t <timeout>] [-h] <subnet>
#   subnet   Base network address, e.g. 192.168.1  (last octet is swept 1-254)
#   -t       Ping timeout in seconds (default: 1)
#   -h       Show this help message
#
# Example:
#   ping_sweep.sh 192.168.1
#   ping_sweep.sh -t 2 10.0.0
#
# Requires: ping
# Privileges: none

set -euo pipefail

TIMEOUT=1

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

if [[ $# -ne 1 ]]; then
    echo "Error: subnet argument is required (e.g. 192.168.1)." >&2
    echo "Run with -h for usage." >&2
    exit 1
fi

SUBNET="$1"
UP=()
DOWN_COUNT=0

echo "Sweeping ${SUBNET}.1-254 (timeout: ${TIMEOUT}s) ..."
echo ""

for i in $(seq 1 254); do
    host="${SUBNET}.${i}"
    if ping -c 1 -W "$TIMEOUT" "$host" &>/dev/null; then
        echo "  UP   $host"
        UP+=("$host")
    else
        (( DOWN_COUNT++ )) || true
    fi
done

echo ""
echo "Results: ${#UP[@]} host(s) up, ${DOWN_COUNT} host(s) down."
