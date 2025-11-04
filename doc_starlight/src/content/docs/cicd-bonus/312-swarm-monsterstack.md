---
title: "TP - Déployer MonsterStack dans Docker Swarm"
description: "Guide TP - Déployer MonsterStack dans Docker Swarm"
sidebar:
  order: 312
draft: false
---


## Objectifs du TP

Dans ce TP, vous allez déployer l'application **MonsterStack** dans un cluster Docker Swarm en exploitant les fonctionnalités avancées d'orchestration :

- Configuration de services répliqués avec stratégie de déploiement
- Limites et réservations de ressources (CPU/RAM)
- Healthchecks et auto-réparation
- Rolling updates zero-downtime
- Gestion des secrets avec Docker Secrets
- Réseaux overlay pour la communication inter-services
- Placement constraints pour contrôler où tournent les conteneurs
- Mise à jour progressive avec rollback automatique

## Prérequis

- Un cluster Docker Swarm fonctionnel (voir TP 310_swarm_install)
- L'application MonsterStack (disponible dans ce dossier)
- Accès au manager Swarm

## Architecture de l'application

**MonsterStack** est une application web composée de trois services :

- **Frontend** : Application Flask (Python) qui affiche une interface web et génère des avatars de monstres
- **ImageBackend** : Service qui génère les images de monstres (dnmonster)
- **Redis** : Cache pour stocker les images générées

```
┌─────────────────┐
│   Frontend      │ :5000 (Python Flask)
│  (3 replicas)   │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐  ┌────────┐
│ Redis  │  │ImageBck│ :8080 (dnmonster)
│(1 rep) │  │(2 rep) │
└────────┘  └────────┘
```

## Étape 1 : Explorer le code de base

Le dossier contient :
- `app/` : Code source de l'application Flask
- `Dockerfile` : Pour builder l'image du frontend
- `docker-compose.yml` : Version simple pour développement local
- `docker-compose.swarm.yml` : Version optimisée pour Swarm (à créer)

### Tester en local avec Docker Compose

Avant de déployer dans Swarm, testons l'application localement :

```bash
cd 312_swarm_monsterstack
docker compose up -d
```

Visitez `http://localhost:5000` et testez l'application. Tapez votre nom pour générer un avatar de monstre !

```bash
docker compose down
```

## Étape 2 : Créer le fichier docker-compose.swarm.yml

Nous allons créer un fichier Docker Compose optimisé pour Swarm avec toutes les fonctionnalités avancées.

Créez le fichier `docker-compose.swarm.yml` :

```yaml
version: '3.8'

services:
  frontend:
    image: ${DOCKER_REGISTRY:-docker.io}/${DOCKER_USER:-myuser}/monsterstack-frontend:${TAG:-latest}
    ports:
      - "5000:5000"
    environment:
      - CONTEXT=PROD
      - REDIS_DOMAIN=redis
      - IMAGEBACKEND_DOMAIN=imagebackend
    networks:
      - monster_network
    deploy:
      replicas: 3
      update_config:
        parallelism: 1        # Met à jour 1 conteneur à la fois
        delay: 10s            # Attend 10s entre chaque mise à jour
        order: start-first    # Démarre les nouveaux avant d'arrêter les anciens (zero-downtime)
        failure_action: rollback  # Rollback automatique en cas d'échec
        monitor: 30s          # Surveille pendant 30s après chaque mise à jour
      rollback_config:
        parallelism: 2
        delay: 5s
        order: stop-first
        monitor: 20s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      resources:
        limits:
          cpus: '0.5'         # Maximum 50% d'un CPU
          memory: 256M
        reservations:
          cpus: '0.25'        # Réserve au minimum 25% d'un CPU
          memory: 128M
      placement:
        constraints:
          - node.role == worker  # Déploie uniquement sur les workers
        preferences:
          - spread: node.labels.zone  # Répartit entre les zones si définies
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.monsterstack.rule=Host(`monsterstack.local`)"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  imagebackend:
    image: amouat/dnmonster:1.0
    networks:
      - monster_network
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
        failure_action: rollback
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          cpus: '0.3'
          memory: 128M
        reservations:
          cpus: '0.1'
          memory: 64M
      placement:
        constraints:
          - node.role == worker
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 20s

  redis:
    image: redis:7-alpine
    networks:
      - monster_network
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          cpus: '0.3'
          memory: 256M
        reservations:
          cpus: '0.1'
          memory: 128M
      placement:
        constraints:
          - node.role == manager  # Redis sur le manager pour la persistance
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes  # Persistence activée

networks:
  monster_network:
    driver: overlay
    attachable: true
    driver_opts:
      encrypted: "true"  # Chiffrement du trafic entre nœuds

volumes:
  redis_data:
    driver: local
```

