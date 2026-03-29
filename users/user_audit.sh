#!/usr/bin/env bash
# user_audit.sh – List local users with last-login date and account status.
#
# Usage: user_audit.sh [-s] [-h]
#   -s  Show system/service accounts too (UID < 1000)
#   -h  Show this help message
#
# Output columns: Username | UID | Shell | Last Login | Status (locked/active)
#
# Requires: lastlog or last, passwd, awk
# Privileges: none (may need sudo for lastlog details on some systems)

set -euo pipefail

SHOW_SYSTEM=false

usage() {
    sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,2\}//; p }' "$0"
    exit 0
}

while getopts ":sh" opt; do
    case $opt in
        s) SHOW_SYSTEM=true ;;
        h) usage ;;
        *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done

printf "%-20s %-6s %-20s %-28s %-10s\n" "Username" "UID" "Shell" "Last Login" "Status"
printf '%s\n' "$(printf '%.0s-' {1..90})"

while IFS=: read -r username _ uid _ _ _ shell; do
    # Skip system accounts unless -s given
    if ! $SHOW_SYSTEM && (( uid < 1000 )); then
        continue
    fi
    # Skip nologin/false shells
    if [[ "$shell" == */false || "$shell" == */nologin ]]; then
        status="no-login"
    else
        status="active"
    fi

    # Last login
    last_login="Never"
    if command -v lastlog &>/dev/null; then
        last_login=$(lastlog -u "$username" 2>/dev/null | tail -1 | awk '{
            if ($2=="**Never") print "Never";
            else print $4,$5,$6,$7,$8
        }')
    elif command -v last &>/dev/null; then
        last_login=$(last -n 1 "$username" 2>/dev/null | head -1 | awk '{print $4,$5,$6,$7}' | grep -v '^$' || echo "Never")
    fi

    # Locked status (Linux: passwd -S)
    if command -v passwd &>/dev/null; then
        lock_info=$(passwd -S "$username" 2>/dev/null | awk '{print $2}' || true)
        [[ "$lock_info" == "L" ]] && status="locked"
    fi

    printf "%-20s %-6s %-20s %-28s %-10s\n" "$username" "$uid" "$shell" "$last_login" "$status"
done < /etc/passwd
