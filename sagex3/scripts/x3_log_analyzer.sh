#!/usr/bin/env bash
# x3_log_analyzer.sh – Analyze a Sage X3 log file and summarize errors and warnings.
#
# Usage: x3_log_analyzer.sh [-l <log-file>] [-d <log-dir>] [-n <lines>] [-h]
#   -l log-file   Path to a specific X3 log file to analyze
#   -d log-dir    Directory to scan for *.log / *.trc files (default: /opt/sagex3/log)
#   -n lines      Number of most-recent lines to scan (default: 5000, 0 = all)
#   -h            Show this help message
#
# Examples:
#   x3_log_analyzer.sh -l /opt/sagex3/log/adxd.log
#   x3_log_analyzer.sh -d /opt/sagex3/log -n 2000
#   x3_log_analyzer.sh -d /var/log/sagex3
#
# Output:
#   For each file: total lines scanned, error count, warning count,
#   and the 10 most recent error/warning lines.
#
# X3 log patterns recognized:
#   Errors   – lines containing ERROR, ERREUR, [ERR], FATAL, Exception, Traceback
#   Warnings – lines containing WARNING, WARN, ATTENTION, [WARN]
#
# Requires: grep, tail, wc, find
# Privileges: needs read access to log files

set -euo pipefail

LOG_FILE=""
LOG_DIR="/opt/sagex3/log"
SCAN_LINES=5000

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

while getopts ":l:d:n:h" opt; do
    case $opt in
        l) LOG_FILE="$OPTARG" ;;
        d) LOG_DIR="$OPTARG" ;;
        n) SCAN_LINES="$OPTARG" ;;
        h) usage ;;
        *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done

HR="$(printf '%0.s─' {1..60})"
section() { echo ""; echo "$HR"; echo "  $1"; echo "$HR"; }

ERROR_PATTERN='ERROR|ERREUR|\[ERR\]|FATAL|Exception|Traceback'
WARN_PATTERN='WARNING|WARN\b|ATTENTION|\[WARN\]'

analyze_file() {
    local file="$1"

    if [[ ! -r "$file" ]]; then
        echo "  [SKIP] Cannot read: $file"
        return
    fi

    # Determine input: full file or last N lines
    local input
    if (( SCAN_LINES > 0 )); then
        input=$(tail -n "$SCAN_LINES" "$file" 2>/dev/null)
    else
        input=$(cat "$file")
    fi

    local total_lines error_count warn_count
    total_lines=$(wc -l <<< "$input")
    error_count=$(grep -cEi "$ERROR_PATTERN" <<< "$input" || true)
    warn_count=$(grep -cEi "$WARN_PATTERN" <<< "$input" || true)

    section "File: $file"
    printf "  %-25s %s\n" "Lines scanned:"  "$total_lines"
    printf "  %-25s %s\n" "Errors found:"   "$error_count"
    printf "  %-25s %s\n" "Warnings found:" "$warn_count"

    if (( error_count > 0 )); then
        echo ""
        echo "  Last 10 error lines:"
        echo "  $(printf '%.0s-' {1..56})"
        # grep is guarded by the error_count check above, so this always has matches
        grep -Ei "$ERROR_PATTERN" <<< "$input" | tail -10 | while IFS= read -r line; do
            echo "  $line"
        done
    fi

    if (( warn_count > 0 )); then
        echo ""
        echo "  Last 10 warning lines:"
        echo "  $(printf '%.0s-' {1..56})"
        # grep is guarded by the warn_count check above, so this always has matches
        grep -Ei "$WARN_PATTERN" <<< "$input" | tail -10 | while IFS= read -r line; do
            echo "  $line"
        done
    fi
}

# ── Main ─────────────────────────────────────────────────────
echo "$HR"
echo "  Sage X3 Log Analyzer"
echo "$HR"
printf "  %-25s %s\n" "Date/Time:" "$(date)"
(( SCAN_LINES > 0 )) && printf "  %-25s %s lines per file\n" "Scan window:" "$SCAN_LINES" \
                      || printf "  %-25s %s\n" "Scan window:" "full file"

if [[ -n "$LOG_FILE" ]]; then
    if [[ ! -e "$LOG_FILE" ]]; then
        echo "Error: log file not found: $LOG_FILE" >&2
        exit 1
    fi
    analyze_file "$LOG_FILE"
else
    if [[ ! -d "$LOG_DIR" ]]; then
        echo "Error: log directory not found: $LOG_DIR" >&2
        exit 1
    fi
    # Find .log and .trc files, sorted by modification time (newest first)
    found=0
    while IFS= read -r -d '' f; do
        analyze_file "$f"
        (( found++ ))
    done < <(find "$LOG_DIR" -maxdepth 2 \( -name "*.log" -o -name "*.trc" \) -print0 \
             | xargs -0 ls -t 2>/dev/null | tr '\n' '\0' || true)

    if (( found == 0 )); then
        echo ""
        echo "  No *.log or *.trc files found in: $LOG_DIR"
    fi
fi

echo ""
