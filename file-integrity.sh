#!/usr/bin/env bash
# record hashes of known app and system configs, compare with separately captured baseline
# READ ONLY: does not alter services, users, firewall, or application files.
set -uo pipefail
export LC_ALL=C
OUT_BASE="${OUT_BASE:-$HOME/foghorn-reports}"
# Never follow a user-supplied path to overwrite existing reports.
mkdir -p -- "$OUT_BASE" || exit 1
OUT=$(mktemp -d "$OUT_BASE/file-integrity.$(date +%Y%m%d-%H%M%S).XXXXXX") || exit 1
chmod 700 "$OUT"
run(){ local name="$1"; shift; { printf 'COMMAND:'; printf ' %q' "$@"; printf '\n\n'; "$@"; } >"$OUT/$name.txt" 2>&1 || :; }
section(){ printf '\n===== %s =====\n' "$1"; }
finish(){ printf 'Saved reports: %s\n' "$OUT"; printf 'Treat outputs as sensitive: do not upload them publicly.\n'; }

MODE="${1:-snapshot}"
case "$MODE" in snapshot|compare) ;; *) echo 'Usage: file-integrity.sh [snapshot|compare] [baseline.tsv]' >&2; exit 2;; esac
BASELINE="${2:-}"
# Paths are configurable; avoid data directories with large media or secrets.
PATHS=(/etc/ssh/sshd_config /etc/httpd/conf /etc/httpd/conf.d /etc/nginx/nginx.conf /etc/nginx/conf.d /var/www/html)
if [[ -n "${INTEGRITY_PATHS:-}" ]]; then IFS=: read -r -a PATHS <<< "$INTEGRITY_PATHS"; fi
manifest="$OUT/manifest.tsv"
: > "$manifest"
for p in "${PATHS[@]}"; do
  [[ -f "$p" ]] && printf '%s\0' "$p"
  [[ -d "$p" ]] && find "$p" -xdev -type f -print0 2>/dev/null
 done | sort -zu | while IFS= read -r -d '' f; do
  # Only hash readable regular files; no content is included in report.
  if [[ -r "$f" ]]; then sha256sum -- "$f" 2>/dev/null || :; fi
done > "$manifest"
if [[ "$MODE" == compare ]]; then
  if [[ -z "$BASELINE" || ! -f "$BASELINE" ]]; then echo 'Provide a trusted baseline.tsv path for comparison' >&2; exit 2; fi
  diff -u -- "$BASELINE" "$manifest" > "$OUT/differences.txt" || :
  echo 'Review differences.txt (empty means identical selected hashes).'
else
  echo 'Save this manifest as a trusted reference after verifying the system is clean.'
fi
finish
