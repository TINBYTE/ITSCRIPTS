#!/usr/bin/env bash
# system_health.sh – Print a full system health snapshot.
#
# Usage: system_health.sh [-h]
#   -h  Show this help message
#
# Displays: hostname, OS, uptime, load average, CPU count,
#           memory usage, swap usage, and disk usage summary.
#
# Requires: uname, uptime, free, df, nproc (or /proc/cpuinfo)
# Privileges: none

set -euo pipefail

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

HR="$(printf '%0.s─' {1..60})"

section() { echo ""; echo "$HR"; echo "  $1"; echo "$HR"; }

# ── Basic info ───────────────────────────────────────────────
section "System Information"
printf "  %-20s %s\n" "Hostname:"  "$(hostname -f 2>/dev/null || hostname)"
printf "  %-20s %s\n" "OS:"        "$(uname -srm)"
if [[ -f /etc/os-release ]]; then
    pretty=$(grep '^PRETTY_NAME' /etc/os-release | cut -d= -f2- | tr -d '"')
    printf "  %-20s %s\n" "Distribution:" "$pretty"
fi
printf "  %-20s %s\n" "Uptime:"    "$(uptime -p 2>/dev/null || uptime)"
printf "  %-20s %s\n" "Date/Time:" "$(date)"

# ── CPU ──────────────────────────────────────────────────────
section "CPU"
cpu_count=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "N/A")
load=$(awk '{print $1" "$2" "$3}' /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}')
printf "  %-20s %s\n" "Logical CPUs:" "$cpu_count"
printf "  %-20s %s\n" "Load avg (1/5/15):" "$load"

# ── Memory ───────────────────────────────────────────────────
section "Memory"
if command -v free &>/dev/null; then
    free -h | awk 'NR==1{printf "  %-14s %8s %8s %8s\n","", $1,$2,$3}
                   NR==2{printf "  %-14s %8s %8s %8s\n","RAM:",$2,$3,$4}
                   NR==3{printf "  %-14s %8s %8s %8s\n","Swap:",$2,$3,$4}'
else
    echo "  'free' command not available."
fi

# ── Disk ─────────────────────────────────────────────────────
section "Disk Usage"
df -h | awk 'NR==1{printf "  %-25s %6s %6s %6s %6s %s\n",$1,$2,$3,$4,$5,$6; next}
             /^\/dev/{printf "  %-25s %6s %6s %6s %6s %s\n",$1,$2,$3,$4,$5,$6}'

echo ""
