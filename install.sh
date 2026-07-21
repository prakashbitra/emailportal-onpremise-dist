#!/bin/bash
# ══════════════════════════════════════════════════════════════════
#  EmailPortal On-Premise — One-command installer
#
#  Run on your server:
#    curl -fsSL https://raw.githubusercontent.com/prakashbitra/emailportal-onpremise-dist/main/install.sh | bash
#
#  What this does:
#    1. Installs Docker (if not present)
#    2. Downloads docker-compose.yml + Caddyfile + .env.template
#    3. Starts the containers (Caddy + 2 app replicas + worker + db)
#    4. Prints the URL to open in your browser
# ══════════════════════════════════════════════════════════════════

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

log()   { echo -e "${CYAN}$1${NC}"; }
ok()    { echo -e "${GREEN}✅  $1${NC}"; }
err()   { echo -e "${RED}❌  $1${NC}"; exit 1; }
warn()  { echo -e "${YELLOW}⚠️   $1${NC}"; }

INSTALL_DIR="${HOME}/emailportal"

log ""
log "╔══════════════════════════════════════════════╗"
log "║   EmailPortal On-Premise — Installer         ║"
log "╚══════════════════════════════════════════════╝"
log ""

# ── 1. Install Docker if missing ──────────────────────────────────
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    ok "Docker installed."
else
    ok "Docker already installed."
fi

# ── 2. Create install directory ───────────────────────────────────
IS_UPGRADE=false
if [ -f "${INSTALL_DIR}/docker-compose.yml" ] && [ -f "${INSTALL_DIR}/.env" ]; then
    IS_UPGRADE=true
    warn "Existing installation found at $INSTALL_DIR — this version adds a reverse proxy"
    warn "(Caddy) and a second app replica for zero-downtime updates. Your existing .env"
    warn "and data are kept; docker-compose.yml will be replaced. Backing up the old one..."
    cp "${INSTALL_DIR}/docker-compose.yml" "${INSTALL_DIR}/docker-compose.yml.bak.$(date +%s)"
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
log "Installing to: $INSTALL_DIR"

# ── 3. Download compose + proxy config + env template ─────────────
log "Downloading configuration files..."
curl -fsSL "https://raw.githubusercontent.com/prakashbitra/emailportal-onpremise-dist/main/docker-compose.yml" -o docker-compose.yml
curl -fsSL "https://raw.githubusercontent.com/prakashbitra/emailportal-onpremise-dist/main/Caddyfile"          -o Caddyfile

if [ "$IS_UPGRADE" = true ]; then
    ok "Configuration files updated (.env kept as-is)."
else
    curl -fsSL "https://raw.githubusercontent.com/prakashbitra/emailportal-onpremise-dist/main/.env.template" -o .env.template

    # Generate secrets automatically — three genuinely independent random
    # values. (Earlier versions of this script accidentally set all three to
    # the same value due to a sed substitution ordering bug — fixed here by
    # using a distinct placeholder token per secret.)
    NEXTAUTH_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" 2>/dev/null || openssl rand -hex 32)
    ENCRYPTION_KEY=$(node -e  "console.log(require('crypto').randomBytes(32).toString('hex'))" 2>/dev/null || openssl rand -hex 32)
    INSTANCE_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" 2>/dev/null || openssl rand -hex 32)
    DB_PASSWORD=$(openssl rand -hex 16)

    sed \
      -e "s/REPLACE_NEXTAUTH_SECRET/${NEXTAUTH_SECRET}/" \
      -e "s/REPLACE_ENCRYPTION_KEY/${ENCRYPTION_KEY}/" \
      -e "s/REPLACE_INSTANCE_SECRET/${INSTANCE_SECRET}/" \
      -e "s/CHANGE_ME/${DB_PASSWORD}/g" \
      .env.template > .env

    ok "Configuration files created."
fi

# ── 4. Pull images + start containers ─────────────────────────────
log "Starting EmailPortal (pulling images, first time takes 1-2 minutes)..."
docker compose up -d

ok "Containers started."

# ── 5. Get server IP ──────────────────────────────────────────────
SERVER_IP=$(hostname -I | awk '{print $1}')
INSTANCE_SECRET_DISPLAY=$(grep -m1 '^INSTANCE_SECRET=' .env | cut -d'"' -f2)

log ""
log "╔══════════════════════════════════════════════╗"
ok  "  Installation complete!"
log "╠══════════════════════════════════════════════╣"
log "  Open this URL in your browser to continue:"
log ""
log "    http://${SERVER_IP}"
log ""
log "  (Set PUBLIC_DOMAIN in .env and restart Caddy — 'docker compose restart"
log "  caddy' — if you want automatic HTTPS on a real domain instead of plain"
log "  HTTP by IP.)"
log ""
log "  The setup wizard will guide you through:"
log "    • Pasting your license key"
log "    • Creating your admin account"
log "    • Configuring email sending (AWS SES)"
log "╚══════════════════════════════════════════════╝"
log ""
log "  Installation directory: $INSTALL_DIR"
log "  Your INSTANCE_SECRET (send to support for license):"
log "    $INSTANCE_SECRET_DISPLAY"
log ""
