---
title: "TP: Déployer automatiquement dans Docker Swarm depuis GitLab CI/CD"
description: "Guide TP: Déployer automatiquement dans Docker Swarm depuis GitLab CI/CD"
sidebar:
  order: 325
---


## Prérequis

- Avoir complété le TP précédent (314 - CI/CD Docker+GitLab)
- Avoir accès au projet GitLab avec le code MonsterStack
- Avoir un cluster Docker Swarm fonctionnel (voir TP 320_swarm_install)

## Objectifs

Dans ce TP, vous allez étendre le pipeline GitLab CI/CD pour :
1. Ajouter un stage de déploiement automatique vers Docker Swarm
2. Configurer l'accès SSH sécurisé au manager Swarm
3. Mettre en œuvre un déploiement zero-downtime avec `docker stack deploy`

## Code de base

Reprenez votre projet du TP 314 ou utilisez le code de correction dans `section_cicd_bonus/314_mise_en_oeuvre_ci_gitlab/`.

## Étape 1 : Préparer le fichier docker-compose.yml pour Swarm

Docker Swarm utilise le format docker-compose v3 avec des sections spécifiques pour l'orchestration.

À la racine de votre projet, créez un fichier `docker-compose.swarm.yml` :

```yaml
version: '3.8'

services:
  frontend:
    image: ${CI_REGISTRY_IMAGE}:${TAG:-latest}
    ports:
      - "5000:5000"
    environment:
      - CONTEXT=PROD
      - REDIS_DOMAIN=redis
      - IMAGEBACKEND_DOMAIN=imagebackend
    networks:
      - monster_network
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

  imagebackend:
    image: amouat/dnmonster:1.0
    networks:
      - monster_network
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure

  redis:
    image: redis:latest
    networks:
      - monster_network
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      restart_policy:
        condition: on-failure

networks:
  monster_network:
    driver: overlay
```

**Points clés :**
- `image: ${CI_REGISTRY_IMAGE}:${TAG:-latest}` : Utilise des variables d'environnement pour l'image
- `deploy.replicas` : Nombre de réplicas par service
- `deploy.update_config` : Configuration du rolling update (zero-downtime)
- `deploy.placement.constraints` : Redis sur le manager uniquement (pour la persistance)
- `networks.driver: overlay` : Réseau overlay pour Swarm multi-nœuds

Commitez ce fichier :
```bash
git add docker-compose.swarm.yml
git commit -m "Add Swarm deployment configuration"
git push gitlab
```

## Étape 2 : Configurer l'accès SSH au cluster Swarm

### 2.1 Générer une paire de clés SSH dédiée

Sur votre machine locale, générez une clé SSH pour GitLab CI/CD :

```bash
ssh-keygen -t ed25519 -C "gitlab-ci-deploy" -f ~/.ssh/gitlab_ci_deploy
```

**N'utilisez PAS de passphrase** (appuyez sur Entrée), car le pipeline doit s'authentifier automatiquement.

### 2.2 Ajouter la clé publique au manager Swarm

Connectez-vous au manager Swarm et ajoutez la clé publique :

```bash
# Sur le manager Swarm
ssh root@<IP_MANAGER_SWARM>

# Créer un utilisateur dédié pour les déploiements
useradd -m -s /bin/bash gitlab-deploy
usermod -aG docker gitlab-deploy

# Copier la clé publique
mkdir -p /home/gitlab-deploy/.ssh
# Collez le contenu de ~/.ssh/gitlab_ci_deploy.pub dans :
nano /home/gitlab-deploy/.ssh/authorized_keys
chmod 700 /home/gitlab-deploy/.ssh
chmod 600 /home/gitlab-deploy/.ssh/authorized_keys
chown -R gitlab-deploy:gitlab-deploy /home/gitlab-deploy/.ssh
```

### 2.3 Configurer les variables GitLab CI/CD

Dans GitLab, allez dans votre projet :
1. **Settings → CI/CD → Variables**
2. Ajoutez les variables suivantes (cliquez sur "Add variable") :

