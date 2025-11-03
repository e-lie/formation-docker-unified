---
title: "TP: Mettre en oeuvre une CI/CD Docker+Gitlab"
description: "Guide TP: Mettre en oeuvre une CI/CD Docker+Gitlab"
sidebar:
  order: 312
---


## Rappel sur la CI/CD

La CI/CD fait partie du DevOps (la fusion des équipes de développement et d'exploitation) et combine les pratiques de l'intégration continue et de la livraison continue. La CI/CD réduit le travail de développement fastidieux et les processus d'approbation manuels, libérant ainsi les équipes pour plus d'efficacité dans leur développement logiciel.

- L'automatisation rend les processus prévisibles et reproductibles, réduisant ainsi les possibilités d'erreurs dues à l'intervention humaine.

- Les équipes obtiennent des retours plus rapides et peuvent intégrer plus fréquemment de petites modifications pour réduire le risque de modifications pouvant perturber le build et le déploiment.

La continuité et l'itération des processus DevOps **accélèrent les cycles de développement logiciels**, permettant ainsi aux organisations de livrer davantage de fonctionnalités.

### L'intégration continue (CI)

L'intégration continue est la pratique qui consiste à intégrer tous les changements de code dans la branche principale d'un code source partagé **tôt et souvent**, en testant automatiquement chaque changement lors de leur validation ou de leur fusion, et en lançant automatiquement un build.

Avec l'intégration continue, les erreurs et les problèmes de sécurité peuvent être identifiés et corrigés plus facilement, et beaucoup plus tôt dans le processus de développement. En "mergeant" fréquemment des changements et en déclenchant des processus de test et de validation automatiques, on minimise la possibilité de conflits de code. Un avantage secondaire est que vous n'avez pas à attendre longtemps pour obtenir des réponses sur la qualité et sécurité de votre code.

Les processus courants de validation du code commencent par une analyse de code statique qui vérifie la qualité du code. Une fois que le code passe les tests statiques, les routines CI automatisées empaquettent et compilent le code pour des tests automatisés supplémentaires. Une CI doit disposer d'un système de gestion de version qui suit les changements afin que vous connaissiez précisément la version du code utilisée.

### La livraison continue (continuous delivery) ?

La livraison continue est une pratique de développement logiciel qui fonctionne en conjonction avec la CI pour automatiser le provisionnement de l'infrastructure et le processus de mise en production de l'application.

Une fois que le code a été testé et buildé dans le cadre du processus CI, la CD prend le relais lors des dernières étapes pour s'assurer qu'il est packagé avec tout ce dont il a besoin pour être déployé dans n'importe quel environnement. Avec la CD, le logiciel est construit de manière à pouvoir être déployé en production à tout moment. Ensuite, vous pouvez déclencher manuellement les déploiements ou passer au déploiement continu, où les déploiements sont également automatisés.

### Qu'est-ce que le déploiement continu (continuous deployment) ?

Le déploiement continu permet aux organisations de déployer automatiquement leurs applications, éliminant ainsi le besoin d'intervention humaine. Avec cette méthode, les équipes DevOps définissent à l'avance les critères de mise en production du code, et lorsque ces critères sont satisfaits et validés, le code est déployé dans l'environnement de production. Cela permet aux organisations d'être plus agiles et de mettre de nouvelles fonctionnalités entre les mains des utilisateurs plus rapidement.

### Pourquoi Docker est central pour la CI ?

- Les pipelines d'automatisation doivent tourner dans un environnement contrôlé qui contient toutes les dépendances nécessaires
- Historiquement avec par exemple Jenkins on utilisait des serveurs dédiés "fixes" provisionnés avec les dépendances nécessaires au boulot des pipelines.

Le problème c'est que cette approche ne permet pas de facilement et économiquement répondre à la charge de calcul nécessaire pour une équipe de dev:

- Typiquement les membres d'une équipe pushent leur code aux même moments de la journée : engorgement de la CI/CD et temps d'attente important.
- Si on prévoit beaucoup de serveurs fixes pour de pipelines pour éviter cela c'est cher et on les utilise seulement une fraction du temps

Autre problème, installer et maintenir les serveurs dédiés peut représenter beaucoup de travail.

- Docker/les conteneurs permettent de lancer des conteneurs dans un cloud (plus dynamique/scalable) pour effectuer les jobs de CI/CD : cela permet avoir des pipelines à la demande.
- Cela permet aussi d'avoir plus facilement une reproductibilité des environnements de CI/CD et peut faciliter l'installation : par exemple pour une application maven on prend un conteneur maven officiel du Docker Hub et une grosse partie du travail est fait par d'autres et facile pour les mises à jour.

- C'est l'approche de Gitlab qui fournit du pipeline as a service par défault basé sur un cloud de conteneur.
- Jenkins installé avec le plugin Docker ou Kubernetes permet également d'utiliser des conteneurs pour les différentes étapes (stages) d'un pipeline.

<!-- ### Pourquoi Kubernetes ?

- Kubernetes est le cloud de conteneurs open source de référence il est donc très **adapté au déploiement d'un système de pipeline à la demande** (par exemple des Gitlab Runners ou le plugin Kubernetes de Jenkins) pour faire l'intégration et la livraison continue (les deux premières étapes de la CI/CD).

- Kubernetes introduit le déploiement déclaratif qui simplifie, standardise et rend reproductible le déploiement d'applications conteneurisées : k8s est recommmandé pour faciliter un déploiement complètement automatique (continuous deployment) proposant un système de modification atomique fiable d'applications complexe (idéalement adaptées à l'architecture microservice/ cloud native).

- K8s propose des fonctionnalités d'authorisation (RBAC, network policies, etc...) qui permettent de bien sécuriser l'infrastructure de CI/CD. -->

### Présentation de Gitlab CI/CD

GitLab CI/CD est une plateforme intégrée d'intégration et de déploiement continu qui permet d'automatiser la construction, le test et le déploiement de vos applications directement depuis votre dépôt GitLab.

#### Concepts clés de GitLab CI/CD

**1. Le fichier `.gitlab-ci.yml`**

C'est le fichier de configuration central qui définit votre pipeline CI/CD. Il doit être placé à la racine de votre dépôt. GitLab détecte automatiquement ce fichier et exécute le pipeline à chaque commit.

**2. Les Runners**

Les runners sont des agents qui exécutent les jobs définis dans votre pipeline :
- **Shared runners** : Fournis automatiquement par GitLab.com (gratuits avec des limites)
- **Specific runners** : Installés sur vos propres serveurs pour plus de contrôle et de ressources

**3. Les Pipelines**

Un pipeline est une collection de jobs organisés en stages qui s'exécutent automatiquement. GitLab affiche visuellement l'état du pipeline avec chaque commit.

**4. Les Stages**

Les stages définissent l'ordre d'exécution des jobs :
- Les jobs d'un même stage s'exécutent **en parallèle** (si des runners sont disponibles)
- Les stages s'exécutent **séquentiellement** (un stage ne démarre que si le précédent réussit)
- Stages par défaut : `build` → `test` → `deploy`

**5. Les Jobs**

Les jobs sont les unités de travail fondamentales qui contiennent :
- `script` : Les commandes à exécuter (attribut obligatoire)
- `stage` : Le stage auquel appartient le job
- `image` : L'image Docker à utiliser pour l'exécution
- `services` : Services Docker supplémentaires (bases de données, etc.)

#### Structure de base d'un `.gitlab-ci.yml`

```yaml
# Définition des stages (optionnel, valeurs par défaut : build, test, deploy)
stages:
  - build
  - test
  - deploy

# Job de build
build-job:
  stage: build
  image: node:20-alpine
  script:
    - echo "Compilation de l'application..."
    - npm install
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour

# Jobs de test (s'exécutent en parallèle)
test-job1:
  stage: test
  image: node:20-alpine
  script:
    - echo "Exécution des tests unitaires"
    - npm run test:unit

test-job2:
  stage: test
  image: node:20-alpine
  script:
    - echo "Exécution des tests d'intégration"
    - npm run test:integration

# Job de déploiement
deploy-prod:
  stage: deploy
  image: docker:cli
  script:
    - echo "Déploiement en production depuis $CI_COMMIT_BRANCH"
    - docker build -t mon-app:$CI_COMMIT_SHA .
    - docker push mon-app:$CI_COMMIT_SHA
  environment: production
  only:
    - main
```

#### Options avancées essentielles

**Variables d'environnement**

GitLab fournit automatiquement de nombreuses variables prédéfinies :

```yaml
variables:
  # Variables globales
  DATABASE_URL: "postgres://localhost/test"

job-example:
  script:
    - echo "Branch: $CI_COMMIT_BRANCH"
    - echo "Commit SHA: $CI_COMMIT_SHA"
    - echo "Registry: $CI_REGISTRY"
```

**Règles d'exécution conditionnelle**

```yaml
deploy-staging:
  stage: deploy
  script:
    - echo "Déploiement en staging"
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
    - if: $CI_MERGE_REQUEST_ID  # S'exécute aussi sur les MR

deploy-production:
  stage: deploy
  script:
    - echo "Déploiement en production"
  rules:
    - if: $CI_COMMIT_TAG  # Seulement sur les tags
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual  # Requiert validation manuelle
```

**Cache et Artifacts**

- **Cache** : Accélère les builds en réutilisant les dépendances entre pipelines
- **Artifacts** : Transfère des fichiers entre jobs d'un même pipeline

```yaml
build-job:
  stage: build
  script:
    - npm install
    - npm run build
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/  # Cache réutilisé entre pipelines
  artifacts:
    paths:
      - dist/  # Transmis aux jobs suivants
    expire_in: 1 day

test-job:
  stage: test
  script:
    - npm run test  # Utilise dist/ du job précédent
  dependencies:
    - build-job
```

**Needs : Optimisation des pipelines**

Par défaut, les jobs attendent que tous les jobs du stage précédent soient terminés. `needs` permet de définir des dépendances spécifiques :

```yaml
stages:
  - build
  - test
  - deploy

build-frontend:
  stage: build
  script:
    - npm run build:frontend

build-backend:
  stage: build
  script:
    - npm run build:backend

test-frontend:
  stage: test
  needs: [build-frontend]  # Démarre dès que build-frontend termine
  script:
    - npm run test:frontend

deploy-all:
  stage: deploy
  needs: [test-frontend, build-backend]
  script:
    - ./deploy.sh
```

**Docker in Docker (DinD)**

Pour construire des images Docker dans GitLab CI :

```yaml
build-image:
  stage: build
  image: docker:cli
  services:
    - docker:dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

#### Bonnes pratiques GitLab CI/CD

1. **Commencer simple** : Un pipeline basique avec build → test → deploy
2. **Utiliser des images Docker légères** : `alpine` ou `slim` pour accélérer
3. **Optimiser le cache** : Mettre en cache `node_modules/`, `vendor/`, etc.
4. **Fail fast** : Placer les jobs rapides (linting, tests unitaires) en premier
5. **Paralléliser** : Diviser les tests en plusieurs jobs pour gagner du temps
6. **Protéger les secrets** : Utiliser les variables masquées dans Settings > CI/CD
7. **Environnements** : Utiliser `environment:` pour tracker les déploiements
8. **Review Apps** : Créer des environnements temporaires pour chaque merge request

#### Exemple complet : Application Node.js

```yaml
stages:
  - check
  - build
  - test
  - deploy

variables:
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

# Stage check : rapide pour feedback immédiat
lint:
  stage: check
  image: node:20-alpine
  script:
    - npm ci
    - npm run lint
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/

# Stage build
build-app:
  stage: build
  image: node:20-alpine
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
    policy: pull

build-docker:
  stage: build
  image: docker:cli
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build --pull -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
  only:
    - main
    - develop

# Stage test : jobs en parallèle
test-unit:
  stage: test
  image: node:20-alpine
  script:
    - npm ci
    - npm run test:unit
  coverage: '/Lines\s*:\s*(\d+\.\d+)%/'
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
    policy: pull

test-integration:
  stage: test
  image: node:20-alpine
  services:
    - postgres:15
    - redis:7-alpine
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: testuser
    POSTGRES_PASSWORD: testpass
    DATABASE_URL: "postgresql://testuser:testpass@postgres:5432/testdb"
    REDIS_URL: "redis://redis:6379"
  script:
    - npm ci
    - npm run test:integration
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
    policy: pull

# Stage deploy
deploy-staging:
  stage: deploy
  image: docker:cli
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker pull $IMAGE_TAG
    - docker tag $IMAGE_TAG $CI_REGISTRY_IMAGE:staging
    - docker push $CI_REGISTRY_IMAGE:staging
  environment:
    name: staging
    url: https://staging.example.com
  only:
    - develop

deploy-production:
  stage: deploy
  image: docker:cli
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker pull $IMAGE_TAG
    - docker tag $IMAGE_TAG $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:latest
  environment:
    name: production
    url: https://example.com
  when: manual
  only:
    - main
```

#### Ressources officielles

- 📚 **Documentation complète** : https://docs.gitlab.com/topics/build_your_application/
- 🚀 **Tutoriel Quick Start** : https://docs.gitlab.com/ci/quick_start/
- 📖 **Référence YAML** : https://docs.gitlab.com/ci/yaml/
- 💡 **Exemples de pipelines** : https://docs.gitlab.com/ci/examples/