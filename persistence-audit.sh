#!/usr/bin/env bash
# cron, timers, enabled services, startup files and key locations
# READ ONLY: does not alter services, users, firewall, or application files.
set -uo pipefail
export LC_ALL=C
OUT_BASE="${OUT_BASE:-$HOME/foghorn-reports}"
# Never follow a user-supplied path to overwrite existing reports.
mkdir -p -- "$OUT_BASE" || exit 1
OUT=$(mktemp -d "$OUT_BASE/persistence-audit.$(date +%Y%m%d-%H%M%S).XXXXXX") || exit 1
chmod 700 "$OUT"
run(){ local name="$1"; shift; { printf 'COMMAND:'; printf ' %q' "$@"; printf '\n\n'; "$@"; } >"$OUT/$name.txt" 2>&1 || :; }
section(){ printf '\n===== %s =====\n' "$1"; }
finish(){ printf 'Saved reports: %s\n' "$OUT"; printf 'Treat outputs as sensitive: do not upload them publicly.\n'; }

run enabled systemctl list-unit-files --type=service --state=enabled --no-pager
run timers systemctl list-timers --all --no-pager
run cron-system ls -la /etc/crontab /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /var/spool/cron
run cron-text cat /etc/crontab
run custom-units find /etc/systemd/system -maxdepth 4 -type f -print
run startup-files find /etc/profile.d /etc/rc.d -maxdepth 2 -type f -print
run key-locations find /home /root -maxdepth 4 -type f -name authorized_keys -print
finish
