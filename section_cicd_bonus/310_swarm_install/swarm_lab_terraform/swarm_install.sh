#!/bin/bash
set -e

echo "=== Starting Docker Swarm Setup ==="

# Variables
NODE_INDEX="${node_index}"
MANAGER_IP="${manager_ip}"
WORKER_TOKEN="${worker_token}"

# Attendre que Docker soit prêt
echo "Waiting for Docker to be ready..."
for i in {1..30}; do
    if docker info > /dev/null 2>&1; then
        echo "Docker is ready"
        break
    fi
    echo "Waiting for Docker... ($i/30)"
    sleep 2
done

# Vérifier si Docker est prêt
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not ready after waiting"
    exit 1
fi

# Vérifier si ce nœud fait déjà partie d'un swarm
if docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo "This node is already part of a swarm"

    if [ "$NODE_INDEX" = "0" ]; then
        echo "This is the manager node"
        # Afficher les informations du swarm
        echo "Current swarm nodes:"
        docker node ls

        # Mettre à jour le fichier swarm-info.txt
        cat > /root/swarm-info.txt <<EOF
Swarm Manager: $(hostname)
Manager IP: $(hostname -I | awk '{print $1}')
Last updated: $(date)

Worker Join Command:
docker swarm join --token $(docker swarm join-token worker -q) $(hostname -I | awk '{print $1}'):2377

Manager Join Command:
docker swarm join --token $(docker swarm join-token manager -q) $(hostname -I | awk '{print $1}'):2377
EOF
        chmod 600 /root/swarm-info.txt
        echo "Swarm info updated in /root/swarm-info.txt"
    else
        echo "This is a worker node"
        echo "Node status:"
        docker info | grep -A 5 "Swarm:"
    fi

    echo "=== Swarm already configured ==="
    exit 0
fi

# Si c'est le premier nœud (index 0), initialiser Swarm en tant que manager
if [ "$NODE_INDEX" = "0" ]; then
    echo "This is the first node - Initializing Swarm as manager..."

    # Initialiser Swarm
    docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')

    # Sauvegarder les tokens
    echo "Swarm initialized successfully!"
    echo "Manager IP: $(hostname -I | awk '{print $1}')"

    # Afficher le token de worker
    echo "Worker join token:"
    WORKER_TOKEN=$(docker swarm join-token worker -q)
    echo "$WORKER_TOKEN"

    # Afficher le token de manager
    echo "Manager join token:"
    docker swarm join-token manager -q

    # Créer un fichier avec les informations du cluster
    cat > /root/swarm-info.txt <<EOF
Swarm Manager initialized on: $(hostname)
Manager IP: $(hostname -I | awk '{print $1}')
Initialized at: $(date)

Worker Join Command:
docker swarm join --token $WORKER_TOKEN $(hostname -I | awk '{print $1}'):2377

Manager Join Command:
docker swarm join --token $(docker swarm join-token manager -q) $(hostname -I | awk '{print $1}'):2377
EOF

    chmod 600 /root/swarm-info.txt
    echo "Swarm information saved to /root/swarm-info.txt"

else
    echo "This is worker node $NODE_INDEX - Joining the swarm..."
    echo "Manager IP: $MANAGER_IP"

    if [ -z "$WORKER_TOKEN" ] || [ "$WORKER_TOKEN" = "pending" ]; then
        echo "ERROR: Worker token not provided. Cannot join swarm automatically."
        echo "You need to join manually using the token from the manager."

        # Créer un script helper pour rejoindre le swarm
        cat > /root/join-swarm.sh <<'EOF'
#!/bin/bash
# Usage: ./join-swarm.sh <manager-ip> <join-token>
#
# To get the join token, run on the manager:
#   docker swarm join-token worker -q

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <manager-ip> <join-token>"
    echo ""
    echo "Example:"
    echo "  $0 10.0.0.1 SWMTKN-1-xxxxx"
    exit 1
fi

MANAGER_IP=$1
JOIN_TOKEN=$2

echo "Joining swarm..."
docker swarm join --token "$JOIN_TOKEN" "$MANAGER_IP:2377"

if [ $? -eq 0 ]; then
    echo "Successfully joined the swarm!"
else
    echo "Failed to join the swarm"
    exit 1
fi
EOF
        chmod +x /root/join-swarm.sh
        echo "Helper script created: /root/join-swarm.sh"
        exit 1
    fi

    # Attendre un peu pour être sûr que le manager est prêt
    echo "Waiting for manager to be ready..."
    sleep 5

    # Rejoindre le swarm
    echo "Joining swarm with token: $${WORKER_TOKEN:0:20}..."
    if docker swarm join --token "$WORKER_TOKEN" "$MANAGER_IP:2377"; then
        echo "Successfully joined the swarm as worker!"
        echo "Node joined to manager at $MANAGER_IP"
    else
        echo "ERROR: Failed to join the swarm"
        echo "You can try manually with: docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377"
        exit 1
    fi
fi

echo "=== Docker Swarm setup completed ==="
