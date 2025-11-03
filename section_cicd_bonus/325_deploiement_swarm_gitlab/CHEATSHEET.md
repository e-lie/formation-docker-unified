# Cheat Sheet - TP 315 Déploiement Swarm depuis GitLab

## Configuration initiale (une seule fois)

### 1. Générer la clé SSH pour GitLab CI/CD

```bash
# Sur votre machine locale
ssh-keygen -t ed25519 -C "gitlab-ci-deploy" -f ~/.ssh/gitlab_ci_deploy
# Ne pas mettre de passphrase (juste Entrée)

# Afficher la clé publique (à copier)
cat ~/.ssh/gitlab_ci_deploy.pub

# Afficher la clé privée (à copier dans GitLab)
cat ~/.ssh/gitlab_ci_deploy
```

### 2. Configurer le manager Swarm

```bash
# Se connecter au manager
ssh root@<IP_MANAGER_SWARM>

# Créer l'utilisateur de déploiement
useradd -m -s /bin/bash gitlab-deploy
usermod -aG docker gitlab-deploy

# Ajouter la clé publique
mkdir -p /home/gitlab-deploy/.ssh
nano /home/gitlab-deploy/.ssh/authorized_keys
# Coller la clé publique générée à l'étape 1

# Fixer les permissions
chmod 700 /home/gitlab-deploy/.ssh
chmod 600 /home/gitlab-deploy/.ssh/authorized_keys
chown -R gitlab-deploy:gitlab-deploy /home/gitlab-deploy/.ssh

# Tester la connexion
exit
ssh gitlab-deploy@<IP_MANAGER_SWARM>
docker ps  # Doit fonctionner sans sudo
```

### 3. Configurer GitLab

Dans votre projet GitLab → Settings → CI/CD → Variables :

| Variable | Valeur | Protected | Masked |
|----------|--------|-----------|--------|
| `SSH_PRIVATE_KEY` | Contenu de `~/.ssh/gitlab_ci_deploy` | ✓ | ✗ |
| `SWARM_MANAGER_IP` | IP du manager (ex: `138.68.123.45`) | ✓ | ✗ |
| `SWARM_DEPLOY_USER` | `gitlab-deploy` | ✗ | ✗ |

## Commandes Git

### Workflow branches

```bash
# Créer une branche feature
git checkout -b feature/nouvelle-fonctionnalite
# Faire vos modifications...
git add .
git commit -m "Add nouvelle fonctionnalité"
git push gitlab feature/nouvelle-fonctionnalite

# Merger dans main (via merge request ou en local)
git checkout main
git merge feature/nouvelle-fonctionnalite
git push gitlab main  # ← Déclenche le déploiement !
```

### Workflow tags (releases)

```bash
# Créer un tag annoté
git tag -a v1.0.0 -m "Release version 1.0.0"
git push gitlab v1.0.0  # ← Déclenche le build et le déploiement

# Lister les tags
git tag -l

# Supprimer un tag (local + remote)
git tag -d v1.0.0
git push gitlab :refs/tags/v1.0.0
```

### Rollback avec Git

```bash
# Option 1 : Redéployer un ancien tag
git push gitlab v0.9.0  # Le pipeline redéploiera cette version

# Option 2 : Créer un commit de revert
git revert <commit_hash>
git push gitlab main

# Option 3 : Reset hard (ATTENTION : destructif)
git reset --hard <commit_hash>
git push gitlab main --force  # À éviter en production !
```

## Commandes Docker Swarm (sur le manager)

### Vérifier l'état du cluster

```bash
# Se connecter au manager
ssh gitlab-deploy@<IP_MANAGER>

# Lister les stacks
docker stack ls

# Lister les services du stack monsterstack
docker stack services monsterstack

# Voir les tâches/conteneurs en cours
docker stack ps monsterstack

# Voir les tâches en erreur
docker stack ps monsterstack --filter "desired-state=running"
```

### Logs et debugging

```bash
# Logs d'un service
docker service logs monsterstack_frontend

# Logs en temps réel (follow)
docker service logs -f monsterstack_frontend

# Logs des 50 dernières lignes
docker service logs --tail 50 monsterstack_frontend

# Inspecter un service
docker service inspect monsterstack_frontend

# Voir les détails d'un conteneur spécifique
docker inspect <container_id>
```

### Mise à jour manuelle

```bash
# Mettre à jour l'image d'un service
docker service update --image registry.gitlab.com/user/project:v1.0.1 monsterstack_frontend

# Rollback vers l'image précédente
docker service rollback monsterstack_frontend

# Scaler un service
docker service scale monsterstack_frontend=5

# Forcer la mise à jour (recrée tous les conteneurs)
docker service update --force monsterstack_frontend
```

### Gestion du stack

```bash
# Redéployer le stack (avec un fichier local)
docker stack deploy -c /path/to/docker-compose.swarm.yml monsterstack

# Supprimer le stack
docker stack rm monsterstack

# Attendre que le stack soit complètement supprimé
watch docker stack ps monsterstack
```

## Commandes de troubleshooting

### Problèmes de connexion SSH

```bash
# Tester la connexion SSH
ssh -v gitlab-deploy@<IP_MANAGER>

# Vérifier les permissions des clés sur le serveur
ssh root@<IP_MANAGER>
ls -la /home/gitlab-deploy/.ssh/
cat /home/gitlab-deploy/.ssh/authorized_keys

# Vérifier les logs SSH du serveur
tail -f /var/log/auth.log  # ou /var/log/secure sur CentOS
```

### Problèmes de registry

