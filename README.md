# homelab

Configuration for my home server, an Intel NUC running Ubuntu 26.04 LTS.
I'm learning in public — this repo grows as the setup does.

## Architecture
- **Public** apps go through a Cloudflare Tunnel → Caddy. No ports are open on the router.
- **Private** apps (admin tools, dashboards) are reachable only over Tailscale, via `tailscale serve`.
- Host firewall (ufw): deny incoming; allow SSH from the LAN and all traffic over Tailscale.
- SSH: keys only, no passwords, no root login.
- Automatic security updates, with reboots at 04:00 when needed.
- Monitoring: healthchecks.io watches the NUC and its disk (smartd) from outside; Uptime Kuma watches each app.

## Apps
| App | Exposure | Notes |
| --- | --- | --- |
| Caddy + static site | Public (sieg.dev) | Through the Cloudflare Tunnel |
| Uptime Kuma | Private (Tailscale) | See [`docs/monitoring.md`](docs/monitoring.md) |
| Pi-hole | Private (Tailscale DNS) | Ad-blocking DNS for my devices; DNS on the Tailscale IP only |

## Layout
- `docker-compose.yml`, `caddy/` — the app stack
- `uptime-kuma/data/`, `pihole/data/` — app data (gitignored; belongs in backups)
- `.env.example` — template listing the required secrets; copy to `.env` (gitignored) and fill in
- `sites/` — static sites (each is its own repo; see `sites/README.md`)
- `host/` — copies of the system configs changed under `/etc`, plus setup scripts
- `docs/` — [rebuild runbook](docs/rebuild.md) and [monitoring reference](docs/monitoring.md)

## Rebuild
Step by step in [`docs/rebuild.md`](docs/rebuild.md).

## Secrets (not in git)
Kept in my password manager as secure notes, each with its restore path:
- **Cloudflare tunnel credentials** → `~/.cloudflared/<tunnel-id>.json`
- **Cloudflare cert.pem** → `~/.cloudflared/cert.pem`
- **Pi-hole admin password** → `/srv/apps/.env` as `PIHOLE_PASSWORD=...`

Restore: recreate each file with the note's exact contents, then:

    chmod 600 ~/.cloudflared/*.json ~/.cloudflared/cert.pem /srv/apps/.env
