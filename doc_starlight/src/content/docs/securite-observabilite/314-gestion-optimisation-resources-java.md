---
title: "314 Gestion Optimisation Resources Java"
description: "Guide 314 Gestion Optimisation Resources Java"
sidebar:
  order: 314
---

# 314 - Gestion et Optimisation des Ressources Java dans Docker


## 1. Quleques concepts

### Shared Memory (SHM)

La **shared memory** (`/dev/shm`) permet la communication rapide entre processus dans un conteneur.

**Applications concernées :**
- **PostgreSQL** : cache, sorts, hash joins
- **Redis** : structures de données partagées
- **Chrome/Selenium** : communication inter-processus
- **ML frameworks** (PyTorch, TensorFlow) : partage de tenseurs

**⚠️ Important :** `shm_size` est **inclus** dans la limite totale de mémoire du conteneur.

### Anatomie de la Mémoire d'un Conteneur Java

```
┌─────────────────────────────────────────┐
│  Container Memory Limit (ex: 2G)       │
│  ┌───────────────────────────────────┐ │
│  │  JVM Memory                       │ │
│  │  ┌─────────────────────────────┐  │ │
│  │  │  Heap (-Xmx)                │  │ │
│  │  │  - Young Generation         │  │ │
│  │  │  - Old Generation           │  │ │
│  │  └─────────────────────────────┘  │ │
│  │  ┌─────────────────────────────┐  │ │
│  │  │  Non-Heap                   │  │ │
│  │  │  - Metaspace                │  │ │
│  │  │  - Code Cache               │  │ │
│  │  └─────────────────────────────┘  │ │
│  │  ┌─────────────────────────────┐  │ │
│  │  │  Native Memory              │  │ │
│  │  │  - Thread Stacks            │  │ │
│  │  │  - Direct Buffers           │  │ │
│  │  └─────────────────────────────┘  │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Formule de calcul :**
```
Container Memory = Heap + Metaspace + CodeCache +
                   ThreadStacks + DirectBuffers + OSOverhead
```

**Règle de base :**
```
-Xmx (max heap) ≈ 50-75% du Container Memory Limit
```

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

---

## 3. Optimisation Java pour Docker

### 3.1 Dockerfile Optimisé

```dockerfile
FROM eclipse-temurin:17-jre-alpine

# Utilisateur non-root
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -s /bin/sh -D appuser

WORKDIR /app
COPY --chown=appuser:appgroup target/myapp.jar /app/app.jar

USER appuser

# Variables JVM
ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:InitialRAMPercentage=50.0 \
               -XX:+UseG1GC \
               -XX:MaxGCPauseMillis=200 \
               -XX:+HeapDumpOnOutOfMemoryError \
               -XX:HeapDumpPath=/app/heapdump.hprof \
               -XX:+ExitOnOutOfMemoryError"

EXPOSE 8080

ENTRYPOINT exec java $JAVA_OPTS -jar /app/app.jar
```

### 3.2 Paramètres JVM Essentiels

#### Options pour Docker (CRITIQUES)

```bash
# Détecter les limites du conteneur
-XX:+UseContainerSupport

# Définir le heap comme % de la RAM du conteneur
-XX:MaxRAMPercentage=75.0       # Heap maximum
-XX:InitialRAMPercentage=50.0   # Heap initial
-XX:MinRAMPercentage=50.0       # Heap minimum
```

**⚠️ NE PAS utiliser `-Xmx`/`-Xms` avec les options `RAMPercentage`** car c'est incompatible

#### Garbage Collectors

```bash
# Petits conteneurs (<512M)
-XX:+UseSerialGC

# Conteneurs moyens (512M-4G) - RECOMMANDÉ
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:G1HeapRegionSize=4m

# Gros conteneurs (>4G) - Java 15+
-XX:+UseZGC
```

#### Métadonnées et Code Cache

```bash
# Limiter Metaspace (classes chargées)
-XX:MaxMetaspaceSize=256m

