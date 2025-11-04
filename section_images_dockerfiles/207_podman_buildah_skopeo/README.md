# TP 207: Builder et pousser des images avec Podman, Buildah et Skopeo

Ce TP vous guide dans l'utilisation de l'écosystème Podman pour construire, gérer et distribuer des images de conteneurs.

## Contenu du TP

- **0_podman_buildah_skopeo.md** : Instructions complètes du TP
- **app/** : Code source de l'application MonsterStack (Flask Python)
- **Dockerfile** : Dockerfile standard (compatible avec Buildah)
- **docker-compose.yml** : Configuration Docker Compose (compatible avec podman-compose)
- **build-with-buildah.sh** : Script de build Buildah natif (approche scriptée)
- **ci-build.sh** : Script CI/CD complet avec Buildah et Skopeo
- **.gitlab-ci-podman.yml** : Exemple de pipeline GitLab CI utilisant Podman/Buildah/Skopeo

## Prérequis

- Linux (Ubuntu 22.04+ ou Debian 11+)
- Podman, Buildah et Skopeo installés

```bash
sudo apt update
sudo apt install -y podman buildah skopeo
```

## Quick Start

### 1. Build avec Buildah (méthode Dockerfile)

```bash
buildah build -t monsterstack:buildah .
```

### 2. Build avec Buildah (méthode scriptée)

```bash
chmod +x build-with-buildah.sh
./build-with-buildah.sh
```

### 3. Exécuter avec Podman

```bash
# Démarrer l'application complète
podman-compose up -d

# Ou manuellement
podman run -d -p 5000:5000 --name monsterstack monsterstack:buildah
```

### 4. Pousser avec Skopeo

```bash
# Inspecter l'image
skopeo inspect containers-storage:localhost/monsterstack:buildah

# Pousser vers un registry
skopeo login docker.io
skopeo copy \
  containers-storage:localhost/monsterstack:buildah \
  docker://docker.io/votre-username/monsterstack:v1.0
```

## Structure de l'application MonsterStack

```
├── app/
│   ├── src/
│   │   └── monster_icon.py     # Application Flask principale
│   ├── tests/
│   │   ├── unit.py             # Tests unitaires
│   │   └── integration.py      # Tests d'intégration
│   └── requirements.dev.txt     # Dépendances de développement
├── Dockerfile                   # Dockerfile standard
├── docker-compose.yml           # Configuration multi-conteneurs
└── boot.sh                      # Script de démarrage
```

## Commandes utiles

### Buildah

```bash
# Lister les images
buildah images

# Lister les conteneurs de travail
buildah containers

# Supprimer une image
buildah rmi monsterstack:buildah

# Nettoyer
buildah rm --all
buildah rmi --all
```

### Podman

```bash
# Lister les conteneurs
podman ps -a

# Lister les images
podman images

# Logs
podman logs monsterstack

# Arrêter et supprimer
podman stop monsterstack
podman rm monsterstack
```

### Skopeo

```bash
# Inspecter une image locale
skopeo inspect containers-storage:localhost/monsterstack:buildah

# Inspecter une image distante
skopeo inspect docker://docker.io/nginx:alpine

# Lister les tags
skopeo list-tags docker://docker.io/library/nginx

# Copier entre registries
skopeo copy \
  docker://source-registry/image:tag \
  docker://dest-registry/image:tag
```

## Workflow CI/CD

Le script `ci-build.sh` démontre un workflow complet :

```bash
# Avec variables d'environnement
export IMAGE_NAME=monsterstack
export REGISTRY=registry.gitlab.com/username
export TAG=v1.0.0

# Build et push
chmod +x ci-build.sh
./ci-build.sh

# Ou avec skip push (local seulement)
SKIP_PUSH=true ./ci-build.sh
```

## Tests

```bash
# Tests unitaires
podman run --rm \
  -v $(pwd)/app:/app:ro \
  monsterstack:buildah \
  python3 -m pytest /app/tests/unit.py

# Tests d'intégration (nécessite Redis)
podman run -d --name redis redis:alpine
podman run --rm \
  --network container:redis \
  -e REDIS_DOMAIN=localhost \
  monsterstack:buildah \
  python3 -m pytest /app/tests/integration.py
```

## Documentation complète

Consultez le fichier **0_podman_buildah_skopeo.md** pour le TP complet avec :
- Explications détaillées
- Exemples pas à pas
- Comparaison Docker vs Podman
- Bonnes pratiques CI/CD
- Troubleshooting

## Liens utiles

- [Podman Documentation](https://docs.podman.io/)
- [Buildah Tutorial](https://github.com/containers/buildah/tree/main/docs/tutorials)
- [Skopeo Documentation](https://github.com/containers/skopeo)
- [Podman Desktop](https://podman-desktop.io/)
