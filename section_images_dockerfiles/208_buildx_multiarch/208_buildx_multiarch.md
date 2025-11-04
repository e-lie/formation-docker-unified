---
title: "TP : Docker Buildx et Multi-Architecture"
---

## Objectifs pédagogiques

- Comprendre les enjeux du multi-architecture
- Maîtriser Docker Buildx pour créer des images multi-plateforme
- Savoir builder et pousser des images pour AMD64 et ARM64
- Utiliser les build contexts et les builders personnalisés

## Introduction : Pourquoi le multi-architecture ?

Dans le monde des conteneurs, différentes architectures de processeurs coexistent :

- **AMD64 (x86_64)** : Architecture dominante des serveurs et PC
- **ARM64 (aarch64)** : Utilisée par les Mac M1/M2/M3, Raspberry Pi, serveurs ARM (AWS Graviton)
- **ARM/v7** : Raspberry Pi 3 et anciens modèles

### Les enjeux du multi-architecture

1. **Portabilité** : Une seule image fonctionne sur toutes les architectures
2. **Performance** : Les images natives sont plus rapides que l'émulation
3. **Coût** : Les instances ARM sont souvent 20-40% moins chères (AWS Graviton, etc.)
4. **Développement** : Les développeurs sur Mac M1/M2 ont besoin d'images ARM

**Problème** : Par défaut, `docker build` crée une image uniquement pour l'architecture de la machine hôte.

## Docker Buildx : Le builder multi-architecture

Docker Buildx est un plugin CLI qui étend les capacités de build de Docker. Il permet notamment :

- Le build multi-architecture en une seule commande
- Le build distribué et la mise en cache avancée
- L'utilisation de nouveaux backends (BuildKit)

### Vérifier Buildx

```bash
# Vérifier que buildx est disponible
docker buildx version

# Lister les builders existants
docker buildx ls
```

Sortie typique :
```
NAME/NODE       DRIVER/ENDPOINT             STATUS    BUILDKIT PLATFORMS
default *       docker
  default       default                     running   v0.11.6  linux/amd64, linux/386
```

### Créer un builder multi-architecture

```bash
# Créer un nouveau builder capable de multi-arch
docker buildx create --name multiarch-builder --use

# Initialiser le builder (télécharge les outils nécessaires)
docker buildx inspect --bootstrap

# Vérifier les plateformes supportées
docker buildx ls
```

Vous devriez voir plusieurs plateformes disponibles :
```
NAME/NODE           DRIVER/ENDPOINT   STATUS   PLATFORMS
multiarch-builder * docker-container
  multiarch-builder0 unix:///var/run/docker.sock running  linux/amd64, linux/arm64, linux/arm/v7, ...
```

## Comment ça marche : QEMU et émulation

Docker Buildx utilise **QEMU** pour émuler différentes architectures :

```bash
# Installer les émulateurs QEMU (généralement déjà fait par Docker Desktop)
docker run --privileged --rm tonistiigi/binfmt --install all

# Vérifier les architectures disponibles
ls -la /proc/sys/fs/binfmt_misc/
```

**Note** : L'émulation est plus lente que le build natif, mais elle permet de builder pour n'importe quelle architecture depuis n'importe quelle machine.

## Builder une image multi-architecture

### Exemple simple : Hello World

```dockerfile
FROM alpine:latest
RUN apk add --no-cache curl
CMD ["echo", "Hello from $(uname -m)"]
```

```bash
# Build pour plusieurs architectures
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag myuser/hello-multiarch:latest \
  --push \
  .
```

**Options importantes** :
- `--platform` : Spécifie les architectures cibles (séparées par des virgules)
- `--push` : Pousse directement vers un registry (obligatoire pour multi-arch)
- `--load` : Charge l'image dans le daemon local (incompatible avec multi-arch)

### Variantes de commandes

