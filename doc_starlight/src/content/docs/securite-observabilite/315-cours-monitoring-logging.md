---
title: "Monitoring et Logging Docker"
description: "Guide Monitoring et Logging Docker"
sidebar:
  order: 315
---


## MONITORING

### Des métriques très dynamiques à surveiller

```
Conteneur:
├─ CPU Usage (%)
├─ Memory Usage (MB/GB)
├─ Memory Limit
├─ Network I/O (MB/s)
├─ Disk I/O (MB/s)
└─ Nombre de processus

Cluster Swarm:
├─ Nombre de nœuds actifs
├─ Services en état "Running"
├─ Réplicas démarrés vs désirés
└─ Ressources disponibles par nœud
```

### Solutions de Monitoring

#### 2.1 Docker Stats (Natif - Basique)

```bash
# Voir les stats en temps réel
docker stats

# Format personnalisé
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Stats d'un service Swarm
docker service ps myapp --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"
```

#### cAdvisor (Google - Simple)

**Caractéristiques :**
- Interface web basique
- Métriques en temps réel
- Historique limité (quelques minutes)
- Export vers Prometheus
- Se déploie en mode global (1 instance par nœud)

**Interface :** http://localhost:8080

#### Prometheus + Grafana (Standard Industrie) ⭐

**Architecture :**

```
┌──────────────┐     ┌─────────────┐     ┌──────────┐
│  Containers  │────▶│ Prometheus  │────▶│ Grafana  │
│  + cAdvisor  │     │  (Métriques)│     │   (UI)   │
└──────────────┘     └─────────────┘     └──────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │ Alertmanager │
                     │   (Alertes)  │
                     └──────────────┘
```

**Composants :**
- **Prometheus** : Collecte et stockage des métriques (TSDB)
- **Grafana** : Visualisation et dashboards
- **Alertmanager** : Gestion et routage des alertes
- **cAdvisor** : Export des métriques conteneurs


#### Exemples de règles d'Alerte

**alert-rules.yml :**

```yaml
groups:
  - name: container_alerts
    interval: 30s
    rules:
      # Alerte CPU élevé
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "CPU élevé sur {{ $labels.name }}"
          description: "{{ $labels.name }} utilise {{ $value }}% CPU"

      # Alerte Mémoire élevée
      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Mémoire critique sur {{ $labels.name }}"
          description: "{{ $labels.name }} utilise {{ $value }}% de sa limite"

      # Alerte conteneur down
      - alert: ContainerDown
        expr: up == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Conteneur {{ $labels.job }} est down"
          description: "Le conteneur ne répond plus depuis 2 minutes"

      # Alerte réplicas insuffisants
      - alert: ServiceReplicasMismatch
        expr: docker_swarm_service_replicas_running < docker_swarm_service_replicas_desired
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Service {{ $labels.service }} manque de réplicas"
```



### Dashboards Grafana Recommandés

```
Dashboard ID à importer:
├─ 193   : Docker and System Monitoring
├─ 11600 : Docker Swarm & Container Overview
├─ 893   : Docker & System Monitoring (cAdvisor)
└─ 15798 : Docker Swarm Monitoring (complet)
```

**Importer un dashboard :**
1. Grafana → Dashboards → Import
2. Entrer l'ID (ex: 11600)
3. Sélectionner la source Prometheus

### Comparaison Solutions Monitoring

| Solution | Complexité | Historique | Alertes | UI | Clustering |
|----------|-----------|------------|---------|-----|------------|
| **docker stats** | ⭐ | ❌ | ❌ | CLI | ✅ |
| **cAdvisor** | ⭐⭐ | Minutes | ❌ | Basique | ✅ |
| **Prometheus+Grafana** | ⭐⭐⭐⭐ | ✅ 30j+ | ✅ | Excellente | ✅ |
| **Datadog** (SaaS) | ⭐⭐ | ✅ Illimité | ✅ | Excellente | ✅ |
| **New Relic** (SaaS) | ⭐⭐ | ✅ Illimité | ✅ | Excellente | ✅ |

**Recommandation :** Prometheus + Grafana pour production (gratuit, puissant, standard industrie)




## LOGGING

### Concepts Fondamentaux

#### Types de Logs

```
Application:
├─ stdout/stderr (console)
├─ Fichiers dans le conteneur
└─ Logs applicatifs structurés (JSON)

Docker:
├─ Container logs (docker logs)
├─ Docker daemon logs
└─ Swarm orchestration logs

Système:
├─ Kernel logs (dmesg)
├─ System logs (syslog)
└─ Audit logs
```

#### Le Problème avec les Conteneurs

