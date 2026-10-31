#!/usr/bin/env bash
# compare two saved triage report folders by filenames and text diffs
# READ ONLY: does not alter services, users, firewall, or application files.
set -uo pipefail
export LC_ALL=C
OUT_BASE="${OUT_BASE:-$HOME/foghorn-reports}"
# Never follow a user-supplied path to overwrite existing reports.
mkdir -p -- "$OUT_BASE" || exit 1
OUT=$(mktemp -d "$OUT_BASE/baseline-compare.$(date +%Y%m%d-%H%M%S).XXXXXX") || exit 1
chmod 700 "$OUT"
run(){ local name="$1"; shift; { printf 'COMMAND:'; printf ' %q' "$@"; printf '\n\n'; "$@"; } >"$OUT/$name.txt" 2>&1 || :; }
section(){ printf '\n===== %s =====\n' "$1"; }
finish(){ printf 'Saved reports: %s\n' "$OUT"; printf 'Treat outputs as sensitive: do not upload them publicly.\n'; }

OLD="${1:-}"; NEW="${2:-}"
if [[ ! -d "$OLD" || ! -d "$NEW" ]]; then
 echo 'Usage: baseline-compare.sh OLD_REPORT_DIR NEW_REPORT_DIR' >&2; exit 2
fi
# File list, textual changes; timestamps and dynamic values can change legitimately.
{ echo 'FILES IN OLD'; find "$OLD" -maxdepth 1 -type f -printf '%f\n' | sort; echo 'FILES IN NEW'; find "$NEW" -maxdepth 1 -type f -printf '%f\n' | sort; } > "$OUT/files.txt"
for f in "$OLD"/*.txt; do
  [[ -f "$f" ]] || continue
  name="${f##*/}"
  [[ -f "$NEW/$name" ]] || { echo "Missing in new: $name" >> "$OUT/summary.txt"; continue; }
  diff -u -- "$f" "$NEW/$name" > "$OUT/diff-$name" || :
  [[ -s "$OUT/diff-$name" ]] && echo "Changed: $name" >> "$OUT/summary.txt" || rm -f "$OUT/diff-$name"
done
printf 'Diffs are indicators only; first baseline may already contain threats.\n' >> "$OUT/summary.txt"
finish
