#!/bin/bash
set -e

echo "=========================================="
echo "  Installation du GitLab Runner (Docker)"
echo "=========================================="
echo ""

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "Erreur : Docker n'est pas installé"
    exit 1
fi

# Vérifier que GitLab est accessible
echo "Vérification de l'accès à GitLab..."
if ! docker ps | grep -q gitlab; then
    echo "Erreur : Le conteneur GitLab n'est pas en cours d'exécution"
    echo "Veuillez d'abord installer GitLab avec ./install-gitlab.sh"
    exit 1
fi

echo "Démarrage du GitLab Runner..."

# Créer le volume pour la configuration du runner
docker volume create gitlab-runner-config

# Démarrer le runner
docker run -d \
  --name gitlab-runner \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v gitlab-runner-config:/etc/gitlab-runner \
  gitlab/gitlab-runner:latest

echo ""
echo "GitLab Runner est démarré."
echo ""
echo "=========================================="
echo "  Enregistrement du Runner"
echo "=========================================="
echo ""
echo "Pour enregistrer le runner avec GitLab :"
echo ""
echo "1. Obtenez le registration token depuis GitLab :"
echo "   - Admin Area > CI/CD > Runners"
echo "   - Ou depuis un projet : Settings > CI/CD > Runners"
echo ""
echo "2. Enregistrez le runner :"
echo ""
echo "docker exec -it gitlab-runner gitlab-runner register \\"
echo "  --non-interactive \\"
echo "  --url \"https://gitlab.dopl.uk\" \\"
echo "  --registration-token \"VOTRE_TOKEN\" \\"
echo "  --executor \"docker\" \\"
echo "  --docker-image \"alpine:latest\" \\"
echo "  --description \"docker-runner\" \\"
echo "  --maintenance-note \"Runner pour lab\" \\"
echo "  --tag-list \"docker,lab\" \\"
echo "  --run-untagged=\"true\" \\"
echo "  --locked=\"false\" \\"
echo "  --access-level=\"not_protected\""
echo ""
echo "3. Vérifiez que le runner est enregistré :"
echo "   docker exec -it gitlab-runner gitlab-runner list"
echo ""
echo "Pour des runners shell (exécution directe sur l'hôte) :"
echo "  Utilisez --executor \"shell\" au lieu de \"docker\""
echo ""
