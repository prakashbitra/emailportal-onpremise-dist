#!/bin/bash
# ══════════════════════════════════════════════════════════════════
#  EmailPortal On-Premise — One-command installer
#
#  Run on your server:
#    curl -fsSL https://raw.githubusercontent.com/prakashbitra/emailportal-onpremise-dist/main/install.sh | bash
#
#  What this does:
#    1. Installs Docker (if not present)
#    2. Downloads docker-compose.yml + .env.template
#    3. Starts the containers
#    4. Prints the URL to open in your browser
# ══════════════════════════════════════════════════════════════════

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${CYAN}$1${NC}"; }
ok()   { echo -e "${GREEN}✅  $1${NC}"; }
err()  { echo -e "${RED}❌  $1${NC}"; exit 1; }

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
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
log "Installing to: $INSTALL_DIR"

# ── 3. Download compose + env template ───────────────────────────
log "Downloading configuration files..."
curl -fsSL "https://raw.githubusercontent.com/prakashbitra/emailportal-onpremise-dist/main/docker-compose.yml" -o docker-compose.yml
curl -fsSL "https://raw.githubusercontent.com/prakashbitra/emailportal-onpremise-dist/main/.env.template"       -o .env.template

# Generate secrets automatically
NEXTAUTH_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" 2>/dev/null || openssl rand -hex 32)
ENCRYPTION_KEY=$(node -e  "console.log(require('crypto').randomBytes(32).toString('hex'))" 2>/dev/null || openssl rand -hex 32)
INSTANCE_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" 2>/dev/null || openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -hex 16)

# Write .env from template with generated secrets
sed \
  -e "s/REPLACE_WITH_RANDOM_64_CHAR_HEX/${NEXTAUTH_SECRET}/" \
  -e "s/REPLACE_WITH_RANDOM_64_CHAR_HEX/${ENCRYPTION_KEY}/" \
  -e "s/REPLACE_WITH_RANDOM_64_CHAR_HEX/${INSTANCE_SECRET}/" \
  -e "s/CHANGE_ME/${DB_PASSWORD}/g" \
  .env.template > .env

ok "Configuration files created."

# ── 4. Pull image + start containers ─────────────────────────────
log "Starting EmailPortal (pulling image, first time takes 1-2 minutes)..."
docker compose up -d

ok "Containers started."

# ── 5. Get server IP ──────────────────────────────────────────────
SERVER_IP=$(hostname -I | awk '{print $1}')

log ""
log "╔══════════════════════════════════════════════╗"
ok  "  Installation complete!"
log "╠══════════════════════════════════════════════╣"
log "  Open this URL in your browser to continue:"
log ""
log "    http://${SERVER_IP}:3000"
log ""
log "  The setup wizard will guide you through:"
log "    • Pasting your license key"
log "    • Creating your admin account"
log "    • Configuring email sending (AWS SES)"
log "╚══════════════════════════════════════════════╝"
log ""
log "  Installation directory: $INSTALL_DIR"
log "  Your INSTANCE_SECRET (send to support for license):"
log "    $INSTANCE_SECRET"
log ""
