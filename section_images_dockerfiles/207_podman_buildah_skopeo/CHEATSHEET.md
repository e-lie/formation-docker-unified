# Podman/Buildah/Skopeo Cheatsheet

Référence rapide des commandes essentielles pour Podman, Buildah et Skopeo.

## Installation

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y podman buildah skopeo

# Verification
podman --version
buildah --version
skopeo --version
```

## Buildah - Construction d'images

### Build depuis Dockerfile/Containerfile

```bash
# Build basique
buildah build -t monsterstack:latest .

# Build avec Containerfile spécifique
buildah build -f Containerfile -t monsterstack:latest .

# Build avec arguments
buildah build --build-arg VERSION=1.0 -t monsterstack:v1.0 .

# Build multi-platform (expérimental)
buildah build --platform linux/amd64,linux/arm64 -t monsterstack:multi .
```

### Build scripté (natif Buildah)

```bash
# Créer un conteneur de travail
ctr=$(buildah from python:3.10)

# Exécuter des commandes
buildah run $ctr apt-get update
buildah run $ctr pip install flask

# Copier des fichiers
buildah copy $ctr ./app /app

# Configurer l'image
buildah config --workingdir /app $ctr
buildah config --env APP_ENV=production $ctr
buildah config --port 5000 $ctr
buildah config --cmd 'python app.py' $ctr

# Commiter en image
buildah commit $ctr monsterstack:scripted

# Nettoyer
buildah rm $ctr
```

### Gestion Buildah

```bash
# Lister les conteneurs de travail
buildah containers

# Lister les images
buildah images

# Supprimer un conteneur de travail
buildah rm <container-id>

# Supprimer une image
buildah rmi monsterstack:latest

# Nettoyer tout
buildah rm --all
buildah rmi --all

# Inspecter une image
buildah inspect monsterstack:latest
```

## Podman - Runtime de conteneurs

### Gestion de base

```bash
# Lancer un conteneur
podman run -d --name myapp -p 8080:80 nginx:alpine

# Lancer en mode interactif
podman run -it --rm alpine sh

# Lancer avec variables d'environnement
podman run -d -e DB_HOST=localhost -e DB_PORT=5432 myapp

# Lister les conteneurs
podman ps          # Actifs
podman ps -a       # Tous

# Arrêter/démarrer
podman stop myapp
podman start myapp
podman restart myapp

# Supprimer
podman rm myapp
podman rm -f myapp    # Force (même si actif)
```

### Logs et debugging

```bash
# Voir les logs
podman logs myapp
podman logs -f myapp    # Suivre en temps réel
podman logs --tail 50 myapp

# Exécuter une commande dans un conteneur
podman exec myapp ls /app
podman exec -it myapp bash

# Inspecter
podman inspect myapp

# Voir les processus
podman top myapp

# Statistiques
podman stats
podman stats myapp
```

### Images

```bash
# Lister les images
podman images

# Télécharger une image
podman pull nginx:alpine

# Supprimer une image
podman rmi nginx:alpine

# Tagger une image
podman tag monsterstack:latest monsterstack:v1.0

# Sauvegarder/charger
podman save -o myapp.tar monsterstack:latest
podman load -i myapp.tar

# Historique de l'image
podman history monsterstack:latest
```

### Réseaux

```bash
# Lister les réseaux
podman network ls

# Créer un réseau
podman network create mynetwork

# Inspecter un réseau
podman network inspect mynetwork

# Connecter un conteneur
podman network connect mynetwork myapp

# Supprimer un réseau
podman network rm mynetwork
```

### Volumes

```bash
# Lister les volumes
podman volume ls

# Créer un volume
podman volume create mydata

# Inspecter
podman volume inspect mydata

# Utiliser un volume
podman run -v mydata:/data alpine

# Supprimer
podman volume rm mydata
```

### Registry et push/pull

```bash
# Login au registry
podman login docker.io
podman login registry.gitlab.com

# Push
podman push monsterstack:latest docker.io/username/monsterstack:latest

# Pull
podman pull docker.io/username/monsterstack:latest

# Logout
podman logout docker.io
```

## Skopeo - Gestion d'images

### Inspection

```bash
# Inspecter une image distante (sans télécharger)
skopeo inspect docker://nginx:alpine
skopeo inspect docker://registry.gitlab.com/user/app:latest

# Inspecter une image locale
skopeo inspect containers-storage:localhost/monsterstack:latest

