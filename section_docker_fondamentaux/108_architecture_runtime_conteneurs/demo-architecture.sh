#!/bin/bash
# Démonstration de l'architecture Docker (dockerd → containerd → runc)

set -e

echo "=== Démonstration de l'Architecture des Runtime de Conteneurs ==="
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    echo "Docker n'est pas installé."
    exit 1
fi

echo -e "${BLUE}1. Architecture Docker : Vue d'ensemble${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${CYAN}Architecture Docker :${NC}"
echo ""
echo "  docker CLI → dockerd (daemon) → containerd → containerd-shim → runc → conteneur"
echo ""
echo "Vérifions que tous ces composants sont présents..."
echo ""

echo -e "${YELLOW}Processus dockerd (daemon Docker) :${NC}"
ps aux | grep "dockerd" | grep -v grep | head -2
echo ""

echo -e "${YELLOW}Processus containerd :${NC}"
ps aux | grep "containerd" | grep -v "grep\|shim" | head -2
echo ""

echo -e "${BLUE}2. Lancement d'un Conteneur et Observation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Démarrage d'un conteneur Nginx...${NC}"
CONTAINER_NAME="demo-architecture-$$"
docker run -d --name $CONTAINER_NAME nginx:alpine > /dev/null
echo "Container lancé: $CONTAINER_NAME"
echo ""

sleep 2

echo -e "${YELLOW}Arbre des processus (hierarchie) :${NC}"
echo ""

# Récupérer le PID du conteneur
CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME)

if command -v pstree &> /dev/null; then
    echo "Arbre complet depuis dockerd :"
    pstree -p | grep -E "dockerd|containerd|$CONTAINER_PID" | head -20 || echo "Processus non trouvés dans pstree"
else
    echo "pstree n'est pas installé, utilisation de ps :"
    echo ""
    ps aux | grep -E "dockerd|containerd|nginx|shim" | grep -v grep
fi
echo ""

echo -e "${YELLOW}Détails de la chaîne de processus :${NC}"
echo ""

# Trouver le containerd-shim parent
SHIM_PID=$(ps -o ppid= -p $CONTAINER_PID 2>/dev/null | tr -d ' ')

if [ -n "$SHIM_PID" ] && [ "$SHIM_PID" != "0" ]; then
    echo "1. containerd-shim (PID: $SHIM_PID)"
    ps -p $SHIM_PID -o pid,ppid,user,command | tail -1
    echo ""
    echo "   ↓ fork/exec"
    echo ""
    echo "2. nginx master process (PID: $CONTAINER_PID)"
    ps -p $CONTAINER_PID -o pid,ppid,user,command | tail -1
    echo ""

    # Trouver les workers nginx
    WORKER_PIDS=$(pgrep -P $CONTAINER_PID 2>/dev/null || echo "")
    if [ -n "$WORKER_PIDS" ]; then
        echo "   ↓ spawns"
        echo ""
        echo "3. nginx worker processes :"
        for pid in $WORKER_PIDS; do
            ps -p $pid -o pid,ppid,user,command | tail -1
        done
    fi
else
    echo "Impossible de tracer la hiérarchie des processus"
    echo "PID du conteneur: $CONTAINER_PID"
fi
echo ""

echo -e "${BLUE}3. Interaction avec containerd Directement${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v ctr &> /dev/null; then
    echo -e "${YELLOW}Utilisation de ctr (CLI containerd) :${NC}"
    echo ""

    echo "Conteneurs dans le namespace 'moby' (utilisé par Docker) :"
    sudo ctr --namespace moby containers list | head -10 || echo "Nécessite sudo"
    echo ""

    echo "Images dans containerd :"
    sudo ctr --namespace moby images list | head -10 || echo "Nécessite sudo"
    echo ""
else
    echo "L'outil 'ctr' n'est pas disponible"
    echo "Il est normalement installé avec containerd"
fi

echo -e "${BLUE}4. Vérification de runc${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v runc &> /dev/null; then
    echo -e "${YELLOW}Version de runc :${NC}"
    runc --version
    echo ""

    echo -e "${YELLOW}runc est le runtime OCI de bas niveau${NC}"
    echo "Il configure les namespaces, cgroups et lance le processus final"
    echo ""
else
    echo "runc n'est pas dans le PATH"
    echo "Docker utilise généralement: /usr/bin/runc"
    if [ -f "/usr/bin/runc" ]; then
        /usr/bin/runc --version
    fi
fi

echo -e "${BLUE}5. Comparaison avec Podman (si installé)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v podman &> /dev/null; then
    echo -e "${CYAN}Architecture Podman :${NC}"
    echo ""
    echo "  podman CLI → libpod → conmon → runc → conteneur"
    echo "  (pas de daemon !)"
    echo ""

    echo -e "${YELLOW}Lancement d'un conteneur Podman :${NC}"
    podman run -d --name podman-demo-$$ nginx:alpine > /dev/null || true
    echo ""

    echo -e "${YELLOW}Processus conmon (équivalent de containerd-shim) :${NC}"
    ps aux | grep "conmon" | grep -v grep | head -3
    echo ""

    echo -e "${GREEN}Différence clé :${NC}"
    echo "  • Docker : Daemon dockerd (root) toujours actif"
    echo "  • Podman : Pas de daemon, processus direct de l'utilisateur"
    echo ""

    podman rm -f podman-demo-$$ > /dev/null 2>&1 || true
else
    echo "Podman n'est pas installé"
    echo ""
    echo "Pour comparer avec Podman, installez-le :"
    echo "  sudo apt install podman"
fi

echo -e "${BLUE}6. Communication Docker CLI → Daemon${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Socket Docker (communication IPC) :${NC}"
ls -l /var/run/docker.sock
echo ""

echo -e "${YELLOW}Le Docker CLI communique via ce socket Unix${NC}"
echo ""

echo "Exemple de requête (simulée) :"
echo "  \$ docker ps"
echo "    ↓"
echo "  HTTP GET /v1.41/containers/json → /var/run/docker.sock"
echo "    ↓"
echo "  dockerd traite la requête et renvoie JSON"
echo ""

echo -e "${YELLOW}Variables d'environnement Docker :${NC}"
docker version --format '{{.Client.Version}}' | xargs -I {} echo "  Client version: {}"
docker version --format '{{.Server.Version}}' | xargs -I {} echo "  Server version: {}"
echo ""

echo -e "${BLUE}7. Nettoyage${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker rm -f $CONTAINER_NAME > /dev/null
echo "Conteneur supprimé: $CONTAINER_NAME"
echo ""

echo "=== Démonstration Terminée ==="
echo ""
echo -e "${GREEN}Points clés :${NC}"
echo ""
echo "  1. Docker utilise une architecture en couches :"
echo "     docker CLI → dockerd → containerd → shim → runc → conteneur"
echo ""
echo "  2. containerd peut être utilisé indépendamment de Docker"
echo "     (notamment dans Kubernetes)"
echo ""
echo "  3. runc est le runtime OCI standard qui configure les"
echo "     namespaces, cgroups et lance le processus final"
echo ""
echo "  4. Podman offre une alternative sans daemon,"
echo "     plus sécurisée et rootless par défaut"
echo ""
echo "  5. Tous respectent le standard OCI (Open Container Initiative)"
echo "     garantissant l'interopérabilité"
