---
title: "Gestion des resources avec Docker ou un cluster Swarm mode"
description: "Guide Gestion des resources avec Docker ou un cluster Swarm mode"
sidebar:
  order: 313
---


## Gestion des Ressources

### Docker Run (ligne de commande)

Avant tout, comprenons comment limiter les ressources avec `docker run` :

```bash
docker run -d \
  --memory="2g" \           # Limite mémoire
  --memory-reservation="1g" \  # Mémoire garantie
  --cpus="2.0" \            # Limite CPU
  --shm-size="256m" \       # Shared memory
  myapp:latest
```

**Concepts clés :**
- `--memory` : limite maximale (hard limit)
- `--memory-reservation` : mémoire réservée (soft limit)
- `--cpus` : nombre de CPUs allouées
- `--shm-size` : taille de `/dev/shm` (mémoire partagée)


### 2. Docker Compose (mode standalone, sans Swarm)

En mode **standalone** (docker-compose up), la syntaxe est différente :

```yaml
version: '3.8'

services:
  myapp:
    image: myapp:latest
    mem_limit: 2g           # Syntaxe standalone
    mem_reservation: 1g
    cpus: 2.0
    shm_size: '256m'
```

Le bloc `deploy` ne fonctionne pas en standalone


### Docker Swarm Mode

Quand vous déployez avec `docker stack deploy`, **seule la section `deploy`** est prise en compte :

```yaml
version: '3.8'

services:
  myapp:
    image: myapp:latest
    
    # Ignoré en mode Swarm
    mem_limit: 2g
    cpus: 2.0
    
    # Syntaxe Swarm
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
    
    # shm_size fonctionne en Swarm (mais au niveau racine du service pas dans le deploy)
    shm_size: '256m'
```

### Spécificités Swarm

#### Comportement du Scheduler Swarm

Si reservations = 2 CPU et 4G RAM :
- Le nœud DOIT avoir 2 CPU et 4G libres pour accepter le conteneur
- Sinon, le conteneur reste en "Pending"

Si limits = 4 CPU et 8G RAM :
- Le conteneur peut utiliser jusqu'à ces limites si disponibles
- Mais sera limité (throttling CPU) s'il dépasse en CPU
- Et tué OOM Killed s'il dépasse en RAM


#### La Règle 50/50 : un bonne Pratique simple

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 8G
    reservations:
      cpus: '2'        # 50% des limits
      memory: 4G       # 50% des limits
```

**Pourquoi ?**
- `reservations` : ressources **garanties** par le scheduler
- `limits` : ressources **maximales** autorisées
- Ratio 50/50 permet un bon équilibre entre garanties et élasticité

Mais pour fixer les seuil il faut monitorer correctement notre application dans un premier temps (et sur le meme type de processeur) pour voir sa consommation réelle.

#### Ressources d'un Nœud

```
Nœud Worker (exemple) :
├─ CPU Total      : 8 cores
├─ RAM Total      : 32 GB
├─ CPU Allocable  : ~7.5 cores  (OS utilise ~0.5)
└─ RAM Allocable  : ~30 GB      (OS + Docker utilisent ~2GB)
```

**Règle :** Toujours garder une marge pour l'OS et Docker daemon (~5-10% des ressources).

### Calcul de Capacité Cluster

#### Exemple de Cluster

```yaml
Cluster Configuration:
├─ Manager Node 1: 4 CPU, 16GB RAM  (pas utilisé pour workload)
├─ Worker Node 1:  8 CPU, 32GB RAM
├─ Worker Node 2:  8 CPU, 32GB RAM
└─ Worker Node 3:  4 CPU, 16GB RAM

Capacité totale (workers uniquement):
├─ CPU:  20 cores
└─ RAM:  80 GB
```

** Important :** Les managers ne devraient pas exécuter de workload en production car cela peut perturber leur fonctionnement en cas de manque de ressources


### Stratégies d'Allocation

#### Stratégie conservative (Production)

**Règle :** N'utiliser que **60-70% des ressources** pour les `limits`.

```
Capacité cluster : 20 CPU, 80GB RAM

Allocations maximales recommandées :
├─ CPU limits  : 12-14 cores (60-70%)
└─ RAM limits  : 48-56 GB (60-70%)
```

**Pourquoi ?**
- Permet les pics de charge (utilisation jusqu'aux `limits`)
- Garde de la marge pour les nouveaux déploiements
- Évite la surcharge lors d'une panne de nœud

#### Sur-allocation (Overbooking)

**Scénario acceptable :**
```yaml
# Cluster: 20 CPU, 80GB RAM

