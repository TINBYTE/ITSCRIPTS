#!/usr/bin/env bash
# x3_backup.sh – Create a timestamped archive of a Sage X3 dossier directory.
#
# Usage: x3_backup.sh [-d <dest>] [-k <days>] [-c <dossier>] [-h] <x3-dossier-dir>
#   x3-dossier-dir   Path to the X3 dossier directory to back up (e.g. /opt/sagex3/folders/MYCOMP)
#   -d dest          Destination directory for archives (default: /var/backups/sagex3)
#   -k days          Retention: delete backups older than N days (default: 14, 0 = keep all)
#   -c dossier       Dossier/company code used in archive name (default: basename of source)
#   -h               Show this help message
#
# Archive naming: <dossier>_YYYYMMDD_HHMMSS.tar.gz
#
# What is backed up:
#   The entire dossier directory tree, including sub-folders for
#   FIL (data files), REPA (report templates), PROC (scripts), TRT (programs),
#   GES (screen / object definitions), and any custom-code sub-directories.
#
# Examples:
#   x3_backup.sh /opt/sagex3/folders/MYCOMP
#   x3_backup.sh -d /mnt/nas/backups -k 30 -c MYCOMP /opt/sagex3/folders/MYCOMP
#
# Requires: tar, find, du
# Privileges: needs read access to source; write access to dest (may need sudo)

set -euo pipefail

DEST="/var/backups/sagex3"
KEEP_DAYS=14
DOSSIER=""

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

while getopts ":d:k:c:h" opt; do
    case $opt in
        d) DEST="$OPTARG" ;;
        k) KEEP_DAYS="$OPTARG" ;;
        c) DOSSIER="$OPTARG" ;;
        h) usage ;;
        *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done
shift $(( OPTIND - 1 ))

if [[ $# -ne 1 ]]; then
    echo "Error: x3-dossier-dir argument is required." >&2
    echo "Run with -h for usage." >&2
    exit 1
fi

SOURCE="$1"

if [[ ! -d "$SOURCE" ]]; then
    echo "Error: dossier directory not found: $SOURCE" >&2
    exit 1
fi

[[ -z "$DOSSIER" ]] && DOSSIER=$(basename "$SOURCE")

mkdir -p "$DEST"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE="${DEST}/${DOSSIER}_${TIMESTAMP}.tar.gz"

HR="$(printf '%0.s─' {1..60})"

echo "$HR"
echo "  Sage X3 Dossier Backup"
echo "$HR"
printf "  %-22s %s\n" "Dossier:"    "$DOSSIER"
printf "  %-22s %s\n" "Source:"     "$SOURCE"
printf "  %-22s %s\n" "Archive:"    "$ARCHIVE"
printf "  %-22s %s\n" "Started:"    "$(date)"

# Estimate source size
SRC_SIZE=$(du -sh "$SOURCE" 2>/dev/null | cut -f1 || echo "N/A")
printf "  %-22s %s\n" "Source size:" "$SRC_SIZE"
echo ""

echo "  Compressing …"
# Use the real directory name for tar's path argument; DOSSIER is used only for archive naming
SRC_BASENAME=$(basename "$SOURCE")
tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$SRC_BASENAME"

ARC_SIZE=$(du -sh "$ARCHIVE" 2>/dev/null | cut -f1 || echo "N/A")
echo "  Done. Archive size: $ARC_SIZE"
printf "  %-22s %s\n" "Finished:" "$(date)"

# ── Retention clean-up ───────────────────────────────────────
if (( KEEP_DAYS > 0 )); then
    echo ""
    echo "  Removing archives older than ${KEEP_DAYS} days from ${DEST} …"
    removed=0
    while IFS= read -r -d '' old; do
        echo "  Removing: $(basename "$old")"
        rm -f "$old"
        (( removed++ ))
    done < <(find "$DEST" -maxdepth 1 -name "${DOSSIER}_*.tar.gz" \
                  -mtime +"$KEEP_DAYS" -print0 2>/dev/null)
    if (( removed == 0 )); then
        echo "  No old archives to remove."
    else
        echo "  Removed $removed archive(s)."
    fi
fi

echo ""
echo "$HR"
echo "  Backup completed successfully: $ARCHIVE"
echo "$HR"
echo ""
