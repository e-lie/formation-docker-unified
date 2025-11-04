---
title: "TP: Builder et pousser des images avec Podman, Buildah et Skopeo"
description: "Guide TP: Builder et pousser des images avec Podman, Buildah et Skopeo"
sidebar:
  order: 207
---


## Introduction

Dans ce TP, vous allez découvrir l'écosystème **Podman**, une alternative à Docker qui offre plusieurs avantages :
- **Podman** : Runtime de conteneurs sans daemon, compatible avec Docker
- **Buildah** : Outil spécialisé pour construire des images de conteneurs
- **Skopeo** : Outil pour inspecter, copier et transférer des images entre registries

## Pourquoi Podman, Buildah et Skopeo ?

### Avantages par rapport à Docker

1. **Pas de daemon** : Podman n'utilise pas de processus daemon central, ce qui améliore la sécurité
2. **Rootless par défaut** : Possibilité d'exécuter des conteneurs sans privilèges root
3. **Compatible OCI** : Respect total des standards Open Container Initiative
4. **Séparation des responsabilités** :
   - **Podman** : Exécution et gestion des conteneurs
   - **Buildah** : Construction d'images optimisée
   - **Skopeo** : Gestion des images dans les registries
5. **Compatible Docker** : `alias docker=podman` fonctionne pour la plupart des commandes

### Cas d'usage

- **Environnements sans Docker** : Kubernetes natif, certaines distributions Linux
- **CI/CD** : Builds sans privilèges root
- **Sécurité renforcée** : Pas de daemon avec privilèges élevés
- **Gestion multi-registry** : Skopeo facilite la migration d'images entre registries

## Partie 1 : Installation de Podman, Buildah et Skopeo


```bash
# Mettre à jour les paquets
sudo apt update

# Installer Podman, Buildah et Skopeo
sudo apt install -y podman buildah skopeo

# Vérifier les installations
podman --version
buildah --version
skopeo --version
```

### Configuration initiale de Podman

```bash
# Créer les répertoires de configuration si nécessaire
mkdir -p ~/.config/containers

# (Optionnel) Configurer les registries
cat << 'EOF' > ~/.config/containers/registries.conf
[registries.search]
registries = ['docker.io', 'quay.io', 'ghcr.io']
EOF
```

## Partie 2 : Builder avec Buildah

Buildah offre plusieurs méthodes pour construire des images. Nous allons voir les deux approches principales.

### Méthode 1 : Build depuis un Dockerfile existant

C'est la méthode la plus simple si vous avez déjà un Dockerfile.

```bash
# Se placer dans le dossier du TP
cd section_images_dockerfiles/207_podman_buildah_skopeo

# Builder l'image avec Buildah
buildah build -t monsterstack:buildah .

# Alternative : utiliser bud (build using dockerfile)
buildah bud -t monsterstack:buildah .

# Lister les images
buildah images
# ou
podman images
```

:::tip[Points clés]
- `buildah build` et `buildah bud` sont équivalents
- Les images buildées avec Buildah sont automatiquement disponibles pour Podman
- Le tag est formaté selon le standard OCI : `localhost/monsterstack:buildah`
:::

### Méthode 2 : Build scriptée (approche native Buildah)

Buildah permet de construire des images de manière scriptée, offrant plus de contrôle et de flexibilité.

Créons un script `build-with-buildah.sh` :

```bash
#!/bin/bash
set -e

# Créer un conteneur de travail depuis une image de base
container=$(buildah from python:3.10)

echo "Container ID: $container"

# Créer l'utilisateur uwsgi
buildah run $container groupadd -r uwsgi
buildah run $container useradd -r -g uwsgi uwsgi

# Installer les dépendances Python
buildah run $container pip install Flask uWSGI requests redis

# Configurer le workdir
buildah config --workingdir /app $container

# Copier les fichiers de l'application
buildah copy $container ./app /app
buildah copy $container boot.sh /boot.sh

# Rendre boot.sh exécutable
buildah run $container chmod a+x /boot.sh

# Définir les variables d'environnement
buildah config --env CONTEXT=PROD $container
buildah config --env IMAGEBACKEND_DOMAIN=imagebackend $container
buildah config --env REDIS_DOMAIN=redis $container

# Exposer les ports
buildah config --port 5000 --port 9191 $container

# Définir l'utilisateur
buildah config --user uwsgi $container

# Définir la commande par défaut
buildah config --cmd '/boot.sh' $container

# Commiter le conteneur en image
buildah commit $container monsterstack:buildah-scripted

# Nettoyer le conteneur de travail
buildah rm $container

echo "Image built successfully: monsterstack:buildah-scripted"
```

