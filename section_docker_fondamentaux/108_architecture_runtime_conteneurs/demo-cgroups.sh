#!/bin/bash
# Démonstration des Cgroups (Control Groups) pour les conteneurs

set -e

echo "=== Démonstration des Cgroups (Control Groups) ==="
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    echo "Docker n'est pas installé."
    exit 1
fi

echo -e "${BLUE}1. Limitation de la Mémoire (Memory Cgroup)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Lancement d'un conteneur avec limite de 256 MB de RAM :${NC}"
docker run -d --name limited-memory \
  --memory="256m" \
  nginx:alpine

echo "Container: limited-memory (limite: 256 MB)"
echo ""

echo -e "${YELLOW}Vérification avec docker stats :${NC}"
docker stats --no-stream limited-memory
echo ""

# Récupérer l'ID complet du conteneur
CONTAINER_ID=$(docker inspect -f '{{.Id}}' limited-memory)

echo -e "${YELLOW}Vérification dans les cgroups du système :${NC}"
CGROUP_PATH="/sys/fs/cgroup/memory/docker/$CONTAINER_ID"

if [ -d "$CGROUP_PATH" ]; then
    LIMIT=$(sudo cat $CGROUP_PATH/memory.limit_in_bytes 2>/dev/null || echo "N/A")
    if [ "$LIMIT" != "N/A" ]; then
        LIMIT_MB=$((LIMIT / 1024 / 1024))
        echo "Limite mémoire (cgroup) : $LIMIT_MB MB"
    fi
else
    # Essayer avec cgroups v2
    CGROUP_V2_PATH="/sys/fs/cgroup/system.slice/docker-$CONTAINER_ID.scope"
    if [ -d "$CGROUP_V2_PATH" ]; then
        echo "Utilisation de cgroups v2"
        LIMIT=$(sudo cat $CGROUP_V2_PATH/memory.max 2>/dev/null || echo "N/A")
        if [ "$LIMIT" != "N/A" ] && [ "$LIMIT" != "max" ]; then
            LIMIT_MB=$((LIMIT / 1024 / 1024))
            echo "Limite mémoire (cgroup v2) : $LIMIT_MB MB"
        fi
    else
        echo "Chemin cgroup: Varie selon la version (v1 ou v2)"
    fi
fi
echo ""

docker rm -f limited-memory > /dev/null

echo -e "${BLUE}2. Limitation du CPU (CPU Cgroup)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Lancement d'un conteneur limité à 0.5 CPU (50%) :${NC}"
docker run -d --name limited-cpu \
  --cpus="0.5" \
  nginx:alpine

echo "Container: limited-cpu (limite: 50% d'un CPU)"
echo ""

echo -e "${YELLOW}Vérification avec docker stats :${NC}"
docker stats --no-stream limited-cpu
echo ""

docker rm -f limited-cpu > /dev/null

echo -e "${BLUE}3. Limitation de l'I/O Disque (Block I/O Cgroup)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Lancement avec limite d'écriture : 1 MB/s${NC}"
docker run -d --name limited-io \
  --device-write-bps /dev/sda:1mb \
  nginx:alpine 2>/dev/null || docker run -d --name limited-io nginx:alpine

echo "Container: limited-io"
echo ""

docker rm -f limited-io > /dev/null

echo -e "${BLUE}4. Limitation du Nombre de Processus (PIDs Cgroup)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Lancement avec limite : maximum 100 processus${NC}"
docker run -d --name limited-pids \
  --pids-limit 100 \
  nginx:alpine

echo "Container: limited-pids (limite: 100 processus max)"
echo ""

echo -e "${YELLOW}Nombre de processus actuels dans le conteneur :${NC}"
docker exec limited-pids sh -c 'ps aux | wc -l'
echo ""

docker rm -f limited-pids > /dev/null

echo -e "${BLUE}5. Test de Dépassement de Limite (OOM Kill)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Lancement d'un conteneur avec stress-test dépassant la limite mémoire :${NC}"
echo "Container essaie d'allouer 200 MB mais limité à 100 MB"
echo ""

# Vérifier si l'image progrium/stress existe, sinon utiliser une alternative
if docker pull progrium/stress:latest &>/dev/null; then
    STRESS_IMAGE="progrium/stress"
    STRESS_CMD="--vm 1 --vm-bytes 200M --vm-hang 0"
else
    echo "Image stress non disponible, simulation avec alpine..."
    STRESS_IMAGE="alpine"
    STRESS_CMD="sh -c 'dd if=/dev/zero of=/dev/null bs=1M count=200'"
fi

docker run -d --name stress-oom \
  --memory="100m" \
  $STRESS_IMAGE $STRESS_CMD || true

echo "Attente de 5 secondes..."
sleep 5

echo ""
echo -e "${YELLOW}Statut du conteneur :${NC}"
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' stress-oom 2>/dev/null || echo "exited")
OOM_KILLED=$(docker inspect -f '{{.State.OOMKilled}}' stress-oom 2>/dev/null || echo "unknown")

echo "Status: $CONTAINER_STATUS"
echo "OOM Killed: $OOM_KILLED"
echo ""

if [ "$OOM_KILLED" = "true" ]; then
    echo -e "${RED}✓ Le conteneur a été tué par l'OOM Killer (Out Of Memory)${NC}"
    echo "  Le cgroup memory a empêché le dépassement de la limite"
else
    echo -e "${YELLOW}Le conteneur n'a pas dépassé la limite ou s'est terminé normalement${NC}"
fi
echo ""

docker rm -f stress-oom > /dev/null 2>&1 || true

echo -e "${BLUE}6. Cgroups v1 vs v2${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Version de cgroups sur ce système :${NC}"
if mount | grep -q "cgroup2"; then
    echo "✓ Cgroups v2 détectés"
    echo ""
    echo "Cgroups v2 unifient tous les contrôleurs dans une hiérarchie unique"
    echo "Avantages : meilleure organisation, contrôle plus fin, meilleures perfs"
elif [ -d "/sys/fs/cgroup/memory" ]; then
    echo "✓ Cgroups v1 détectés"
    echo ""
    echo "Cgroups v1 utilisent des hiérarchies séparées par contrôleur"
    echo "Chemins typiques :"
    echo "  - /sys/fs/cgroup/memory/"
    echo "  - /sys/fs/cgroup/cpu/"
    echo "  - /sys/fs/cgroup/blkio/"
else
    echo "? Version de cgroups indéterminée"
fi
echo ""

echo "=== Démonstration Terminée ==="
echo ""
echo -e "${GREEN}Résumé des Cgroups :${NC}"
echo "  • Memory  : Limite de RAM (OOM kill si dépassement)"
echo "  • CPU     : Pourcentage de CPU utilisable"
echo "  • Block I/O : Débit disque en lecture/écriture"
echo "  • PIDs    : Nombre maximum de processus"
echo "  • Network : Bande passante réseau (avec tc)"
echo "  • Devices : Accès aux périphériques"
echo ""
echo "Les cgroups permettent la LIMITATION et la MESURE des ressources"
echo "utilisées par les conteneurs !"
