---
title: "TP - Déployer une Stack de Monitoring dans Docker Swarm"
description: "Guide TP - Déployer une Stack de Monitoring dans Docker Swarm"
sidebar:
  order: 315
draft: false
---


## Objectifs du TP

Dans ce TP, vous allez déployer une stack complète de monitoring et observabilité dans votre cluster Docker Swarm :

- **Prometheus** : Collecte et stockage des métriques
- **Grafana** : Visualisation des métriques et création de dashboards
- **Loki** : Agrégation et stockage des logs
- **Promtail** : Agent de collecte des logs sur chaque nœud

Cette stack vous permettra de :
- Surveiller l'état et les performances de votre cluster Swarm
- Visualiser les métriques système et applicatives
- Centraliser et consulter les logs de tous vos conteneurs
- Créer des alertes sur des métriques critiques

## Prérequis

- Un cluster Docker Swarm fonctionnel (voir TP 310_swarm_install)
- L'application MonsterStack déployée (voir TP 312_swarm_monsterstack - optionnel)
- Accès au manager Swarm
- Au moins 4 GB de RAM disponible sur le cluster

## Accès ssh au manager Swarm

**Se connecter à un hôte Docker distant via SSH**

Ajoutez à `~/.bashrc`:

```bash
export DOCKER_HOST="ssh://<votreuser>@<ip-server-1>" # terraform apply pour reoutput les IP
```

## Architecture de la stack de monitoring

```
┌─────────────────────────────────────────────────────────┐
│                     Grafana :3000                       │
│              (Interface de visualisation)               │
└───────────────────┬─────────────────┬───────────────────┘
                    │                 │
                    ▼                 ▼
        ┌─────────────────┐  ┌─────────────────┐
        │  Prometheus      │  │      Loki       │
        │     :9090        │  │     :3100       │
        │  (Métriques)     │  │     (Logs)      │
        └────────┬─────────┘  └────────┬────────┘
                 │                     │
        ┌────────┴────────┐   ┌────────┴────────┐
        │                 │   │                 │
        ▼                 ▼   ▼                 ▼
   ┌─────────┐      ┌─────────┐         ┌─────────┐
   │cAdvisor │      │  Node   │         │Promtail │
   │ :8080   │      │Exporter │         │ (Global)│
   │(Docker) │      │  :9100  │         │         │
   └─────────┘      └─────────┘         └─────────┘
```

### Composants

**Prometheus** :
- Collecte les métriques depuis cAdvisor, Node Exporter et les services
- Stocke les séries temporelles
- Permet d'exécuter des requêtes PromQL

**Grafana** :
- Interface web pour visualiser les données
- Dashboards pré-configurés pour Docker Swarm
- Connexion à Prometheus et Loki

**Loki** :
- Système d'agrégation de logs inspiré de Prometheus
- Stocke et indexe les logs des conteneurs
- Requêtes avec LogQL

**Promtail** :
- Agent de collecte des logs
- Déployé en mode global (1 par nœud)
- Collecte les logs de tous les conteneurs du nœud

**cAdvisor** :
- Collecte les métriques des conteneurs Docker
- Exposition des métriques au format Prometheus

**Node Exporter** :
- Collecte les métriques système (CPU, RAM, disque, réseau)
- Déployé sur chaque nœud

## Étape 1 : Créer les fichiers de configuration

### 1.1 Configuration Prometheus

Créez le fichier `prometheus.yml` :

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'swarm-cluster'
    monitor: 'swarm-monitoring'

# Règles d'alerte (optionnel)
# rule_files:
#   - /etc/prometheus/alerts/*.yml

scrape_configs:
  # Métriques Prometheus lui-même
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Métriques Docker (cAdvisor)
  - job_name: 'cadvisor'
    dns_sd_configs:
      - names:
          - 'tasks.cadvisor'
        type: 'A'
        port: 8080
    relabel_configs:
      - source_labels: [__meta_dns_name]
        target_label: node

  # Métriques système (Node Exporter)
  - job_name: 'node-exporter'
    dns_sd_configs:
      - names:
          - 'tasks.node-exporter'
        type: 'A'
        port: 9100
    relabel_configs:
      - source_labels: [__meta_dns_name]
        target_label: node

  # Métriques Docker Swarm (si disponible)
  - job_name: 'dockerd'
    static_configs:
      - targets: ['host.docker.internal:9323']
    # Note: nécessite d'activer les métriques Docker avec --experimental et --metrics-addr
