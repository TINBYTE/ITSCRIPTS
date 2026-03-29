#!/usr/bin/env bash
# network_info.sh – Display network interfaces, IPs, routes, and DNS servers.
#
# Usage: network_info.sh [-h]
#   -h  Show this help message
#
# Requires: ip (iproute2) or ifconfig, route/netstat
# Privileges: none

set -euo pipefail

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

HR="$(printf '%0.s─' {1..60})"
section() { echo ""; echo "$HR"; echo "  $1"; echo "$HR"; }

# ── Interfaces & IPs ─────────────────────────────────────────
section "Network Interfaces & IP Addresses"
if command -v ip &>/dev/null; then
    ip -o addr show | awk '{printf "  %-12s %-10s %s\n", $2, $3, $4}'
else
    ifconfig | grep -E '^[a-z]|inet ' | sed 's/^/  /'
fi

# ── Routing table ────────────────────────────────────────────
section "Routing Table"
if command -v ip &>/dev/null; then
    ip route show | sed 's/^/  /'
else
    netstat -rn | sed 's/^/  /'
fi

# ── DNS servers ──────────────────────────────────────────────
section "DNS Servers"
if [[ -f /etc/resolv.conf ]]; then
    grep '^nameserver' /etc/resolv.conf | sed 's/^/  /' || echo "  No nameservers found."
else
    echo "  /etc/resolv.conf not found."
fi

# ── Active connections summary ───────────────────────────────
section "Active TCP Connections (summary)"
if command -v ss &>/dev/null; then
    ss -tn state established 2>/dev/null | tail -n +2 | wc -l | xargs printf "  Established connections: %s\n"
    echo ""
    ss -tlnp 2>/dev/null | grep LISTEN | awk '{printf "  %-30s %s\n", $4, $6}' | head -20
elif command -v netstat &>/dev/null; then
    netstat -tn 2>/dev/null | grep ESTABLISHED | wc -l | xargs printf "  Established connections: %s\n"
fi

echo ""
