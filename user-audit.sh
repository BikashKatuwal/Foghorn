#!/usr/bin/env bash
# accounts, sudo rights, login history, SSH authorized-key locations (not contents)
# READ ONLY: does not alter services, users, firewall, or application files.
set -uo pipefail
export LC_ALL=C
OUT_BASE="${OUT_BASE:-$HOME/foghorn-reports}"
# Never follow a user-supplied path to overwrite existing reports.
mkdir -p -- "$OUT_BASE" || exit 1
OUT=$(mktemp -d "$OUT_BASE/user-audit.$(date +%Y%m%d-%H%M%S).XXXXXX") || exit 1
chmod 700 "$OUT"
run(){ local name="$1"; shift; { printf 'COMMAND:'; printf ' %q' "$@"; printf '\n\n'; "$@"; } >"$OUT/$name.txt" 2>&1 || :; }
section(){ printf '\n===== %s =====\n' "$1"; }
finish(){ printf 'Saved reports: %s\n' "$OUT"; printf 'Treat outputs as sensitive: do not upload them publicly.\n'; }

run users getent passwd
run groups getent group
run wheel getent group wheel
run sudoers-files ls -l /etc/sudoers /etc/sudoers.d
run sessions who -a
run recent-logins last -n 40
run key-locations find /home /root -maxdepth 4 -type f -name authorized_keys -print
finish
