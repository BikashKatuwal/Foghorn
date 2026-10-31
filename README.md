# Foghorn CCDC — 12 Read-Only Scripts

Target: **Rocky Linux**. Competition packet identifies Foghorn as **Wiki / Chat** at internal **192.168.220.13**, but **does not identify the actual software or URLs**. Discover them before changing anything.

## Install / run on your authorized practice VM

```bash
cd ~
git clone https://github.com/BikashKatuwal/Foghorn.git   # only if repository contains this toolkit
cd Foghorn
# Or extract this ZIP and cd into its folder
bash -n service-health.sh
sudo bash network-audit.sh
sudo bash service-health.sh
```

Run any script using `sudo bash SCRIPTNAME.sh` if elevated evidence is needed. Scripts **do not patch, stop, restart, block, delete or change configurations**. They write timestamped reports into `foghorn-reports/`, owned by the invoking user/root as applicable. **Never push the reports into public GitHub.** Reports may contain identities, network data, process arguments or sensitive logging.

| File | Purpose |
|---|---|
| `service-health.sh` | Discover running services/ports and check explicitly configured Wiki/Chat URLs |
| `user-audit.sh` | Accounts, wheel group, sessions and SSH key locations |
| `persistence-audit.sh` | Cron, timers, enabled units and startup paths |
| `process-audit.sh` | Processes, parent relationships, running services |
| `network-audit.sh` | Addresses, routing, sockets, DNS |
| `ssh-audit.sh` | Effective SSH config, journal and status |
| `web-audit.sh` | Apache/Nginx checks, website paths, relevant logs |
| `firewall-audit.sh` | Firewalld, nftables, SELinux state |
| `file-integrity.sh` | SHA-256 snapshot of selected configs and web files / compare |
| `container-audit.sh` | Docker/Podman inventory if installed |
| `incident-collector.sh` | Timestamped volatile state and recent journal events |
| `baseline-compare.sh` | Diff two existing triage/report directories |

## Examples

```bash
sudo bash service-health.sh
# After verifying the real Wiki/Chat URLs and making sure they are authorized:
sudo WIKI_URL='http://127.0.0.1/wiki/' CHAT_URL='http://127.0.0.1/chat/' bash service-health.sh
sudo bash file-integrity.sh snapshot
# Compare file manifests:
sudo bash file-integrity.sh compare /path/to/trusted/manifest.tsv
# Compare two report directories:
sudo bash baseline-compare.sh /path/to/old-report /path/to/new-report
```

## How to read the results

Every script prints `Saved reports: /path/...`. List the directory with `sudo ls -la /path/...` and open a named `.txt` with `sudo less /path/.../filename.txt`.

`file-integrity.sh`: the hashes are in `manifest.tsv`; compare with a *separately retained*, verified trusted manifest. A different hash needs investigation, not automatic deletion. Baseline snapshots might already contain attacker activity.

`service-health.sh`: local service status is **not** a substitute for login/post/send-message testing from a scoring vantage point. Wiki/Chat URLs must be established from actual applications/scoring guidance.

## Safety and competition rules

- Confirm permitted tooling with organizers before running AI-assisted scripts in the competition.
- Packet page 9 says AI-generated inject submissions receive zero points; do not submit generated inject content.
- Preserve score-required Wiki, Chat and SSH functionality; checks may occur every 2–4 minutes. Never blindly harden away scored ports.
- No remediation is automated. Investigate findings and coordinate with your captain.
- Commands gracefully leave an error in the relevant report if a tool (Docker, Apache, etc.) is missing.