```

### 1.2 Configuration Promtail

Créez le fichier `promtail-config.yml` :

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'stream'
      - source_labels: ['__meta_docker_swarm_service_name']
        target_label: 'service'
      - source_labels: ['__meta_docker_swarm_stack_namespace']
        target_label: 'stack'
```

### 1.3 Configuration Loki

Créez le fichier `loki-config.yml` :

```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  instance_addr: 127.0.0.1
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  max_cache_freshness_per_query: 10m
  split_queries_by_interval: 15m
  max_query_parallelism: 32

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: true
  retention_period: 168h

compactor:
  working_directory: /loki/compactor
  compaction_interval: 10m
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
```

## Étape 2 : Créer le docker-compose.swarm.yml

Créez le fichier `docker-compose.swarm.yml` :

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=7d'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
    volumes:
      - prometheus-data:/prometheus
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    networks:
      - monitoring
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - monitoring
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
      restart_policy:
        condition: on-failure
    ports:
      - "3000:3000"

  loki:
    image: grafana/loki:latest
    command: -config.file=/etc/loki/loki-config.yml
    volumes:
      - loki-data:/loki
      - ./loki-config.yml:/etc/loki/loki-config.yml:ro
    networks:
      - monitoring
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
    ports:
      - "3100:3100"

  promtail:
    image: grafana/promtail:latest
    command: -config.file=/etc/promtail/promtail-config.yml
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./promtail-config.yml:/etc/promtail/promtail-config.yml:ro
    networks:
      - monitoring
    deploy:
      mode: global  # Un promtail par nœud
      resources:
        limits:
          cpus: '0.2'
          memory: 256M
        reservations:
          cpus: '0.1'
          memory: 128M
      restart_policy:
        condition: on-failure

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    networks:
      - monitoring
    deploy:
      mode: global  # Un cAdvisor par nœud
      resources:
        limits:
          cpus: '0.3'
          memory: 256M
        reservations:
          cpus: '0.1'
          memory: 128M
    ports:
      - target: 8080
        published: 8080
        protocol: tcp
        mode: host

  node-exporter:
    image: prom/node-exporter:latest
    command:
      - '--path.rootfs=/host'
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /:/host:ro,rslave
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
    networks:
      - monitoring
    deploy:
      mode: global  # Un node-exporter par nœud
      resources:
        limits:
          cpus: '0.2'
          memory: 128M
        reservations:
          cpus: '0.1'
          memory: 64M
    ports:
      - target: 9100
        published: 9100
        protocol: tcp
        mode: host

networks:
  monitoring:
    driver: overlay
    attachable: true

volumes:
  prometheus-data:
    driver: local
  grafana-data:
    driver: local
  loki-data:
    driver: local
```

### Points importants de cette configuration

**1. Services centralisés (Manager)** :
- Prometheus, Grafana et Loki tournent sur le manager
- Données persistées avec des volumes nommés
- Placement sur le manager pour la stabilité

**2. Services distribués (Global)** :
- Promtail, cAdvisor et Node Exporter en mode `global`
- Un agent par nœud pour collecter les données localement
- Publication des ports en mode `host` pour cAdvisor et Node Exporter

**3. Réseau monitoring** :
- Réseau overlay dédié au monitoring
- `attachable: true` permet de le connecter à d'autres services

**4. Découverte de services** :
- Prometheus utilise DNS service discovery (`tasks.cadvisor`, `tasks.node-exporter`)
- Automatique grâce à Docker Swarm

## Étape 3 : Copier les fichiers sur le manager Swarm

Les fichiers de configuration doivent être présents sur le manager Swarm pour que les bind mounts fonctionnent.

### 3.1 Préparer les fichiers en local

Sur votre machine locale :

```bash
cd section_swarm_gitlab/315_swarm_monitoring

# Vérifier que tous les fichiers sont présents
ls -la
# Vous devriez voir :
# - docker-compose.swarm.yml
# - prometheus.yml
# - loki-config.yml
# - promtail-config.yml
```

### 3.2 Copier le dossier sur le manager

```bash
# Remplacez <user> et <ip-manager> par vos valeurs
scp -r ../315_swarm_monitoring <user>@<ip-manager>:~/

# Exemple :
# scp -r ../315_swarm_monitoring elie@192.168.1.10:~/
```

### 3.3 Se connecter au manager et vérifier

```bash
# Se connecter au manager
ssh <user>@<ip-manager>

# Vérifier que les fichiers sont présents
cd ~/315_swarm_monitoring
ls -la

