#!/usr/bin/env bash
# web-service details, application locations and logs (not secrets)
# READ ONLY: does not alter services, users, firewall, or application files.
set -uo pipefail
export LC_ALL=C
OUT_BASE="${OUT_BASE:-$HOME/foghorn-reports}"
# Never follow a user-supplied path to overwrite existing reports.
mkdir -p -- "$OUT_BASE" || exit 1
OUT=$(mktemp -d "$OUT_BASE/web-audit.$(date +%Y%m%d-%H%M%S).XXXXXX") || exit 1
chmod 700 "$OUT"
run(){ local name="$1"; shift; { printf 'COMMAND:'; printf ' %q' "$@"; printf '\n\n'; "$@"; } >"$OUT/$name.txt" 2>&1 || :; }
section(){ printf '\n===== %s =====\n' "$1"; }
finish(){ printf 'Saved reports: %s\n' "$OUT"; printf 'Treat outputs as sensitive: do not upload them publicly.\n'; }

run web-roots ls -la /var/www /opt /srv
run web-ports ss -tlnp
if command -v httpd >/dev/null; then
 run apache-config-test httpd -t
 run apache-vhosts httpd -S
 run apache-service systemctl status httpd --no-pager
 run apache-errors tail -n 100 /var/log/httpd/error_log
fi
if command -v nginx >/dev/null; then
 run nginx-config-test nginx -t
 run nginx-service systemctl status nginx --no-pager
 run nginx-errors tail -n 100 /var/log/nginx/error.log
fi
run app-packages rpm -qa
finish
