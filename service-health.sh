#!/usr/bin/env bash
# service health and OPTIONAL explicitly configured Wiki/Chat URLs
# READ ONLY: does not alter services, users, firewall, or application files.
set -uo pipefail
export LC_ALL=C
OUT_BASE="${OUT_BASE:-$HOME/foghorn-reports}"
# Never follow a user-supplied path to overwrite existing reports.
mkdir -p -- "$OUT_BASE" || exit 1
OUT=$(mktemp -d "$OUT_BASE/service-health.$(date +%Y%m%d-%H%M%S).XXXXXX") || exit 1
chmod 700 "$OUT"
run(){ local name="$1"; shift; { printf 'COMMAND:'; printf ' %q' "$@"; printf '\n\n'; "$@"; } >"$OUT/$name.txt" 2>&1 || :; }
section(){ printf '\n===== %s =====\n' "$1"; }
finish(){ printf 'Saved reports: %s\n' "$OUT"; printf 'Treat outputs as sensitive: do not upload them publicly.\n'; }

run running-services systemctl list-units --type=service --state=running --no-pager
run listeners ss -tulpn
for name in sshd httpd nginx mariadb postgresql docker podman; do
  run "service-$name" systemctl is-active "$name"
done
# Configure with WIKI_URL and CHAT_URL; do not guess service endpoints.
for service in WIKI CHAT; do
  var="${service}_URL"; url="${!var:-}"
  [[ -z "$url" ]] && continue
  case "$url" in http://*|https://*) ;; *) echo "Skipping $var: URL must start http(s)" >&2; continue;; esac
  # Restrict to URLs explicitly supplied by operator; output status only.
  run "${service,,}-http" curl --silent --show-error --location --output /dev/null --write-out 'status=%{http_code} total=%{time_total}s final=%{url_effective}\n' --connect-timeout 4 --max-time 12 "$url"
done
finish