### Points importants de cette configuration Swarm

**1. Deploy section (spécifique à Swarm)** :
- `replicas` : Nombre de conteneurs à lancer
- `update_config` : Stratégie de mise à jour progressive
- `rollback_config` : Stratégie de rollback automatique
- `restart_policy` : Politique de redémarrage des conteneurs
- `resources` : Limites et réservations CPU/RAM
- `placement` : Contraintes de placement sur les nœuds

**2. Resources** :
- `limits` : Valeurs maximales (hard limit)
- `reservations` : Ressources garanties réservées par le scheduler

**3. Update strategies** :
- `order: start-first` : Zero-downtime (démarre avant d'arrêter)
- `order: stop-first` : Libère les ressources avant (économie)
- `failure_action: rollback` : Retour automatique à la version précédente

**4. Healthchecks** :
- Vérifie la santé du conteneur
- Si échec après X retries → redémarrage automatique
- Intégré au rolling update pour valider avant de continuer

**5. Placement constraints** :
- `node.role == worker` : Uniquement sur les workers
- `node.role == manager` : Uniquement sur les managers (ex: Redis pour persistance)
- `node.labels.zone == eu-west-1` : Selon des labels personnalisés

## Étape 3 : Builder et pousser l'image du frontend

Le frontend nécessite de builder une image personnalisée.

### 3.1 Builder l'image

```bash
docker build -t monsterstack-frontend:1.0 .
```

### 3.2 Pousser sur un registry

Pour que tous les nœuds Swarm puissent accéder à l'image :

**Option A : Docker Hub (public/privé)**

```bash
# Se connecter
docker login docker.io

# Tagger l'image
docker tag monsterstack-frontend:1.0 docker.io/<votre_user>/monsterstack-frontend:1.0

# Pousser
docker push docker.io/<votre_user>/monsterstack-frontend:1.0
```

**Option B : Registry local (pour tests)**

```bash
# Lancer un registry local sur le manager
docker service create --name registry --publish 5000:5000 registry:2

# Tagger et pousser
docker tag monsterstack-frontend:1.0 localhost:5000/monsterstack-frontend:1.0
docker push localhost:5000/monsterstack-frontend:1.0

# Modifier docker-compose.swarm.yml pour utiliser localhost:5000
```

**Option C : GitLab Registry (recommandé en CI/CD)**

Voir TP 324_mise_en_oeuvre_ci_gitlab pour l'intégration CI/CD complète.

## Étape 4 : Déployer le stack dans Swarm

### 4.1 Déployer avec docker stack deploy

```bash
# Exporter les variables d'environnement si nécessaire
export DOCKER_USER=votre_user
export TAG=1.0

# Déployer le stack
docker stack deploy -c docker-compose.swarm.yml monsterstack
```

La commande `docker stack deploy` :
- Crée ou met à jour tous les services définis
- Crée automatiquement le réseau overlay
- Applique les configurations de réplication et placement

### 4.2 Vérifier le déploiement

```bash
# Lister les stacks
docker stack ls

# Lister les services du stack
docker stack services monsterstack

# Détails d'un service
docker service ps monsterstack_frontend

# Logs d'un service
docker service logs monsterstack_frontend

# Voir où tournent les conteneurs
docker service ps monsterstack_frontend --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"
```

Attendez que tous les services soient à `X/X replicas` (peut prendre 1-2 minutes).

### 4.3 Tester l'application

Trouvez l'IP d'un nœud Swarm et visitez `http://<IP_NODE>:5000`

Grâce au **routing mesh**, le port 5000 est accessible depuis **n'importe quel nœud** du cluster, même si le conteneur tourne ailleurs !

```bash
# Test en ligne de commande
curl http://<IP_NODE>:5000

# Générer un monstre
curl -X POST -d "name=Docker" http://<IP_NODE>:5000/
```

## Étape 5 : Tester le scaling dynamique

Swarm permet de scaler les services à chaud sans interruption.

```bash
# Scaler le frontend à 6 replicas
docker service scale monsterstack_frontend=6

# Observer le scaling en temps réel
watch docker service ps monsterstack_frontend

# Vérifier la charge sur les nœuds
docker node ls
docker node ps <NODE_ID>

# Retour à 3 replicas
docker service scale monsterstack_frontend=3
```

**Questions** :
- Combien de temps prend le scaling ?
- L'application reste-t-elle disponible pendant le scaling ?
- Comment les conteneurs sont-ils répartis sur les nœuds ?

## Étape 6 : Tester le rolling update

Simulons une mise à jour de l'application avec zero-downtime.

### 6.1 Préparer une nouvelle version

Modifiez légèrement l'application (par exemple dans `app/monster_icon.py`, changez le titre de la page) et rebuildez :

```bash
# Modifier le code
sed -i 's/<title>MonsterStack<\/title>/<title>MonsterStack v2<\/title>/' app/templates/index.html

# Rebuilder
docker build -t <votre_registry>/monsterstack-frontend:2.0 .
docker push <votre_registry>/monsterstack-frontend:2.0
```

### 6.2 Mettre à jour le service

```bash
# Mise à jour progressive
docker service update --image <votre_registry>/monsterstack-frontend:2.0 monsterstack_frontend

# Observer le rolling update
watch docker service ps monsterstack_frontend
```

Observez :
- Les conteneurs sont mis à jour **1 par 1** (parallelism: 1)
- Swarm attend **10 secondes** entre chaque (delay: 10s)
- Les nouveaux conteneurs démarrent **avant** l'arrêt des anciens (order: start-first)
- Le healthcheck valide chaque conteneur avant de continuer

**Pendant la mise à jour** :
```bash
# L'application reste accessible
while true; do curl -s http://<IP_NODE>:5000 | grep title; sleep 1; done
```

Vous devriez voir une transition progressive de v1 à v2 sans interruption !

### 6.3 Simuler un échec et rollback automatique

Mettons à jour avec une image cassée :

```bash
# Image qui n'existe pas ou qui crash au démarrage
docker service update --image <votre_registry>/monsterstack-frontend:broken monsterstack_frontend
```

Observez :
- Swarm détecte l'échec via le healthcheck
- Après plusieurs échecs, il déclenche le **rollback automatique**
- Le service revient à la version précédente (v2.0)

```bash
# Vérifier l'historique des mises à jour
docker service inspect monsterstack_frontend --pretty
```

## Étape 7 : Utiliser Docker Secrets (bonus)

Les secrets permettent de gérer de façon sécurisée les mots de passe et clés.

### 7.1 Créer un secret

```bash
# Créer un secret pour Redis (par exemple un mot de passe)
echo "SuperSecretPassword123" | docker secret create redis_password -

# Lister les secrets
docker secret ls

# Inspecter (le contenu reste chiffré)
docker secret inspect redis_password
```

### 7.2 Utiliser le secret dans docker-compose.swarm.yml

Modifiez le fichier pour utiliser le secret :

```yaml
services:
  redis:
    image: redis:7-alpine
    secrets:
      - redis_password
    command: >
      sh -c "redis-server --requirepass $$(cat /run/secrets/redis_password) --appendonly yes"
    # ... reste de la config

  frontend:
    # ...
    secrets:
      - redis_password
    environment:
      - REDIS_PASSWORD_FILE=/run/secrets/redis_password
    # ...

secrets:
  redis_password:
    external: true  # Le secret existe déjà
```

Les secrets sont :
- Montés dans `/run/secrets/<secret_name>`
- Chiffrés en transit et au repos
- Accessibles uniquement aux services autorisés
- Jamais exposés dans les logs ou `docker inspect`

### 7.3 Redéployer avec les secrets

```bash
docker stack deploy -c docker-compose.swarm.yml monsterstack
```

Le code applicatif doit être modifié pour lire le mot de passe depuis `/run/secrets/redis_password` au lieu d'une variable d'environnement classique.

## Étape 8 : Monitoring et observabilité

### 8.1 Surveiller les ressources

```bash
# Stats en temps réel d'un service
docker stats $(docker ps -q -f name=monsterstack_frontend)

# Voir les événements du service
docker service logs --tail 50 -f monsterstack_frontend

# Voir les détails d'un conteneur spécifique
docker inspect <CONTAINER_ID>
```

### 8.2 Visualiser avec Visualizer (optionnel)

Déployer un outil de visualisation du cluster :

```bash
docker service create \
  --name=viz \
  --publish=8080:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  dockersamples/visualizer
```

Visitez `http://<IP_MANAGER>:8080` pour voir une carte du cluster en temps réel.

### 8.3 Utiliser Portainer (recommandé)

Portainer offre une interface web complète pour gérer Swarm.

```bash
curl -L https://downloads.portainer.io/ce2-19/portainer-agent-stack.yml -o portainer-agent-stack.yml

docker stack deploy -c portainer-agent-stack.yml portainer
```

Visitez `http://<IP_MANAGER>:9000` et créez un compte admin.

## Étape 9 : Nettoyage

```bash
# Supprimer le stack complet
docker stack rm monsterstack

# Vérifier que tout est supprimé
docker stack ls
docker service ls

# Supprimer le réseau (optionnel, fait automatiquement)
docker network rm monsterstack_monster_network

# Supprimer les secrets
docker secret rm redis_password
```

## Questions de réflexion

### 1. Limites de ressources
- Que se passe-t-il si un conteneur dépasse sa limite de mémoire ?
  - **Réponse** : Il est tué par l'OOM Killer et redémarré selon la restart_policy
- Pourquoi séparer `limits` et `reservations` ?
  - **Réponse** : Les réservations garantissent les ressources minimales, les limites empêchent la surconsommation

### 2. Placement
- Pourquoi placer Redis sur le manager ?
  - **Réponse** : Pour garantir la persistance (le volume reste sur le même nœud)
- Comment répartir équitablement la charge ?
  - **Réponse** : Utiliser `preferences: spread` sur des labels de nœuds

### 3. Stratégie de mise à jour
- Quand utiliser `order: start-first` vs `order: stop-first` ?
  - **start-first** : Applications stateless, zero-downtime (besoin de plus de ressources temporairement)
  - **stop-first** : Ressources limitées, applications stateful (évite les conflits)
- Comment tester une mise à jour sur un seul conteneur d'abord ?
  - **Réponse** : Mettre `parallelism: 1` et `delay` élevé, tester, puis continuer ou rollback

### 4. Haute disponibilité
- Que se passe-t-il si un worker tombe ?
  - **Réponse** : Les conteneurs sont automatiquement relancés sur d'autres nœuds (self-healing)
- Comment gérer la perte du manager ?
  - **Réponse** : Utiliser plusieurs managers (quorum 3 ou 5) avec Raft consensus

### 5. Comparaison avec Kubernetes
- Différences principales ?
  - **Swarm** : Simple, intégré à Docker, suffisant pour PME
  - **Kubernetes** : Plus complexe, écosystème riche, standard pour grandes infras
- Quand choisir Swarm vs Kubernetes ?
  - **Swarm** : Équipe petite, infrastructure simple, besoin de rapidité
  - **Kubernetes** : Équipe expérimentée, multi-cloud, écosystème mature

## Améliorations possibles

### 1. Ajouter un reverse proxy (Traefik)

Traefik s'intègre nativement avec Swarm pour le routing HTTP.

```bash
docker network create --driver=overlay traefik-public

docker service create \
  --name traefik \
  --constraint=node.role==manager \
  --publish 80:80 \
  --publish 8080:8080 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  --network traefik-public \
  traefik:v2.10 \
  --api.insecure=true \
  --providers.docker=true \
  --providers.docker.swarmMode=true \
  --providers.docker.exposedbydefault=false \
  --entrypoints.web.address=:80
```

Ajoutez ensuite des labels au service frontend (déjà présents dans le docker-compose.swarm.yml).

### 2. Ajouter de la persistance avec volumes nommés

Pour les données critiques, utiliser des volumes avec drivers spécifiques (NFS, GlusterFS, etc.).

### 3. Monitoring avec Prometheus + Grafana

Stack complète pour monitorer les métriques Swarm.

### 4. CI/CD avec GitLab

Voir TP 325_deploiement_swarm_gitlab pour automatiser le déploiement.


## Références

- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Docker Stack Deploy](https://docs.docker.com/engine/reference/commandline/stack_deploy/)
- [Docker Compose file v3 (Swarm)](https://docs.docker.com/compose/compose-file/compose-file-v3/)
- [Docker Service Update](https://docs.docker.com/engine/reference/commandline/service_update/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [Best practices for Swarm](https://docs.docker.com/engine/swarm/admin_guide/)
