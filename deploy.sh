#!/usr/bin/env bash
# Deploy what's on main: pull the repo, fetch images, rebuild Caddy, restart only what changed.
set -euo pipefail
cd "$(dirname "$0")"

git pull --ff-only
docker compose pull --ignore-buildable   # registry images (skips our locally built Caddy)
docker compose build --pull              # rebuild Caddy from its pinned base images
docker compose up -d                     # recreates only containers whose image changed
docker image prune -f                    # remove dangling leftovers
docker compose ps
