# sites/

Static sites served by Caddy (mounted at /srv in the container).
Each site is its own git repo and is not tracked here.

| Site | Repo | Served at |
| --- | --- | --- |
| `personal-website` | public | `sieg.dev` (and any other host on `:8081`) |
| `viralab-site` | private | `viralab.sieg.dev` |

Deploy a site: `git pull` in its folder. Caddy serves the files directly, so nothing needs restarting.

## Restore
    cd /srv/apps/sites
    git clone git@github.com:SiegfredLorelle/personal-website.git

`viralab-site` is private, so it needs its own read-only deploy key (GitHub won't reuse the
homelab repo's key for a second repo):

    ssh-keygen -t ed25519 -C "nuc viralab-site" -f ~/.ssh/viralab-site -N ""
    cat ~/.ssh/viralab-site.pub   # GitHub → viralab-site → Settings → Deploy keys (read-only)
    cat >> ~/.ssh/config << 'CFG'
    Host github-viralab-site
        HostName github.com
        User git
        IdentityFile ~/.ssh/viralab-site
        IdentitiesOnly yes
    CFG
    cd /srv/apps/sites && git clone github-viralab-site:SiegfredLorelle/viralab-site.git