```
Problèmes:
├─ Logs éparpillés sur plusieurs nœuds
├─ Conteneurs éphémères = perte de logs
├─ Volumes de logs énormes
└─ Difficile de corréler les événements

Solution: Centralisation des logs
├─ Collecter depuis tous les conteneurs
├─ Stocker dans un système centralisé
├─ Indexer pour recherche rapide
└─ Visualiser et analyser
```

### Architecture Générique de Logging

```
┌─────────────┐
│ Application │──┐
│ (stdout)    │  │
└─────────────┘  │
                 │    ┌──────────┐    ┌─────────┐    ┌────────────┐
┌─────────────┐  ├───▶│ Collecte │───▶│ Stockage│───▶│Visualisation│
│ Application │──┘    │ (Agent)  │    │ (Index) │    │    (UI)    │
│ (logs file) │       └──────────┘    └─────────┘    └────────────┘
└─────────────┘            │
                           ▼
                    ┌──────────────┐
                    │ Transformation│
                    │  (Parsing)    │
                    └──────────────┘
```

**Composants :**
1. **Collecte** : Récupère les logs (Filebeat, Fluentd, Promtail)
2. **Transformation** : Parse et enrichit (Logstash, Fluentd)
3. **Stockage** : Indexe et stocke (Elasticsearch, Loki)
4. **Visualisation** : Interface de recherche (Kibana, Grafana)


### Configuration Docker Logging Driver

#### Au Niveau du Daemon

**/etc/docker/daemon.json :**

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "labels": "production_status",
    "env": "os,customer"
  }
}
```

---

#### Au Niveau du Conteneur

```yaml
services:
  myapp:
    image: myapp:latest
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
        labels: "service,environment"
```

#### Drivers Disponibles

| Driver | Usage | Performance |
|--------|-------|-------------|
| `json-file` | Par défaut, fichiers JSON | Moyenne |
| `syslog` | Envoi vers syslog | Bonne |
| `journald` | Systemd journald | Bonne |
| `fluentd` | Envoi vers Fluentd | Moyenne |
| `gelf` | Graylog | Bonne |
| `local` | Optimisé performances | Excellente |
| `none` | Pas de logs | N/A |



### Stack EFK (Elasticsearch + Fluentd + Kibana)

#### Architecture

```
┌──────────────┐
│  Conteneurs  │
│   (stdout)   │
└──────┬───────┘
       │
       ▼
┌──────────────┐    ┌──────────────┐    ┌─────────┐
│   Fluentd    │───▶│Elasticsearch │───▶│ Kibana  │
│ (Collecte +  │    │  (Stockage + │    │  (UI)   │
│  Transform)  │    │   Indexation)│    │         │
└──────────────┘    └──────────────┘    └─────────┘
```

**Caractéristiques :**
- **Fluentd** : Collecteur léger et flexible
- **Elasticsearch** : Moteur de recherche full-text distribué
- **Kibana** : Interface de visualisation puissante
- **Ressources** : 4-8GB RAM minimum


#### Configuration Fluentd

**fluentd.conf :**

```xml
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

# Parser les logs JSON
<filter docker.**>
  @type parser
  key_name log
  <parse>
    @type json
  </parse>
</filter>

# Enrichir avec des métadonnées
<filter docker.**>
  @type record_transformer
  <record>
    hostname "#{Socket.gethostname}"
    tag ${tag}
  </record>
</filter>

# Envoyer vers Elasticsearch
<match docker.**>
  @type elasticsearch
  host elasticsearch
  port 9200
  logstash_format true
  logstash_prefix docker
  flush_interval 5s
</match>
```

---

#### Configurer les Conteneurs pour Fluentd

```yaml
services:
  myapp:
    image: myapp:latest
    logging:
      driver: fluentd
      options:
        fluentd-address: localhost:24224
        tag: docker.myapp
        fluentd-async-connect: "true"
```


### Stack ELK avec Filebeat

#### Architecture

```
┌──────────────┐
│  Conteneurs  │
│  (log files) │
└──────┬───────┘
       │
       ▼
┌──────────────┐    ┌──────────┐    ┌──────────────┐    ┌────────┐
│   Filebeat   │───▶│ Logstash │───▶│Elasticsearch │───▶│ Kibana │
│  (Collecte)  │    │(Transform)│    │  (Stockage)  │    │  (UI)  │
└──────────────┘    └──────────┘    └──────────────┘    └────────┘
```

**Différence avec Fluentd :**
- **Filebeat** : Plus léger, spécialisé fichiers
- **Logstash** : Parsing très puissant mais gourmand
- **Ressources** : 6-12GB RAM minimum


#### Configuration Filebeat

**filebeat.yml :**

```yaml
filebeat.inputs:
  # Logs des conteneurs Docker
  - type: container
    paths:
      - '/var/lib/docker/containers/*/*.log'
    processors:
      - add_docker_metadata:
          host: "unix:///var/run/docker.sock"

