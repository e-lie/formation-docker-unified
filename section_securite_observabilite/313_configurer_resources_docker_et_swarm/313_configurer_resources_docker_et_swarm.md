---
title: Gestion des resources avec Docker ou un cluster Swarm mode
---

## 2. Configuration des Ressources dans Docker

### 2.1 Docker Compose

```yaml
version: '3.8'

services:
  myapp:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G      # Limite totale
        reservations:
          cpus: '1'
          memory: 1G      # Ressources garanties
```

### 2.2 Docker Swarm

**Dans Swarm, seule la section `deploy.resources` est prise en compte.**

```yaml
version: '3.8'

services:
  myapp:
    image: myapp:latest
    deploy:
      replicas: 1
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'        # 50% de limits (bonne pratique)
          memory: 4G
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
```

**Règle 50/50 :** `reservations` = 50% de `limits`


## 5. Configuration Shared Memory

### 5.1 Dimensionnement par Application

| Application | shm_size | Memory Limit | Ratio SHM/Total |
|-------------|----------|--------------|-----------------|
| Java app | 128m | 2-4G | 6% |
| PostgreSQL | 256m-1g | 2-8G | 12-25% |
| Redis | 64m | 512m-2G | 6% |
| Selenium/Chrome | 2g | 4G | 50% |
| GitLab (prod) | 512m-1g | 8-16G | 6% |

### 5.2 Exemple PostgreSQL

```yaml
services:
  postgres:
    image: postgres:15
    shm_size: '512m'
    deploy:
      resources:
        limits:
          memory: 4G
    environment:
      POSTGRES_SHARED_BUFFERS: 256MB  # 50% de shm_size
      POSTGRES_WORK_MEM: 16MB
      POSTGRES_MAX_CONNECTIONS: 100
```

**⚠️ Pour Swarm :** `shm_size` au niveau racine, pas dans `deploy`

```yaml
services:
  postgres:
    image: postgres:15
    shm_size: '512m'  # Ici, pas dans deploy
    deploy:
      resources:
        limits:
          memory: 4G
```