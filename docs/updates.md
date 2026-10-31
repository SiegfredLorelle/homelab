# Updates

## Container images (Renovate)

Renovate watches `docker-compose.yml` and `caddy/Dockerfile` and opens PRs — config in `renovate.json`:
Saturdays before 9 AM (Asia/Manila), images pinned to digests, digest-only updates grouped,
major versions wait for approval on the **Dependency Dashboard** issue, nothing auto-merges.

1. **Review** the PR: read the release notes in its description, check **Files changed**.
2. **Merge** it on GitHub.
3. **Deploy** on the NUC: `cd /srv/apps && ./deploy.sh`
4. **Verify**: `lab.sieg.dev` all green, Uptime Kuma all up, `sieg.dev` loads.

Want an update before Saturday? Tick its box on the Dependency Dashboard.

**Rollback**: on the merged PR, click **Revert** and merge the revert PR, then `./deploy.sh` again.

**Disk**: `deploy.sh` removes dangling images. Old versions still pile up — every few months run
`docker image prune -a` (removes all unused images; the next Caddy build re-downloads its base).

## Host packages (apt)

Ubuntu's own packages update daily via unattended-upgrades (reboot at 04:00 if needed).
**Not covered**: packages from added repositories — cloudflared, Tailscale, Docker Engine.
Check with `apt list --upgradable`; update with `sudo apt update && sudo apt upgrade`.
(An automatic setup for these is planned.)

## Habits

- **Pull before editing on the NUC**: Renovate commits to GitHub too. `git pull` is set to `--ff-only`
  (`git config --global pull.ff only`), so diverged histories stop instead of merging silently.
- **Security news** about something we run (Tailscale, cloudflared, Caddy…): check whether our setup
  uses the affected feature, then update — even if not affected.