Rendre le script exécutable et l'exécuter :

```bash
chmod +x build-with-buildah.sh
./build-with-buildah.sh
```

:::note[Avantages du build scripté]
- **Contrôle fin** : Chaque étape est explicite
- **Debuggable** : Possibilité d'inspecter le conteneur entre les étapes
- **Pas de cache** : Reconstruction complète à chaque fois (utile pour CI/CD)
- **Optimisation** : Possibilité d'optimiser les layers manuellement
:::

### Comparer les deux méthodes

```bash
# Lister toutes les images
podman images

# Comparer les tailles
podman images | grep monsterstack
```

### Inspecter une image

```bash
# Avec Buildah
buildah inspect monsterstack:buildah

# Avec Skopeo (plus détaillé)
skopeo inspect containers-storage:localhost/monsterstack:buildah
```

## Partie 3 : Pousser des images avec Skopeo

Skopeo est un outil puissant pour gérer les images sans avoir besoin de les charger dans le storage local.

### Inspecter une image distante

```bash
# Inspecter une image sur Docker Hub (sans la télécharger)
skopeo inspect docker://docker.io/library/nginx:alpine

# Inspecter notre image locale
skopeo inspect containers-storage:localhost/monsterstack:buildah
```

### Copier une image vers un registry

Skopeo peut copier des images entre différents types de storage et registries.

#### Exemple 1 : Pousser vers Docker Hub

```bash
# Se connecter au registry
skopeo login docker.io

# Copier l'image locale vers Docker Hub
skopeo copy \
  containers-storage:localhost/monsterstack:buildah \
  docker://docker.io/votre-username/monsterstack:v1.0

# Alternative : tagger puis pousser
podman tag monsterstack:buildah docker.io/votre-username/monsterstack:v1.0
podman push docker.io/votre-username/monsterstack:v1.0
```

#### Exemple 2 : Pousser vers GitLab Container Registry

```bash
# Se connecter au registry GitLab
skopeo login registry.gitlab.com

# Copier l'image
skopeo copy \
  containers-storage:localhost/monsterstack:buildah \
  docker://registry.gitlab.com/votre-username/monsterstack:v1.0
```

#### Exemple 3 : Copier entre registries (sans téléchargement local)

```bash
# Copier directement de Docker Hub vers GitLab Registry
skopeo copy \
  docker://docker.io/nginx:alpine \
  docker://registry.gitlab.com/votre-username/nginx:alpine
```

:::tip[Avantages de Skopeo]
- **Pas de daemon** : Fonctionne sans runtime de conteneurs
- **Efficacité** : Copie directe entre registries
- **Inspection** : Voir les métadonnées sans télécharger
- **Signature** : Support de la signature d'images
:::

### Gérer les credentials de registry

```bash
# Voir les registries configurés
cat ~/.config/containers/registries.conf

# Lister les authentifications
cat ~/.config/containers/auth.json

# Se déconnecter
skopeo logout docker.io
```

## Partie 4 : Exécuter avec Podman

Podman est compatible avec la plupart des commandes Docker.

### Exécuter l'application en mode développement

```bash
# Lancer les services avec podman-compose
# Installer podman-compose si nécessaire
pip3 install --user podman-compose

# Ou utiliser podman directement (comme docker run)
podman run -d \
  --name monsterstack-frontend \
  -p 5000:5000 \
  -e CONTEXT=DEV \
  -e REDIS_DOMAIN=redis \
  -e IMAGEBACKEND_DOMAIN=imagebackend \
  monsterstack:buildah

# Lancer Redis
podman run -d --name redis redis:alpine

# Lancer le backend d'images
podman run -d --name imagebackend amouat/dnmonster:1.0

# Créer un réseau et reconnecter les conteneurs
podman network create monster_network

# Recréer les conteneurs avec le réseau
podman rm -f monsterstack-frontend redis imagebackend

podman run -d \
  --name redis \
  --network monster_network \
  redis:alpine

podman run -d \
  --name imagebackend \
  --network monster_network \
  amouat/dnmonster:1.0

podman run -d \
  --name monsterstack-frontend \
  --network monster_network \
  -p 5000:5000 \
  -e CONTEXT=PROD \
  -e REDIS_DOMAIN=redis \
  -e IMAGEBACKEND_DOMAIN=imagebackend \
  monsterstack:buildah
```

