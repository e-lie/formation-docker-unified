---
title: "Optimiser la gestion des ressources Java dans Docker"
description: "Guide Optimiser la gestion des ressources Java dans Docker"
sidebar:
  order: 314
---


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

Quand une application Java tourne dans un conteneur Docker, la mémoire totale allouée au conteneur (par exemple 2GB) doit être partagée entre différentes zones. Le Heap (configuré avec -Xmx) n'est qu'une partie de cette mémoire totale.
Les trois grandes zones :

Heap : La mémoire où vivent vos objets Java (Young/Old Generation)
Non-Heap : Métadonnées des classes (Metaspace) et code compilé (Code Cache)
Native Memory : Threads de l'OS, buffers directs, et autres allocations système

```
Container Memory = Heap + Metaspace + CodeCache +
                   ThreadStacks + DirectBuffers + OSOverhead
```

La règle de base :

```
-Xmx (max heap) ≈ 50-75% du Container Memory Limit
```

Par exemple, avec un conteneur de 2GB, mettez -Xmx1200m ou -Xmx1500m maximum.
Pourquoi ?

Si vous mettez -Xmx2G dans un conteneur de 2GB, il ne reste plus de place pour les autres zones mémoire. Résultat : votre conteneur sera tué par l'OOM Killer (Out Of Memory) même si le Heap n'est pas plein, car la mémoire totale dépasse la limite du conteneur.

## Optimisation Java pour Docker

### Paramètres JVM Essentiels

#### Options de mémoire automatique pour Docker

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

### Dockerfile Optimisé

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

### Deux exemples de profils applicatifs

#### Une API Standard avec TOMCAT (2 GB RAM)

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

#### Une Application plus importante (4+ GB)

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
