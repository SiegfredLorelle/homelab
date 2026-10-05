#!/usr/bin/env bash
# Recreate the NUC firewall. Run with sudo on a fresh install.
set -euo pipefail
ufw default deny incoming
ufw default allow outgoing
ufw allow from 192.168.68.0/22 to any port 22 proto tcp comment 'LAN SSH'
ufw allow in on tailscale0 comment 'Tailscale mesh'
ufw allow 41641/udp comment 'Tailscale direct connections'
ufw --force enable
ufw status verbose