# Lister les tags disponibles
skopeo list-tags docker://docker.io/library/nginx
```

### Copie d'images

```bash
# Copier d'un registry à un autre (sans passer par le local)
skopeo copy \
  docker://docker.io/nginx:alpine \
  docker://registry.example.com/nginx:alpine

# Copier du storage local vers un registry
skopeo copy \
  containers-storage:localhost/monsterstack:latest \
  docker://docker.io/username/monsterstack:latest

# Copier avec authentification
skopeo copy \
  --src-creds user:pass \
  --dest-creds user:pass \
  docker://source/image \
  docker://dest/image

# Copier vers une archive
skopeo copy docker://nginx:alpine docker-archive:nginx.tar
skopeo copy docker://nginx:alpine oci-archive:nginx-oci.tar
skopeo copy docker://nginx:alpine dir:nginx-dir
```

### Authentification

```bash
# Login
skopeo login docker.io
skopeo login -u username -p password registry.example.com

# Logout
skopeo logout docker.io

# Credentials sont stockés dans ~/.docker/config.json ou ~/.config/containers/auth.json
```

### Suppression et nettoyage

```bash
# Supprimer une image distante (si permissions)
skopeo delete docker://registry.example.com/myapp:old

# Synchroniser (copier toutes les images d'un repo)
skopeo sync --src docker --dest docker source/repo dest/repo
```

## Podman Compose

```bash
# Installer podman-compose
pip3 install --user podman-compose

# Démarrer les services
podman-compose up -d

# Voir les logs
podman-compose logs -f

# Arrêter
podman-compose down

# Rebuild
podman-compose build

# Executer une commande
podman-compose exec frontend bash
```

## Podman en mode rootless

```bash
# Podman fonctionne sans root par défaut
podman run -d nginx:alpine    # Pas besoin de sudo

# Configuration rootless
podman system migrate           # Migrer vers rootless
podman info | grep rootless     # Vérifier le mode

# Ports < 1024 nécessitent une config spéciale
sudo sysctl net.ipv4.ip_unprivileged_port_start=80
```

## Nettoyage et maintenance

```bash
# Buildah
buildah rm --all
buildah rmi --all

# Podman
podman stop $(podman ps -q)      # Arrêter tous les conteneurs
podman rm $(podman ps -aq)       # Supprimer tous les conteneurs
podman rmi $(podman images -q)   # Supprimer toutes les images

# Nettoyage système complet
podman system prune              # Conteneurs/images non utilisés
podman system prune -a           # Tout
podman system prune -a --volumes # Tout + volumes

# Voir l'utilisation disque
podman system df
```

## Conversion Docker → Podman

```bash
# Alias pour compatibilité
alias docker=podman
alias docker-compose=podman-compose

# Ou utiliser Podman comme socket Docker
systemctl --user start podman.socket
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock

# docker-compose utilise alors Podman via le socket
docker-compose up -d
```

## Génération de manifests Kubernetes

```bash
# Générer un pod YAML depuis un conteneur
podman generate kube myapp > myapp-pod.yaml

# Générer depuis plusieurs conteneurs
podman generate kube container1 container2 > app.yaml

# Appliquer dans Kubernetes
kubectl apply -f myapp-pod.yaml

# Générer depuis podman-compose
podman play kube app.yaml
```

## Tips et astuces

### Créer un alias permanent
```bash
echo "alias docker=podman" >> ~/.bashrc
echo "alias docker-compose=podman-compose" >> ~/.bashrc
source ~/.bashrc
```

### Configurer les registries
```bash
# Éditer ~/.config/containers/registries.conf
[registries.search]
registries = ['docker.io', 'quay.io', 'registry.gitlab.com']

[registries.insecure]
registries = ['localhost:5000']
```

### Build cache
```bash
# Buildah n'a pas de cache par défaut (contrairement à Docker)
# Pour réutiliser des layers, utiliser --layers
buildah build --layers -t myapp .
```

### Debugging
```bash
# Verbose mode
podman --log-level debug run nginx
buildah --log-level debug build -t myapp .

# Voir les événements
podman events

# Info système
podman info
buildah info
```

## Ressources

- [Podman Docs](https://docs.podman.io/)
- [Buildah Tutorials](https://github.com/containers/buildah/tree/main/docs/tutorials)
- [Skopeo Docs](https://github.com/containers/skopeo)
- [Podman Desktop](https://podman-desktop.io/)
