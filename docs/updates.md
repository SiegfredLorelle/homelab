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

Updated daily by unattended-upgrades (reboot at 04:00 if needed):
- Ubuntu security updates — including Docker, which is Ubuntu's own package (`docker.io`),
  so only conservative fixes
- **Tailscale, cloudflared, NodeSource (Node 24)** — added in `host/apt/51unattended-upgrades-thirdparty`

**Manual**: Ubuntu's non-security bug-fix updates. Check occasionally (e.g. with Saturday's
Renovate PRs): `apt list --upgradable`, then `sudo apt update && sudo apt upgrade`.

**Adding a third-party repo later**: find its labels with `apt-cache policy`, add a line to
`host/apt/51unattended-upgrades-thirdparty`, copy it to `/etc/apt/apt.conf.d/`, and check with
`sudo unattended-upgrade --dry-run --debug 2>&1 | grep -i 'allowed origins'`.

Updated services restart themselves automatically (Ubuntu's `needrestart`, e.g. cloudflared).
**Kernel** updates need a reboot — automatic at 04:00, or `sudo reboot` to do it while watching.

## Habits

- **Pull before editing on the NUC**: Renovate commits to GitHub too. `git pull` is set to `--ff-only`
  (`git config --global pull.ff only`), so diverged histories stop instead of merging silently.
- If `git pull` says the branches have diverged, you have unpushed local commits while GitHub
  moved on (e.g. a merged Renovate PR). Run `git pull --rebase` — it replays your local commits
  on top. Safe for commits not yet pushed.
- **Security news** about something we run (Tailscale, cloudflared, Caddy…): check whether our setup
  uses the affected feature, then update — even if not affected.
