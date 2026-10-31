#!/usr/bin/env bash
# Docker/Podman containers, mounts and published ports; no secrets dump
# READ ONLY: does not alter services, users, firewall, or application files.
set -uo pipefail
export LC_ALL=C
OUT_BASE="${OUT_BASE:-$HOME/foghorn-reports}"
# Never follow a user-supplied path to overwrite existing reports.
mkdir -p -- "$OUT_BASE" || exit 1
OUT=$(mktemp -d "$OUT_BASE/container-audit.$(date +%Y%m%d-%H%M%S).XXXXXX") || exit 1
chmod 700 "$OUT"
run(){ local name="$1"; shift; { printf 'COMMAND:'; printf ' %q' "$@"; printf '\n\n'; "$@"; } >"$OUT/$name.txt" 2>&1 || :; }
section(){ printf '\n===== %s =====\n' "$1"; }
finish(){ printf 'Saved reports: %s\n' "$OUT"; printf 'Treat outputs as sensitive: do not upload them publicly.\n'; }

if command -v podman >/dev/null; then
 run podman-containers podman ps -a --no-trunc
 run podman-images podman images
 run podman-ports podman ps --format '{{.ID}} {{.Names}} {{.Ports}}'
fi
if command -v docker >/dev/null; then
 run docker-containers docker ps -a --no-trunc
 run docker-images docker images
 run docker-ports docker ps --format '{{.ID}} {{.Names}} {{.Ports}}'
fi
finish
