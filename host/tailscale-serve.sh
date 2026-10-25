#!/usr/bin/env bash
# Re-create the Tailscale Serve config (private apps, tailnet only).
# Run with sudo after `tailscale up`, with HTTPS certificates enabled in the admin console.
# Each private app gets its own HTTPS port; add a line per app.
set -euo pipefail

tailscale serve --bg --https=3001 http://127.0.0.1:3001   # Uptime Kuma
tailscale serve --bg --https=8082 http://127.0.0.1:8082   # Pi-hole admin

tailscale serve status