```bash
# Build sans push (enregistre dans le builder cache)
docker buildx build --platform linux/amd64,linux/arm64 -t myuser/app:latest .

# Build avec push automatique
docker buildx build --platform linux/amd64,linux/arm64 -t myuser/app:latest --push .

# Build et export en local (une seule architecture à la fois)
docker buildx build --platform linux/amd64 -t myapp:latest --load .

# Build avec plusieurs tags
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myuser/app:latest \
  -t myuser/app:1.0.0 \
  --push \
  .
```

## Les manifests multi-architecture

Quand vous poussez une image multi-architecture, Docker crée automatiquement un **manifest list** :

```bash
# Inspecter un manifest multi-architecture
docker buildx imagetools inspect nginx:latest

# Sortie exemple :
# Name:      docker.io/library/nginx:latest
# MediaType: application/vnd.docker.distribution.manifest.list.v2+json
# Digest:    sha256:abc123...
#
# Manifests:
#   Name:      docker.io/library/nginx:latest@sha256:def456...
#   MediaType: application/vnd.docker.distribution.manifest.v2+json
#   Platform:  linux/amd64
#
#   Name:      docker.io/library/nginx:latest@sha256:ghi789...
#   MediaType: application/vnd.docker.distribution.manifest.v2+json
#   Platform:  linux/arm64
```

Quand vous faites `docker pull nginx:latest`, Docker sélectionne automatiquement la bonne architecture.

## Optimisations et bonnes pratiques

### 1. Utiliser des images de base multi-arch

Choisissez des images de base qui supportent déjà plusieurs architectures :

```dockerfile
# ✅ Ces images supportent amd64 et arm64
FROM python:3.11-slim
FROM node:20-alpine
FROM golang:1.21
FROM nginx:alpine

# ❌ Vérifiez toujours la compatibilité des images tierces
FROM some-custom-image:latest  # Peut ne pas être multi-arch
```

### 2. Gérer les dépendances spécifiques à l'architecture

Certaines dépendances peuvent nécessiter des ajustements :

```dockerfile
FROM python:3.11-slim

# Installer des dépendances qui peuvent varier selon l'archi
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Les wheels Python peuvent nécessiter une compilation
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
```

### 3. Utiliser des ARGs pour l'architecture

Docker injecte automatiquement des variables d'architecture :

```dockerfile
FROM alpine:latest

# Variables automatiques disponibles
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT

RUN echo "Building for platform: ${TARGETPLATFORM}" && \
    echo "Architecture: ${TARGETARCH}" && \
    echo "Variant: ${TARGETVARIANT}"

# Exemple : télécharger le bon binaire selon l'architecture
RUN wget https://example.com/app-${TARGETARCH}.tar.gz
```

Variables disponibles :
- `TARGETPLATFORM` : Ex. `linux/amd64`, `linux/arm64`
- `TARGETARCH` : Ex. `amd64`, `arm64`
- `TARGETVARIANT` : Ex. `v7` pour ARM
- `TARGETOS` : Ex. `linux`, `windows`

### 4. Cache et performance

```bash
# Utiliser un cache registry pour accélérer les builds
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --cache-from type=registry,ref=myuser/app:buildcache \
  --cache-to type=registry,ref=myuser/app:buildcache,mode=max \
  -t myuser/app:latest \
  --push \
  .
```

### 5. Builds multistage pour réduire la taille

```dockerfile
# Stage 1 : Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Stage 2 : Production (plus léger)
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## TP : Builder et déployer une application multi-architecture

### Contexte

Vous allez travailler avec une application complète comprenant :
- **Backend** : API FastAPI (Python) qui expose des informations sur l'architecture
- **Frontend** : Application Svelte qui consomme l'API

L'objectif est de builder ces deux images pour AMD64 et ARM64, puis de les pousser sur un registry.

### Étape 1 : Explorer le code

```bash
# Structure du projet
cd app/
ls -la backend/ frontend/

