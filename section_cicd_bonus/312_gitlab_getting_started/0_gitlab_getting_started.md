---
title: "TP: Mettre en oeuvre une CI/CD Docker+Gitlab"
weight: 38
# sidebar_class_name: hidden
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

#### 6. Les Environnements

Les environnements GitLab représentent des cibles de déploiement (development, staging, production) et permettent de **tracker l'historique des déploiements**, gérer les rollbacks, et contrôler les accès.

##### Concept d'environnement

Un environnement dans GitLab est une représentation d'un lieu de déploiement. Il permet :
- De **suivre quelle version du code** est déployée où
- D'avoir un **historique complet** des déploiements
- De **revenir à une version antérieure** (rollback) en un clic
- De **protéger les environnements** critiques (production)
- De **visualiser l'état** de chaque environnement dans l'interface GitLab

##### Types d'environnements

**Environnements statiques** (persistants)

Ce sont des environnements réutilisés à travers les déploiements :

```yaml
deploy-production:
  stage: deploy
  script:
    - echo "Déploiement en production"
    - ./deploy-prod.sh
  environment:
    name: production
    url: https://app.example.com
  only:
    - main
```

**Environnements dynamiques** (temporaires)

Créés à la demande, typiquement pour les review apps :

```yaml
deploy-review:
  stage: deploy
  script:
    - echo "Déploiement de la review app"
    - ./deploy-review.sh $CI_COMMIT_REF_SLUG
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_COMMIT_REF_SLUG.review.example.com
    on_stop: stop-review
    auto_stop_in: 1 week
  only:
    - merge_requests

stop-review:
  stage: deploy
  script:
    - echo "Nettoyage de la review app"
    - ./cleanup-review.sh $CI_COMMIT_REF_SLUG
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
  only:
    - merge_requests
```

##### Tiers d'environnements

GitLab assigne automatiquement des tiers selon les noms, ou vous pouvez les spécifier explicitement :