# Enrichissement
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~

# Output vers Logstash
output.logstash:
  hosts: ["logstash:5044"]

# Ou directement vers Elasticsearch (plus simple)
# output.elasticsearch:
#   hosts: ["elasticsearch:9200"]

logging.level: info
```


#### Configuration Logstash

**logstash.conf :**

```ruby
input {
  beats {
    port => 5044
  }
}

filter {
  # Parser les logs JSON
  if [message] =~ /^\{.*\}$/ {
    json {
      source => "message"
    }
  }

  # Parser les timestamps
  date {
    match => ["timestamp", "ISO8601"]
    target => "@timestamp"
  }

  # Extraire des champs depuis les logs
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }

  # Nettoyer les champs inutiles
  mutate {
    remove_field => ["agent", "ecs", "host"]
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "docker-logs-%{+YYYY.MM.dd}"
  }
  
  # Debug (optionnel)
  stdout { codec => rubydebug }
}
```

---

### Stack PLG (Promtail + Loki + Grafana)

#### Architecture

```
┌──────────────┐
│  Conteneurs  │
│   (stdout)   │
└──────┬───────┘
       │
       ▼
┌──────────────┐    ┌──────────┐    ┌─────────┐
│   Promtail   │───▶│   Loki   │───▶│ Grafana │
│  (Collecte)  │    │(Stockage)│    │  (UI)   │
└──────────────┘    └──────────┘    └─────────┘
```

**Philosophie Loki :**
- Ne parse PAS les logs (contrairement à ELK)
- Indexe uniquement les labels (metadata)
- Recherche en texte brut très rapide
- Consomme 10× moins de ressources qu'Elasticsearch
- **Ressources** : 1-2GB RAM seulement


#### Configuration Loki

**loki-config.yml :**

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
  chunk_idle_period: 15m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/cache
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks

limits_config:
  retention_period: 720h  # 30 jours
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: true
  retention_period: 720h
```


#### Configuration Promtail

**promtail-config.yml :**

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # Logs des conteneurs Docker
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      # Extraire le nom du conteneur
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
      # Extraire l'image
      - source_labels: ['__meta_docker_container_image']
        target_label: 'image'
      # Extraire le service Swarm
      - source_labels: ['__meta_docker_container_label_com_docker_swarm_service_name']
        target_label: 'service'
      # Extraire le nœud
      - source_labels: ['__meta_docker_container_label_com_docker_swarm_node_id']
        target_label: 'node_id'
    pipeline_stages:
      # Parser les logs JSON
      - json:
          expressions:
            level: level
            timestamp: timestamp
            message: message
      # Extraire le timestamp
      - timestamp:
          source: timestamp
          format: RFC3339
      # Labelliser par niveau
      - labels:
          level:
```

#### Configuration Datasource Grafana

**grafana-datasources.yml :**

```yaml
apiVersion: 1

datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    isDefault: true
    jsonData:
      maxLines: 1000
```


### Comparaison des Stacks de Logging

| Critère | EFK (Fluentd) | ELK (Filebeat) | PLG (Loki) |
|---------|---------------|----------------|------------|
| **Complexité** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **Ressources** | 4-8GB RAM | 6-12GB RAM | 1-2GB RAM |
| **Parsing** | ✅ Puissant | ✅ Très puissant | ❌ Basique |
| **Indexation** | ✅ Full-text | ✅ Full-text | 🔸 Labels uniquement |
| **Vitesse recherche** | Rapide | Rapide | Très rapide |
| **Coût stockage** | Élevé | Élevé | Faible |
| **Scalabilité** | ✅ Bonne | ✅ Excellente | ✅ Excellente |
| **Courbe apprentissage** | Moyenne | Difficile | Facile |
| **Intégration Grafana** | ⚠️ Via plugin | ⚠️ Via plugin | ✅ Native |


### Requêtes de Recherche

#### Kibana (ELK/EFK)

```
# Recherche simple
container.name: "webapp"

# Recherche avec wildcard
message: "error*"

# Combinaison AND/OR
container.name: "webapp" AND level: "error"

# Range temporel
@timestamp: [now-1h TO now]

# Aggrégation
COUNT(container.name) GROUP BY container.name
```


#### Loki (LogQL)

```
# Tous les logs d'un service
{service="webapp"}

# Filtrage par niveau
{service="webapp"} |= "error"

# Recherche regex
{service="webapp"} |~ "error|warning"

# Exclusion
{service="webapp"} != "debug"

# Parsing JSON
{service="webapp"} | json | level="error"

# Métriques (rate)
rate({service="webapp"}[5m])

# Count par container
sum(count_over_time({job="docker"}[5m])) by (container)
```