| Key | Value | Type | Protected | Masked |
|-----|-------|------|-----------|--------|
| `SSH_PRIVATE_KEY` | Contenu de `~/.ssh/gitlab_ci_deploy` (clé privée) | Variable | ✓ | ✗ |
| `SWARM_MANAGER_IP` | IP du manager Swarm (ex: `138.68.123.45`) | Variable | ✓ | ✗ |
| `SWARM_DEPLOY_USER` | `gitlab-deploy` | Variable | ✗ | ✗ |

**Note de sécurité :**
- Cochez "Protected" pour limiter l'usage aux branches protégées (main, staging)
- La clé privée ne peut pas être "Masked" car trop longue, mais reste cachée dans les logs

## Étape 3 : Ajouter le stage de déploiement au pipeline

Modifiez votre `.gitlab-ci.yml` pour ajouter le stage `deploy` et le job correspondant.

### 3.1 Ajouter le stage deploy

Modifiez la liste des stages au début du fichier :

```yaml
stages:
  - check
  - build-integration
  - deliver-staging
  - deploy  # Nouveau stage
```

### 3.2 Créer le job deploy-swarm

Ajoutez ce job à la fin de votre `.gitlab-ci.yml` :

```yaml
deploy-swarm:
  stage: deploy
  image: docker:cli
  before_script:
    # Installer les outils nécessaires
    - apk add --no-cache openssh-client bash envsubst
    # Configurer SSH
    - mkdir -p ~/.ssh
    - echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - ssh-keyscan -H $SWARM_MANAGER_IP >> ~/.ssh/known_hosts
  script:
    # Substituer les variables d'environnement dans le docker-compose
    - export TAG=${CI_COMMIT_TAG:-$CI_COMMIT_REF_SLUG}
    - envsubst < docker-compose.swarm.yml > docker-compose.deploy.yml
    - cat docker-compose.deploy.yml  # Afficher pour debug

    # Copier le fichier sur le manager Swarm
    - scp docker-compose.deploy.yml $SWARM_DEPLOY_USER@$SWARM_MANAGER_IP:/tmp/monsterstack-compose.yml

    # Se connecter au manager et déployer le stack
    - |
      ssh $SWARM_DEPLOY_USER@$SWARM_MANAGER_IP << 'EOF'
        # Déployer le stack avec docker stack deploy
        docker stack deploy -c /tmp/monsterstack-compose.yml monsterstack --with-registry-auth

        # Attendre que les services soient à jour
        echo "Waiting for services to be ready..."
        sleep 10

        # Afficher le statut des services
        docker stack services monsterstack

        # Cleanup
        rm /tmp/monsterstack-compose.yml
      EOF
  environment:
    name: production
    url: http://$SWARM_MANAGER_IP:5000
  only:
    - main
    - tags
```

**Explications :**
- `apk add envsubst` : Outil pour remplacer les variables dans le fichier compose
- `export TAG=${CI_COMMIT_TAG:-$CI_COMMIT_REF_SLUG}` : Utilise le tag Git si disponible, sinon le nom de branche
- `envsubst` : Remplace `${CI_REGISTRY_IMAGE}` et `${TAG}` par leurs valeurs réelles
- `scp` : Copie le fichier compose sur le manager
- `docker stack deploy --with-registry-auth` : Déploie le stack et propage les credentials du registry
- `environment:` : Crée un environnement "production" dans GitLab avec lien vers l'app
- `only: [main, tags]` : S'exécute uniquement sur la branche main ou lors de la création d'un tag

## Étape 4 : Tester le déploiement

### 4.1 Pousser les modifications

```bash
git add .gitlab-ci.yml
git commit -m "Add Swarm deployment stage"
git push gitlab main
```

### 4.2 Suivre le pipeline

1. Allez dans **Build → Pipelines** dans GitLab
2. Observez l'exécution des stages :
   - `check` : Linting et tests unitaires en parallèle
   - `build-integration` : Tests d'intégration et build Docker
   - `deliver-staging` : Sauté (pas sur branche staging)
   - `deploy` : Déploiement sur Swarm