# Vous devriez voir tous les fichiers de configuration
```

## Étape 4 : Déployer la stack de monitoring

### 4.1 Déployer le stack

```bash
# Déployer la stack complète
docker stack deploy -c docker-compose.swarm.yml monitoring
```

### 4.2 Vérifier le déploiement

```bash
# Lister les services du stack
docker stack services monitoring

# Attendre que tous les services soient ready
watch docker stack services monitoring

# Voir les conteneurs en cours d'exécution
docker stack ps monitoring

# Vérifier les logs si nécessaire
docker service logs monitoring_prometheus
docker service logs monitoring_grafana
docker service logs monitoring_loki
```

Attendez que tous les services affichent le nombre de replicas attendu (peut prendre 2-3 minutes).

## Étape 5 : Accéder aux interfaces

### 5.1 Prometheus

Accédez à Prometheus : `http://<IP_MANAGER>:9090`

**Explorations** :
- Allez dans Status > Targets pour voir les cibles scrapées
- Testez des requêtes PromQL dans l'onglet Graph :
  ```promql
  # CPU usage par conteneur
  rate(container_cpu_usage_seconds_total[5m])

  # Mémoire utilisée par conteneur
  container_memory_usage_bytes

  # Nombre de conteneurs par nœud
  count(container_last_seen) by (instance)
  ```

### 5.2 Grafana

Accédez à Grafana : `http://<IP_MANAGER>:3000`

**Première connexion** :
- Username : `admin`
- Password : `admin` (vous serez invité à le changer)

**Configuration des sources de données** :

1. Allez dans Configuration > Data Sources
2. Ajoutez Prometheus :
   - Type : Prometheus
   - URL : `http://prometheus:9090`
   - Access : Server (default)
   - Save & Test

3. Ajoutez Loki :
   - Type : Loki
   - URL : `http://loki:3100`
   - Save & Test

**Importer des dashboards** :

1. Allez dans Dashboards > Import
2. Importez les dashboards suivants (par ID) :
   - **893** : Docker Swarm & Container Overview
   - **1860** : Node Exporter Full
   - **12708** : Docker and System Monitoring
   - **13639** : Loki & Promtail (logs)

3. Sélectionnez vos sources de données (Prometheus et Loki)

### 5.3 Loki (optionnel)

Accédez à l'API Loki : `http://<IP_MANAGER>:3100/ready`

Pour consulter les logs directement :
```bash
# Via Grafana Explore > Loki
# Ou via LogCLI si installé
```

## Étape 6 : Tests et validation

### 6.1 Générer de la charge

Si vous avez déployé MonsterStack (TP 312), générez de la charge :

```bash
# Stress test
for i in {1..100}; do
  curl -X POST -d "name=User$i" http://<IP_NODE>:5000/
  sleep 0.1
done
```

Observez dans Grafana :
- L'augmentation du CPU et de la mémoire
- Le nombre de requêtes HTTP
- Les logs d'accès

### 6.2 Vérifier les logs dans Grafana

1. Allez dans Explore
2. Sélectionnez Loki comme source
3. Requêtes LogQL exemple :
   ```logql
   # Tous les logs du stack monsterstack
   {stack="monsterstack"}

   # Logs d'erreur
   {stack="monsterstack"} |= "error"

   # Logs du service frontend
   {service="monsterstack_frontend"}
   ```

### 6.3 Simuler une panne

Arrêtez manuellement un conteneur et observez :

```bash
# Trouver un conteneur
docker ps | grep monsterstack_frontend

# Arrêter un conteneur spécifique
docker stop <CONTAINER_ID>

# Observer la récupération
watch docker service ps monsterstack_frontend
```

Dans Grafana, vous devriez voir :
- Le conteneur disparaître des métriques
- Un nouveau conteneur apparaître (auto-healing)
- Les logs de redémarrage

## Étape 7 : Créer un dashboard personnalisé (bonus)

Créez un dashboard pour MonsterStack :

1. Dans Grafana, créez un nouveau dashboard
2. Ajoutez des panels :

**Panel 1 : Nombre de replicas** :
```promql
count(container_last_seen{container_label_com_docker_swarm_service_name=~"monsterstack.*"}) by (container_label_com_docker_swarm_service_name)
```

**Panel 2 : CPU usage par service** :
```promql
sum(rate(container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name=~"monsterstack.*"}[5m])) by (container_label_com_docker_swarm_service_name)
```

**Panel 3 : Mémoire utilisée** :
```promql
sum(container_memory_usage_bytes{container_label_com_docker_swarm_service_name=~"monsterstack.*"}) by (container_label_com_docker_swarm_service_name)
```

