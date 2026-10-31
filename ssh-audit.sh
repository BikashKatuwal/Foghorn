#!/usr/bin/env bash
# effective SSH configuration, logs, and listener status
# READ ONLY: does not alter services, users, firewall, or application files.
set -uo pipefail
export LC_ALL=C
OUT_BASE="${OUT_BASE:-$HOME/foghorn-reports}"
# Never follow a user-supplied path to overwrite existing reports.
mkdir -p -- "$OUT_BASE" || exit 1
OUT=$(mktemp -d "$OUT_BASE/ssh-audit.$(date +%Y%m%d-%H%M%S).XXXXXX") || exit 1
chmod 700 "$OUT"
run(){ local name="$1"; shift; { printf 'COMMAND:'; printf ' %q' "$@"; printf '\n\n'; "$@"; } >"$OUT/$name.txt" 2>&1 || :; }
section(){ printf '\n===== %s =====\n' "$1"; }
finish(){ printf 'Saved reports: %s\n' "$OUT"; printf 'Treat outputs as sensitive: do not upload them publicly.\n'; }

if command -v sshd >/dev/null; then run effective-config sshd -T; fi
run status systemctl status sshd --no-pager
run auth-events journalctl -u sshd --since '2 hours ago' --no-pager
run listeners ss -tlnp
run sessions who -a
finish
