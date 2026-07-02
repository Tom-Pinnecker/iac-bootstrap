#!/usr/bin/env bash
# Bootstrap installer
# Copyright (c) 2026 Pinnecker Engineering
# Licensed under the MIT License. See LICENSE file for details.

set -Eeuo pipefail

###############################################################################
# Bootstrap Ubuntu Server
#
# - Updates system
# - Installs Git
# - Creates GitHub deploy key
# - Configures SSH
# - Creates /srv directory structure
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

print_header() {
    echo
    echo "==============================================================="
    echo "$1"
    echo "==============================================================="
}

###############################################################################
# System Update
###############################################################################

print_header "Updating system"

apt update
apt upgrade -y

###############################################################################
# Install packages
###############################################################################

print_header "Installing packages"

apt install -y \
    git \
    ca-certificates

###############################################################################
# SSH
###############################################################################

print_header "Preparing SSH"

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

fi

###############################################################################
# Server layout
###############################################################################

print_header "Creating server directory structure"

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

print_header "Checking Docker group"

if getent group docker >/dev/null; then
    usermod -aG docker "$BOOTSTRAP_USER"
    echo "User added to docker group."
else
    echo "Docker not installed yet. Skipping."
fi

###############################################################################
# Finished
###############################################################################

print_header "Bootstrap complete"

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
