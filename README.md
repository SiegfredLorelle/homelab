# homelab

Configuration for my home server, an Intel NUC running Ubuntu 26.04 LTS.
I'm learning in public — this repo grows as the setup does.

## Architecture
- **Public** apps go through a Cloudflare Tunnel → Caddy. No ports are open on the router.
- **Private** apps (admin tools, dashboards) are reachable only over Tailscale.
- Host firewall (ufw): deny incoming; allow SSH from the LAN and all traffic over Tailscale.
- SSH: keys only, no passwords, no root login.
- Automatic security updates, with reboots at 04:00 when needed.

## Layout
- `docker-compose.yml`, `caddy/` — the app stack
- `sites/` — static sites (each is its own repo; see `sites/README.md`)
- `host/` — copies of the system configs changed under `/etc`

## Rebuild (outline)
1. Install Ubuntu, Docker, Tailscale, cloudflared.
2. Clone this repo to `/srv/apps`, and clone the sites into `sites/`.
3. Copy `host/` files back to their `/etc` locations; run `sudo ./host/ufw-setup.sh`.
4. Restore the tunnel credentials (kept outside git), then run `docker compose up -d`.
5. Recreate the gitleaks pre-commit hook in `.git/hooks/`.
