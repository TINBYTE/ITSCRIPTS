#!/usr/bin/env bash
# log_analyzer.sh – Summarize error/warning/critical counts in a log file.
#
# Usage: log_analyzer.sh [-n <lines>] [-h] <logfile>
#   logfile     Log file to analyze (use - for stdin)
#   -n lines    Show the N most recent matching lines per level (default: 10)
#   -h          Show this help message
#
# Searches for lines containing (case-insensitive):
#   CRITICAL, ERROR, WARN, INFO
#
# Requires: grep, awk
# Privileges: needs read access to the log file

set -euo pipefail

TAIL_LINES=10

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

while getopts ":n:h" opt; do
    case $opt in
        n) TAIL_LINES="$OPTARG" ;;
        h) usage ;;
        *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done
shift $(( OPTIND - 1 ))

if [[ $# -ne 1 ]]; then
    echo "Error: logfile argument is required." >&2
    echo "Run with -h for usage." >&2
    exit 1
fi

LOGFILE="$1"

if [[ "$LOGFILE" != "-" && ! -f "$LOGFILE" ]]; then
    echo "Error: File not found: $LOGFILE" >&2
    exit 1
fi

# Buffer stdin into a temp file so it can be read multiple times
TMPFILE=""
if [[ "$LOGFILE" == "-" ]]; then
    TMPFILE=$(mktemp)
    trap 'rm -f "$TMPFILE"' EXIT
    cat > "$TMPFILE"
    LOGFILE="$TMPFILE"
fi

HR="$(printf '%0.s─' {1..60})"
section() { echo ""; echo "$HR"; echo "  $1"; echo "$HR"; }

# Count each level
CRITICAL=$(grep -ci 'critical' "$LOGFILE" || true)
ERRORS=$(grep   -ci 'error'    "$LOGFILE" || true)
WARNINGS=$(grep -ci 'warn'     "$LOGFILE" || true)
INFOS=$(grep    -ci 'info'     "$LOGFILE" || true)
TOTAL=$(wc -l < "$LOGFILE")

section "Log Summary: ${LOGFILE}"
printf "  %-12s %d\n" "Total lines:" "$TOTAL"
printf "  %-12s %d\n" "CRITICAL:"    "$CRITICAL"
printf "  %-12s %d\n" "ERROR:"       "$ERRORS"
printf "  %-12s %d\n" "WARN:"        "$WARNINGS"
printf "  %-12s %d\n" "INFO:"        "$INFOS"

for level in CRITICAL ERROR WARN; do
    section "Last ${TAIL_LINES} ${level} lines"
    grep -i "$level" "$LOGFILE" | tail -n "$TAIL_LINES" | while IFS= read -r line; do
        echo "  $line"
    done || echo "  (none found)"
done

echo ""
