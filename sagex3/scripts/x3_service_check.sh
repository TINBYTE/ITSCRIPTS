#!/usr/bin/env bash
# x3_service_check.sh – Check the status of Sage X3 system services; optionally restart them.
#
# Usage: x3_service_check.sh [-r] [-x3dir <x3-root>] [-h]
#   -r            Attempt to restart any stopped X3 service (requires sudo/root)
#   -x3dir path   Sage X3 installation root (default: /opt/sagex3)
#   -h            Show this help message
#
# Examples:
#   x3_service_check.sh
#   x3_service_check.sh -r
#   x3_service_check.sh -x3dir /opt/sagex3 -r
#
# Monitored services (systemd units, with fallback to process detection):
#   adxd          – Sage X3 application server daemon
#   adxadmin      – Sage X3 administration service
#   SageX3WebServer  – Sage X3 web server (Syracuse / Tomcat-based)
#
# Requires: systemctl (preferred) or ps
# Privileges: read-only needs none; -r flag requires root

set -euo pipefail

RESTART=false
X3_ROOT="/opt/sagex3"

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -r)        RESTART=true; shift ;;
        -x3dir)    X3_ROOT="${2:?'-x3dir requires a path argument'}"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; echo "Run with -h for usage." >&2; exit 1 ;;
    esac
done

# Services to monitor: display-name => systemd-unit (or empty to use process detection only)
declare -A SERVICES=(
    ["adxd"]="adxd"
    ["adxadmin"]="adxadmin"
    ["SageX3WebServer"]="SageX3WebServer"
)

HR="$(printf '%0.s─' {1..50})"
section() { echo ""; echo "$HR"; echo "  $1"; echo "$HR"; }

# ── X3 installation info ─────────────────────────────────────
section "Sage X3 Installation"
printf "  %-22s %s\n" "X3 root:" "$X3_ROOT"
if [[ -d "$X3_ROOT" ]]; then
    printf "  %-22s %s\n" "Directory exists:" "YES"
    # Try to detect version from a manifest/version file if present
    for vf in "$X3_ROOT"/VERSION "$X3_ROOT"/runtime/VERSION; do
        if [[ -f "$vf" ]]; then
            printf "  %-22s %s\n" "Version file:" "$(head -1 "$vf")"
            break
        fi
    done
else
    printf "  %-22s %s\n" "Directory exists:" "NO (path not found)"
fi

# ── Service status ───────────────────────────────────────────
section "Service Status"
printf "  %-30s %-10s\n" "Service" "Status"
printf '  %s\n' "$(printf '%.0s-' {1..42})"

EXIT_CODE=0

check_service() {
    local svc="$1"
    if command -v systemctl &>/dev/null && systemctl list-units --type=service --all 2>/dev/null | grep -q "${svc}\.service"; then
        systemctl is-active --quiet "${svc}.service" 2>/dev/null
    else
        # Fallback: check running processes
        pgrep -x "$svc" &>/dev/null
    fi
}

restart_service() {
    local svc="$1"
    if command -v systemctl &>/dev/null && systemctl list-units --type=service --all 2>/dev/null | grep -q "${svc}\.service"; then
        systemctl restart "${svc}.service"
    else
        echo "  → Cannot restart $svc automatically (no systemd unit found)." >&2
        return 1
    fi
}

for svc in "${!SERVICES[@]}"; do
    if check_service "$svc" 2>/dev/null; then
        printf "  %-30s %-10s\n" "$svc" "RUNNING"
    else
        printf "  %-30s %-10s\n" "$svc" "STOPPED"
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

# ── Open X3 connections ──────────────────────────────────────
section "Active X3 Connections"
if command -v ss &>/dev/null; then
    count=$(ss -tnp 2>/dev/null | grep -c 'adxd\|adxadmin\|1818\|1805' || true)
elif command -v netstat &>/dev/null; then
    count=$(netstat -tnp 2>/dev/null | grep -c 'adxd\|adxadmin\|1818\|1805' || true)
else
    count="N/A"
fi
printf "  %-30s %s\n" "X3 related connections:" "$count"

echo ""
exit "$EXIT_CODE"
