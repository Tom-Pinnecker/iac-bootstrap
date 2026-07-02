#!/usr/bin/env bash
# Bootstrap installer
# Copyright (c) 2026 Pinnecker Engineering
# Licensed under the MIT License. See LICENSE file for details.

set -eu

###############################################################################
# Bootstrap Ubuntu Server
#
# - Updates system
# - Installs Git + Docker
# - Creates GitHub key
# - Configures SSH
# - Creates /srv directory structure
# - Adds user to docker group
# - Prepares CLI command tool 'iac'
#
# Run:
#   curl ... | sudo bash
#
###############################################################################

BOOTSTRAP_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$BOOTSTRAP_USER" | cut -d: -f6)"

SSH_DIR="$USER_HOME/.ssh"
KEY_FILE="$SSH_DIR/github_key"
SSH_CONFIG="$SSH_DIR/config"

###############################################################################
# Helper
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[ OK ]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

###############################################################################
# System Update
###############################################################################

log_info "Updating system"

apt update
apt upgrade -y

###############################################################################
# Install packages
###############################################################################

log_info "Installing packages"

apt install -y \
    git \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

###############################################################################
# Install docker
###############################################################################

log_info "Installing Docker dependencies..."

log_info "Adding Docker GPG key..."

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

log_info "Adding Docker repository..."

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

log_info "Installing Docker Engine..."

apt update

apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

log_ok "Docker installed"

###############################################################################
# SSH
###############################################################################

log_info "Preparing SSH"

mkdir -p "$SSH_DIR"

chown "$BOOTSTRAP_USER:$BOOTSTRAP_USER" "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ ! -f "$KEY_FILE" ]]; then
    ssh-keygen \
        -t ed25519 \
        -f "$KEY_FILE" \
        -N "" \
        -C "$(hostname)-key"

    chown "$BOOTSTRAP_USER:$BOOTSTRAP_USER" \
        "$KEY_FILE" \
        "$KEY_FILE.pub"

    chmod 600 "$KEY_FILE"
    chmod 644 "$KEY_FILE.pub"
    log_ok "SSH key created successfully"
fi

touch "$SSH_CONFIG"

chmod 600 "$SSH_CONFIG"
chown "$BOOTSTRAP_USER:$BOOTSTRAP_USER" "$SSH_CONFIG"

if ! grep -q "IdentityFile ~/.ssh/github_key" "$SSH_CONFIG"; then

    cat >> "$SSH_CONFIG" <<'EOF'

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_key
    IdentitiesOnly yes

EOF

    log_ok "Added SSH config entry for github.com"

fi

###############################################################################
# Server layout
###############################################################################

log_info "Creating server directory structure"

mkdir -p \
    /srv/iac \
    /srv/data \
    /srv/backups \
    /srv/secrets

chown -R "$BOOTSTRAP_USER:$BOOTSTRAP_USER" /srv/iac
chmod 755 /srv/iac

chown -R "$BOOTSTRAP_USER:$BOOTSTRAP_USER" /srv/data
chmod 755 /srv/data

chown -R "$BOOTSTRAP_USER:$BOOTSTRAP_USER" /srv/backups
chmod 755 /srv/backups

chown root:root /srv/secrets
chmod 700 /srv/secrets

###############################################################################
# Docker group
###############################################################################

log_info "Checking Docker group"

if getent group docker >/dev/null; then
    usermod -aG docker "$BOOTSTRAP_USER"
    log_ok "User added to docker group."
else
    log_warn "Docker not installed yet. Skipping."
fi

###############################################################################
# Install CLI symlink
###############################################################################

log_info "Installing CLI tool 'iac' symlink"

sudo ln -s /srv/iac/bin/iac /usr/local/bin/iac

###############################################################################
# Finished
###############################################################################

log_ok "Bootstrap complete"

echo
echo "Next steps:"
echo
echo "1. Add this public key to your repository source:"
echo
cat "$KEY_FILE.pub"
echo
echo "2. Clone your Infrastructure repository:"
echo
echo "   cd /srv"
echo "   git clone git@github.com:<user>/<repo>.git iac"
echo
