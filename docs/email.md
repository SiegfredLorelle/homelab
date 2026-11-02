# Email (`@sieg.dev`)

Not part of the NUC: everything below lives in Cloudflare, Resend and Gmail, so mail keeps
working even when the NUC is off. Recorded here so it can be rebuilt or moved later.

## How it works

    Receiving:  sender ──▶ MX (Cloudflare Email Routing) ──▶ forwards to main Gmail ──▶ Gmail filters/labels
    Sending:    Gmail "Send mail as" ──▶ Resend SMTP (signs as sieg.dev) ──▶ recipient

Cost: free (Cloudflare Email Routing, Resend free tier: 3,000/month, 100/day).

## Receiving: Cloudflare Email Routing

Cloudflare dashboard → Email Service → Email Routing → `sieg.dev`.

| Address | Destination |
| --- | --- |
| `hi@sieg.dev` | main Gmail |
| `work@sieg.dev` | main Gmail |
| `git@sieg.dev` | main Gmail |
| Catch-all (any other `@sieg.dev`) | main Gmail |

The destination Gmail must be **verified** (Destination addresses tab). Email Routing adds and
**locks** the root MX and SPF records. The **Activity log** tab shows what happened to each message.

## Gmail labels

Settings → Filters and Blocked Addresses. Each `@sieg.dev` email gets the parent label plus one child:

| Filter | Label |
| --- | --- |
| To: `@sieg.dev` | `sieg.dev` |
| To: `hi@sieg.dev` | `sieg.dev/hi` |
| To: `work@sieg.dev` | `sieg.dev/work` |
| To: `git@sieg.dev` | `sieg.dev/git` |
| Has the words: `to:(@sieg.dev) -to:(hi@sieg.dev) -to:(work@sieg.dev) -to:(git@sieg.dev)` | `sieg.dev/other` |

Adding a named address later: add its routing rule, a filter, and its exclusion to the `other` filter.

## Sending: Resend + Gmail "Send mail as"

- Resend domain `sieg.dev`, region Tokyo (ap-northeast-1), click/open tracking **off**.
- DNS (added via Cloudflare Domain Connect): CNAME `send`, CNAME `rsend`, TXT `resend._domainkey` (DKIM).
- API key `gmail-send-as`: **sending access**, `sieg.dev` only. In the password manager.
- Gmail → Settings → Accounts and Import → Send mail as: `hi@` and `work@`, name "Siegfred Lorelle Mina",
  SMTP `smtp.resend.com`, port `465` (SSL), username `resend`, password = the API key.
- "Reply from the same address the message was sent to" is on.
- **Bounce alerts**: Resend → Webhooks → events `email.bounced` and `email.complained` → ntfy:
  `https://ntfy.sh/<topic>?tpl=yes&t=Resend%3A%20%7B%7B.type%7D%7D&m=To%3A%20%7B%7B.data.to%7D%7D%0ASubject%3A%20%7B%7B.data.subject%7D%7D&p=4&ta=warning`
  (ntfy template → "Resend: email.bounced / To: … / Subject: …"). Test by sending from `hi@` to `bounced@resend.dev`.

**Check a sent email**: in the recipient's Gmail, ⋮ → Show original → SPF, DKIM and DMARC should all be PASS
(DKIM `d=sieg.dev`, SPF via `rsend.sieg.dev`).

## DMARC

Managed with Cloudflare DMARC Management (free): `_dmarc` TXT `v=DMARC1; p=none; rua=...@dmarc-reports.cloudflare.net`.
Reports show who sends as `sieg.dev`. **Plan:** once reports show only Resend, tighten to `p=quarantine`.

## Quirks

- Mail **from the main Gmail to its own `@sieg.dev` address** shows only in Sent: Gmail hides messages sent to
  yourself. Test from another account.
- Gmail's "Show original" summary says DMARC **FAIL** when there is no DMARC result at all (e.g. no record yet,
  or a cached "no record" answer). Check the raw `Authentication-Results:` line for `dmarc=`.

## When something goes wrong

| Problem | Where to look |
| --- | --- |
| Mail to `@sieg.dev` not arriving | Cloudflare → Email Routing → `sieg.dev` → **Activity log** (forwarded / rejected / failed) |
| Sent mail not arriving / bounced | **ntfy** push (bounce/complaint webhook), then **Resend → Emails / Logs** — bounces go to Resend (`rsend.sieg.dev`), not to Gmail |
| Gmail can't send as `@sieg.dev` | Gmail's "message not delivered" notice; check the Resend API key in Send mail as |
| Spoofing / authentication issues | Cloudflare → **DMARC Management** reports |
| Records changed or missing | Uptime Kuma monitors **Mail MX** and **Mail DKIM**; domain expiry is watched by **Personal Website** |

## Moving later

The addresses never change: only DNS and settings do.

- **To a mailbox provider (Proton, Tuta, Fastmail, Zoho…)**: add `sieg.dev` there, then disable Cloudflare
  Email Routing and replace the root MX/SPF records with the provider's (plus its DKIM). Recreate addresses or a
  catch-all there. Sending then goes through the provider; Resend's records can be removed. Update DMARC reports
  if needed. Gmail filters and "Send mail as" become unnecessary.
- **Self-hosting**: not recommended on the NUC. Home IPs are on spam blocklists and ISPs often block port 25;
  a mail server going down means lost mail. If ever tried: a rented server (VPS) running e.g. Stalwart or
  Mailcow, ideally keeping Resend as the outbound relay, and a backup MX.

## Not covered by email

Homelab alerts (Uptime Kuma, healthchecks.io) go to the main Gmail directly and to ntfy push; see
[`monitoring.md`](monitoring.md).
