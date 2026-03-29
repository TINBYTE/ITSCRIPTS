#!/usr/bin/env bash
# bulk_create_users.sh – Create multiple Linux users from a CSV file.
#
# Usage: bulk_create_users.sh [-d <default-shell>] [-g <group>] [-h] <csv-file>
#   csv-file        Path to CSV with columns: username,full_name,password
#                   (header row is skipped automatically)
#   -d shell        Default login shell (default: /bin/bash)
#   -g group        Primary group for all created users (default: same as username)
#   -h              Show this help message
#
# CSV example:
#   username,full_name,password
#   jdoe,John Doe,Passw0rd!
#   asmith,Alice Smith,S3cur3Pass
#
# Requires: useradd, chpasswd
# Privileges: must be run as root (sudo)

set -euo pipefail

DEFAULT_SHELL="/bin/bash"
GROUP=""

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

while getopts ":d:g:h" opt; do
    case $opt in
        d) DEFAULT_SHELL="$OPTARG" ;;
        g) GROUP="$OPTARG" ;;
        h) usage ;;
        *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done
shift $(( OPTIND - 1 ))

if [[ $# -ne 1 ]]; then
    echo "Error: CSV file argument is required." >&2
    echo "Run with -h for usage." >&2
    exit 1
fi

CSV_FILE="$1"

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: File not found: $CSV_FILE" >&2
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

CREATED=0
SKIPPED=0
FAILED=0
LINE_NUM=0

while IFS=',' read -r username full_name password; do
    (( LINE_NUM++ ))

    # Skip header row
    [[ "$username" == "username" ]] && continue
    # Skip blank lines
    [[ -z "$username" ]] && continue

    # Trim whitespace
    username="${username// /}"

    if id "$username" &>/dev/null; then
        echo "SKIP    $username – user already exists."
        (( SKIPPED++ )) || true
        continue
    fi

    useradd_args=(-m -s "$DEFAULT_SHELL" -c "$full_name")
    [[ -n "$GROUP" ]] && useradd_args+=(-g "$GROUP")

    if useradd "${useradd_args[@]}" "$username" 2>/dev/null; then
        echo "$username:$password" | chpasswd
        echo "CREATED $username ($full_name)"
        (( CREATED++ )) || true
    else
        echo "FAILED  $username – useradd returned an error." >&2
        (( FAILED++ )) || true
    fi
done < "$CSV_FILE"

echo ""
echo "Done. Created: $CREATED  |  Skipped: $SKIPPED  |  Failed: $FAILED"
