# TP - Déployer MonsterStack dans Docker Swarm

## Contenu du dossier

- `312_swarm_monsterstack.md` : TP complet avec explications détaillées
- `docker-compose.yml` : Version simple pour développement local
- `docker-compose.swarm.yml` : Version optimisée pour Docker Swarm avec fonctionnalités avancées
- `Dockerfile` : Pour builder l'image du frontend
- `app/` : Code source de l'application Flask

## Démarrage rapide

### Test en local

```bash
docker compose up -d
# Visitez http://localhost:5000
docker compose down
```

### Déploiement dans Swarm

```bash
# 1. Builder et pousser l'image
docker build -t <votre_registry>/monsterstack-frontend:1.0 .
docker push <votre_registry>/monsterstack-frontend:1.0

# 2. Configurer les variables
export DOCKER_USER=<votre_user>
export TAG=1.0

# 3. Déployer
docker stack deploy -c docker-compose.swarm.yml monsterstack

# 4. Vérifier
docker stack services monsterstack
```

## Fonctionnalités Swarm démontrées

- ✅ Réplication multi-conteneurs (frontend: 3, imagebackend: 2, redis: 1)
- ✅ Limites et réservations de ressources CPU/RAM
- ✅ Rolling updates avec zero-downtime (order: start-first)
- ✅ Rollback automatique en cas d'échec
- ✅ Healthchecks et auto-réparation
- ✅ Placement constraints (workers vs managers)
- ✅ Réseau overlay chiffré
- ✅ Persistence avec volumes

## Architecture

```
┌─────────────────┐
│   Frontend      │ :5000 (Flask - 3 replicas)
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐  ┌────────┐
│ Redis  │  │ImageBck│ :8080 (2 replicas)
│(1 rep) │  │        │
└────────┘  └────────┘
```

Consultez le fichier `312_swarm_monsterstack.md` pour le TP complet !