```bash
# Se connecter au registry GitLab depuis le Swarm
docker login registry.gitlab.com
# Username: votre_username_gitlab
# Password: votre_personal_access_token

# Tester le pull d'une image
docker pull registry.gitlab.com/user/project:main

# Vérifier les credentials Docker
cat ~/.docker/config.json
```

### Problèmes de réseau

```bash
# Lister les réseaux overlay
docker network ls --filter driver=overlay

# Inspecter le réseau
docker network inspect monsterstack_monster_network

# Tester la connectivité entre services
docker exec <container_id> ping redis
docker exec <container_id> nslookup redis
```

### Problèmes de volumes/persistence

```bash
# Lister les volumes
docker volume ls

# Inspecter un volume
docker volume inspect <volume_name>

# Nettoyer les volumes non utilisés (ATTENTION)
docker volume prune
```

## Variables GitLab CI/CD utiles

Dans vos jobs, ces variables sont automatiquement disponibles :

```yaml
# Variables de commit
$CI_COMMIT_SHA          # Hash du commit (ex: a1b2c3d4)
$CI_COMMIT_SHORT_SHA    # Hash court (ex: a1b2c3d)
$CI_COMMIT_REF_NAME     # Nom de la branche/tag (ex: main, v1.0.0)
$CI_COMMIT_REF_SLUG     # Nom nettoyé (ex: main, v1-0-0)
$CI_COMMIT_TAG          # Nom du tag si c'est un tag (vide sinon)
$CI_COMMIT_BRANCH       # Nom de la branche (vide si tag)

# Variables de registry
$CI_REGISTRY            # registry.gitlab.com
$CI_REGISTRY_IMAGE      # registry.gitlab.com/user/project
$CI_REGISTRY_USER       # gitlab-ci-token
$CI_REGISTRY_PASSWORD   # Token temporaire

# Variables de projet
$CI_PROJECT_NAME        # Nom du projet
$CI_PROJECT_NAMESPACE   # Namespace (user ou groupe)
$CI_PROJECT_PATH        # user/project

# Variables de pipeline
$CI_PIPELINE_ID         # ID du pipeline
$CI_JOB_ID              # ID du job
$CI_JOB_NAME            # Nom du job (ex: deploy-swarm)
```

## Commandes utiles dans le pipeline

### Substitution de variables

```bash
# Avec envsubst (paquet gettext)
export TAG=v1.0.0
export CI_REGISTRY_IMAGE=registry.gitlab.com/user/project
envsubst < docker-compose.swarm.yml > docker-compose.deploy.yml

# Vérifier le résultat
cat docker-compose.deploy.yml
```

### Copie de fichiers via SCP

```bash
# Copier un fichier
scp fichier.yml user@host:/tmp/

# Copier un dossier
scp -r dossier/ user@host:/tmp/

# Avec clé SSH spécifique
scp -i ~/.ssh/id_rsa fichier.yml user@host:/tmp/
```

### Exécution de commandes via SSH

```bash
# Commande simple
ssh user@host "docker stack ls"

# Commandes multiples avec heredoc
ssh user@host << 'EOF'
  docker stack deploy -c /tmp/compose.yml myapp
  docker stack services myapp
EOF

# Avec transfert de variables
ssh user@host "export TAG=$TAG && docker stack deploy ..."
```

## Monitoring du déploiement

### Depuis GitLab

1. **Build → Pipelines** : Voir tous les pipelines
2. **Deployments → Environments** : Voir l'historique des déploiements
3. **Cliquer sur le job** → Voir les logs en temps réel

### Depuis le Swarm

```bash
# Voir le rolling update en temps réel
watch -n 1 'docker stack ps monsterstack --no-trunc'

# Suivre les logs pendant le déploiement
docker service logs -f monsterstack_frontend

# Vérifier qu'il n'y a pas de conteneurs en erreur
docker stack ps monsterstack --filter "desired-state=running" | grep -v Running
```

## Exemples de scénarios

### Scénario 1 : Déploiement d'urgence (hotfix)

```bash
# 1. Créer une branche hotfix
git checkout -b hotfix/critical-bug
# Corriger le bug...
git add .
git commit -m "Fix critical security issue"

# 2. Merger directement dans main
git checkout main
git merge hotfix/critical-bug
git push gitlab main

# 3. Créer un tag patch
git tag -a v1.0.1 -m "Hotfix: critical security issue"
git push gitlab v1.0.1

# Le pipeline déploie automatiquement en production
```

### Scénario 2 : Rollback d'urgence

```bash
# Sur le Swarm (rollback immédiat)
ssh gitlab-deploy@<IP_MANAGER>
docker service rollback monsterstack_frontend

# Ou via GitLab (redéploie la version précédente)
git push gitlab v1.0.0  # Ancien tag qui fonctionnait
```

### Scénario 3 : Test avant déploiement

```bash
# 1. Modifier le pipeline pour rendre le deploy manuel
# Dans .gitlab-ci.yml, ajouter au job deploy-swarm:
#   when: manual

# 2. Push et observer les tests
git push gitlab main

# 3. Si tests OK, cliquer sur "Play" dans GitLab pour déployer
```

## Nettoyage

### Sur le Swarm

```bash
# Supprimer le stack
docker stack rm monsterstack

# Nettoyer les images non utilisées
docker image prune -a

# Nettoyer tout (ATTENTION)
docker system prune -a --volumes
```

### Dans GitLab

```bash
# Supprimer les anciennes images du registry
# Via l'interface GitLab: Packages & Registries → Container Registry
# Ou via l'API/CLI
```

## Ressources

- [Énoncé du TP](./0_intro.md)
- [README détaillé](./README.md)
- [Documentation Docker Stack](https://docs.docker.com/engine/reference/commandline/stack/)
- [Documentation GitLab CI/CD](https://docs.gitlab.com/ee/ci/)
