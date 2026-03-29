#!/usr/bin/env bash
# disk_usage.sh – Report disk usage per mount point.
#
# Usage: disk_usage.sh [-w <warn%>] [-c <crit%>] [-h]
#   -w  Warning threshold in percent  (default: 80)
#   -c  Critical threshold in percent (default: 90)
#   -h  Show this help message
#
# Requires: df, awk
# Privileges: none (run as any user)

set -euo pipefail

WARN_THRESHOLD=80
CRIT_THRESHOLD=90

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

while getopts ":w:c:h" opt; do
    case $opt in
        w) WARN_THRESHOLD="$OPTARG" ;;
        c) CRIT_THRESHOLD="$OPTARG" ;;
        h) usage ;;
        *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done

printf "%-30s %6s %6s %6s %7s  %s\n" "Filesystem" "Size" "Used" "Avail" "Use%" "Mounted on"
printf '%s\n' "$(printf '%.0s-' {1..75})"

EXIT_CODE=0

while IFS= read -r line; do
    # Extract percentage value (strip the % sign)
    raw_pct=$(echo "$line" | awk '{print $5}')
    mount=$(echo "$line" | awk '{print $6}')

    # Skip header row and blank values
    [[ -z "$raw_pct" || "$raw_pct" == "Use%" ]] && continue

    pct="${raw_pct//%/}"

    # Skip any non-numeric values (e.g. "-" on some systems)
    [[ "$pct" =~ ^[0-9]+$ ]] || continue

    status=""
    if (( pct >= CRIT_THRESHOLD )); then
        status=" [CRITICAL]"
        EXIT_CODE=2
    elif (( pct >= WARN_THRESHOLD )); then
        status=" [WARNING]"
        [[ $EXIT_CODE -lt 2 ]] && EXIT_CODE=1
    fi

    printf "%-30s %6s %6s %6s %6s%%  %s%s\n" \
        "$(echo "$line" | awk '{print $1}')" \
        "$(echo "$line" | awk '{print $2}')" \
        "$(echo "$line" | awk '{print $3}')" \
        "$(echo "$line" | awk '{print $4}')" \
        "$pct" \
        "$mount" \
        "$status"
done < <(df -h --output=source,size,used,avail,pcent,target 2>/dev/null || df -h)

echo ""
echo "Warn threshold: ${WARN_THRESHOLD}%  |  Critical threshold: ${CRIT_THRESHOLD}%"
exit "$EXIT_CODE"
