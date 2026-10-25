# Monitoring

Two layers, each covering the other's blind spot:

| Layer | Answers | Alerts within |
| --- | --- | --- |
| **healthchecks.io** (outside) | Is the NUC alive and online? Is its disk healthy? | ~15 minutes (disk: instant on failure) |
| **Uptime Kuma** (on the NUC) | Is each app working? | ~3 minutes |

Uptime Kuma keeps its settings in its database, not in git. Until backups exist, this page is how to recreate them.

## healthchecks.io

Alerts: email. Ping URLs stay out of git — anyone holding one could send fake "alive" pings.

### Whole-box heartbeat: `nuc`

- Period: **5 minutes**, grace: **10 minutes**
- Pinged by the user crontab — see `host/crontab.example`

### Disk health: `nuc-disk`

- Period: **1 day**, grace: **2 hours**
- `smartd` watches `/dev/sda` (short self-test daily 02:00, long Sundays 03:00) and runs `host/smart/smartd-alert.sh` on any problem → instant **fail** ping
- Cron runs the same script daily at 09:00 → **OK** ping if `smartctl -H` reports PASSED
- Ping URL in `/etc/smart-healthcheck.env` (root-only, not in git)
- Drive: BIWIN 64 GB SATA SSD. `Power_On_Hours` is unreliable on this model; watch reallocated sectors, uncorrectable errors, and wear leveling instead

## Uptime Kuma

Version 2, SQLite database, data in `uptime-kuma/data/` (gitignored).
Reachable only over Tailscale at `https://<nuc>.<tailnet>.ts.net:3001` (see `host/tailscale-serve.sh`).

### Notification

| Setting | Value |
| --- | --- |
| Type | Email (SMTP) |
| Friendly name | Personal Gmail |
| Host / port | `smtp.gmail.com` / `587`, None / STARTTLS |
| Username | Gmail address |
| Password | Google **app password** (kept in the password manager) |
| Default enabled | Yes, and applied to all existing monitors |

Switch this to the new provider's SMTP server when email moves off Gmail, then revoke the app password.

### Monitors

All monitors: heartbeat interval **60 s**, retries **2**, retry interval **60 s**.

| Name | Type | Target | Extra |
| --- | --- | --- | --- |
| Personal Website (public) | HTTP(s) - Keyword | `https://sieg.dev` | Keyword from the page title; certificate expiry and domain expiry notifications on |
| Caddy (internal) | HTTP(s) | `http://caddy:8081` | Uses the Docker service name, not `127.0.0.1` |
| Pi-hole (DNS) | DNS | `github.com` via resolver `pihole`, port 53 | Containers can't reach `100.115.71.107` (ufw blocks the Docker bridge), so it uses the service name. Domain expiry off |

If only the public monitor fails, the problem is the tunnel or Cloudflare. If both fail, Caddy is down.

When you add a monitor, add a row here in the same commit.