### Utiliser Podman Compose

Podman supporte docker-compose via `podman-compose`.

```bash
# Utiliser le docker-compose.yml existant
podman-compose up -d

# Voir les logs
podman-compose logs -f

# Arrêter
podman-compose down
```

:::caution[Compatibilité]
`podman-compose` est une réimplémentation de docker-compose et peut avoir quelques différences mineures. Pour une compatibilité maximale, utilisez `docker-compose` avec Podman en mode Docker socket.
:::

### Vérifier le fonctionnement

```bash
# Tester l'API
curl http://localhost:5000

# Vérifier les logs
podman logs monsterstack-frontend

# Inspecter le conteneur
podman inspect monsterstack-frontend

# Voir les processus
podman top monsterstack-frontend
```

### Utiliser Podman en mode rootless

Un des avantages majeurs de Podman est le support rootless (sans privilèges root).

```bash
# Tout fonctionne sans sudo !
podman run -d --name test-nginx -p 8080:80 nginx:alpine

# Voir les conteneurs en tant qu'utilisateur normal
podman ps

# Nettoyer
podman rm -f test-nginx
```

:::note[Ports rootless]
En mode rootless, les ports < 1024 nécessitent une configuration spéciale. Par défaut, utilisez des ports ≥ 1024 ou configurez `net.ipv4.ip_unprivileged_port_start`.
:::

## Partie 5 : Workflow complet CI/CD

Voici un exemple de workflow complet utilisant Buildah et Skopeo dans un contexte CI/CD.

### Script de build CI/CD

Créons un script `ci-build.sh` :

```bash
#!/bin/bash
set -e

# Variables
IMAGE_NAME="monsterstack"
REGISTRY="registry.gitlab.com/votre-username"
TAG="${CI_COMMIT_SHA:-latest}"

echo "=== Building image with Buildah ==="
buildah build -t ${IMAGE_NAME}:${TAG} .

echo "=== Running tests ==="
# Lancer les tests unitaires dans un conteneur
podman run --rm \
  -v $(pwd)/app:/app:ro \
  ${IMAGE_NAME}:${TAG} \
  python3 -m pytest /app/tests/unit.py || true

echo "=== Pushing image with Skopeo ==="
# Pousser vers le registry
skopeo copy \
  --dest-creds=${REGISTRY_USER}:${REGISTRY_PASSWORD} \
  containers-storage:localhost/${IMAGE_NAME}:${TAG} \
  docker://${REGISTRY}/${IMAGE_NAME}:${TAG}

echo "=== Tagging as latest ==="
# Tagger aussi comme 'latest'
skopeo copy \
  --dest-creds=${REGISTRY_USER}:${REGISTRY_PASSWORD} \
  containers-storage:localhost/${IMAGE_NAME}:${TAG} \
  docker://${REGISTRY}/${IMAGE_NAME}:latest

echo "=== Build and push complete ==="
```

### Exemple de pipeline GitLab CI

Créons un fichier `.gitlab-ci-podman.yml` :

```yaml
stages:
  - build
  - test
  - push

variables:
  IMAGE_NAME: monsterstack
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

build-with-buildah:
  stage: build
  image: quay.io/buildah/stable:latest
  script:
    - buildah build -t $IMAGE_NAME:$CI_COMMIT_SHORT_SHA .
    - buildah push $IMAGE_NAME:$CI_COMMIT_SHORT_SHA oci-archive:image.tar
  artifacts:
    paths:
      - image.tar
    expire_in: 1 hour

test-image:
  stage: test
  image: quay.io/podman/stable:latest
  dependencies:
    - build-with-buildah
  script:
    - podman load -i image.tar
    - podman run --rm $IMAGE_NAME:$CI_COMMIT_SHORT_SHA python3 -m pytest /app/tests/unit.py || true

push-with-skopeo:
  stage: push
  image: quay.io/skopeo/stable:latest
  dependencies:
    - build-with-buildah
  before_script:
    - skopeo login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    # Charger l'image depuis l'archive OCI
    - skopeo copy oci-archive:image.tar docker://$IMAGE_TAG
    - skopeo copy oci-archive:image.tar docker://$CI_REGISTRY_IMAGE:latest
  only:
    - main
```

