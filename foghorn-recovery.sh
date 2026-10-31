#!/usr/bin/env bash
# Foghorn (Rocky Linux) CCDC incident triage - read-only by default.
# --safe-fix: only attempt to start nginx/php-fpm if inactive AND nginx -t passes for nginx.
set -u
umask 077
SAFE_FIX=0
if [[ "${1:-}" == "--safe-fix" ]]; then SAFE_FIX=1; elif [[ $# -gt 0 ]]; then echo "Usage: bash $0 [--safe-fix]"; exit 2; fi
OUT="/root/foghorn-reports/recovery.$(date +%Y%m%d-%H%M%S).$$"
mkdir -p "$OUT" || exit 1
exec > >(tee "$OUT/summary.txt") 2>&1
say(){ printf '\n===== %s =====\n' "$*"; }
run(){ local tag="$1"; shift; say "$tag"; timeout 20 "$@" 2>&1 || echo "[CHECK WARNING] $tag failed or timed out (exit=$?)"; }
check_http(){ local tag="$1" host="$2" path="$3"; say "$tag"; curl --noproxy '*' -k -sS -L --max-redirs 3 --connect-timeout 4 --max-time 12 --resolve "${host}:443:192.168.220.13" -o "$OUT/${tag}.html" -w 'HTTP=%{http_code} remote_ip=%{remote_ip} redirect=%{url_effective}\n' "https://${host}${path}" || echo '[CHECK WARNING] HTTPS request failed'; }
say 'Context'; date -Is; hostnamectl 2>&1 | head -n 12; id; echo "SAFE_FIX=$SAFE_FIX"
run 'Network addresses' ip -br addr
run 'Routes' ip route
run 'Resolver' cat /etc/resolv.conf
run 'Host resolution wiki' getent ahostsv4 wiki.acme.anvil
run 'Host resolution chat' getent ahostsv4 chat.acme.anvil
run 'Host resolution SSO' getent ahostsv4 sso.acme.anvil
run 'Listening sockets' ss -tulpn
run 'Service statuses' systemctl --no-pager --plain status nginx php-fpm sshd
run 'Failed services' systemctl --failed --no-pager
run 'Running services' systemctl list-units --type=service --state=running --no-pager
run 'Scheduled timers' systemctl list-timers --all --no-pager
run 'Podman containers' podman ps -a
run 'Root cron' crontab -l
run 'System cron' cat /etc/crontab
run 'System cron directories' ls -la /etc/cron.d /etc/cron.hourly
run 'Nginx configuration validation' nginx -t
run 'Nginx virtual hosts (redacted to specific lines)' bash -c "nginx -T 2>&1 | grep -E 'server_name|listen |proxy_pass|ssl_certificate '"
run 'Firewall service state' systemctl is-active firewalld
run 'Firewall nftables summary' bash -c "nft list ruleset 2>&1 | grep -Ei 'hook input|policy|drop|reject|dport (80|443)' | head -n 80"
check_http wiki wiki.acme.anvil '/doku.php?id=start'
check_http chat chat.acme.anvil '/api/info'
say 'Local TLS trust checks (no -k)'
for host in wiki.acme.anvil chat.acme.anvil; do curl --noproxy '*' -sS --connect-timeout 4 --max-time 8 --resolve "${host}:443:192.168.220.13" -o /dev/null -w "$host HTTP=%{http_code} TLS_verify=%{ssl_verify_result}\n" "https://$host/" || true; done
say 'TLS certificate from nginx'
for host in wiki.acme.anvil chat.acme.anvil; do echo "-- $host --"; timeout 8 openssl s_client -connect 192.168.220.13:443 -servername "$host" </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName -fingerprint -sha256 2>&1 || true; done
say 'SSO exact endpoint'
curl --noproxy '*' -sS -o "$OUT/sso.json" -w 'HTTP=%{http_code} remote_ip=%{remote_ip}\n' --connect-timeout 4 --max-time 10 'http://sso.acme.anvil/realms/master/.well-known/openid-configuration' || true
say 'Network neighbor SSO'; ip neigh show 192.168.220.122
say 'Recent nginx access (sensitive URLs may appear)'; tail -n 60 /var/log/nginx/access.log 2>&1 || true
say 'Recent nginx errors'; tail -n 70 /var/log/nginx/error.log 2>&1 || true
say 'Recent service warnings'; journalctl --since '30 minutes ago' -p warning -n 70 --no-pager 2>&1 || true
say 'Recently changed systemd files'; find /etc/systemd/system -type f -mmin -240 -ls 2>/dev/null | head -n 50
say 'Relevant service definitions (may contain secret paths; review before sharing)'
for svc in wiki-hook.service vault-agent-rocketchat.service forgejo-runner.service meshagent.service; do systemctl show "$svc" -p Id -p FragmentPath -p ExecStart -p ActiveState 2>&1; done
if [[ "$SAFE_FIX" == 1 ]]; then
  say 'SAFE FIX: bounded service recovery'
  if ! systemctl is-active --quiet nginx; then
    if nginx -t; then echo 'nginx inactive; attempting start'; systemctl start nginx; else echo 'nginx config invalid; NOT starting'; fi
  else echo 'nginx active: unchanged'; fi
  if ! systemctl is-active --quiet php-fpm; then echo 'php-fpm inactive; attempting start'; systemctl start php-fpm; else echo 'php-fpm active: unchanged'; fi
  systemctl is-active nginx php-fpm || true
fi
say 'Completed'; echo "REPORT_DIR=$OUT"; echo 'Do not share raw files publicly: may contain internal IPs, usernames, URLs, or session data.'
