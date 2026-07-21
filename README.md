# EmailPortal On-Premise

Self-hosted email marketing platform — campaigns, automations, RSS-to-email, transactional
API, unsubscribe management, and more, running entirely on your own server.

## Requirements

- A Linux server (any distro) with Docker support — 2 CPU / 4GB RAM minimum recommended
- Root or sudo access
- Outbound internet access (to pull Docker images and, optionally, send via AWS SES)

## Install

Run this on your server:

```bash
curl -fsSL https://raw.githubusercontent.com/prakashbitra/emailportal-onpremise-dist/main/install.sh | bash
```

This installs Docker if it's missing, downloads the configuration files, generates your
instance's secrets, and starts everything (Caddy reverse proxy, two app replicas, background
worker, PostgreSQL). Takes 1–2 minutes on first run. When it finishes, it prints the URL to open
and an `INSTANCE_SECRET` value you'll need for licensing (see below).

By default it's reachable at `http://YOUR_SERVER_IP`. If you have a real domain pointed at the
server, set `PUBLIC_DOMAIN` in `.env` and run `docker compose restart caddy` to get automatic
HTTPS instead.

## Getting a license

**Self-service** (Solo / Growth / Scale tiers, annual or perpetual):

👉 **[license.brandmaster.ae/emailportal](https://license.brandmaster.ae/emailportal)**

Pick a tier, pay by card, and your license key is issued immediately — shown on the success page
and emailed to you. You can manage your license anytime at
[license.brandmaster.ae/portal/login](https://license.brandmaster.ae/portal/login).

**Need more than 3 nodes, multiple separate deployments (agencies/resellers), or prefer to pay by
bank transfer?** Use the "Contact us" link on the pricing page instead.

Once you have a key, open your instance and go to **Admin → Infrastructure → License Key** to
paste it in — or enter it during the first-run setup wizard below.

## First-run setup

After install, open the printed URL in your browser. The setup wizard walks you through:
1. Pasting your license key
2. Creating your admin account
3. Configuring email sending (AWS SES credentials)

## Updates

Once licensed with an active maintenance contract (AMC), go to **Admin → Infrastructure** and
click **Check for Updates**, then **Update Now** — this downloads and applies the new version
automatically, with a health check before and after each container swap.

## Support

Questions or issues — use the "Contact us" link at
[license.brandmaster.ae/emailportal](https://license.brandmaster.ae/emailportal).
