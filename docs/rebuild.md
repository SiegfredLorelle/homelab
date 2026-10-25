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

1. From each laptop, copy its key to the NUC:

        ssh-copy-id nuc

2. Get this repo onto the NUC (see step 5), then apply the hardening config:

        sudo cp host/ssh/00-hardening.conf /etc/ssh/sshd_config.d/
        sudo sshd -t && sudo systemctl restart ssh

3. **Keep your current session open** and test `ssh nuc` from a new terminal before closing it.

## 4. Tailscale

    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up

**(manual)** Tailscale admin console → **DNS**: turn on **MagicDNS** and **HTTPS Certificates**.

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

## 7. Cloudflare Tunnel

1. Install `cloudflared` (package from Cloudflare's downloads page).
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

    cd /srv/apps
    docker compose up -d
    sudo ./host/tailscale-serve.sh

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
- [ ] `docker ps` lists `caddy` and `uptime-kuma`, bound to `127.0.0.1`
- [ ] https://sieg.dev loads on a phone over cellular data
- [ ] `ssh nuc` and `ssh nuc-ts` connect with keys, no password prompt
- [ ] Uptime Kuma loads over Tailscale, and all monitors are green
- [ ] healthchecks.io shows `nuc` and `nuc-disk` as up
- [ ] `sudo reboot` — everything above comes back on its own