# Limiter Code Cache (code JIT compilé)
-XX:ReservedCodeCacheSize=128m
```

#### Thread Stacks

```bash
-Xss256k    # Micro-services simples
-Xss512k    # Recommandé (défaut)
-Xss1m      # Applications standards
```

**Calcul :** `Nombre de threads × Stack size`
- Exemple : 200 threads × 1M = 200MB

#### Optimisations Diverses

```bash
# Heap dump en cas d'OOM (debug)
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/app/dumps/heapdump.hprof
```

Deux exemples de profils applicatifs

### Une API Standard (2 GB)

```yaml
services:
  api:
    image: myapp:latest
    deploy:
      resources:
        limits:
          memory: 2G
    environment:
      JAVA_OPTS: >-
        -XX:+UseContainerSupport
        -XX:MaxRAMPercentage=75.0
        -XX:InitialRAMPercentage=50.0
        -Xss512k
        -XX:MaxMetaspaceSize=256m
        -XX:ReservedCodeCacheSize=128m
        -XX:+UseG1GC
        -XX:MaxGCPauseMillis=200
        -XX:+UseStringDeduplication
        -XX:+HeapDumpOnOutOfMemoryError
        -XX:HeapDumpPath=/app/dumps/heapdump.hprof

      SERVER_TOMCAT_THREADS_MAX: 100
      SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE: 10
```

**Calcul :**
- Heap max: 2G × 75% = 1.5G
- Metaspace: 256M
- CodeCache: 128M
- Thread stacks (100 threads × 512k): ~50M

### Une Application Lourde (4+ GB)

```yaml
services:
  heavy-app:
    image: myapp:latest
    deploy:
      resources:
        limits:
          memory: 8G
    environment:
      JAVA_OPTS: >-
        -XX:+UseContainerSupport
        -XX:MaxRAMPercentage=75.0
        -XX:InitialRAMPercentage=60.0
        -Xss1m
        -XX:MaxMetaspaceSize=512m
        -XX:ReservedCodeCacheSize=256m
        -XX:+UseG1GC
        -XX:MaxGCPauseMillis=100
        -XX:ParallelGCThreads=4
        -XX:ConcGCThreads=2
        -XX:+UseStringDeduplication

      SERVER_TOMCAT_THREADS_MAX: 200
      SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE: 20
```

---

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



### Problèmes Courants

#### OutOfMemoryError malgré limite correcte

**Diagnostic :**
```bash
docker logs <container> | grep OutOfMemory
docker exec <container> jcmd 1 GC.heap_dump /app/dumps/dump.hprof
```

**Solution :**
```yaml
environment:
  JAVA_OPTS: "-XX:MaxRAMPercentage=65.0"  # Réduire de 75% à 65%
```

#### Metaspace OutOfMemoryError

```bash
# Erreur
java.lang.OutOfMemoryError: Metaspace
```

**Solution :**
```yaml
environment:
  JAVA_OPTS: "-XX:MaxMetaspaceSize=512m"  # Augmenter
```

#### "No space left on device" pour SHM

**Diagnostic :**
```bash
docker exec <container> df -h /dev/shm
```

**Solution :**
```yaml
services:
  app:
    shm_size: '1g'  # Augmenter
```



## Points Clés à Retenir

### Recommandations par Taille

| Taille Conteneur | MaxRAMPercentage | GC | Metaspace | CodeCache | Stack Size |
|------------------|------------------|-----|-----------|-----------|------------|
| 512M (micro) | 65% | SerialGC | 96m | 32m | 256k |
| 2G (standard) | 75% | G1GC | 256m | 128m | 512k |
| 4G+ (lourd) | 75% | G1GC | 512m | 256m | 1m |

1. **Toujours** utiliser `-XX:+UseContainerSupport` pour les applications Java dans Docker
2. **Privilégier** `MaxRAMPercentage` plutôt que `-Xmx`/`-Xms`
3. **Règle 75/25** : 75% de RAM pour heap, 25% pour non-heap + overhead
4. **G1GC** est le meilleur choix pour la plupart des applications (512M-4G)
5. **Réduire** le stack size (`-Xss512k`) pour économiser la RAM
6. **Désactiver** JMX si non utilisé (`SPRING_JMX_ENABLED=false`)
7. **Monitorer** avec heap dumps et métriques Prometheus
8. **Tester** les limites en conditions réelles avant production

## Ressources

- [JVM Options Reference](https://docs.oracle.com/en/java/javase/17/docs/specs/man/java.html)
- [Spring Boot Docker Guide](https://spring.io/guides/topicals/spring-boot-docker/)
- [Docker Resource Constraints](https://docs.docker.com/config/containers/resource_constraints/)
