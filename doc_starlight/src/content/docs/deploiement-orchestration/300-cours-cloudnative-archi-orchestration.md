---
title: "Cours : Orchestration de conteneurs, architecture logicielle et le concept de cloudnative"
description: "Guide Cours : Orchestration de conteneurs, architecture logicielle et le concept de cloudnative"
sidebar:
  order: 300
---


## Le Cloud Native Histoire et Émergence

Le concept de **Cloud Native** est né dans les années 2010, en réponse à l'évolution des besoins en infrastructure et au développement du cloud computing. Voici les grandes étapes :

**Les origines (2010-2015)**
L'émergence du cloud native est intimement liée à l'adoption massive des services cloud (AWS, Azure, Google Cloud) et à l'évolution des pratiques de développement. Des entreprises comme Netflix, Google et Amazon ont été pionnières, développant des applications conçues spécifiquement pour tirer parti de l'élasticité et de la résilience du cloud.

**La formalisation (2015)**
En 2015, la **Cloud Native Computing Foundation (CNCF)** a été créée sous l'égide de la Linux Foundation. Cette organisation a standardisé les pratiques et popularisé des technologies clés comme Kubernetes (dont Google a fait don du code source).

**L'explosion (2016-aujourd'hui)**
Le cloud native est devenu le paradigme dominant pour le développement d'applications modernes, avec un écosystème riche d'outils et de technologies.

## Les Principes Fondamentaux du mouvement Cloud Native

Le cloud native repose sur plusieurs piliers interconnectés :

### 1. **Microservices**
L'application est décomposée en petits services indépendants, chacun responsable d'une fonction métier spécifique. Ces services communiquent via des API légères (REST, gRPC). Cela permet une meilleure scalabilité, une maintenance facilitée et des déploiements indépendants.

### 2. **Conteneurisation**
Les applications sont packagées dans des conteneurs qui encapsulent le code, les dépendances et la configuration. Les conteneurs garantissent la portabilité et la cohérence entre les environnements de développement, test et production.

### 3. **Orchestration dynamique**
Des plateformes comme Kubernetes gèrent automatiquement le déploiement, la mise à l'échelle et la gestion des conteneurs. L'orchestration permet l'auto-réparation, l'équilibrage de charge et l'utilisation optimale des ressources.

### 4. **DevOps et CI/CD**
L'intégration et le déploiement continus sont essentiels au cloud native. Les équipes de développement et d'opérations collaborent étroitement, avec une automatisation poussée des tests, du déploiement et du monitoring.

### 5. **Infrastructure as Code (IaC)**
L'infrastructure est définie et gérée via du code versionné (Terraform, Ansible), permettant reproductibilité, traçabilité et automatisation.

### 6. **Résilience et observabilité**
Les applications sont conçues pour tolérer les pannes (circuit breakers, retry patterns). L'observabilité (logs, métriques, traces) est intégrée dès la conception pour faciliter le monitoring et le debugging.

### 7. **Scalabilité élastique**
Les applications peuvent automatiquement s'adapter à la charge en ajoutant ou supprimant des ressources selon les besoins, optimisant ainsi les coûts.

## Les Bénéfices

Le cloud native offre plusieurs avantages majeurs : agilité accrue dans le développement, réduction du time-to-market, meilleure utilisation des ressources, haute disponibilité, et capacité à innover rapidement.

## Cours : Architectures Logicielles et Docker