# Examiner les Dockerfiles
cat backend/Dockerfile
cat frontend/Dockerfile
```

**Questions** :
1. Quelles sont les images de base utilisées ?
2. Ces images supportent-elles le multi-architecture ?
3. Y a-t-il des multistage builds ?

### Étape 2 : Tester en local (architecture native uniquement)

```bash
# Lancer l'application avec docker-compose
docker-compose up --build

# Dans un autre terminal, tester l'API
curl http://localhost:8000/api/info

# Ouvrir le frontend dans un navigateur
# http://localhost
```

**Observation** : Notez l'architecture retournée par l'API. C'est l'architecture de votre machine.

### Étape 3 : Configurer Buildx

```bash
# Créer un builder multi-architecture
docker buildx create --name tp-multiarch --use

# Initialiser et vérifier
docker buildx inspect --bootstrap
docker buildx ls
```

**Question** : Quelles plateformes sont disponibles pour votre builder ?

### Étape 4 : Builder le backend en multi-architecture

```bash
# Se connecter au registry (Docker Hub ou autre)
docker login

# Remplacer 'votreusername' par votre username Docker Hub
export DOCKER_USERNAME=votreusername

# Builder le backend pour AMD64 et ARM64
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag ${DOCKER_USERNAME}/multiarch-backend:latest \
  --file app/backend/Dockerfile \
  --push \
  app/backend/

# Vérifier l'image multi-arch
docker buildx imagetools inspect ${DOCKER_USERNAME}/multiarch-backend:latest
```

**À observer** :
- Le temps de build (plus long car deux architectures)
- Les deux manifests dans l'output de `imagetools inspect`
- Les tailles d'image pour chaque architecture

### Étape 5 : Builder le frontend en multi-architecture

```bash
# Builder le frontend
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag ${DOCKER_USERNAME}/multiarch-frontend:latest \
  --file app/frontend/Dockerfile \
  --push \
  app/frontend/
```

**Challenge** : Le frontend utilise un build multistage. Identifiez les deux stages et expliquez leur rôle.

### Étape 6 : Utiliser le script de build

Un script `build-multiarch.sh` est fourni pour automatiser le processus :

```bash
# Rendre le script exécutable
chmod +x build-multiarch.sh

# Configurer les variables
export DOCKER_USERNAME=votreusername
export VERSION=1.0.0

# Lancer le build
./build-multiarch.sh
```

**Exercice** : Ouvrez et étudiez le script. Quelles sont les étapes automatisées ?

### Étape 7 : Tester sur différentes architectures (Optionnel)

Si vous avez accès à une machine ARM (Mac M1/M2, Raspberry Pi, instance AWS Graviton) :

```bash
# Sur la machine ARM, pull l'image
docker pull ${DOCKER_USERNAME}/multiarch-backend:latest

# Docker sélectionne automatiquement l'architecture ARM64
docker run --rm ${DOCKER_USERNAME}/multiarch-backend:latest \
  python -c "import platform; print(platform.machine())"
```

**Sans machine ARM** : Vous pouvez utiliser l'émulation :

```bash
# Forcer l'utilisation d'une image ARM64 avec émulation
docker run --rm --platform linux/arm64 \
  ${DOCKER_USERNAME}/multiarch-backend:latest \
  python -c "import platform; print(platform.machine())"
```

⚠️ **Attention** : L'émulation est beaucoup plus lente que l'exécution native.

### Étape 8 : Inspecter les images

```bash
# Voir les détails des manifests
docker buildx imagetools inspect ${DOCKER_USERNAME}/multiarch-backend:latest

# Comparer les tailles d'images
# Noter les différences de taille entre AMD64 et ARM64
```

**Questions d'analyse** :
1. Quelle architecture a l'image la plus grande ? Pourquoi ?
2. Combien de layers ont été créés pour chaque architecture ?
3. Y a-t-il des layers partagés entre les architectures ?

## Commandes de référence

### Gestion des builders

```bash
# Créer un nouveau builder
docker buildx create --name mybuilder --driver docker-container

# Utiliser un builder
docker buildx use mybuilder

# Lister les builders
docker buildx ls

# Inspecter un builder
docker buildx inspect mybuilder