## Partie 6 : Commandes utiles et comparaison

### Tableau de comparaison Docker vs Podman

| Opération | Docker | Podman |
|-----------|--------|--------|
| Lancer un conteneur | `docker run` | `podman run` |
| Lister les conteneurs | `docker ps` | `podman ps` |
| Builder une image | `docker build` | `buildah build` ou `podman build` |
| Pousser une image | `docker push` | `podman push` ou `skopeo copy` |
| Inspecter une image | `docker inspect` | `podman inspect` ou `skopeo inspect` |
| Copier entre registries | ❌ | `skopeo copy` |
| Exécuter sans root | ⚠️ Limité | ✅ Natif |

### Alias pour transition Docker → Podman

```bash
# Ajouter dans ~/.bashrc ou ~/.zshrc
alias docker=podman
alias docker-compose=podman-compose

# Recharger le shell
source ~/.bashrc
```

### Commandes Buildah utiles

```bash
# Lister les conteneurs de travail
buildah containers

# Lister les images
buildah images

# Supprimer une image
buildah rmi monsterstack:buildah

# Nettoyer tout
buildah rm --all
buildah rmi --all
```

### Commandes Skopeo utiles

```bash
# Inspecter sans télécharger
skopeo inspect docker://nginx:alpine

# Lister les tags d'une image
skopeo list-tags docker://docker.io/library/nginx

# Copier depuis un registry vers un fichier tar
skopeo copy docker://nginx:alpine docker-archive:nginx.tar

# Supprimer une image distante (si permissions)
skopeo delete docker://registry.example.com/monsterstack:old
```

## Questions de réflexion

1. **Pourquoi Buildah et Podman sont-ils séparés ?**
   - Séparation des responsabilités : build vs runtime
   - Permet d'optimiser chaque outil pour sa tâche
   - Possibilité d'utiliser Buildah dans des environnements sans Podman

2. **Quels sont les avantages du mode rootless ?**
   - Sécurité accrue : pas de daemon root
   - Isolation utilisateur : chaque utilisateur a son propre espace
   - Conformité : certaines réglementations interdisent l'exécution en root

3. **Quand utiliser Skopeo plutôt que `podman push` ?**
   - Copie directe entre registries (sans local)
   - Inspection d'images distantes
   - Scripts CI/CD où Podman n'est pas installé
   - Gestion de signatures d'images

4. **Podman peut-il totalement remplacer Docker ?**
   - Pour la plupart des cas : oui
   - Limitations : Docker Swarm non supporté (utiliser Kubernetes)
   - Écosystème Docker (Desktop, extensions) non équivalent

## Nettoyage

```bash
# Arrêter tous les conteneurs
podman stop -a

# Supprimer tous les conteneurs
podman rm -a

# Supprimer toutes les images
podman rmi -a

# Nettoyer le système complet
podman system prune -a --volumes

# Nettoyer Buildah
buildah rm --all
buildah rmi --all
```

## Conclusion

Vous avez maintenant découvert l'écosystème Podman :

✅ **Buildah** : Construction d'images flexible et scriptable
✅ **Skopeo** : Gestion d'images multi-registry sans daemon
✅ **Podman** : Runtime de conteneurs compatible Docker et rootless

### Cas d'usage recommandés

- **CI/CD** : Buildah pour builds sans privilèges
- **Gestion multi-registry** : Skopeo pour copier/migrer des images
- **Environnements restreints** : Podman en mode rootless
- **Kubernetes natif** : Podman génère des manifests Kubernetes

### Pour aller plus loin

- **Podman Desktop** : Interface graphique alternative à Docker Desktop
- **Quadlets** : Systemd units pour gérer des conteneurs Podman
- **Podman pods** : Groupes de conteneurs (équivalent Kubernetes pods)
- **Buildah + multistage** : Builds optimisés complexes

## Références

- 📚 [Podman Documentation](https://docs.podman.io/)
- 🔨 [Buildah Tutorial](https://github.com/containers/buildah/tree/main/docs/tutorials)
- 🚀 [Skopeo Documentation](https://github.com/containers/skopeo)
- 📖 [Podman vs Docker](https://developers.redhat.com/articles/podman-next-generation-linux-container-tools)
