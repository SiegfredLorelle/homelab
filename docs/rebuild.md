# Rebuild runbook

How to go from a blank NUC to everything running again.
Steps marked **(manual)** happen outside the NUC — in the BIOS, the router app, or a web dashboard.

## Before you start

You need access to:

- the password manager (tunnel credentials, app logins, recovery codes)
- GitHub (this repo and the website repo)
- the Cloudflare, Tailscale, and healthchecks.io dashboards
- the router app (TP-Link Deco)

## 1. Hardware and OS

1. **(manual)** BIOS (F2 at boot): **Power → Secondary Power Settings → After Power Failure → Power On**. Save with F10.
2. Install **Ubuntu 26.04 LTS**, with OpenSSH server enabled.
3. Set the timezone:

        sudo timedatectl set-timezone Asia/Manila

4. **(manual)** Router: reserve the NUC's IP in the Deco app (**More → Advanced → Address Reservation**). Update the `nuc` entry in `~/.ssh/config` on each laptop if the IP changed.

## 2. Base packages

    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git ufw unattended-upgrades kitty-terminfo neovim gitleaks
    sudo update-alternatives --config editor    # pick nvim

Install **Docker Engine** and the **compose plugin** following the official guide for Ubuntu (docs.docker.com/engine/install/ubuntu), then let your user run Docker:

    sudo usermod -aG docker "$USER"    # log out and back in afterwards

## 3. SSH keys, then hardening

1. A reinstalled NUC has a new host key. On each laptop (and in Termux on the phone), forget the old one:

        ssh-keygen -R 192.168.68.62
        ssh-keygen -R 100.115.71.107

   Then, from each laptop, copy its key to the NUC:

        ssh-copy-id nuc

   **Phone (Termux):** add its key from a laptop session — append the phone's `id_ed25519.pub` line
   to `~/.ssh/authorized_keys` on the NUC (use `>>`, never `>`). This works before and after hardening.

   Keep each key labeled by device (`arch-pc`, `macbook-m5-pro`, `nothing-phone-3a`) so a lost device's line is easy to remove.

2. Get this repo onto the NUC (see step 5), then apply the hardening config:

        sudo cp host/ssh/00-hardening.conf /etc/ssh/sshd_config.d/
        sudo sshd -t && sudo systemctl restart ssh

3. **Keep your current session open** and test `ssh nuc` from a new terminal before closing it.

## 4. Tailscale

    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up

**(manual)** Tailscale admin console → **DNS**: turn on **MagicDNS** and **HTTPS Certificates**.

**(manual)** Keep the NUC's Tailscale IP at `100.115.71.107` — Pi-hole's ports, the tailnet DNS setting, and `nuc-ts` SSH entries depend on it. In the Tailscale admin console → **Machines**: remove the old NUC entry, then on the new one choose **⋯ → Edit machine IPv4** and set `100.115.71.107`. Run `sudo tailscale up` again if the address doesn't change right away.

## 5. This repo

1. Create the NUC's deploy key and add it to this repo on GitHub (**Settings → Deploy keys**, with write access):

        ssh-keygen -t ed25519 -C "nuc"
        cat ~/.ssh/id_ed25519.pub

2. Clone the repo and the sites:

        sudo mkdir -p /srv/apps && sudo chown "$USER": /srv/apps
        git clone git@github.com:SiegfredLorelle/homelab.git /srv/apps
        cd /srv/apps/sites && git clone https://github.com/SiegfredLorelle/personal-website.git

3. Recreate the gitleaks pre-commit hook (hooks are not stored in git):

        cat > /srv/apps/.git/hooks/pre-commit << 'EOF'
        #!/usr/bin/env bash
        gitleaks protect --staged --redact -v
        EOF
        chmod +x /srv/apps/.git/hooks/pre-commit

