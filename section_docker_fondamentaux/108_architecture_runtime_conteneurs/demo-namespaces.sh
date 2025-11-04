#!/bin/bash
# Démonstration des Namespaces Linux pour les conteneurs

set -e

echo "=== Démonstration des Namespaces Linux ==="
echo ""

# Couleurs pour la lisibilité
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo "Docker n'est pas installé. Installez-le pour continuer."
    exit 1
fi

echo -e "${BLUE}1. Démonstration du Namespace PID${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Sur l'hôte, voici les premiers processus :${NC}"
ps aux | head -5
echo ""

echo -e "${YELLOW}Lançons un conteneur et regardons SES processus :${NC}"
docker run --rm alpine ps aux
echo ""

echo -e "${GREEN}✓ Observation :${NC} Le conteneur voit UNIQUEMENT ses processus"
echo "  Le processus 'ps' a le PID 1 dans le conteneur,"
echo "  mais un PID différent sur l'hôte (namespace PID isolé)"
echo ""

echo -e "${BLUE}2. Démonstration du Namespace NET (Network)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Interfaces réseau de l'hôte :${NC}"
ip addr show | grep -E "^[0-9]+:|inet " | head -8
echo ""

echo -e "${YELLOW}Interfaces réseau dans un conteneur :${NC}"
docker run --rm alpine ip addr show
echo ""

echo -e "${GREEN}✓ Observation :${NC} Le conteneur a ses propres interfaces réseau"
echo "  (généralement eth0 + lo) complètement séparées de l'hôte"
echo ""

echo -e "${BLUE}3. Démonstration du Namespace MNT (Mount)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Système de fichiers racine de l'hôte :${NC}"
ls -la / | head -8
echo ""

echo -e "${YELLOW}Système de fichiers racine dans un conteneur Alpine :${NC}"
docker run --rm alpine ls -la /
echo ""

echo -e "${GREEN}✓ Observation :${NC} Le conteneur voit un système de fichiers complètement différent"
echo "  C'est le namespace MNT qui isole les points de montage"
echo ""

echo -e "${BLUE}4. Démonstration du Namespace UTS (Hostname)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Hostname de l'hôte :${NC}"
hostname
echo ""

echo -e "${YELLOW}Hostname dans un conteneur (généré aléatoirement) :${NC}"
docker run --rm alpine hostname
echo ""

echo -e "${YELLOW}Hostname personnalisé dans un conteneur :${NC}"
docker run --rm --hostname demo-container alpine hostname
echo ""

echo -e "${GREEN}✓ Observation :${NC} Chaque conteneur peut avoir son propre hostname"
echo "  indépendant de l'hôte (namespace UTS)"
echo ""

echo -e "${BLUE}5. Explorer les Namespaces d'un Conteneur en Détail${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Démarrage d'un conteneur en arrière-plan...${NC}"
CONTAINER_ID=$(docker run -d nginx:alpine)
echo "Container ID: $CONTAINER_ID"
echo ""

echo -e "${YELLOW}Récupération du PID du processus principal...${NC}"
CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_ID)
echo "PID du conteneur sur l'hôte: $CONTAINER_PID"
echo ""

if [ -n "$CONTAINER_PID" ] && [ "$CONTAINER_PID" != "0" ]; then
    echo -e "${YELLOW}Namespaces du conteneur (liens symboliques) :${NC}"
    sudo ls -l /proc/$CONTAINER_PID/ns/ 2>/dev/null || echo "Nécessite sudo pour voir les namespaces"
    echo ""

    echo -e "${YELLOW}Comparaison avec les namespaces du processus init (PID 1) :${NC}"
    sudo ls -l /proc/1/ns/ 2>/dev/null || echo "Nécessite sudo pour voir les namespaces"
    echo ""

    echo -e "${GREEN}✓ Observation :${NC} Les numéros après 'mnt:[', 'net:[', etc. sont différents"
    echo "  Cela confirme que le conteneur utilise des namespaces isolés"
fi
echo ""

echo -e "${YELLOW}Nettoyage du conteneur...${NC}"
docker rm -f $CONTAINER_ID > /dev/null
echo ""

echo -e "${BLUE}6. Namespace USER (Rootless)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Dans Docker standard, les processus tournent en root :${NC}"
docker run --rm alpine id
echo ""

if command -v podman &> /dev/null; then
    echo -e "${YELLOW}Avec Podman rootless, le mapping est différent :${NC}"
    podman run --rm alpine id
    echo ""
    echo -e "${GREEN}✓ Observation :${NC} Podman utilise le User Namespace pour mapper"
    echo "  root dans le conteneur vers votre UID utilisateur sur l'hôte"
else
    echo -e "${YELLOW}Podman n'est pas installé${NC}"
    echo "Installez Podman pour voir la démonstration du mode rootless :"
    echo "  sudo apt install podman"
fi
echo ""

echo "=== Démonstration Terminée ==="
echo ""
echo -e "${GREEN}Résumé des Namespaces :${NC}"
echo "  • PID  : Isolation des processus"
echo "  • NET  : Isolation réseau (interfaces, ports, routes)"
echo "  • MNT  : Isolation du système de fichiers"
echo "  • UTS  : Isolation du hostname"
echo "  • IPC  : Isolation de la communication inter-processus"
echo "  • USER : Isolation des UID/GID (rootless)"
echo "  • CGROUP: Isolation de la vue des cgroups"
echo ""
echo "Ces namespaces sont la BASE de l'isolation des conteneurs Linux !"