# Supprimer un builder
docker buildx rm mybuilder
```

### Build multi-architecture

```bash
# Build simple multi-arch avec push
docker buildx build --platform linux/amd64,linux/arm64 -t user/app:tag --push .

# Build avec cache
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --cache-from type=registry,ref=user/app:cache \
  --cache-to type=registry,ref=user/app:cache \
  -t user/app:tag \
  --push .

# Build une seule architecture et charger en local
docker buildx build --platform linux/amd64 -t app:latest --load .
```

### Inspection des images

```bash
# Inspecter un manifest multi-arch
docker buildx imagetools inspect nginx:latest

# Voir les layers d'une architecture spécifique
docker buildx imagetools inspect --raw nginx:latest | jq .

# Créer un nouveau tag à partir d'un manifest existant
docker buildx imagetools create -t user/app:newtag user/app:oldtag
```

## Pour aller plus loin

### 1. GitHub Actions pour le CI/CD multi-arch

Exemple de workflow GitHub Actions :

```yaml
name: Build Multi-Arch

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v2

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: user/app:latest
```

### 2. Registries alternatifs

```bash
# GitHub Container Registry
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/username/app:latest --push .

# AWS ECR (nécessite authentication)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t 123456789.dkr.ecr.us-east-1.amazonaws.com/app:latest --push .

# GitLab Container Registry
docker buildx build --platform linux/amd64,linux/arm64 \
  -t registry.gitlab.com/username/project/app:latest --push .
```

### 3. Architectures supplémentaires

```bash
# Ajouter ARM v7 (Raspberry Pi 3)
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t user/app:latest --push .

# Windows containers (nécessite Windows builders)
docker buildx build \
  --platform windows/amd64 \
  -t user/app:latest --push .
```

## Ressources

- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/)
- [BuildKit Documentation](https://github.com/moby/buildkit)
- [QEMU Documentation](https://www.qemu.org/documentation/)
- [Docker Hub Multi-Arch](https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/)

## Troubleshooting

### Erreur : "multiple platforms feature is currently not supported"

**Solution** : Utilisez `--push` ou `--output type=registry` au lieu de `--load`.

```bash
# ❌ Ne fonctionne pas avec multi-arch
docker buildx build --platform linux/amd64,linux/arm64 -t app --load .

# ✅ Fonctionne
docker buildx build --platform linux/amd64,linux/arm64 -t app --push .
```

### Erreur : "exec user process caused: exec format error"

**Cause** : Vous essayez d'exécuter une image d'une architecture différente sans émulation.

**Solution** :
```bash
# Installer QEMU
docker run --privileged --rm tonistiigi/binfmt --install all
```

### Build très lent

**Causes** :
1. Émulation QEMU (normal pour architectures non-natives)
2. Pas de cache configuré

**Solutions** :
```bash
# Utiliser le cache registry
docker buildx build \
  --cache-from type=registry,ref=user/app:cache \
  --cache-to type=registry,ref=user/app:cache \
  --platform linux/amd64,linux/arm64 \
  -t user/app:latest --push .

# Ou builder chaque architecture séparément sur des machines natives
```

### Permission denied lors du push

**Solution** :
```bash
# Se connecter au registry
docker login

# Ou avec un token
echo $DOCKER_TOKEN | docker login -u username --password-stdin
```

## Conclusion

Docker Buildx permet de créer facilement des images multi-architecture, rendant vos applications portables sur différents types de matériel. Bien que le build soit plus long, les bénéfices en termes de compatibilité et de flexibilité de déploiement sont considérables.

**Points clés à retenir** :
- ✅ Utilisez `--platform` pour spécifier les architectures cibles
- ✅ Les images multi-arch nécessitent `--push` (pas de `--load`)
- ✅ Docker utilise QEMU pour émuler les architectures non-natives
- ✅ Les manifest lists permettent à Docker de choisir automatiquement la bonne architecture
- ✅ Les images de base doivent supporter le multi-architecture
