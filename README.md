# homelab

Configuration for my home server, an Intel NUC running Ubuntu 26.04 LTS.
I'm learning in public — this repo grows as the setup does.

## Architecture
- **Public** apps go through a Cloudflare Tunnel → Caddy. No ports are open on the router.
- **Private** apps live at `<job>.lab.sieg.dev`, reachable only over Tailscale: Pi-hole resolves `*.lab.sieg.dev` to the NUC's Tailscale IP, and Caddy serves them with a Let's Encrypt wildcard certificate (Cloudflare DNS challenge). The `tailscale serve` `ts.net` URLs remain as a fallback.
- Host firewall (ufw): deny incoming; allow SSH from the LAN and all traffic over Tailscale.
- SSH: keys only, no passwords, no root login.
- Automatic security updates, with reboots at 04:00 when needed.
- Monitoring: healthchecks.io watches the NUC and its disk (smartd) from outside; Uptime Kuma watches each app.
- Tailscale exit node: my devices can route through home on untrusted Wi-Fi (chosen per device, off by default).

## Apps
| App | Exposure | Notes |
| --- | --- | --- |
| Caddy + static site | Public (sieg.dev) | Through the Cloudflare Tunnel |
| Uptime Kuma | Private — `status.lab.sieg.dev` | See [`docs/monitoring.md`](docs/monitoring.md) |
| Pi-hole | Private — `dns.lab.sieg.dev`; DNS on the Tailscale IP | Ad-blocking DNS for my devices |
| Homepage (dashboard) | Private — `lab.sieg.dev` | Start page: app tiles, live Pi-hole and Uptime Kuma widgets. Config in `homepage/config/` |

## Layout
- `docker-compose.yml`, `caddy/` — the app stack
- `uptime-kuma/data/`, `pihole/data/`, `caddy/data/` — app data and certificates (gitignored; belongs in backups)
- `homepage/config/` — dashboard config (YAML); its `logs/` folder is gitignored
- `.env.example` — template listing the required secrets; copy to `.env` (gitignored) and fill in
- `sites/` — static sites (each is its own repo; see `sites/README.md`)
- `host/` — copies of the system configs changed under `/etc`, plus setup scripts
- `docs/` — [rebuild runbook](docs/rebuild.md), [monitoring reference](docs/monitoring.md), [updates](docs/updates.md)
- `deploy.sh` — deploy what's on `main` (pull, fetch/rebuild images, restart what changed)
- `renovate.json` — Renovate settings for update PRs; see [`docs/updates.md`](docs/updates.md)

## Rebuild
Step by step in [`docs/rebuild.md`](docs/rebuild.md).

## Day to day
- Tailscale stays connected on every device (Android: **Always-on VPN**); the exit node is only for untrusted networks.
- Every device uses Pi-hole for DNS. If websites stop loading, turn Tailscale off on that device — if that fixes it, the NUC or Pi-hole is down (healthchecks.io / Uptime Kuma should have emailed).

## Secrets (not in git)
Kept in my password manager as secure notes, each with its restore path:
- **Cloudflare tunnel credentials** → `~/.cloudflared/<tunnel-id>.json`
- **Cloudflare cert.pem** → `~/.cloudflared/cert.pem`
- **Cloudflare API token (Caddy DNS)** → `/srv/apps/.env` as `CLOUDFLARE_API_TOKEN=...`
- **Pi-hole admin password** → `/srv/apps/.env` as `PIHOLE_PASSWORD=...`
- **Pi-hole app password (Homepage)** → `/srv/apps/.env` as `HOMEPAGE_VAR_PIHOLE_KEY=...`

Restore: recreate each file with the note's exact contents, then:

    chmod 600 ~/.cloudflared/*.json ~/.cloudflared/cert.pem /srv/apps/.env