**Panel 4 : Logs récents** (Loki) :
```logql
{stack="monsterstack"} | json | line_format "{{.time}} {{.msg}}"
```

## Étape 8 : Configurer des alertes (bonus avancé)

### 8.1 Créer des règles d'alerte Prometheus

Créez le fichier `alerts.yml` :

```yaml
groups:
  - name: swarm_alerts
    interval: 30s
    rules:
      - alert: HighCPUUsage
        expr: sum(rate(container_cpu_usage_seconds_total[5m])) by (container_label_com_docker_swarm_service_name) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage for service {{ $labels.container_label_com_docker_swarm_service_name }}"
          description: "Service {{ $labels.container_label_com_docker_swarm_service_name }} has CPU usage above 80% for 5 minutes."

      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "Service {{ $labels.job }} on {{ $labels.instance }} is down."

      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.9
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage for container {{ $labels.name }}"
          description: "Container {{ $labels.name }} is using more than 90% of its memory limit."
```

Modifiez `prometheus.yml` pour inclure les alertes :

```yaml
rule_files:
  - /etc/prometheus/alerts.yml
```

Mettez à jour le service Prometheus dans `docker-compose.swarm.yml` :

```yaml
prometheus:
  # ...
  volumes:
    - prometheus-data:/prometheus
    - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    - ./alerts.yml:/etc/prometheus/alerts.yml:ro
  # ...
```

Redéployez :

```bash
docker stack deploy -c docker-compose.swarm.yml monitoring
```

Vérifiez les alertes dans Prometheus : `http://<IP_MANAGER>:9090/alerts`

### 8.2 Configurer Alertmanager (optionnel)

Pour envoyer des notifications (email, Slack, etc.), ajoutez Alertmanager au stack.

## Étape 9 : Nettoyage

Pour supprimer la stack de monitoring :

```bash
# Supprimer le stack
docker stack rm monitoring

# Vérifier la suppression
docker stack ls
docker service ls

# Supprimer les volumes (ATTENTION : perte de données)
docker volume rm monitoring_prometheus-data
docker volume rm monitoring_grafana-data
docker volume rm monitoring_loki-data
```

## Questions de réflexion

### 1. Architecture
- Pourquoi placer Prometheus, Grafana et Loki sur le manager ?
  - **Réponse** : Stabilité, persistance des données, éviter les pertes lors des migrations
- Pourquoi Promtail, cAdvisor et Node Exporter en mode global ?
  - **Réponse** : Pour collecter les données locales sur chaque nœud

### 2. Performances
- Quelle est l'impact du monitoring sur les ressources du cluster ?
  - **Réponse** : ~10-15% de CPU et 2-3 GB de RAM pour toute la stack
- Comment optimiser la rétention des données ?
  - **Réponse** : Ajuster `--storage.tsdb.retention.time` dans Prometheus et `retention_period` dans Loki

### 3. Sécurité
- Comment sécuriser les accès à Grafana et Prometheus ?
  - **Réponse** : Authentification, reverse proxy (Traefik) avec TLS, réseau privé
- Comment protéger les données sensibles dans les logs ?
  - **Réponse** : Filtrage dans Promtail, masquage des secrets

### 4. Haute disponibilité
- Que se passe-t-il si le manager (avec Prometheus) tombe ?
  - **Réponse** : Perte temporaire du monitoring jusqu'à redémarrage ou basculement
- Comment rendre la stack monitoring hautement disponible ?
  - **Réponse** : Plusieurs managers, Prometheus en mode clustered (Thanos), Loki distribué

## Améliorations possibles

### 1. Ajouter Alertmanager
Pour gérer les notifications d'alertes (email, Slack, PagerDuty, etc.)

### 2. Ajouter Thanos
Pour la haute disponibilité de Prometheus et le stockage long terme

### 3. Intégrer avec Traefik
Pour l'accès sécurisé (HTTPS) aux interfaces Grafana et Prometheus

### 4. Monitoring applicatif
Instrumenter vos applications avec des bibliothèques Prometheus pour exporter des métriques métier

### 5. Logs structurés
Modifier les applications pour générer des logs JSON exploitables par Loki

### 6. Distributed tracing
Ajouter Tempo pour le tracing distribué (APM)

## Références

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/)
- [cAdvisor](https://github.com/google/cadvisor)
- [Node Exporter](https://github.com/prometheus/node_exporter)
- [Monitoring Docker Swarm with Prometheus](https://docs.docker.com/config/daemon/prometheus/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [LogQL Tutorial](https://grafana.com/docs/loki/latest/logql/)
