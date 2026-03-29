#!/usr/bin/env bash
# backup.sh – Archive a directory as a timestamped tar.gz with retention.
#
# Usage: backup.sh [-d <dest>] [-k <days>] [-h] <source-dir>
#   source-dir   Directory to back up
#   -d dest      Destination directory for archives (default: /var/backups)
#   -k days      Number of days to keep old backups (default: 7, 0 = keep all)
#   -h           Show this help message
#
# Archive naming: <basename>_YYYYMMDD_HHMMSS.tar.gz
#
# Requires: tar, find
# Privileges: needs write access to dest; needs read access to source

set -euo pipefail

DEST="/var/backups"
KEEP_DAYS=7

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

while getopts ":d:k:h" opt; do
    case $opt in
        d) DEST="$OPTARG" ;;
        k) KEEP_DAYS="$OPTARG" ;;
        h) usage ;;
        *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done
shift $(( OPTIND - 1 ))

if [[ $# -ne 1 ]]; then
    echo "Error: source directory argument is required." >&2
    echo "Run with -h for usage." >&2
    exit 1
fi

SOURCE="$1"

if [[ ! -d "$SOURCE" ]]; then
    echo "Error: Source directory not found: $SOURCE" >&2
    exit 1
fi

mkdir -p "$DEST"

BASENAME=$(basename "$SOURCE")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE="${DEST}/${BASENAME}_${TIMESTAMP}.tar.gz"

echo "Backing up: $SOURCE"
echo "Archive:    $ARCHIVE"

tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$BASENAME"

SIZE=$(du -sh "$ARCHIVE" | cut -f1)
echo "Done. Archive size: $SIZE"

# Retention clean-up
if (( KEEP_DAYS > 0 )); then
    echo ""
    echo "Removing archives older than ${KEEP_DAYS} days from $DEST ..."
    find "$DEST" -maxdepth 1 -name "${BASENAME}_*.tar.gz" -mtime +"$KEEP_DAYS" -print -delete
    echo "Clean-up complete."
fi
