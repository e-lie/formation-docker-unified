---
title: "TP: Mettre en oeuvre une CI/CD Docker+Gitlab"
weight: 38
# sidebar_class_name: hidden
---

### Code de base

Dans le dépot de code unifié : `section_cicd_bonus/313_mise_en_oeuvre_ci_gitlab_base`

### Se connecter au gitlab de lab

- https://gitlab.dopl.uk

- login: votreprenom mdp : xK9#mZ2$pL7@qR5!

### Créer un projet Gitlab

- Créez un compte sur Gitlab (gratuit)
- créer une clé ssh avec `ssh-keygen` (faire juste entrer a toute les questions suffit ici => id_rsa sans passphrase)
- Ajoutez la clé à votre compte (vous pourrez l'enlever à la fin du TP)
- Créez un projet privé `monsterstack_app` par exemple
- Ajoutez un remote git au dépot git avec `git remote add gitlab <ssh_url_du_projet>`
- Poussez le projet avec `git push gitlab` et vérifiez sur la page du projet que votre code est bien poussé.

## Stage `check` : vérifier rapidement les erreurs du code

Dans Gitlab pour configurer une CI/CD il suffit de créer à la racine du projet un fichier `.gitlab-ci.yml`. Il définit un ensemble d'étapes (Jobs) regroupés en Stages qui forment un pipeline d'automatisation.

- Créez ce fichier.

- Ajoutez au début une liste de stages dans l'ordre de leur exécution:

```yaml
stages:
  - check
  - build-integration
  - deliver-staging
```

### Job Linting (vérification syntaxique du code)

Nous allons maintenant créer un job très simple sur le modèle:

```yaml
<nom_job>:
  stage: <stage_job>
  image: <image_docker_de_base>
  script:
    - <commande_1>
    - <commande_2>
    - ...
```

- Ajoutez le job `linting` faisant partie du stage `check` basé sur l'image docker: `python:3.10-slim`.

Ce Job doit vérifier simplement qu'il n'y a pas d'erreurs grossières dans le code de notre logiciel en utilisant la librairie `pyflakes`:

- Ajoutez une commande pour installer pyflakes avec `pip install pyflakes`
- Ajoutez une commande pour lancer pyflakes avec `pyflakes app/*.py`

- Créez un commit et poussez votre code `git push gitlab` pour vérifier que le pipeline fonctionne (s'il échoue vous devriez reçevoir un mail sur l'adresse mail de votre compte)
- Allez voir dans l'interface gitlab section `Build > pipelines` comment s'est déroulé le pipeline

### Job Unit testing

Créez un nouveau Job `unit-testing` également dans le stage `check` basé également sur l'image python précédente. Il doit lancer les tests unitaires avec la suite de commandes:

```yaml
  - cd app
  - python -m venv venv
  - source venv/bin/activate
  - pip install -r requirements.dev.txt
  - python -m unittest tests/unit.py
```

- Poussez le résultat avec un nouveau commit

Constatez le déroulement du nouveau Job du pipeline :  qu'a-t-il de particulier ?

Que teste le fichier `unit.py` ?

## Stage build integration

Le stage `check` a pour but d'être rapide et de tester rapidement la qualité du code et l'absence de régressions directes (si une partie du code est cassée). On pourrait même activer une quality gate et refuser le push dans certaines conditions.

Cependant pour tout logiciel certaines parties ne peuvent être testée qu'avec tous les composants du logiciel. C'est le role des tests d'intégration de vérifier qu'au dela des fonctions isolées (units) les différents composants fonctionnent bien ensembles.

Pour les tests d'intégration nous avons généralement besoin des différents morceaux/services composant une application. Dans ce cas la conteneurisation (Docker) rentre en jeu d'une nouvelle façon. elle permet de provisionner rapidement les différentes parties d'une application dans un pipeline Gitlab et de les connecter comme avec un Docker compose.

### Job `integration-testing`

- Créez ce nouveau job dans le stage `build-integration` avec comme image `python:3.10-slim`
- Ajoutez une section `services` comme suit:

```yaml
...
  stage: ...
  image: ...
  services:
    - name: <image_name>
      alias: <container_domain_name>
    - name: <image_name>
      alias: <container_domain_name>
  script:
  ...
```

Cette section est une fonctionnalité de Gitlab qui permet de connecter de nouveaux conteneurs au conteneur principal du pipeline (décrit vie `image:`). Pour chaque conteneur de service ajouté, `name` est le nom de l'image à utilisé et `alias` est le nom de domaine à assigner au conteneur pour que les requêtes venants des autres services puisse le trouver et aboutir (comme les DNS de Docker et K8s). 

Pour notre application il nous faut:
  - `amouat/dnmonster:1.0` comme indiqué dans le déploiement de imagebackend avec l'alias / domain `imagebackend`
  - `redis:latest` avec comme domaine `redis`

- Complétez la section.

Maintenant que les nouveaux conteneurs sont configurés nous pouvons déclencher les tests vérifiant l'intégration des parties de notre application avec les commandes :

```yaml
  - cd app
  - python -m venv venv
  - source venv/bin/activate
  - pip install -r requirements.dev.txt
  - python -m unittest tests/integration.py
```

- Poussez le code et allez observer le pipeline.

### Job `docker-build`

Une fois l'application validé a minima via le stage `check` il semble raisonnable de construire l'image de conteneur de notre application pour pouvoir l'utiliser plus tard et notamment la déployer.

Ajoutez le Job suivant au pipeline:

```yaml
docker-build:
  stage: build-integration
  # Use the official docker image.
  image: docker:cli
  services:
    - docker:dind
  variables:
    DOCKER_IMAGE_NAME: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  script:
    - docker build --pull -t "$DOCKER_IMAGE_NAME" .
    # All branches are tagged with $DOCKER_IMAGE_NAME (defaults to commit ref slug)
    - docker push "$DOCKER_IMAGE_NAME"
  # Run this job in a branch where a Dockerfile exists
  rules:
    - if: $CI_COMMIT_BRANCH
      exists:
        - Dockerfile
```

- Quelles sont les étapes du build ?
- Quel est la version/tag utilisée pour l'image ?
- Une fois ce code poussé allez voir le pipeline

### Stage/Job `deliver-staging`, publier l'application pour une préprod

L'image construite à l'étape précédente est une image de travail dont la version est basée sur le commit qui a servit à la concevoir. C'est un artefact temporaire attendant une validation plus approfondie. Si elle réussi l'image sera publiée sinon elle sera vite supprimée.

Cette image pourra être utilisé pour un déploiement de test ou simplement pour effectuer des tests plus poussés en conditions a peu près réaliste (analyse de sécurité, déploiement dans un cluster et tests fonctionnels sur l'interface par exemple, idéalement automatisés par exemple avec Selenium ou autre solution).

Une fois d'autres tests effectués on peut délivrer l'application, c'est à dire la publier en tant qu'image de référence soit pour la production ou juste une préproduction (`staging`). Pour publier notre image en `staging` ajoutez l'étape suivante au pipeline.

```yaml
docker-deliver-staging:
  stage: deliver-staging
  # Use the official docker image.
  image: docker:cli
  services:
    - docker:dind
  variables:
    DOCKER_IMAGE_NAME: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  script:
    # Staging branch generates a `staging` image
    - docker pull "$DOCKER_IMAGE_NAME"
    - docker tag "$DOCKER_IMAGE_NAME" "$CI_REGISTRY_IMAGE:staging"
    - docker push "$CI_REGISTRY_IMAGE:staging"
  # Run this job in a branch where a Dockerfile exists
  rules:
    - if: $CI_COMMIT_BRANCH == "staging"
    - if: $CI_COMMIT_BRANCH
      exists:
        - Dockerfile
```

- Qu'est-ce qui déclenche la construction de cette image ?
- Que fait cette étape précisément ?

## Conclusion

Ce TP présente un exemple de pipeline Gitlab et Docker illustrant de façon simplifié un workflow de continous integration et delivery.

Pour la suite on devrait utiliser par exemple Kubernetes pour déployer l'application en la poussant dans un cluster ou en mode GitOps en publiant

## Références

<!-- ### Doc Gitlab

- ... -->

#### Tutos exemple:

- https://mohammed-abouzahr.medium.com/integration-test-starter-with-ci-5037410817ee
- https://spin.atomicobject.com/2021/06/07/integration-testing-gitlab/
- 