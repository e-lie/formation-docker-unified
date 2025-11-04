# TP 315 - Correction : Déploiement Swarm depuis GitLab CI/CD

Ce dossier contient le code de correction complet du TP 315.

## Structure des fichiers

```
315_deploiement_swarm_gitlab/
├── 0_intro.md                    # Énoncé du TP
├── README.md                     # Ce fichier
├── .gitlab-ci.yml                # Pipeline CI/CD complet avec déploiement Swarm
├── docker-compose.swarm.yml      # Configuration Swarm avec variables
├── docker-compose.yml            # Configuration dev (inchangée)
├── Dockerfile                    # Image de l'application
├── boot.sh                       # Script de démarrage
└── app/                          # Code source de l'application
    ├── src/
    │   └── monster_icon.py
    └── tests/
        ├── unit.py
        └── integration.py
```

## Différences avec le TP 314

### Nouveaux fichiers

1. **docker-compose.swarm.yml** :
   - Configuration spécifique pour Swarm
   - Utilise des variables d'environnement : `${CI_REGISTRY_IMAGE}` et `${TAG}`
   - Section `deploy:` avec replicas et update_config
   - Réseau overlay pour multi-nœuds

2. **Stage deploy dans .gitlab-ci.yml** :
   - Installation de `openssh-client` et `gettext` (pour `envsubst`)
   - Configuration SSH avec clé privée stockée dans GitLab
   - Substitution des variables avec `envsubst`
   - Copie du fichier via SCP
   - Déploiement via SSH avec `docker stack deploy`

### Modifications du pipeline

**Nouveau stage** :
```yaml
stages:
  - check
  - build-integration
  - deliver-staging
  - deploy  # ← Nouveau
```

**Variables GitLab requises** (à configurer dans Settings → CI/CD → Variables) :
- `SSH_PRIVATE_KEY` : Clé privée SSH pour se connecter au manager
- `SWARM_MANAGER_IP` : Adresse IP du nœud manager Swarm
- `SWARM_DEPLOY_USER` : Utilisateur SSH (recommandé : `gitlab-deploy`)

## Utilisation de la correction

### Option 1 : Utiliser le code directement

```bash
# Copier tout le dossier vers votre projet GitLab
cd /chemin/vers/votre/projet/gitlab
cp -r section_cicd_bonus/315_deploiement_swarm_gitlab/* .

# Ajouter et pousser
git add .
git commit -m "Add Swarm deployment pipeline"
git push gitlab main
```

### Option 2 : Comparer avec votre code

Utilisez `diff` pour comparer votre travail avec la correction :

```bash
diff votre-projet/.gitlab-ci.yml section_cicd_bonus/315_deploiement_swarm_gitlab/.gitlab-ci.yml
diff votre-projet/docker-compose.swarm.yml section_cicd_bonus/315_deploiement_swarm_gitlab/docker-compose.swarm.yml
```

## Points clés de la correction

### 1. Gestion des tags Git

Le pipeline utilise le tag Git s'il existe, sinon le nom de branche :

```yaml
- export TAG=${CI_COMMIT_TAG:-$CI_COMMIT_REF_SLUG}
```

Dans `docker-build`, si c'est un tag, on pousse aussi avec le nom du tag :

```yaml
- |
  if [ -n "$CI_COMMIT_TAG" ]; then
    docker tag "$DOCKER_IMAGE_NAME" "$CI_REGISTRY_IMAGE:$CI_COMMIT_TAG"
    docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_TAG"
  fi
```

### 2. Zero-downtime deployment

Configuration dans `docker-compose.swarm.yml` :

```yaml
deploy:
  update_config:
    parallelism: 1        # Met à jour 1 conteneur à la fois
    delay: 10s            # Attend 10s entre chaque update
    order: start-first    # Lance les nouveaux avant d'arrêter les anciens
```

### 3. Sécurité SSH

- Clé privée stockée dans GitLab (variable protégée)
- Utilisateur dédié `gitlab-deploy` sur le Swarm (non-root)
- Scan automatique de la clé du serveur : `ssh-keyscan`

### 4. Registry authentication

L'option `--with-registry-auth` propage les credentials du manager aux workers :

```bash
docker stack deploy -c /tmp/monsterstack-compose.yml monsterstack --with-registry-auth
```

Sans cette option, les workers ne pourraient pas pull les images du registry privé GitLab.

## Tester la correction

### 1. Configuration initiale