services:
  api:
    deploy:
      replicas: 10
      resources:
        reservations:
          cpus: '1'      # 10 CPU réservés
          memory: 4G     # 40GB réservés
        limits:
          cpus: '2'      # 20 CPU potentiels (100% du cluster!)
          memory: 8G     # 80GB potentiels (100% du cluster!)
```

**Analyse :**
```
Réservations : 10 CPU, 40GB  ✅ OK (50% cluster)
Limits totaux: 20 CPU, 80GB  ⚠️ Impossible si tous au max en même temps

Mais c'est acceptable si:
- Tous les réplicas n'atteignent jamais leur max simultanément
- Charge moyenne < 50% par conteneur
```


### Haute Disponibilité et Tolérance aux Pannes

#### Règle N-1

**Principe :** Le cluster doit pouvoir absorber la perte d'un nœud.

```
Cluster: 3 nœuds × 8 CPU, 32GB

Capacité avec N-1:
- En fonctionnement normal: 24 CPU, 96GB
- Si 1 nœud tombe:         16 CPU, 64GB

Allocation maximale sûre:
├─ Reservations: 60% de (N-1) = 9.6 CPU, 38GB
└─ Limits:       80% de (N-1) = 12.8 CPU, 51GB
```

#### Exemple avec Contraintes de Placement

```yaml
services:
  critical_app:
    deploy:
      replicas: 3
      resources:
        reservations:
          cpus: '2'
          memory: 8G
        limits:
          cpus: '4'
          memory: 16G
      placement:
        max_replicas_per_node: 1  # 1 réplica max par nœud
        constraints:
          - node.role == worker
```

**Garantie :**
- Si 1 nœud tombe, les 2 autres réplicas continuent
- Service toujours disponible (2/3 réplicas actifs)


### Monitoring et Ajustement

#### Métriques à Surveiller

```bash
# Voir l'utilisation réelle des ressources
docker stats --no-stream

# Voir les tâches en attente (pending)
docker service ps <service> --filter desired-state=running

# Voir la capacité des nœuds
docker node ls
docker node inspect <node_id> --format '{{json .Description.Resources}}'
```

#### Indicateurs de Problème

| Symptôme | Cause Probable | Solution |
|----------|---------------|----------|
| Réplicas en "Pending" | Pas assez de ressources | ↓ Reservations ou ↑ Nœuds |
| CPU Throttling fréquent | Limits trop bas | ↑ CPU limits |
| OOM Kill répétés | Memory limits trop bas | ↑ Memory limits |
| Nœuds > 80% utilisés | Sur-allocation | Rééquilibrer ou ajouter nœuds |

### Résumé

1. **Règle 60/70** : Réserver max 60-70% des ressources du cluster
2. **Règle 50/50** : Reservations = 50% des limits (sauf cas spéciaux)
3. **Règle N-1** : Pouvoir perdre 1 nœud sans impact
4. **Monitoring** : Surveiller l'utilisation réelle pour ajuster
5. **Overbooking modéré** : OK si limits totaux < 150% des ressources
6. **DB et services critiques** : reservations = limits (pas de burst)
7. **Marge de sécurité** : Garder 20-30% de ressources libres




Le secret d'un cluster sain :

```
Reservations < 60% capacité cluster
Limits raisonnables (overbooking limité à ~150%)
Toujours pouvoir perdre 1 nœud (N-1)
Monitoring régulier de l'utilisation réelle
```

### Shared Memory (shm_size) : Pourquoi c'est important ?

`/dev/shm` est une zone de mémoire partagée utilisée par :
- **PostgreSQL** : pour les communications inter-processus
- **Chrome/Selenium** : pour le rendu graphique
- **Applications Java** : pour certaines librairies natives

**Par défaut : 64MB** (souvent insuffisant !)

#### Exemples pratiques

```yaml
# PostgreSQL en Swarm
services:
  postgres:
    image: postgres:15
    shm_size: '512m'  # Au niveau racine, pas dans deploy !
    deploy:
      resources:
        limits:
          memory: 4G
    environment:
      POSTGRES_SHARED_BUFFERS: 256MB  # 50% de shm_size
```

```yaml
# Chrome/Selenium en Swarm
services:
  selenium:
    image: selenium/standalone-chrome
    shm_size: '2g'    # Chrome a besoin de beaucoup de SHM
    deploy:
      resources:
        limits:
          memory: 4G
```

### Vérification et Monitoring

```bash
# Voir les ressources allouées à un service Swarm
docker service ps myapp --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"

# Voir les stats en temps réel
docker stats

# Inspecter les limites d'un conteneur
docker inspect <container_id> | grep -A 20 "Memory"

# Vérifier la mémoire partagée
docker exec <container_id> df -h /dev/shm
```