| Tier | Exemples de noms | Utilisation |
|------|------------------|-------------|
| **production** | production, live, prod | Production en service |
| **staging** | staging, stage, preprod | Pré-production, validation finale |
| **testing** | test, qa, testing | Tests automatisés ou manuels |
| **development** | dev, develop, review/* | Développement, review apps |
| **other** | Noms personnalisés | Cas spécifiques |

Spécifier explicitement le tier :

```yaml
deploy-demo:
  stage: deploy
  script:
    - ./deploy-demo.sh
  environment:
    name: demo-client
    deployment_tier: staging
    url: https://demo-client.example.com
```

##### URLs dynamiques

Pour les plateformes qui génèrent des URLs aléatoires (Heroku, Cloud Run, etc.) :

```yaml
deploy-cloud:
  stage: deploy
  script:
    - echo "Déploiement sur le cloud..."
    - DEPLOY_URL=$(gcloud run deploy --format='value(status.url)')
    - echo "DYNAMIC_ENVIRONMENT_URL=$DEPLOY_URL" >> deploy.env
  artifacts:
    reports:
      dotenv: deploy.env
  environment:
    name: production
    url: $DYNAMIC_ENVIRONMENT_URL
```

Le fichier `deploy.env` est lu par GitLab qui injecte les variables dans l'environnement.

##### Arrêt automatique des environnements

Les environnements peuvent s'arrêter automatiquement :

**1. Après une période de temps**

```yaml
deploy-review:
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_COMMIT_REF_SLUG.review.example.com
    on_stop: stop-review
    auto_stop_in: 3 days  # Accepte: "1 hour", "2 days 3 hours", etc.

stop-review:
  script:
    - ./cleanup.sh $CI_COMMIT_REF_SLUG
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

**2. À la suppression ou merge de la branche**

GitLab arrête automatiquement les environnements dynamiques quand :
- La branche est supprimée
- La merge request est fusionnée

##### Protection des environnements

Les environnements peuvent être protégés pour contrôler qui peut déployer :

**Configuration** (dans Settings > CI/CD > Protected Environments) :
- Seuls certains rôles peuvent déployer (Maintainer, specific users)
- Nécessite une approbation avant déploiement
- Restreint l'accès aux variables sensibles

```yaml
deploy-production:
  stage: deploy
  script:
    - ./deploy-prod.sh
  environment:
    name: production
    url: https://app.example.com
  when: manual  # Déploiement manuel pour plus de contrôle
  only:
    - main
```

##### Variables scopées aux environnements

Les variables peuvent être limitées à des environnements spécifiques (Settings > CI/CD > Variables) :

```
Nom: DATABASE_PASSWORD
Valeur: prod_secret_password
Environment scope: production
```

Cela empêche l'accès à ces variables depuis d'autres environnements, renforçant la sécurité.

##### Exemple complet : Workflow avec environnements

```yaml
stages:
  - build
  - test
  - review
  - staging
  - production

# Build de l'application
build:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

# Tests
test:
  stage: test
  script:
    - npm run test

# Review apps pour chaque MR
deploy-review:
  stage: review
  script:
    - kubectl create namespace review-$CI_COMMIT_REF_SLUG || true
    - helm upgrade --install review-$CI_COMMIT_REF_SLUG ./chart
        --set image.tag=$CI_COMMIT_SHA
        --set ingress.host=review-$CI_COMMIT_REF_SLUG.example.com
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://review-$CI_COMMIT_REF_SLUG.example.com
    on_stop: stop-review
    auto_stop_in: 7 days
  only:
    - merge_requests

stop-review:
  stage: review
  script:
    - helm uninstall review-$CI_COMMIT_REF_SLUG
    - kubectl delete namespace review-$CI_COMMIT_REF_SLUG
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
  only:
    - merge_requests

# Staging : déploiement automatique depuis develop
deploy-staging:
  stage: staging
  script:
    - helm upgrade --install staging ./chart
        --set image.tag=$CI_COMMIT_SHA
        --set ingress.host=staging.example.com
  environment:
    name: staging
    url: https://staging.example.com
    deployment_tier: staging
  only:
    - develop

# Production : déploiement manuel depuis main
deploy-production:
  stage: production
  script:
    - helm upgrade --install production ./chart
        --set image.tag=$CI_COMMIT_SHA
        --set ingress.host=app.example.com
  environment:
    name: production
    url: https://app.example.com
    deployment_tier: production
  when: manual  # Nécessite validation manuelle
  only:
    - main
```

##### Visualisation et gestion

Dans l'interface GitLab :

1. **Deployments > Environments** :
   - Liste de tous les environnements
   - Statut actuel de chaque environnement
   - Historique des déploiements
   - Possibilité de rollback en un clic

2. **Pour chaque environnement** :
   - URL cliquable vers l'application déployée
   - Commit et tag associés
   - Date et auteur du déploiement
   - Logs du pipeline de déploiement
   - Actions disponibles (redéployer, rollback, stop)

3. **Dans les Merge Requests** :
   - Badge indiquant les environnements où la MR est déployée
   - Lien direct vers les review apps
   - Statut des déploiements automatiques

##### Bonnes pratiques environnements

1. **Nommer clairement** : Utilisez des noms explicites (production, staging, review/*)
2. **Définir des URLs** : Toujours fournir une URL pour accéder facilement
3. **Protéger la production** : Activer la protection et les approbations
4. **Utiliser auto_stop_in** : Nettoyer automatiquement les review apps
5. **Scoper les variables** : Limiter les secrets aux environnements nécessaires
6. **Tiers explicites** : Spécifier `deployment_tier` pour une catégorisation claire
7. **Déploiement manuel en prod** : Utiliser `when: manual` pour validation humaine
8. **Review apps systématiques** : Créer une review app pour chaque MR

#### Ressources officielles

- 📚 **Documentation complète** : https://docs.gitlab.com/topics/build_your_application/
- 🚀 **Tutoriel Quick Start** : https://docs.gitlab.com/ci/quick_start/
- 📖 **Référence YAML** : https://docs.gitlab.com/ci/yaml/
- 🌍 **Environnements** : https://docs.gitlab.com/ci/environments/
- 💡 **Exemples de pipelines** : https://docs.gitlab.com/ci/examples/