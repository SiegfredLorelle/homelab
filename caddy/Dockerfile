# Caddy with the Cloudflare DNS plugin (for the *.lab.sieg.dev certificate)
FROM caddy:2-builder@sha256:c4cd20eaa0b69112fd5d4f721ffc9671687e1d5d0b155c8620cf7546dbef94c0 AS builder
RUN xcaddy build --with github.com/caddy-dns/cloudflare

FROM caddy:2-alpine@sha256:e70b164da81ef698b3ad19af799ea6086ce6d9e48ed4079eb9fe26f6fbf14ee5
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
