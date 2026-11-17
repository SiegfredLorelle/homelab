# Caddy with the Cloudflare DNS plugin (for the *.lab.sieg.dev certificate)
FROM caddy:2-builder@sha256:aef223d1f943bc12a29a9e0a0a73983aa19a36672daede7507da4201a6b1016a AS builder
RUN xcaddy build --with github.com/caddy-dns/cloudflare

FROM caddy:2-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