## Table des matières
1. [Introduction aux architectures logicielles](#introduction)
2. [Architecture Monolithique](#monolithique)
3. [Architecture Microservices](#microservices)
4. [Architectures Hybrides et Alternatives](#hybrides)
5. [Docker et les Architectures](#docker)
6. [Comparaisons et Choix d'Architecture](#comparaisons)
7. [Patterns et Bonnes Pratiques](#patterns)
8. [Cas Pratiques](#cas-pratiques)

---

## 1. Introduction aux Architectures Logicielles {#introduction}

### 1.1 Qu'est-ce qu'une architecture logicielle ?

L'architecture logicielle définit l'organisation fondamentale d'un système, ses composants, leurs relations, et les principes qui gouvernent sa conception et son évolution. Elle répond aux questions :

- Comment structurer le code et les composants ?
- Comment gérer les dépendances entre modules ?
- Comment déployer et faire évoluer l'application ?
- Comment assurer la maintenabilité et la scalabilité ?

### 1.2 Critères de choix d'une architecture

Le choix d'une architecture dépend de plusieurs facteurs :

**Facteurs techniques**
- Complexité de l'application
- Besoins en scalabilité
- Performance requise
- Contraintes de disponibilité

**Facteurs organisationnels**
- Taille et structure de l'équipe
- Expertise technique disponible
- Budget et ressources
- Time-to-market

**Facteurs métier**
- Évolutivité des besoins
- Fréquence des changements
- Criticité du service
- Réglementations et conformité

---

## 2. Architecture Monolithique {#monolithique}

### 2.1 Définition et Caractéristiques

Une **architecture monolithique** consiste en une application construite comme une unité unique et indivisible. Tous les composants (interface utilisateur, logique métier, accès aux données) sont interconnectés et interdépendants dans une seule base de code.

**Caractéristiques principales :**
- Base de code unique
- Déploiement atomique (tout ou rien)
- Base de données partagée
- Couplage fort entre composants
- Processus unique en exécution

### 2.2 Structure typique d'un monolithe

```
Application Monolithique
│
├── Couche Présentation (UI)
│   ├── Vues
│   ├── Contrôleurs
│   └── Templates
│
├── Couche Métier (Business Logic)
│   ├── Services métier
│   ├── Règles de gestion
│   └── Workflows
│
├── Couche Accès aux Données (DAL)
│   ├── Repositories
│   ├── Modèles de données
│   └── Mappeurs ORM
│
└── Base de Données Unique
```

### 2.3 Avantages du Monolithe

**Simplicité de développement**
- Environnement de développement unifié
- Pas de gestion de communication inter-services
- Debugging plus simple avec un seul processus
- Stack technologique unique

**Déploiement simple**
- Un seul artefact à déployer
- Pas de gestion de versions multiples
- Rollback facile
- Infrastructure simplifiée

**Performance**
- Pas de latence réseau interne
- Transactions locales rapides
- Pas de sérialisation/désérialisation entre services
- Optimisations globales possibles

**Consistency et Intégrité**
- Transactions ACID complètes
- Cohérence des données garantie
- Gestion simplifiée de l'état
- Pas de problèmes de consistency distribuée

**Coûts réduits**
- Infrastructure minimale
- Moins de complexité opérationnelle
- Monitoring simplifié
- Moins de ressources DevOps nécessaires

### 2.4 Inconvénients du Monolithe

**Scalabilité limitée**
- Impossible de scaler des composants individuellement
- Réplication complète obligatoire
- Gaspillage de ressources
- Difficultés avec la croissance

**Complexité croissante**
- Code devient difficile à comprendre
- Temps de compilation augmente
- Difficultés pour naviguer dans la codebase
- Augmentation de la dette technique

**Déploiements risqués**
- Changement mineur = redéploiement complet
- Risque élevé à chaque déploiement
- Temps d'arrêt potentiel
- Testing complexe de l'ensemble

**Manque de flexibilité technologique**
- Stack unique pour toute l'application
- Difficile d'adopter de nouvelles technologies
- Dépendance à des frameworks vieillissants
- Migration technologique coûteuse

**Problèmes organisationnels**
- Coordination difficile entre équipes
- Conflits de merge fréquents
- Ownership peu clair
- Barrières à l'entrée pour nouveaux développeurs

### 2.5 Quand choisir un Monolithe ?

Le monolithe est approprié quand :

- **Projet nouveau ou petit** : équipe réduite, besoins clairs et limités
- **Domaine métier simple** : peu de logique complexe, règles stables
- **Contraintes de ressources** : budget limité, peu d'expertise DevOps
- **Besoins en performance** : latence critique, transactions fréquentes
- **Startup en phase de validation** : besoin de rapidité, pivots fréquents
- **Applications internes** : charge prévisible, peu d'utilisateurs

### 2.6 Monolithe et Docker

**Avantages de dockeriser un monolithe :**

```dockerfile
# Exemple de Dockerfile pour un monolithe Java
FROM openjdk:17-jdk-slim

WORKDIR /app

# Copie du JAR de l'application
COPY target/monolith-app.jar app.jar

# Configuration
ENV SPRING_PROFILES_ACTIVE=production
ENV JVM_OPTS="-Xmx2g -Xms1g"

# Port d'exposition
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Démarrage
ENTRYPOINT ["sh", "-c", "java $JVM_OPTS -jar app.jar"]
```

**Bénéfices :**
- Portabilité accrue entre environnements
- Isolation des dépendances
- Déploiement reproductible
- Facilite le passage futur aux microservices
- Rollback simplifié avec les versions d'images

**Limites :**
- Toujours limité aux contraintes du monolithe
- Taille d'image potentiellement importante
- Pas de scalabilité granulaire

---

## 3. Architecture Microservices {#microservices}

### 3.1 Définition et Philosophie

Les **microservices** constituent un style architectural où une application est composée de petits services indépendants, chacun exécutant un processus unique et communiquant via des mécanismes légers (généralement HTTP/REST ou messaging).

**Principes fondateurs :**
- Décentralisation des décisions
- Automatisation de l'infrastructure
- Design for failure (concevoir en anticipant les pannes)
- Evolutionary design (conception évolutive)

### 3.2 Caractéristiques des Microservices

**Autonomie**
Chaque service est :
- Déployable indépendamment
- Possède sa propre base de données
- Géré par une équipe dédiée
- Versionné séparément

**Spécialisation**
- Un service = une responsabilité métier
- Bounded context (contexte délimité selon DDD)
- Interface contractuelle claire
- Faible couplage, forte cohésion

**Résilience**
- Isolation des pannes
- Circuit breakers
- Timeouts et retry logic
- Graceful degradation

**Scalabilité indépendante**
- Chaque service scale selon ses besoins
- Optimisation des ressources
- Auto-scaling par service
- Load balancing granulaire

### 3.3 Architecture Typique Microservices

```
                    ┌─────────────────┐
                    │   API Gateway   │
                    │   (Kong/Nginx)  │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
    ┌───────▼──────┐  ┌─────▼──────┐  ┌─────▼──────┐
    │   Service    │  │  Service   │  │  Service   │
    │   Commandes  │  │  Produits  │  │  Paiements │
    │   (Node.js)  │  │  (Java)    │  │  (Python)  │
    └──────┬───────┘  └─────┬──────┘  └─────┬──────┘
           │                │                │
    ┌──────▼───────┐ ┌─────▼──────┐  ┌─────▼──────┐
    │   MongoDB    │ │ PostgreSQL │  │   Redis    │
    └──────────────┘ └────────────┘  └────────────┘
           │                │                │
           └────────────────┼────────────────┘
                            │
                    ┌───────▼────────┐
                    │  Event Bus     │
                    │  (Kafka/RabbitMQ)│
                    └────────────────┘
```

### 3.4 Patterns de Communication

**Communication Synchrone (Request/Response)**

*REST/HTTP*
```python
# Service Produits expose une API REST
@app.route('/api/products/<product_id>', methods=['GET'])
def get_product(product_id):
    product = db.products.find_one({'id': product_id})
    return jsonify(product)

# Service Commandes consomme l'API
import requests

def create_order(product_id, quantity):
    # Appel synchrone au service Produits
    response = requests.get(f'http://product-service/api/products/{product_id}')
    product = response.json()
    
    if product['stock'] >= quantity:
        # Créer la commande
        order = {...}
        return order
    else:
        raise InsufficientStock()
```

*gRPC*
```protobuf
// Definition du service
syntax = "proto3";

service ProductService {
  rpc GetProduct (ProductRequest) returns (ProductResponse);
  rpc UpdateStock (UpdateStockRequest) returns (UpdateStockResponse);
}

message ProductRequest {
  string product_id = 1;
}

message ProductResponse {
  string product_id = 1;
  string name = 2;
  double price = 3;
  int32 stock = 4;
}
```

**Communication Asynchrone (Event-Driven)**

*Publish/Subscribe*
```javascript
// Service Commandes publie un événement
const kafka = require('kafka-node');
const Producer = kafka.Producer;
const client = new kafka.KafkaClient();
const producer = new Producer(client);

// Publier un événement OrderCreated
function publishOrderCreated(order) {
  const event = {
    type: 'OrderCreated',
    timestamp: new Date(),
    data: {
      orderId: order.id,
      customerId: order.customerId,
      items: order.items,
      totalAmount: order.totalAmount
    }
  };
  
  producer.send([{
    topic: 'orders',
    messages: JSON.stringify(event)
  }], (err, data) => {
    if (err) console.error('Error publishing event:', err);
  });
}

// Service Notifications écoute les événements
const Consumer = kafka.Consumer;
const consumer = new Consumer(
  client,
  [{ topic: 'orders', partition: 0 }],
  { autoCommit: true }
);

consumer.on('message', (message) => {
  const event = JSON.parse(message.value);
  
  if (event.type === 'OrderCreated') {
    // Envoyer notification au client
    sendEmailNotification(event.data.customerId, event.data);
  }
});
```

### 3.5 Data Management dans les Microservices

**Database per Service Pattern**

Chaque microservice possède sa propre base de données, garantissant l'encapsulation des données et l'autonomie.

```
Service Commandes → MongoDB (documents flexibles)
Service Produits → PostgreSQL (relations complexes)
Service Paiements → Redis (cache rapide) + PostgreSQL
Service Analytics → Elasticsearch (recherche)
```

**Gestion de la Consistance**

*Saga Pattern* : Transactions distribuées via une séquence d'opérations locales
```javascript
// Saga orchestrée pour créer une commande
class OrderSaga {
  async execute(orderData) {
    try {
      // Étape 1: Réserver les produits
      const reservation = await productService.reserveStock(orderData.items);
      
      // Étape 2: Traiter le paiement
      const payment = await paymentService.processPayment(orderData.amount);
      
      // Étape 3: Créer la commande
      const order = await orderService.createOrder(orderData);
      
      // Étape 4: Confirmer la réservation
      await productService.confirmReservation(reservation.id);
      
      return order;
      
    } catch (error) {
      // Compensation: annuler les opérations réussies
      await this.compensate(orderData);
      throw error;
    }
  }
  
  async compensate(orderData) {
    // Annuler la réservation de stock
    await productService.cancelReservation(orderData.reservationId);
    // Rembourser le paiement
    await paymentService.refund(orderData.paymentId);
  }
}
```

*Event Sourcing* : Stocker les événements plutôt que l'état
```javascript
// Au lieu de stocker l'état final
// État: { orderId: 123, status: 'shipped', items: [...] }

// Stocker les événements
const events = [
  { type: 'OrderCreated', timestamp: '2025-01-15T10:00:00Z', data: {...} },
  { type: 'OrderPaid', timestamp: '2025-01-15T10:05:00Z', data: {...} },
  { type: 'OrderShipped', timestamp: '2025-01-16T14:00:00Z', data: {...} }
];

// Reconstituer l'état en rejouant les événements
function replayEvents(events) {
  let state = {};
  events.forEach(event => {
    state = applyEvent(state, event);
  });
  return state;
}
```

### 3.6 Avantages des Microservices

**Scalabilité granulaire**
- Scaler uniquement les services sous charge
- Optimisation des coûts
- Meilleure utilisation des ressources
- Réponse rapide aux pics de trafic

**Résilience et Isolation**
- Panne isolée à un service
- Dégradation gracieuse
- Plus de disponibilité globale
- Facilite le testing du chaos engineering

**Flexibilité technologique**
- Chaque service peut utiliser sa stack optimale
- Adoption progressive de nouvelles technologies
- Expérimentation sans risque
- Attirer des talents avec des stacks modernes

**Organisation et Ownership**
- Équipes autonomes par service
- Responsabilité claire
- Déploiements indépendants
- Cycle de développement accéléré

**Évolutivité du code**
- Codebase plus petite et compréhensible
- Moins de complexité par service
- Refactoring plus simple
- Nouvelle fonctionnalité = nouveau service

### 3.7 Défis et Inconvénients des Microservices

**Complexité opérationnelle**
- Multiplication des déploiements
- Monitoring et logging distribués
- Debugging complexe (traces distribuées)
- Nécessite orchestration (Kubernetes)

**Latence réseau**
- Communications inter-services plus lentes
- Sérialisation/désérialisation des données
- Timeouts et retries nécessaires
- Impact sur la performance globale

**Gestion de la consistance**
- Pas de transactions ACID globales
- Eventual consistency
- Gestion complexe des états distribués
- Saga et compensation patterns nécessaires

**Testing complexe**
- Tests d'intégration difficiles
- Environnements de test coûteux
- Gestion des dépendances entre services
- Contract testing nécessaire

**Coûts d'infrastructure**
- Plus de ressources nécessaires
- Orchestration et service mesh
- Monitoring et observabilité avancés
- Expertise DevOps/SRE indispensable

**Overhead de développement**
- Duplication de code possible
- Gestion des versions d'API
- Documentation critique
- Contrats d'interface à maintenir

### 3.8 Quand choisir les Microservices ?

Les microservices sont appropriés quand :

- **Application complexe** : domaines métier multiples et distincts
- **Équipes multiples** : plusieurs équipes autonomes
- **Scalabilité variable** : besoins différents par fonctionnalité
- **Évolution rapide** : changements fréquents et indépendants
- **Expertise DevOps** : capacité à gérer la complexité opérationnelle
- **Haute disponibilité requise** : criticité de certains services
- **Innovation technologique** : besoin d'expérimenter différentes technologies

### 3.9 Microservices et Docker

Docker est **essentiel** pour les microservices. Il résout plusieurs problèmes clés :

**Isolation et Portabilité**
```dockerfile
# Service Produits (Java/Spring Boot)
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY target/product-service.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

# Service Commandes (Node.js)
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]

# Service Paiements (Python)
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```

**Orchestration avec Docker Compose**
```yaml
version: '3.8'

services:
  product-service:
    build: ./services/product-service
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=product-db
      - KAFKA_BROKERS=kafka:9092
    depends_on:
      - product-db
      - kafka
    networks:
      - microservices-net
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  order-service:
    build: ./services/order-service
    ports:
      - "3000:3000"
    environment:
      - MONGO_URI=mongodb://order-db:27017/orders
      - PRODUCT_SERVICE_URL=http://product-service:8080
    depends_on:
      - order-db
      - kafka
    networks:
      - microservices-net

  payment-service:
    build: ./services/payment-service
    ports:
      - "5000:5000"
    environment:
      - REDIS_HOST=redis
      - DATABASE_URL=postgresql://postgres:password@payment-db/payments
    depends_on:
      - payment-db
      - redis
    networks:
      - microservices-net

  # Bases de données
  product-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: products
      POSTGRES_PASSWORD: password
    volumes:
      - product-data:/var/lib/postgresql/data
    networks:
      - microservices-net

  order-db:
    image: mongo:6
    volumes:
      - order-data:/data/db
    networks:
      - microservices-net

  payment-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: payments
      POSTGRES_PASSWORD: password
    volumes:
      - payment-data:/var/lib/postgresql/data
    networks:
      - microservices-net

  redis:
    image: redis:7-alpine
    networks:
      - microservices-net

  # Message Broker
  kafka:
    image: confluentinc/cp-kafka:latest
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
    depends_on:
      - zookeeper
    networks:
      - microservices-net

  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    networks:
      - microservices-net

  # API Gateway
  api-gateway:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - product-service
      - order-service
      - payment-service
    networks:
      - microservices-net

volumes:
  product-data:
  order-data:
  payment-data:

networks:
  microservices-net:
    driver: bridge
```

**Avantages de Docker pour Microservices :**

1. **Développement local simplifié** : tous les services peuvent tourner sur une machine
2. **Consistency** : même environnement dev/test/prod
3. **Isolation** : chaque service dans son conteneur
4. **Découverte de services** : DNS intégré dans Docker networks
5. **Scaling simple** : `docker-compose up --scale order-service=5`
6. **Resource management** : limites CPU/mémoire par conteneur

---

## 4. Architectures Hybrides et Alternatives {#hybrides}

### 4.1 Architecture Modulaire (Modular Monolith)

Le **monolithe modulaire** combine les avantages du monolithe et des microservices en structurant l'application en modules découplés au sein d'un seul déploiement.

**Structure :**
```
Application Modulaire
│
├── Module Commandes
│   ├── API (interfaces publiques)
│   ├── Domain (logique métier)
│   ├── Infrastructure (implémentation)
│   └── Database Schema (schéma dédié)
│
├── Module Produits
│   ├── API
│   ├── Domain
│   ├── Infrastructure
│   └── Database Schema
│
├── Module Paiements
│   ├── API
│   ├── Domain
│   ├── Infrastructure
│   └── Database Schema
│
└── Shared Kernel (code partagé minimal)
    ├── Common types
    ├── Utilities
    └── Infrastructure commune
```

**Règles strictes :**
- Modules communiquent uniquement via des interfaces définies
- Pas de dépendances circulaires
- Chaque module a son propre schéma de base de données (dans la même DB)
- Pas d'accès direct aux données d'un autre module

**Exemple avec Docker :**
```dockerfile
# Un seul conteneur, mais architecture modulaire interne
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY modules/ modules/
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/modular-app.jar app.jar

# L'application contient tous les modules mais ils sont découplés
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Avantages :**
- Simplicité du déploiement monolithique
- Separation of concerns comme les microservices
- Transactions ACID possibles
- Migration progressive vers microservices facilitée
- Performance optimale (pas de latence réseau)

**Quand l'utiliser :**
- Équipe moyenne (5-20 développeurs)
- Domaine métier complexe mais pas énorme
- Besoin de transactions ACID
- Préparer une future migration microservices

### 4.2 Architecture Service-Oriented (SOA)

SOA est un ancêtre des microservices avec des services plus gros et un couplage plus fort.

**Différences avec Microservices :**
- Services plus larges (coarse-grained)
- Communication via ESB (Enterprise Service Bus)
- Partage de base de données possible
- Gouvernance centralisée
- Utilisation extensive de standards (SOAP, WSDL, XML)

**Architecture SOA typique :**
```
┌──────────────────────────────────────────┐
│         Enterprise Service Bus           │
│              (ESB - MuleSoft)            │
└────┬────────┬────────┬────────┬─────────┘
     │        │        │        │
┌────▼───┐ ┌──▼───┐ ┌──▼───┐ ┌──▼─────┐
│Service │ │Service│ │Service│ │Service │
│Gestion │ │Client │ │Produit│ │Facturation│
│Commande│ │       │ │       │ │        │
└────┬───┘ └──┬───┘ └──┬───┘ └──┬─────┘
     │        │        │        │
     └────────┴────────┴────────┘
              │
     ┌────────▼────────┐
     │  Base de Données│
     │    Partagée     │
     └─────────────────┘
```

**Docker et SOA :**
```yaml
version: '3.8'
services:
  esb:
    image: mulesoft/mule:latest
    ports:
      - "8081:8081"
    volumes:
      - ./esb-config:/opt/mule/apps
    networks:
      - soa-net

  order-service:
    build: ./services/order
    environment:
      - ESB_ENDPOINT=http://esb:8081
    networks:
      - soa-net

  customer-service:
    build: ./services/customer
    environment:
      - ESB_ENDPOINT=http://esb:8081
    networks:
      - soa-net

  shared-database:
    image: oracle-database:19c
    networks:
      - soa-net

networks:
  soa-net:
```

### 4.3 Architecture Serverless / FaaS

Les **fonctions as a service** poussent la granularité encore plus loin que les microservices.

**Caractéristiques :**
- Unité de déploiement = fonction
- Scaling automatique à zéro
- Pay-per-execution
- Stateless par nature
- Cold start challenge

**Exemple avec Docker (simulation locale) :**
```dockerfile
# Fonction de traitement de commande
FROM python:3.11-slim
WORKDIR /function
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY handler.py .

# AWS Lambda compatible
CMD ["python", "-c", "from handler import lambda_handler; import json; print(lambda_handler({'test': 'event'}, None))"]
```

```python
# handler.py
import json

def lambda_handler(event, context):
    """
    Fonction serverless de traitement de commande
    """
    order_data = json.loads(event['body'])
    
    # Logique métier minimaliste
    order_id = process_order(order_data)
    
    return {
        'statusCode': 200,
        'body': json.dumps({'orderId': order_id})
    }

def process_order(data):
    # Traitement de la commande
    return "ORDER-" + str(hash(str(data)))
```

**Docker Compose pour simulation serverless locale :**
```yaml
version: '3.8'
services:
  # Simuler AWS Lambda avec OpenFaaS
  gateway:
    image: openfaas/gateway:latest
    ports:
      - "8080:8080"
    environment:
      - functions_provider_url=http://faas-swarm:8080/
    networks:
      - functions

  process-order-function:
    build: ./functions/process-order
    labels:
      - "openfaas.function=process-order"
    environment:
      - fprocess=python handler.py
    networks:
      - functions

  send-notification-function:
    build: ./functions/send-notification
    labels:
      - "openfaas.function=send-notification"
    networks:
      - functions

networks:
  functions:
```

### 4.4 Architecture Hexagonale (Ports & Adapters)

L'architecture hexagonale isole la logique métier des préoccupations techniques.

**Structure :**
```
           ┌─────────────────────────┐
           │   Adapters Entrants     │
           │  (REST API, gRPC, CLI)  │
           └──────────┬──────────────┘
                      │
           ┌──────────▼──────────────┐
           │        Ports            │
           │    (Interfaces)         │
           └──────────┬──────────────┘
                      │
           ┌──────────▼──────────────┐
           │    Domain / Core        │
           │   (Business Logic)      │
           └──────────┬──────────────┘
                      │
           ┌──────────▼──────────────┐
           │        Ports            │
           │    (Interfaces)         │
           └──────────┬──────────────┘
                      │
           ┌──────────▼──────────────┐
           │   Adapters Sortants     │
           │  (DB, API, Message Bus) │
           └─────────────────────────┘
```

**Implémentation avec Docker :**
```dockerfile
# Multi-stage build pour architecture hexagonale
FROM golang:1.21 AS builder
WORKDIR /app

# Copier le domain (indépendant)
COPY domain/ domain/

# Copier les ports (interfaces)
COPY ports/ ports/

# Copier les adapters
COPY adapters/ adapters/

# Build
RUN go build -o app ./cmd/api

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/app .

# Configuration des adapters via env vars
ENV DB_ADAPTER=postgres
ENV MESSAGE_ADAPTER=rabbitmq
ENV HTTP_PORT=8080

EXPOSE 8080
CMD ["./app"]
```

**Avantages avec Docker :**
- Swap facile d'adapters via variables d'environnement
- Tests avec des mocks d'adapters
- Isolation parfaite du domain

### 4.5 Architecture Event-Driven

Architecture centrée sur les événements et la communication asynchrone.

**Architecture complète :**
```
┌──────────┐      ┌──────────┐      ┌──────────┐
│ Service  │      │ Service  │      │ Service  │
│ Commande │      │ Produit  │      │ Paiement │
└────┬─────┘      └────┬─────┘      └────┬─────┘
     │ publish         │ publish         │ publish
     │                 │                 │
     └─────────────────┼─────────────────┘
                       │
            ┌──────────▼──────────┐
            │   Event Store /     │
            │   Message Broker    │
            │   (Kafka / NATS)    │
            └──────────┬──────────┘
                       │
     ┌─────────────────┼─────────────────┐
     │ subscribe       │ subscribe       │ subscribe
     │                 │                 │
┌────▼─────┐      ┌────▼─────┐      ┌────▼─────┐
│ Service  │      │ Service  │      │ Service  │
│  Email   │      │Analytics │      │Inventory │
└──────────┘      └──────────┘      └──────────┘
```

**Docker Compose pour Event-Driven :**
```yaml
version: '3.8'

services:
  # Event Store
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
    depends_on:
      - zookeeper
    networks:
      - event-driven

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    networks:
      - event-driven

  # Event Producers
  order-service:
    build: ./services/order
    environment:
      - KAFKA_BROKERS=kafka:9092
      - EVENTS_TOPIC=orders
    depends_on:
      - kafka
    networks:
      - event-driven

  # Event Consumers
  email-service:
    build: ./services/email
    environment:
      - KAFKA_BROKERS=kafka:9092
      - CONSUME_TOPICS=orders,payments
      - CONSUMER_GROUP=email-service
    depends_on:
      - kafka
    networks:
      - event-driven
    deploy:
      replicas: 3  # Multiple consumers pour parallélisation

  analytics-service:
    build: ./services/analytics
    environment:
      - KAFKA_BROKERS=kafka:9092
      - CONSUME_TOPICS=orders,products,payments
      - CONSUMER_GROUP=analytics-service
    depends_on:
      - kafka
    networks:
      - event-driven

  # Event Store UI pour visualisation
  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    ports:
      - "8080:8080"
    environment:
      - KAFKA_CLUSTERS_0_NAME=local
      - KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=kafka:9092
    networks:
      - event-driven

networks:
  event-driven:
```

### 4.6 Architecture CQRS (Command Query Responsibility Segregation)

Séparer les opérations de lecture et d'écriture pour optimiser chacune.

**Architecture CQRS :**
```
                    ┌─────────────┐
                    │   Client    │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
         Commands                   Queries
              │                         │
    ┌─────────▼────────┐    ┌──────────▼───────┐
    │  Write Model     │    │   Read Model     │
    │  (Commands)      │    │   (Queries)      │
    │                  │    │                  │
    │  - Validation    │    │  - Projections   │
    │  - Business Logic│    │  - Denormalized  │
    │  - Persist Events│    │  - Optimized Read│
    └─────────┬────────┘    └──────────┬───────┘
              │                        │
              │ Events                 │
              │                        │
    ┌─────────▼────────┐               │
    │   Event Store    │───────────────┘
    │   (Write DB)     │   Projections
    └──────────────────┘
```

**Implémentation Docker :**
```yaml
version: '3.8'

services:
  # Write Side (Commands)
  command-service:
    build: ./services/command
    environment:
      - EVENT_STORE_URI=mongodb://event-store:27017
      - KAFKA_BROKERS=kafka:9092
    depends_on:
      - event-store
      - kafka
    networks:
      - cqrs-net

  # Event Store (Write Database)
  event-store:
    image: mongo:6
    volumes:
      - event-data:/data/db
    networks:
      - cqrs-net

  # Read Side (Queries) - multiple projections
  query-service-orders:
    build: ./services/query-orders
    environment:
      - READ_DB_URI=postgresql://read-db:5432/orders_view
      - KAFKA_BROKERS=kafka:9092
      - CONSUME_TOPICS=orders
    depends_on:
      - read-db
      - kafka
    networks:
      - cqrs-net

  query-service-analytics:
    build: ./services/query-analytics
    environment:
      - READ_DB_URI=postgresql://read-db:5432/analytics_view
      - KAFKA_BROKERS=kafka:9092
      - CONSUME_TOPICS=orders,products,payments
    depends_on:
      - read-db
      - kafka
    networks:
      - cqrs-net

  # Read Database (projections optimisées)
  read-db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: password
    volumes:
      - read-data:/var/lib/postgresql/data
    networks:
      - cqrs-net

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
    networks:
      - cqrs-net

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    networks:
      - cqrs-net

volumes:
  event-data:
  read-data:

networks:
  cqrs-net:
```

---

## 5. Docker et les Architectures {#docker}

### 5.1 Pourquoi Docker est essentiel aux architectures modernes

Docker transforme la manière de construire, déployer et gérer des applications, quelle que soit l'architecture choisie.

**Bénéfices universels :**

**Portabilité**
- "Works on my machine" résolu
- Même environnement dev/test/prod
- Migration facilitée entre clouds

**Isolation**
- Dépendances encapsulées
- Pas de conflits de versions
- Sécurité renforcée

**Efficience**
- Démarrage rapide (secondes vs minutes pour VM)
- Overhead minimal
- Densité élevée sur un hôte

**Reproductibilité**
- Infrastructure as Code
- Builds déterministes
- Rollback facile

### 5.2 Docker Images : Best Practices

**Multi-stage Builds**
```dockerfile
# Mauvaise pratique : image lourde avec outils de build
FROM node:18
WORKDIR /app
COPY . .
RUN npm install  # Installe aussi les devDependencies
RUN npm run build
CMD ["npm", "start"]
# Taille: ~1.2GB

# Bonne pratique : multi-stage pour image légère
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
EXPOSE 3000
CMD ["node", "dist/server.js"]
# Taille: ~150MB
```

**Optimisation des Layers**
```dockerfile
# Mauvaise pratique : layers inefficaces
FROM python:3.11
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt
# Chaque changement de code rebuild toutes les dépendances

# Bonne pratique : ordre optimisé
FROM python:3.11-slim
WORKDIR /app

# Layer de dépendances (change rarement)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Layer du code (change souvent)
COPY . .

EXPOSE 8000
CMD ["python", "app.py"]
# Les dépendances sont en cache si seul le code change
```

**Images de Base Appropriées**
```dockerfile
# Pour production : alpine (petite, sécurisée)
FROM python:3.11-alpine  # ~50MB
FROM node:18-alpine      # ~170MB
FROM golang:1.21-alpine  # ~300MB

# Pour développement : images complètes
FROM python:3.11         # ~900MB avec plus d'outils
FROM node:18             # ~1GB

# Images distroless (Google) : ultra-sécurisées, minimales
FROM gcr.io/distroless/python3  # Pas de shell, seulement runtime
```

**Security Best Practices**
```dockerfile
FROM node:18-alpine

# Créer un utilisateur non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Installer dépendances en tant que root
COPY package*.json ./
RUN npm ci --only=production

# Copier le code
COPY --chown=nodejs:nodejs . .

# Changer vers utilisateur non-root
USER nodejs

EXPOSE 3000
CMD ["node", "server.js"]
```

### 5.3 Docker Networking pour Architectures Distribuées

**Types de Networks Docker**

```bash
# Bridge (défaut) : isolation entre conteneurs
docker network create my-bridge-net

# Host : utilise le réseau de l'hôte directement
docker run --network=host my-app

# Overlay : communication entre hosts Docker Swarm/Kubernetes
docker network create --driver overlay my-overlay-net

# Macvlan : assigne une MAC address au conteneur
docker network create -d macvlan my-macvlan-net
```

**Service Discovery et DNS**
```yaml
version: '3.8'

services:
  frontend:
    image: my-frontend
    networks:
      - app-net
    environment:
      # Service discovery via DNS : nom du service = hostname
      - BACKEND_URL=http://backend:8080
      - DATABASE_URL=http://database:5432

  backend:
    image: my-backend
    networks:
      - app-net
    environment:
      - DATABASE_HOST=database  # Résolu par DNS interne
    depends_on:
      - database

  database:
    image: postgres:15
    networks:
      - app-net

networks:
  app-net:
    driver: bridge
```

**Network Isolation et Sécurité**
```yaml
version: '3.8'

services:
  frontend:
    image: my-frontend
    networks:
      - public-net
      - backend-net
    ports:
      - "80:80"  # Exposé publiquement

  backend:
    image: my-backend
    networks:
      - backend-net  # Pas sur public-net
      - database-net
    # Pas de ports exposés publiquement

  database:
    image: postgres:15
    networks:
      - database-net  # Réseau complètement isolé
    # Accessible uniquement par backend

networks:
  public-net:
    driver: bridge
  backend-net:
    driver: bridge
    internal: false
  database-net:
    driver: bridge
    internal: true  # Pas d'accès externe
```

### 5.4 Docker Volumes et Persistance

**Types de Volumes**

```yaml
version: '3.8'

services:
  app:
    image: my-app
    volumes:
      # Named volume : géré par Docker, persistent
      - app-data:/var/lib/app/data
      
      # Bind mount : lie un dossier hôte (dev)
      - ./src:/app/src
      
      # tmpfs : en mémoire, non-persistent
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 100M

volumes:
  app-data:  # Créé et géré par Docker
```

**Patterns de Persistance**

*Databases*
```yaml
services:
  postgres:
    image: postgres:15
    volumes:
      # Données persistées
      - postgres-data:/var/lib/postgresql/data
      
      # Scripts d'initialisation
      - ./init-scripts:/docker-entrypoint-initdb.d:ro
    
    environment:
      POSTGRES_PASSWORD: password

volumes:
  postgres-data:
    driver: local
```

*Configuration Management*
```yaml
services:
  app:
    image: my-app
    volumes:
      # Configuration en lecture seule
      - ./config/app.yaml:/etc/app/config.yaml:ro
      
      # Secrets
      - ./secrets:/run/secrets:ro
    
    environment:
      CONFIG_PATH: /etc/app/config.yaml
```

*Shared Storage entre Services*
```yaml
services:
  worker1:
    image: my-worker
    volumes:
      - shared-data:/data

  worker2:
    image: my-worker
    volumes:
      - shared-data:/data

  processor:
    image: my-processor
    volumes:
      - shared-data:/input:ro  # Lecture seule

volumes:
  shared-data:
```

### 5.5 Health Checks et Self-Healing

**Healthchecks dans Dockerfile**
```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY . .

EXPOSE 3000

# Healthcheck intégré
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node healthcheck.js || exit 1

CMD ["node", "server.js"]
```

```javascript
// healthcheck.js
const http = require('http');

const options = {
  host: 'localhost',
  port: 3000,
  path: '/health',
  timeout: 2000
};

const healthCheck = http.request(options, (res) => {
  console.log(`STATUS: ${res.statusCode}`);
  if (res.statusCode === 200) {
    process.exit(0);
  } else {
    process.exit(1);
  }
});

healthCheck.on('error', (err) => {
  console.error('ERROR:', err);
  process.exit(1);
});

healthCheck.end();
```

**Healthchecks dans Docker Compose**
```yaml
version: '3.8'

services:
  api:
    image: my-api
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

  database:
    image: postgres:15
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    
  worker:
    image: my-worker
    depends_on:
      database:
        condition: service_healthy  # Attend que DB soit healthy
      api:
        condition: service_started
```

### 5.6 Resource Management

**Limits et Reservations**
```yaml
version: '3.8'

services:
  high-priority:
    image: my-critical-service
    deploy:
      resources:
        limits:
          cpus: '2.0'      # Maximum 2 CPUs
          memory: 2048M    # Maximum 2GB RAM
        reservations:
          cpus: '1.0'      # Garantit au moins 1 CPU
          memory: 1024M    # Garantit au moins 1GB RAM

  low-priority:
    image: my-batch-service
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

**CPU Affinity et Pinning**
```yaml
services:
  latency-sensitive:
    image: my-app
    cpuset: "0,1"  # Utilise uniquement CPU 0 et 1
    cpu_shares: 1024  # Poids relatif pour partage CPU
```

### 5.7 Logging et Observabilité

**Configuration des Logs**
```yaml
version: '3.8'

services:
  app:
    image: my-app
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "service,environment"
        env: "APP_VERSION"

  app-with-fluentd:
    image: my-app
    logging:
      driver: "fluentd"
      options:
        fluentd-address: "fluentd:24224"
        tag: "docker.{{.Name}}"

  app-with-gelf:
    image: my-app
    logging:
      driver: "gelf"
      options:
        gelf-address: "udp://logstash:12201"
        tag: "my-app"
```

**Stack Observabilité Complète**
```yaml
version: '3.8'

services:
  # Application
  app:
    image: my-app
    environment:
      - PROMETHEUS_PORT=9090
      - JAEGER_AGENT_HOST=jaeger
    depends_on:
      - prometheus
      - jaeger
    networks:
      - monitoring

  # Métriques
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    networks:
      - monitoring

  # Logs
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - loki-data:/loki
    networks:
      - monitoring

  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./promtail-config.yml:/etc/promtail/config.yml
    networks:
      - monitoring

  # Tracing distribué
  jaeger:
    image: jaegertracing/all-in-one:latest
    environment:
      - COLLECTOR_ZIPKIN_HOST_PORT=:9411
    ports:
      - "5775:5775/udp"
      - "6831:6831/udp"
      - "6832:6832/udp"
      - "5778:5778"
      - "16686:16686"  # UI
      - "14268:14268"
      - "14250:14250"
      - "9411:9411"
    networks:
      - monitoring

volumes:
  prometheus-data:
  grafana-data:
  loki-data:

networks:
  monitoring:
```

---

## 6. Comparaisons et Choix d'Architecture {#comparaisons}

### 6.1 Matrice de Comparaison

| Critère | Monolithe | Monolithe Modulaire | Microservices | Serverless |
|---------|-----------|---------------------|---------------|------------|
| **Complexité initiale** | ⭐ Très faible | ⭐⭐ Faible | ⭐⭐⭐⭐ Élevée | ⭐⭐⭐ Moyenne |
| **Scalabilité** | ⭐⭐ Limitée | ⭐⭐⭐ Moyenne | ⭐⭐⭐⭐⭐ Excellente | ⭐⭐⭐⭐⭐ Excellente |
| **Performance** | ⭐⭐⭐⭐⭐ Excellente | ⭐⭐⭐⭐ Très bonne | ⭐⭐⭐ Moyenne | ⭐⭐ Variable |
| **Déploiement** | ⭐⭐⭐⭐⭐ Très simple | ⭐⭐⭐⭐ Simple | ⭐⭐ Complexe | ⭐⭐⭐⭐ Simple |
| **Coûts d'infrastructure** | ⭐⭐⭐⭐⭐ Faibles | ⭐⭐⭐⭐ Faibles | ⭐⭐ Élevés | ⭐⭐⭐⭐ Variables |
| **Résilience** | ⭐⭐ Faible | ⭐⭐⭐ Moyenne | ⭐⭐⭐⭐⭐ Excellente | ⭐⭐⭐⭐ Très bonne |
| **Flexibilité techno** | ⭐ Aucune | ⭐⭐ Limitée | ⭐⭐⭐⭐⭐ Totale | ⭐⭐⭐ Moyenne |
| **Courbe d'apprentissage** | ⭐⭐⭐⭐⭐ Facile | ⭐⭐⭐⭐ Facile | ⭐⭐ Difficile | ⭐⭐⭐ Moyenne |
| **Maintenance** | ⭐⭐ Difficile | ⭐⭐⭐ Moyenne | ⭐⭐⭐⭐ Bonne | ⭐⭐⭐⭐ Bonne |
| **Time-to-market** | ⭐⭐⭐⭐⭐ Rapide | ⭐⭐⭐⭐ Rapide | ⭐⭐ Lent | ⭐⭐⭐⭐ Rapide |

### 6.2 Arbre de Décision

```
Nouvelle application ?
│
├─ OUI
│  │
│  ├─ Équipe < 5 personnes ?
│  │  │
│  │  ├─ OUI → MONOLITHE (avec Docker)
│  │  │
│  │  └─ NON
│  │     │
│  │     ├─ Domaine simple ?
│  │     │  │
│  │     │  ├─ OUI → MONOLITHE MODULAIRE
│  │     │  │
│  │     │  └─ NON
│  │     │     │
│  │     │     ├─ Budget DevOps suffisant ?
│  │     │     │  │
│  │     │     │  ├─ OUI → MICROSERVICES
│  │     │     │  │
│  │     │     │  └─ NON → MONOLITHE MODULAIRE
│  │     │
│  │     └─ Charges variables/imprévisibles ?
│  │        │
│  │        └─ OUI → Considérer SERVERLESS
│
└─ NON (Application existante)
   │
   ├─ Monolithe actuel ingérable ?
   │  │
   │  ├─ OUI
   │  │  │
   │  │  ├─ Migration progressive possible ?
   │  │  │  │
   │  │  │  ├─ OUI → Strangler Pattern vers microservices
   │  │  │  │
   │  │  │  └─ NON → Refactor en monolithe modulaire d'abord
   │  │
   │  └─ NON → Garder le monolithe, améliorer avec Docker
```

### 6.3 Patterns de Migration

**Du Monolithe aux Microservices : Strangler Pattern**

```
Phase 1: Identification
Monolithe ─────────────┐
│ Module A            │
│ Module B            │  Identifier les limites
│ Module C            │  des bounded contexts
│ Module D            │
└─────────────────────┘

Phase 2: Extraction progressive
Monolithe ─────────────┐       ┌──────────────┐
│ Module A            │       │ Microservice │
│ Module B            │◄──────┤  Module C    │
│ Module D            │       │  (Docker)    │
└─────────────────────┘       └──────────────┘

Phase 3: Migration complète
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│Microservice  │  │Microservice  │  │Microservice  │
│  Module A    │  │  Module C    │  │  Module D    │
└──────────────┘  └──────────────┘  └──────────────┘
```

**Exemple Docker pour Strangler Pattern :**
```yaml
version: '3.8'

services:
  # Monolithe existant
  legacy-app:
    image: legacy-monolith:latest
    networks:
      - app-net
    environment:
      - FEATURE_MODULE_C_ENABLED=false  # Désactivé, externalisé

  # Nouveau microservice extrait
  module-c-service:
    build: ./services/module-c
    networks:
      - app-net
    depends_on:
      - module-c-db

  module-c-db:
    image: postgres:15
    networks:
      - app-net

  # Proxy qui route selon le chemin
  nginx-router:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx-strangler.conf:/etc/nginx/nginx.conf:ro
    networks:
      - app-net
    depends_on:
      - legacy-app
      - module-c-service

networks:
  app-net:
```

```nginx
# nginx-strangler.conf
http {
    upstream legacy {
        server legacy-app:8080;
    }
    
    upstream module_c {
        server module-c-service:8080;
    }
    
    server {
        listen 80;
        
        # Routes vers le nouveau microservice
        location /api/module-c/ {
            proxy_pass http://module_c;
        }
        
        # Tout le reste vers le monolithe
        location / {
            proxy_pass http://legacy;
        }
    }
}
```

### 6.4 Anti-Patterns à Éviter

**Distributed Monolith**
❌ Créer des microservices trop couplés
```
Service A ──(API)──► Service B ──(API)──► Service C
   │                    │                    │
   └────────(DB)────────┴────────(DB)────────┘
   Partage de base de données = pas de vrais microservices
```

**Micro-Frontend Chaos**
❌ Décomposer le frontend exactement comme le backend
```
Frontend A  Frontend B  Frontend C
    │           │           │
Service A   Service B   Service C
```
✅ Mieux : Frontend cohérent avec BFF (Backend For Frontend)

**Nanoservices**
❌ Services trop petits et trop nombreux
```
UserNameService, UserEmailService, UserPhoneService...
→ Overhead de communication >> Valeur ajoutée
```

**Prematurely Breaking Up**
❌ Décomposer avant de comprendre le domaine
```
Jour 1: "Faisons des microservices !"
Jour 30: "Ces services sont au mauvais endroit..."
Jour 60: "On regroupe tout ?"
```
✅ Mieux : Commencer monolithe, décomposer quand les limites sont claires

---

## 7. Patterns et Bonnes Pratiques {#patterns}

### 7.1 API Gateway Pattern

L'API Gateway est le point d'entrée unique pour tous les clients.

**Responsabilités :**
- Routing des requêtes
- Authentification et autorisation
- Rate limiting
- Load balancing
- Transformation des requêtes/réponses
- Caching
- Logging et monitoring

**Implémentation avec Kong et Docker :**
```yaml
version: '3.8'

services:
  # API Gateway
  kong:
    image: kong:3.4-alpine
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: kong-db
      KONG_PG_PASSWORD: kong
      KONG_PROXY_ACCESS_LOG: /dev/stdout
      KONG_ADMIN_ACCESS_LOG: /dev/stdout
      KONG_PROXY_ERROR_LOG: /dev/stderr
      KONG_ADMIN_ERROR_LOG: /dev/stderr
      KONG_ADMIN_LISTEN: 0.0.0.0:8001
    ports:
      - "8000:8000"  # Proxy
      - "8443:8443"  # Proxy SSL
      - "8001:8001"  # Admin API
    networks:
      - kong-net
    depends_on:
      - kong-db

  kong-db:
    image: postgres:15
    environment:
      POSTGRES_USER: kong
      POSTGRES_DB: kong
      POSTGRES_PASSWORD: kong
    volumes:
      - kong-data:/var/lib/postgresql/data
    networks:
      - kong-net

  # Microservices derrière le gateway
  user-service:
    build: ./services/user
    networks:
      - kong-net

  order-service:
    build: ./services/order
    networks:
      - kong-net

  product-service:
    build: ./services/product
    networks:
      - kong-net

volumes:
  kong-data:

networks:
  kong-net:
```

**Configuration Kong (via Admin API) :**
```bash
# Ajouter les services
curl -i -X POST http://localhost:8001/services/ \
  --data "name=user-service" \
  --data "url=http://user-service:8080"

# Ajouter les routes
curl -i -X POST http://localhost:8001/services/user-service/routes \
  --data "paths[]=/api/users"

# Ajouter des plugins (rate limiting)
curl -i -X POST http://localhost:8001/services/user-service/plugins \
  --data "name=rate-limiting" \
  --data "config.minute=100"

# Ajouter authentification JWT
curl -i -X POST http://localhost:8001/services/user-service/plugins \
  --data "name=jwt"
```

### 7.2 Service Mesh Pattern

Service Mesh gère la communication inter-services (observabilité, sécurité, résilience).

**Istio avec Docker (simulation) :**
```yaml
version: '3.8'

services:
  # Envoy Proxy (sidecar) pour chaque service
  user-service:
    build: ./services/user
    networks:
      - mesh

  user-service-proxy:
    image: envoyproxy/envoy:v1.28-latest
    volumes:
      - ./envoy/user-service.yaml:/etc/envoy/envoy.yaml
    networks:
      - mesh
    command: /usr/local/bin/envoy -c /etc/envoy/envoy.yaml

  order-service:
    build: ./services/order
    networks:
      - mesh

  order-service-proxy:
    image: envoyproxy/envoy:v1.28-latest
    volumes:
      - ./envoy/order-service.yaml:/etc/envoy/envoy.yaml
    networks:
      - mesh

networks:
  mesh:
```

**Bénéfices du Service Mesh :**
- Retry automatique
- Circuit breaking
- Mutual TLS (mTLS)
- Distributed tracing
- Metrics automatiques
- Traffic splitting (A/B testing, canary)

### 7.3 Circuit Breaker Pattern

Prévient les cascades de pannes.

**Implémentation avec Resilience4j (Java) :**
```java
// Dockerfile
FROM eclipse-temurin:17-jre-alpine
COPY target/app-with-circuitbreaker.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]

// Code Java
@Service
public class OrderService {
    
    private final CircuitBreakerRegistry circuitBreakerRegistry;
    private final ProductServiceClient productClient;
    
    @CircuitBreaker(name = "productService", fallbackMethod = "fallbackGetProduct")
    public Product getProduct(String productId) {
        return productClient.getProduct(productId);
    }
    
    // Méthode de fallback si circuit ouvert
    public Product fallbackGetProduct(String productId, Exception e) {
        log.warn("Circuit breaker activated for product: {}", productId, e);
        // Retourner données en cache ou réponse par défaut
        return Product.defaultProduct(productId);
    }
}
```

**Configuration :**
```yaml
# application.yml
resilience4j:
  circuitbreaker:
    instances:
      productService:
        slidingWindowSize: 10
        minimumNumberOfCalls: 5
        failureRateThreshold: 50
        waitDurationInOpenState: 10s
        permittedNumberOfCallsInHalfOpenState: 3
```

### 7.4 Retry Pattern

**Avec exponentiel backoff :**
```python
# Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "service.py"]

# service.py
import time
import requests
from tenacity import retry, stop_after_attempt, wait_exponential

class PaymentService:
    
    @retry(
        stop=stop_after_attempt(5),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        reraise=True
    )
    def process_payment(self, payment_data):
        """
        Retry avec backoff exponentiel:
        Tentative 1: immédiat
        Tentative 2: attendre 1s
        Tentative 3: attendre 2s
        Tentative 4: attendre 4s
        Tentative 5: attendre 8s
        """
        response = requests.post(
            'http://payment-gateway:8080/charge',
            json=payment_data,
            timeout=5
        )
        response.raise_for_status()
        return response.json()
```

### 7.5 Saga Pattern pour Transactions Distribuées

**Saga Chorégraphiée (Event-Driven) :**
```yaml
# docker-compose-saga.yml
version: '3.8'

services:
  order-service:
    build: ./services/order
    environment:
      - KAFKA_BROKERS=kafka:9092
    networks:
      - saga-net

  payment-service:
    build: ./services/payment
    environment:
      - KAFKA_BROKERS=kafka:9092
    networks:
      - saga-net

  inventory-service:
    build: ./services/inventory
    environment:
      - KAFKA_BROKERS=kafka:9092
    networks:
      - saga-net

  shipping-service:
    build: ./services/shipping
    environment:
      - KAFKA_BROKERS=kafka:9092
    networks:
      - saga-net

  kafka:
    image: confluentinc/cp-kafka:latest
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
    networks:
      - saga-net

  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    networks:
      - saga-net

networks:
  saga-net:
```

**Flow de la Saga :**
```
1. OrderService: CreateOrder → Event: OrderCreated
2. PaymentService: Écoute OrderCreated → ProcessPayment → Event: PaymentProcessed
3. InventoryService: Écoute PaymentProcessed → ReserveItems → Event: ItemsReserved
4. ShippingService: Écoute ItemsReserved → ScheduleShipment → Event: ShipmentScheduled

En cas d'échec:
X. InventoryService: Échec → Event: ItemsReservationFailed
X. PaymentService: Écoute ItemsReservationFailed → RefundPayment → Event: PaymentRefunded
X. OrderService: Écoute PaymentRefunded → CancelOrder → Event: OrderCancelled
```

### 7.6 Sidecar Pattern

Conteneur auxiliaire qui étend les fonctionnalités du conteneur principal.

```yaml
version: '3.8'

services:
  # Application principale
  web-app:
    image: my-web-app
    volumes:
      - app-logs:/var/log/app
    networks:
      - app-net

  # Sidecar: Log aggregator
  log-sidecar:
    image: fluent/fluent-bit:latest
    volumes:
      - app-logs:/var/log/app:ro  # Lecture des logs de l'app
      - ./fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf
    networks:
      - app-net

  # Sidecar: Metrics exporter
  metrics-sidecar:
    image: prom/node-exporter:latest
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
    networks:
      - app-net

volumes:
  app-logs:

networks:
  app-net:
```

### 7.7 Database per Service avec Shared Data

**Event-Driven Data Replication :**
```yaml
version: '3.8'

services:
  # Service propriétaire des données
  user-service:
    build: ./services/user
    environment:
      - DB_URI=postgresql://user-db:5432/users
      - KAFKA_BROKERS=kafka:9092
    networks:
      - data-net

  user-db:
    image: postgres:15
    environment:
      POSTGRES_DB: users
      POSTGRES_PASSWORD: password
    volumes:
      - user-data:/var/lib/postgresql/data
    networks:
      - data-net

  # Service consommateur (read-only replica)
  order-service:
    build: ./services/order
    environment:
      - DB_URI=postgresql://order-db:5432/orders
      - USER_READ_DB_URI=postgresql://user-replica-db:5432/user_view
      - KAFKA_BROKERS=kafka:9092
    networks:
      - data-net

  order-db:
    image: postgres:15
    environment:
      POSTGRES_DB: orders
    volumes:
      - order-data:/var/lib/postgresql/data
    networks:
      - data-net

  # Base de données répliquée (projection)
  user-replica-db:
    image: postgres:15
    environment:
      POSTGRES_DB: user_view
    volumes:
      - user-replica-data:/var/lib/postgresql/data
    networks:
      - data-net

  # Service de synchronisation
  data-sync-service:
    build: ./services/data-sync
    environment:
      - KAFKA_BROKERS=kafka:9092
      - TARGET_DB=postgresql://user-replica-db:5432/user_view
    networks:
      - data-net

  kafka:
    image: confluentinc/cp-kafka:latest
    networks:
      - data-net

volumes:
  user-data:
  order-data:
  user-replica-data:

networks:
  data-net:
```

---

## 8. Cas Pratiques {#cas-pratiques}

### 8.1 E-Commerce Microservices complet

**Architecture :**
```
                    ┌──────────────┐
                    │ API Gateway  │
                    │   (Kong)     │
                    └──────┬───────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐      ┌──────▼──────┐    ┌─────▼──────┐
   │ Product │      │   Order     │    │  Payment   │
   │ Service │      │   Service   │    │  Service   │
   │ (Java)  │      │  (Node.js)  │    │  (Python)  │
   └────┬────┘      └──────┬──────┘    └─────┬──────┘
        │                  │                  │
   ┌────▼────┐      ┌──────▼──────┐    ┌─────▼──────┐
   │Postgres │      │   MongoDB   │    │   Redis    │
   └─────────┘      └─────────────┘    └────────────┘
        │                  │                  │
        └──────────────────┴──────────────────┘
                           │
                    ┌──────▼──────┐
                    │    Kafka    │
                    └─────────────┘
```

**Fichier docker-compose.yml complet :**
```yaml
version: '3.8'

services:
  # ======================
  # Infrastructure
  # ======================
  
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_MULTIPLE_DATABASES: products,inventory,analytics
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init-scripts/postgres:/docker-entrypoint-initdb.d
    networks:
      - ecommerce-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  mongodb:
    image: mongo:6
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password
    volumes:
      - mongo-data:/data/db
    networks:
      - ecommerce-net
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - ecommerce-net
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    networks:
      - ecommerce-net

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
    networks:
      - ecommerce-net
    healthcheck:
      test: ["CMD", "kafka-broker-api-versions", "--bootstrap-server=localhost:9092"]
      interval: 30s
      timeout: 10s
      retries: 5

  # ======================
  # API Gateway
  # ======================
  
  kong-database:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: kong
      POSTGRES_DB: kong
      POSTGRES_PASSWORD: kong
    volumes:
      - kong-data:/var/lib/postgresql/data
    networks:
      - ecommerce-net
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "kong"]
      interval: 10s
      timeout: 5s
      retries: 5

  kong-migration:
    image: kong:3.4-alpine
    command: kong migrations bootstrap
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: kong-database
      KONG_PG_PASSWORD: kong
    depends_on:
      kong-database:
        condition: service_healthy
    networks:
      - ecommerce-net

  kong:
    image: kong:3.4-alpine
    depends_on:
      kong-migration:
        condition: service_completed_successfully
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: kong-database
      KONG_PG_PASSWORD: kong
      KONG_PROXY_ACCESS_LOG: /dev/stdout
      KONG_ADMIN_ACCESS_LOG: /dev/stdout
      KONG_PROXY_ERROR_LOG: /dev/stderr
      KONG_ADMIN_ERROR_LOG: /dev/stderr
      KONG_ADMIN_LISTEN: 0.0.0.0:8001
    ports:
      - "8000:8000"
      - "8443:8443"
      - "8001:8001"
    networks:
      - ecommerce-net
    healthcheck:
      test: ["CMD", "kong", "health"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ======================
  # Microservices
  # ======================
  
  product-service:
    build:
      context: ./services/product-service
      dockerfile: Dockerfile
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/products
      - SPRING_DATASOURCE_USERNAME=postgres
      - SPRING_DATASOURCE_PASSWORD=postgres
      - KAFKA_BOOTSTRAP_SERVERS=kafka:9092
      - SERVER_PORT=8080
    depends_on:
      postgres:
        condition: service_healthy
      kafka:
        condition: service_healthy
    networks:
      - ecommerce-net
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  order-service:
    build:
      context: ./services/order-service
      dockerfile: Dockerfile
    environment:
      - MONGO_URI=mongodb://admin:password@mongodb:27017/orders?authSource=admin
      - KAFKA_BROKERS=kafka:9092
      - PRODUCT_SERVICE_URL=http://product-service:8080
      - PAYMENT_SERVICE_URL=http://payment-service:5000
      - PORT=3000
    depends_on:
      mongodb:
        condition: service_healthy
      kafka:
        condition: service_healthy
    networks:
      - ecommerce-net
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  payment-service:
    build:
      context: ./services/payment-service
      dockerfile: Dockerfile
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - KAFKA_BROKERS=kafka:9092
      - STRIPE_API_KEY=${STRIPE_API_KEY}
      - PORT=5000
    depends_on:
      redis:
        condition: service_healthy
      kafka:
        condition: service_healthy
    networks:
      - ecommerce-net
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.25'
          memory: 256M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  inventory-service:
    build:
      context: ./services/inventory-service
      dockerfile: Dockerfile
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/inventory
      - KAFKA_BROKERS=kafka:9092
      - PORT=8081
    depends_on:
      postgres:
        condition: service_healthy
      kafka:
        condition: service_healthy
    networks:
      - ecommerce-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  notification-service:
    build:
      context: ./services/notification-service
      dockerfile: Dockerfile
    environment:
      - KAFKA_BROKERS=kafka:9092
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=${SMTP_PORT}
      - SMTP_USER=${SMTP_USER}
      - SMTP_PASS=${SMTP_PASS}
    depends_on:
      kafka:
        condition: service_healthy
    networks:
      - ecommerce-net
    deploy:
      replicas: 1

  # ======================
  # Observability
  # ======================
  
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - ecommerce-net
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'

  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
    ports:
      - "3001:3000"
    depends_on:
      - prometheus
    networks:
      - ecommerce-net

  jaeger:
    image: jaegertracing/all-in-one:latest
    environment:
      - COLLECTOR_ZIPKIN_HOST_PORT=:9411
    ports:
      - "5775:5775/udp"
      - "6831:6831/udp"
      - "6832:6832/udp"
      - "5778:5778"
      - "16686:16686"
      - "14268:14268"
      - "14250:14250"
      - "9411:9411"
    networks:
      - ecommerce-net

volumes:
  postgres-data:
  mongo-data:
  redis-data:
  kong-data:
  prometheus-data:
  grafana-data:

networks:
  ecommerce-net:
    driver: bridge
```

**Commandes de gestion :**
```bash
# Démarrer tous les services
docker-compose up -d

# Scaler un service spécifique
docker-compose up -d --scale product-service=5

# Voir les logs d'un service
docker-compose logs -f order-service

# Redémarrer un service
docker-compose restart payment-service

# Voir l'état des services
docker-compose ps

# Arrêter tout
docker-compose down

# Arrêter et supprimer les volumes
docker-compose down -v
```

### 8.2 Migration Progressive d'un Monolithe

**Phase 1 : Monolithe Dockerisé**
```dockerfile
# Dockerfile.monolith
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/monolith.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Phase 2 : Extraction du premier service**
```yaml
version: '3.8'

services:
  # Monolithe original (désactive module utilisateur)
  legacy-monolith:
    build:
      context: .
      dockerfile: Dockerfile.monolith
    environment:
      - USER_MODULE_EXTERNAL=true
      - USER_SERVICE_URL=http://user-service:8080
    ports:
      - "8080:8080"
    networks:
      - migration-net

  # Nouveau microservice Utilisateurs
  user-service:
    build: ./services/user
    environment:
      - DB_URL=postgresql://user-db:5432/users
    depends_on:
      - user-db
    networks:
      - migration-net

  user-db:
    image: postgres:15
    environment:
      POSTGRES_DB: users
      POSTGRES_PASSWORD: password
    volumes:
      - user-data:/var/lib/postgresql/data
    networks:
      - migration-net

  # Proxy pour router progressivement
  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx-migration.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "80:80"
    depends_on:
      - legacy-monolith
      - user-service
    networks:
      - migration-net

volumes:
  user-data:

networks:
  migration-net:
```

**Configuration Nginx pour migration progressive :**
```nginx
# nginx-migration.conf
http {
    upstream monolith {
        server legacy-monolith:8080;
    }
    
    upstream user_service {
        server user-service:8080;
    }
    
    # Split traffic: 90% monolith, 10% nouveau service (canary)
    split_clients "${remote_addr}" $backend {
        10%     user_service;
        *       monolith;
    }
    
    server {
        listen 80;
        
        location /api/users/ {
            # Router vers le backend sélectionné
            proxy_pass http://$backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location / {
            # Tout le reste vers le monolithe
            proxy_pass http://monolith;
        }
    }
}
```

### 8.3 Application Serverless Simulée

```yaml
version: '3.8'

services:
  # Simuler AWS Lambda avec OpenFaaS
  gateway:
    image: openfaas/gateway:latest
    ports:
      - "8080:8080"
    environment:
      - functions_provider_url=http://faasd:8080/
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    networks:
      - functions

  # Fonction: Resize d'image
  image-resize:
    build: ./functions/image-resize
    labels:
      - "openfaas.function=image-resize"
    environment:
      - fprocess=python handler.py
      - read_timeout=60
      - write_timeout=60
    networks:
      - functions

  # Fonction: Envoi d'email
  send-email:
    build: ./functions/send-email
    labels:
      - "openfaas.function=send-email"
    environment:
      - fprocess=node index.js
    networks:
      - functions

  # Fonction: Traitement de paiement
  process-payment:
    build: ./functions/process-payment
    labels:
      - "openfaas.function=process-payment"
    environment:
      - fprocess=python handler.py
    networks:
      - functions

networks:
  functions:
```

---

## Conclusion

Ce cours a couvert en profondeur les architectures logicielles modernes et leur relation avec Docker :

1. **Monolithique** : Simple et efficace pour débuter, dockerisable facilement
2. **Microservices** : Flexibilité maximale, nécessite Docker/Kubernetes
3. **Alternatives** : Modulaire, SOA, Serverless, Event-Driven, CQRS
4. **Docker** : Technologie essentielle, facilitateur d'architectures modernes
5. **Patterns** : Solutions éprouvées aux défis architecturaux
6. **Migration** : Approche progressive du monolithe aux microservices

**Recommandations finales :**

- Commencer simple (monolithe) et évoluer selon les besoins
- Dockeriser dès le début pour faciliter les évolutions futures
- Ne pas suivre aveuglément les tendances (microservices ne sont pas toujours la solution)
- Investir dans l'observabilité et l'automatisation
- Prioriser la valeur métier sur la complexité technique
- Itérer et apprendre de ses erreurs

Le choix d'architecture doit toujours être guidé par les besoins réels du projet, les contraintes de l'équipe, et les objectifs business, jamais par la mode technologique du moment.