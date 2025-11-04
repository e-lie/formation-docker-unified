#!/bin/bash
set -e

USERNAME="${username}"

echo "=== Starting Docker Installation ==="

# Ajout de la clé GPG officielle de Docker
echo "Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Ajout du dépôt Docker
echo "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installation de Docker
echo "Installing Docker..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Démarrage et activation de Docker
echo "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Vérification de l'installation
echo "Docker version:"
docker --version

# Ajout de l'utilisateur au groupe docker
echo "Adding $USERNAME to docker group..."
usermod -aG docker "$USERNAME"

# Ajout de l'utilisateur ubuntu au groupe docker (si existe)
usermod -aG docker ubuntu 2>/dev/null || true

echo "=== Docker installation completed successfully ==="
echo "User $USERNAME has docker access"