### 4.3 Vérifier le déploiement

Cliquez sur le job `deploy-swarm` pour voir les logs. Vous devriez voir :
```
ID             NAME                      MODE         REPLICAS   IMAGE
abc123         monsterstack_frontend     replicated   2/2        registry.gitlab.com/...
def456         monsterstack_imagebackend replicated   2/2        amouat/dnmonster:1.0
ghi789         monsterstack_redis        replicated   1/1        redis:latest
```

Connectez-vous au manager Swarm pour vérifier :

```bash
ssh gitlab-deploy@<IP_MANAGER>
docker stack ps monsterstack
docker service logs monsterstack_frontend
```

Testez l'application :
```bash
curl http://<IP_MANAGER>:5000
```

## Étape 5 : Déploiement avec tags (bonus)

Pour un workflow production plus mature, créez un tag Git :

```bash
git tag -a v1.0.0 -m "First production release"
git push gitlab v1.0.0
```

Cela déclenchera le pipeline et déploiera l'image taguée `v1.0.0` dans Swarm.

Modifiez ensuite le code, créez un nouveau tag `v1.0.1`, et observez le rolling update zero-downtime !

## Questions de réflexion

1. **Que se passe-t-il si le manager Swarm est indisponible pendant le déploiement ?**
   - Le pipeline échouera. Solution : Utiliser plusieurs managers (haute disponibilité)

2. **Comment gérer les secrets (mots de passe, API keys) ?**
   - Utiliser `docker secret create` au lieu de variables d'environnement en clair
   - Exemple : `echo "db_password" | docker secret create db_pass -`

3. **Comment faire un rollback en cas de problème ?**
   - Redéployer avec l'ancien tag : `docker service update --image registry.../app:v1.0.0 monsterstack_frontend`
   - Ou relancer le pipeline sur le commit/tag précédent

4. **Pourquoi utiliser `order: start-first` dans update_config ?**
   - Lance les nouveaux conteneurs avant d'arrêter les anciens
   - Garantit qu'il y a toujours des instances disponibles (zero-downtime)

5. **Comment gérer plusieurs environnements (staging, production) ?**
   - Créer plusieurs jobs avec des variables différentes
   - Exemple : `deploy-staging` vers cluster de test, `deploy-production` vers cluster prod

## Amélioration possible : Utiliser Docker Secrets

Modifiez `docker-compose.swarm.yml` pour utiliser des secrets :

```yaml
services:
  frontend:
    # ...
    secrets:
      - db_password
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password

secrets:
  db_password:
    external: true
```

Créez le secret sur le Swarm :
```bash
echo "supersecret" | docker secret create db_password -
```

## Conclusion

Vous avez maintenant un pipeline complet de CI/CD avec déploiement automatique dans Docker Swarm :

1. **Check** : Validation rapide du code (linting, tests unitaires)
2. **Build-Integration** : Tests d'intégration et construction de l'image Docker
3. **Deliver-Staging** : Publication de l'image staging
4. **Deploy** : Déploiement automatique dans le cluster Swarm

Ce workflow permet :
- Des déploiements rapides et automatisés
- Un rollout progressif sans interruption de service
- Une traçabilité complète (qui a déployé quoi, quand)
- Une facilité de rollback via les tags Git

Pour aller plus loin, explorez :
- **Portainer** : Interface web pour gérer Swarm et automatiser les déploiements
- **GitLab Environments** : Suivi des déploiements avec historique
- **Blue/Green deployment** : Deux stacks en parallèle pour switch instantané
- **Monitoring** : Prometheus + Grafana pour surveiller les services déployés

## Références

- [GitLab CI/CD SSH deployment](https://docs.gitlab.com/ee/ci/examples/deployment/)
- [Docker Stack Deploy](https://docs.docker.com/engine/reference/commandline/stack_deploy/)
- [Docker Compose file v3](https://docs.docker.com/compose/compose-file/compose-file-v3/)
- [Docker Swarm update configs](https://docs.docker.com/engine/swarm/swarm-tutorial/rolling-update/)
