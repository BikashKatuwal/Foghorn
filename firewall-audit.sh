#!/usr/bin/env bash
# firewalld zones, nftables and SELinux status
# READ ONLY: does not alter services, users, firewall, or application files.
set -uo pipefail
export LC_ALL=C
OUT_BASE="${OUT_BASE:-$HOME/foghorn-reports}"
# Never follow a user-supplied path to overwrite existing reports.
mkdir -p -- "$OUT_BASE" || exit 1
OUT=$(mktemp -d "$OUT_BASE/firewall-audit.$(date +%Y%m%d-%H%M%S).XXXXXX") || exit 1
chmod 700 "$OUT"
run(){ local name="$1"; shift; { printf 'COMMAND:'; printf ' %q' "$@"; printf '\n\n'; "$@"; } >"$OUT/$name.txt" 2>&1 || :; }
section(){ printf '\n===== %s =====\n' "$1"; }
finish(){ printf 'Saved reports: %s\n' "$OUT"; printf 'Treat outputs as sensitive: do not upload them publicly.\n'; }

run firewalld-status systemctl status firewalld --no-pager
if command -v firewall-cmd >/dev/null; then
 run zones firewall-cmd --get-active-zones
 run rules firewall-cmd --list-all-zones
fi
if command -v nft >/dev/null; then run nft-rules nft list ruleset; fi
if command -v getenforce >/dev/null; then run selinux getenforce; fi
if command -v sestatus >/dev/null; then run selinux-detail sestatus; fi
if command -v ausearch >/dev/null; then run recent-denials ausearch -m AVC,USER_AVC -ts recent; fi
finish
