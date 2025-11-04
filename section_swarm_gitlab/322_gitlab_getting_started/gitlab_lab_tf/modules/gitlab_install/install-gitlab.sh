#!/bin/bash
set -e

echo "=========================================="
echo "  Installation de GitLab CE (Docker)"
echo "=========================================="
echo ""

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "Erreur : Docker n'est pas installé"
    exit 1
fi

# Vérifier que le fichier docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    echo "Erreur : docker-compose.yml n'existe pas dans le répertoire courant"
    exit 1
fi

echo "Démarrage de GitLab..."
docker compose up -d

echo ""
echo "GitLab est en cours de démarrage..."
echo "Cela peut prendre plusieurs minutes (5-10 minutes)."
echo ""
echo "Pour suivre les logs :"
echo "  docker compose logs -f gitlab"
echo ""
echo "Pour vérifier l'état :"
echo "  docker compose ps"
echo ""
echo "GitLab sera accessible une fois démarré."
echo ""
echo "=========================================="
echo "  Configuration post-installation"
echo "=========================================="
echo ""
echo "1. Attendez que GitLab soit complètement démarré :"
echo "   docker exec -it gitlab gitlab-ctl status"
echo ""
echo "2. Pour créer un Personal Access Token (nécessaire pour Terraform) :"
echo "   - Connectez-vous en tant que root, utilisez le mdp root fournis à l'installation dans terraform"
echo "   - Allez dans : User Settings > Access Tokens"
echo "   - Créez un token avec le scope 'api'"
echo "   - Sauvegardez le token pour la configuration Terraform"
echo ""
