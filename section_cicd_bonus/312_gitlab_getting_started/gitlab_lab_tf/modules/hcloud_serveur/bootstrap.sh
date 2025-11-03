#!/bin/bash
set -e

USERNAME="${username}"

echo "=== Starting Bootstrap ==="

# Mise à jour du système
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Installation des dépendances de base
echo "Installing base dependencies..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    sudo \
    git \
    vim \
    htop \
    jq \
    openssh-server \
    neovim \
    btop

# Création de l'utilisateur personnalisé
if ! id "$USERNAME" &>/dev/null; then
    echo "Creating user $USERNAME..."
    useradd -m -s /bin/bash "$USERNAME"

    # Ajout de l'utilisateur au groupe sudo
    usermod -aG sudo "$USERNAME"

    # Configuration de sudo sans mot de passe pour cet utilisateur
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
    chmod 0440 /etc/sudoers.d/$USERNAME

    # Copie des clés SSH de root vers le nouvel utilisateur
    if [ -d /root/.ssh ]; then
        mkdir -p /home/$USERNAME/.ssh
        cp /root/.ssh/authorized_keys /home/$USERNAME/.ssh/authorized_keys 2>/dev/null || true
        chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
        chmod 700 /home/$USERNAME/.ssh
        chmod 600 /home/$USERNAME/.ssh/authorized_keys 2>/dev/null || true
    fi

    echo "User $USERNAME created successfully"
else
    echo "User $USERNAME already exists"
fi

echo "=== Bootstrap completed successfully ==="