## 6. Host configs

    cd /srv/apps

    # Firewall
    sudo ./host/ufw-setup.sh

    # Fast boot when the Ethernet port has no cable
    sudo mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d
    sudo cp host/systemd/wait-online-override.conf \
      /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf
    sudo systemctl daemon-reload

    # Automatic security updates + 04:00 reboots
    sudo dpkg-reconfigure -plow unattended-upgrades    # answer Yes
    sudo cp host/apt/52auto-reboot /etc/apt/apt.conf.d/

    # Kernel settings: Pi-hole binds to the Tailscale IP before Tailscale is up; IP forwarding for the exit node
    sudo cp host/sysctl/*.conf /etc/sysctl.d/
    sudo sysctl --system

## 7. Cloudflare Tunnel

1. Install `cloudflared` from Cloudflare's apt repository, so `apt upgrade` keeps it current:

        sudo mkdir -p --mode=0755 /usr/share/keyrings
        curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null
        echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
        sudo apt update && sudo apt install cloudflared

2. Restore the two secure notes from the password manager — see **Secrets** in the README:

        mkdir -p ~/.cloudflared
        # recreate <tunnel-id>.json and cert.pem from the notes, then:
        chmod 600 ~/.cloudflared/*.json ~/.cloudflared/cert.pem

3. Install the config and run the tunnel as a service:

        sudo mkdir -p /etc/cloudflared
        sudo cp host/cloudflared/config.yml /etc/cloudflared/
        sudo cloudflared service install

   `credentials-file` in `config.yml` must point at the restored `.json` file.

## 8. Apps

Create `.env` from the template and fill in each value from the password manager:

    cd /srv/apps
    cp .env.example .env && chmod 600 .env
    nvim .env

Then start everything:

    cd /srv/apps
    docker compose up -d
    sudo ./host/tailscale-serve.sh

The first `docker compose up -d` builds the custom Caddy image (a few minutes). Caddy then gets the
`lab.sieg.dev` + `*.lab.sieg.dev` certificates by itself — check with:

    docker logs caddy 2>&1 | grep 'obtained successfully'

If the Cloudflare token was lost, create a new one (**manual**): Cloudflare → My Profile → API Tokens →
"Edit zone DNS" template + **Zone → Zone → Read**, zone `sieg.dev` only. Put it in `.env` and the password manager.

**Pi-hole DNS for the tailnet:**

1. On the NUC, keep it off its own Pi-hole: `sudo tailscale set --accept-dns=false`
2. **(manual)** Tailscale admin → **DNS**: add global nameserver `100.115.71.107`, turn on **Override DNS servers**, keep MagicDNS on.
3. **(manual)** On each device: browser DNS over HTTPS **off** (Zen: Settings → Privacy & Security); Android **Private DNS** off or automatic.

**Exit node (for untrusted Wi-Fi):**

1. Rewrite the sender only for exit-node internet traffic, so Pi-hole keeps seeing real device names:

        sudo cp host/systemd/exit-node-nat.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable --now exit-node-nat

2. Offer the exit node with Tailscale's own catch-all rewriting off (its warning is expected; step 1 does that job):

        sudo tailscale set --advertise-exit-node --snat-subnet-routes=false

3. **(manual)** Tailscale admin → **Machines** → the NUC → **⋯ → Edit route settings** → tick **Use as exit node**.
4. **(manual)** Tailscale admin → **DNS** → Pi-hole nameserver → **Use with exit node** on, so ad-blocking still applies.

**Uptime Kuma**: restore `uptime-kuma/data/` from backup if one exists. Otherwise open it, choose **SQLite**, create the admin account, and recreate the monitors and notification from [`monitoring.md`](monitoring.md).

## 9. Heartbeats

Copy `host/crontab.example` into `crontab -e`, replacing `<your-id>` with the `nuc` check's ping URL from healthchecks.io.

Disk health (`nuc-disk` check):

    sudo apt install --no-install-recommends smartmontools -y
    echo 'HC_URL=https://hc-ping.com/<nuc-disk-id>' | sudo tee /etc/smart-healthcheck.env > /dev/null
    sudo chmod 600 /etc/smart-healthcheck.env
    sudo cp host/smart/smartd-alert.sh /usr/local/bin/
    sudo cp host/smart/smart-healthcheck.cron /etc/cron.d/smart-healthcheck
    sudo cp host/smart/smartd.conf /etc/smartd.conf
    sudo systemctl enable --now smartmontools
    sudo /usr/local/bin/smartd-alert.sh daily

## 10. Verify

- [ ] `sudo ufw status` shows `active` with the expected rules
- [ ] `systemctl is-active cloudflared` shows `active`
- [ ] `docker ps` lists `caddy`, `uptime-kuma` and `pihole`; web ports on `127.0.0.1`, Pi-hole DNS on `100.115.71.107:53`
- [ ] https://sieg.dev loads on a phone over cellular data
- [ ] `ssh nuc` and `ssh nuc-ts` connect with keys from both laptops, and `ssh nuc-ts` from the phone (Termux), no password prompt
- [ ] Uptime Kuma loads over Tailscale, and all monitors are green
- [ ] healthchecks.io shows `nuc` and `nuc-disk` as up
- [ ] `nslookup doubleclick.net` on a laptop returns `0.0.0.0`, and Pi-hole's Query Log shows each device by name (not `172.18.0.1`)
- [ ] Phone on mobile data with the NUC as exit node: `ifconfig.me` shows the home IP
- [ ] On a tailnet device: `https://status.lab.sieg.dev` and `https://dns.lab.sieg.dev` load with a valid certificate; `https://typo.lab.sieg.dev` shows the 404 page
- [ ] `sudo reboot` — everything above comes back on its own
