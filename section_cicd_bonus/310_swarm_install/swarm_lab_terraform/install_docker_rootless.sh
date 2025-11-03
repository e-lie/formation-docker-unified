#!/bin/bash
set -e

USERNAME="${username}"

echo "=== Starting Docker Rootless Installation ==="

# Installation des dépendances pour Docker Rootless
echo "Installing rootless dependencies..."
apt-get update
apt-get install -y \
    uidmap \
    dbus-user-session \
    fuse-overlayfs \
    slirp4netns

# Installation de Docker via le script officiel
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
rm /tmp/get-docker.sh

# Configuration du système pour rootless
echo "Configuring system for rootless Docker..."

# Augmenter les limites pour l'utilisateur
cat >> /etc/security/limits.conf <<EOF
${username} soft nofile 65536
${username} hard nofile 65536
${username} soft nproc 4096
${username} hard nproc 4096
EOF

# Configurer les namespaces utilisateur
echo "kernel.unprivileged_userns_clone=1" > /etc/sysctl.d/99-rootless.conf
sysctl --system

# Activer le mode lingering pour l'utilisateur (permet au service de persister)
loginctl enable-linger "$USERNAME"

# Installation de Docker en mode rootless pour l'utilisateur
echo "Setting up rootless Docker for $USERNAME..."
su - "$USERNAME" <<'EOSU'
set -e

# Installation de Docker rootless
export SKIP_IPTABLES=1
curl -fsSL https://get.docker.com/rootless -o /tmp/install-rootless.sh
sh /tmp/install-rootless.sh
rm /tmp/install-rootless.sh

# Configuration de l'environnement
cat >> ~/.bashrc <<'EOF'

# Docker Rootless
export PATH=/home/$USER/bin:$PATH
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
EOF

# Charger la configuration
source ~/.bashrc

# Démarrer le service Docker rootless
systemctl --user start docker
systemctl --user enable docker

# Vérifier l'installation
echo "Docker rootless version:"
docker --version
docker context use rootless

echo "=== Docker Rootless installation completed for \$USERNAME ==="
EOSU

# Créer un helper script pour démarrer Docker au boot
cat > /usr/local/bin/docker-rootless-start-${username}.sh <<EOF
#!/bin/bash
# Start Docker rootless for ${username}
su - ${username} -c "systemctl --user start docker"
EOF
chmod +x /usr/local/bin/docker-rootless-start-${username}.sh

# Ajouter le script au démarrage système
cat > /etc/systemd/system/docker-rootless-${username}.service <<EOF
[Unit]
Description=Docker Rootless for ${username}
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/docker-rootless-start-${username}.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable docker-rootless-${username}.service

echo "=== Docker Rootless installation completed successfully ==="
echo "User $USERNAME can now use Docker in rootless mode"
echo "Note: $USERNAME needs to reconnect (logout/login) for environment changes to take effect"