Sur le manager Swarm, créez l'utilisateur de déploiement :

```bash
ssh root@<IP_MANAGER>
useradd -m -s /bin/bash gitlab-deploy
usermod -aG docker gitlab-deploy
su - gitlab-deploy
mkdir ~/.ssh
chmod 700 ~/.ssh
# Ajoutez votre clé publique dans ~/.ssh/authorized_keys
```

### 2. Configurer GitLab

Settings → CI/CD → Variables, ajoutez :
- `SSH_PRIVATE_KEY` : Votre clé privée
- `SWARM_MANAGER_IP` : IP du manager (ex: `138.68.123.45`)
- `SWARM_DEPLOY_USER` : `gitlab-deploy`

### 3. Déclencher le pipeline

```bash
# Sur la branche main
git push gitlab main

# Ou avec un tag
git tag v1.0.0
git push gitlab v1.0.0
```

### 4. Vérifier le déploiement

Dans GitLab :
- Build → Pipelines → Cliquez sur le pipeline
- Cliquez sur le job `deploy-swarm`
- Vérifiez les logs

Sur le Swarm :
```bash
ssh gitlab-deploy@<IP_MANAGER>
docker stack ls
docker stack services monsterstack
docker stack ps monsterstack
```

Testez l'application :
```bash
curl http://<IP_MANAGER>:5000
```

## Workflow complet

1. **Développement** : Travail sur une branche feature
2. **Push** : `git push gitlab feature-xyz`
   - ✅ Stages check et build-integration s'exécutent
   - ❌ Deploy est sauté (pas sur main)

3. **Merge** : Fusion dans `main`
   - ✅ Tous les stages s'exécutent
   - ✅ Déploiement automatique en production

4. **Release** : Création d'un tag `git tag v1.0.0`
   - ✅ Tous les stages s'exécutent
   - ✅ Image taguée `v1.0.0` déployée

5. **Rollback** : Redéployer l'ancien tag
   ```bash
   ssh gitlab-deploy@<IP>
   docker service update --image registry.../app:v0.9.0 monsterstack_frontend
   ```

## Améliorations possibles

### Déploiement manuel

Ajoutez `when: manual` dans le job `deploy-swarm` pour requérir une confirmation :

```yaml
deploy-swarm:
  # ...
  when: manual
```

### Environnements multiples

Créez des jobs séparés pour staging et production :

```yaml
deploy-staging:
  # ...
  variables:
    SWARM_MANAGER_IP: $STAGING_SWARM_IP
  environment:
    name: staging
  rules:
    - if: $CI_COMMIT_BRANCH == "staging"

deploy-production:
  # ...
  variables:
    SWARM_MANAGER_IP: $PRODUCTION_SWARM_IP
  environment:
    name: production
  rules:
    - if: $CI_COMMIT_TAG
  when: manual
```

### Health checks

Ajoutez un health check dans le job deploy :

```yaml
- |
  ssh ... << 'EOF'
    docker stack deploy ...

    # Attendre et vérifier le health
    for i in {1..30}; do
      if curl -f http://localhost:5000/health; then
        echo "Application is healthy!"
        exit 0
      fi
      echo "Waiting for health check... ($i/30)"
      sleep 10
    done

    echo "Health check failed!"
    exit 1
  EOF
```

## Troubleshooting

### Erreur "Permission denied (publickey)"

- Vérifiez que la clé publique est bien dans `~/.ssh/authorized_keys` de l'utilisateur
- Vérifiez les permissions : `chmod 600 ~/.ssh/authorized_keys`

### Erreur "docker command not found"

- L'utilisateur n'est pas dans le groupe docker : `usermod -aG docker gitlab-deploy`
- Il faut se déconnecter/reconnecter : `su - gitlab-deploy`

### Services qui ne démarrent pas

- Vérifiez les logs : `docker service logs monsterstack_frontend`
- Vérifiez que l'image existe dans le registry
- Vérifiez `--with-registry-auth` si registry privé

### Variables non substituées

- Utilisez `envsubst` (paquet `gettext`)
- Vérifiez que les variables sont exportées : `export TAG=...`
- Pour debug : `cat docker-compose.deploy.yml` avant le SCP

## Références

- [Énoncé complet du TP](./0_intro.md)
- [TP 314 - CI/CD GitLab](../314_mise_en_oeuvre_ci_gitlab/)
- [TP 320 - Installation Swarm](../320_swarm_install/)
