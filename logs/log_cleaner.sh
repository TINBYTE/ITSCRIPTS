#!/usr/bin/env bash
# log_cleaner.sh – Delete or compress log files older than N days.
#
# Usage: log_cleaner.sh [-d <dir>] [-a <days>] [-c] [-p <pattern>] [-n] [-h]
#   -d dir      Directory to clean (default: /var/log)
#   -a days     Age threshold in days (default: 30)
#   -c          Compress instead of delete (gzip files not already compressed)
#   -p pattern  Filename glob pattern (default: *.log)
#   -n          Dry-run – print what would be done, but do nothing
#   -h          Show this help message
#
# Examples:
#   log_cleaner.sh -d /var/log/myapp -a 14 -c
#   log_cleaner.sh -d /var/log -a 60 -p "*.log" -n
#
# Requires: find, gzip
# Privileges: needs write access to the log directory (often root)

set -euo pipefail

LOG_DIR="/var/log"
AGE_DAYS=30
COMPRESS=false
PATTERN="*.log"
DRY_RUN=false

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

while getopts ":d:a:cp:nh" opt; do
    case $opt in
        d) LOG_DIR="$OPTARG" ;;
        a) AGE_DAYS="$OPTARG" ;;
        c) COMPRESS=true ;;
        p) PATTERN="$OPTARG" ;;
        n) DRY_RUN=true ;;
        h) usage ;;
        *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done

if [[ ! -d "$LOG_DIR" ]]; then
    echo "Error: Log directory not found: $LOG_DIR" >&2
    exit 1
fi

$DRY_RUN && echo "[DRY RUN] No files will actually be modified."
echo "Directory : $LOG_DIR"
echo "Pattern   : $PATTERN"
echo "Older than: ${AGE_DAYS} days"
echo "Action    : $($COMPRESS && echo compress || echo delete)"
echo ""

COUNT=0
SIZE_FREED=0

while IFS= read -r -d '' file; do
    file_size=$(du -b "$file" 2>/dev/null | cut -f1 || echo 0)
    if $COMPRESS; then
        if $DRY_RUN; then
            echo "COMPRESS (dry-run): $file"
        else
            gzip -9 "$file" && echo "COMPRESSED: ${file}.gz"
        fi
    else
        if $DRY_RUN; then
            echo "DELETE (dry-run): $file"
        else
            rm -f "$file" && echo "DELETED: $file"
        fi
        (( SIZE_FREED += file_size )) || true
    fi
    (( COUNT++ )) || true
done < <(find "$LOG_DIR" -maxdepth 3 -name "$PATTERN" -mtime +"$AGE_DAYS" -type f -print0)

echo ""
echo "Files processed: $COUNT"
if ! $COMPRESS; then
    freed_human=$(numfmt --to=iec-i --suffix=B "$SIZE_FREED" 2>/dev/null || echo "${SIZE_FREED} bytes")
    echo "Space freed:     $freed_human"
fi
