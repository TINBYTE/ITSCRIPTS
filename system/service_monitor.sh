#!/usr/bin/env bash
# service_monitor.sh – Check whether services are running; optionally restart them.
#
# Usage: service_monitor.sh [-r] [-h] <service1> [service2 ...]
#   -r  Attempt to restart any stopped service (requires sudo/root)
#   -h  Show this help message
#
# Examples:
#   service_monitor.sh nginx mysql ssh
#   service_monitor.sh -r nginx mysql
#
# Requires: systemctl (systemd) or service (SysV)
# Privileges: read-only check needs none; -r flag requires root

set -euo pipefail

RESTART=false

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

while getopts ":rh" opt; do
    case $opt in
        r) RESTART=true ;;
        h) usage ;;
        *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done
shift $(( OPTIND - 1 ))

if [[ $# -eq 0 ]]; then
    echo "Error: at least one service name is required." >&2
    echo "Run with -h for usage." >&2
    exit 1
fi

check_service() {
    local svc="$1"
    if command -v systemctl &>/dev/null; then
        systemctl is-active --quiet "$svc"
    else
        service "$svc" status &>/dev/null
    fi
}

restart_service() {
    local svc="$1"
    if command -v systemctl &>/dev/null; then
        systemctl restart "$svc"
    else
        service "$svc" restart
    fi
}

printf "%-30s %-10s\n" "Service" "Status"
printf '%s\n' "$(printf '%.0s-' {1..42})"

EXIT_CODE=0

for svc in "$@"; do
    if check_service "$svc" 2>/dev/null; then
        printf "%-30s %-10s\n" "$svc" "RUNNING"
    else
        printf "%-30s %-10s\n" "$svc" "STOPPED"
        EXIT_CODE=1
        if $RESTART; then
            echo "  → Attempting to restart $svc ..."
            if restart_service "$svc" 2>/dev/null; then
                echo "  → $svc restarted successfully."
            else
                echo "  → Failed to restart $svc." >&2
            fi
        fi
    fi
done

exit "$EXIT_CODE"
