# Monitoring

Two layers, each covering the other's blind spot:

| Layer | Answers | Alerts within |
| --- | --- | --- |
| **healthchecks.io** (outside) | Is the NUC alive and online? | ~15 minutes |
| **Uptime Kuma** (on the NUC) | Is each app working? | ~3 minutes |

Uptime Kuma keeps its settings in its database, not in git. Until backups exist, this page is how to recreate them.

## healthchecks.io

- Check name: `nuc`
- Period: **5 minutes**, grace: **10 minutes**
- Pinged by the user crontab — see `host/crontab.example`
- Alerts: email

The ping URL stays out of git. Anyone holding it could send fake "alive" pings.

## Uptime Kuma

Version 2, SQLite database, data in `uptime-kuma/data/` (gitignored).
Reachable only over Tailscale at `https://<nuc>.<tailnet>.ts.net:3001` (see `host/tailscale-serve.sh`).

### Notification

| Setting | Value |
| --- | --- |
| Type | Email (SMTP) |
| Friendly name | Gmail |
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

If only the public monitor fails, the problem is the tunnel or Cloudflare. If both fail, Caddy is down.

When you add a monitor, add a row here in the same commit.
