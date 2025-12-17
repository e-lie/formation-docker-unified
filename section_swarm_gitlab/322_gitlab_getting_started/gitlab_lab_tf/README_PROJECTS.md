# GitLab Lab - Déploiement en 3 Projets

Ce projet Terraform a été divisé en 3 sous-projets indépendants pour faciliter le déploiement progressif de GitLab. Cela permet d'exécuter `terraform apply` en 3 étapes sans avoir à commenter/décommenter des modules.

## Architecture des projets

```
gitlab_lab_tf/
├── modules/                    # Modules Terraform partagés
├── 1_hcloud_server_docker_dns/ # Projet 1: Serveur + Docker + DNS
├── 2_gitlab_install/           # Projet 2: Installation GitLab
├── 3_gitlab_runner_provision/  # Projet 3: Runner + Provisionnement
└── README_PROJECTS.md          # Ce fichier
```

## Prérequis

- Un compte Hetzner Cloud avec un token API
- (Optionnel) Un compte DigitalOcean avec un token API pour le DNS
- Une clé SSH configurée dans Hetzner Cloud
- Terraform >= 1.0

## Déploiement étape par étape

### Étape 1: Serveur + Docker + DNS

Ce projet crée le serveur Hetzner, installe Docker et configure le DNS (optionnel).

```bash
cd 1_hcloud_server_docker_dns

# Copiez le fichier de configuration
cp terraform.tfvars.dist terraform.tfvars

# Éditez terraform.tfvars avec vos tokens
vim terraform.tfvars

# Initialisez Terraform
terraform init

# Déployez
terraform apply
```

**Outputs importants:**
- `server_info` : Informations sur le serveur créé
- `ssh_connection` : Commande SSH pour se connecter
- `dns_records` : Enregistrements DNS créés (si activé)

**Durée estimée:** 2-3 minutes

---

### Étape 2: Installation GitLab

Ce projet installe GitLab sur le serveur créé à l'étape 1.

```bash
cd ../2_gitlab_install

# Copiez le fichier de configuration
cp terraform.tfvars.dist terraform.tfvars

# Éditez terraform.tfvars (utilisez le même hcloud_token et gitlab_external_url)
vim terraform.tfvars

# Initialisez Terraform
terraform init

# Déployez
terraform apply
```

**Outputs importants:**
- `gitlab_url` : URL d'accès à GitLab
- `next_steps` : Instructions pour finaliser l'installation

**Durée estimée:**
- Terraform apply : 1-2 minutes
- Démarrage de GitLab : 10-20 minutes (si `auto_install_gitlab = true`)

**Après le déploiement:**

1. Attendez que GitLab soit accessible (10-20 minutes)
2. Vérifiez l'état sur le serveur :
   ```bash
   ssh gitlab-admin@<SERVER_IP>
   docker ps
   docker logs gitlab-ce
   ```

3. Accédez à GitLab via l'URL affichée dans les outputs

4. Connectez-vous avec :
   - Username: `root`
   - Password: Celui configuré dans `gitlab_root_password`

5. Créez un Personal Access Token :
   - Allez dans **User Settings** > **Access Tokens**
   - Name: `Terraform`
   - Scopes: cochez `api`
   - Expiration: définissez une date ou laissez vide
   - Cliquez sur **Create personal access token**
   - **Copiez le token** (il ne sera plus visible après)

---

### Étape 3: Runner + Provisionnement

Ce projet configure un GitLab Runner et provisionne les utilisateurs pour votre lab.

**IMPORTANT:** Vous devez avoir complété l'étape 2 et créé un Personal Access Token.

```bash
cd ../3_gitlab_runner_provision

# Copiez le fichier de configuration
cp terraform.tfvars.dist terraform.tfvars

# Éditez terraform.tfvars et ajoutez votre gitlab_token
vim terraform.tfvars

# Initialisez Terraform
terraform init

# Déployez
terraform apply
```

**Outputs importants:**
- `runner_info` : Informations sur le runner créé
- `runner_status` : Statut du runner
- `gitlab_users` : Liste des utilisateurs créés (sensible)

**Durée estimée:** 2-3 minutes

**Après le déploiement:**

1. Vérifiez le runner dans GitLab :
   - Allez dans **Admin Area** > **CI/CD** > **Runners**
   - Vous devriez voir votre runner avec le statut "online"

2. Les utilisateurs créés peuvent se connecter avec :
   - Username: `stagiaire1`, `stagiaire2`, etc.
   - Password: `xK9#mZ2$pL7@qR5!`

---

## Configuration des fichiers terraform.tfvars

### Projet 1: Server + Docker + DNS

Variables obligatoires:
```hcl
hcloud_token        = "votre_token_hetzner"
hcloud_ssh_keys     = ["nom-de-votre-cle-ssh"]
gitlab_external_url = "https://gitlab.dopl.uk"  # Votre domaine
```

Variables optionnelles (DNS):
```hcl
digitalocean_token = "votre_token_digitalocean"  # Pour config DNS auto
```

### Projet 2: GitLab Install

Variables obligatoires:
```hcl
hcloud_token        = "votre_token_hetzner"
gitlab_external_url = "https://gitlab.dopl.uk"  # Même que Projet 1
gitlab_root_password = "VotreMotDePasseSecurise123!"
```

Variables importantes:
```hcl
auto_install_gitlab = true  # Lance GitLab automatiquement
enable_https        = true  # Active Let's Encrypt
letsencrypt_email   = "votre@email.com"
```

### Projet 3: Runner + Provision

Variables obligatoires:
```hcl
hcloud_token        = "votre_token_hetzner"
gitlab_external_url = "https://gitlab.dopl.uk"  # Même que précédemment
gitlab_token        = "glpat-xxxxxxxxxxxxx"     # Token créé dans GitLab
```

Variables optionnelles:
```hcl
auto_install_runner = true
runner_executor     = "docker"  # ou "shell"
runner_tags         = ["docker", "auto", "shared"]
```

---

## Workflow complet résumé

```bash
# 1. Serveur + Docker + DNS (2-3 min)
cd 1_hcloud_server_docker_dns
terraform init && terraform apply

# 2. Installation GitLab (10-20 min pour le démarrage)
cd ../2_gitlab_install
terraform init && terraform apply

# Attendez que GitLab soit accessible, puis créez un PAT

# 3. Runner + Provisionnement (2-3 min)
cd ../3_gitlab_runner_provision
# Ajoutez gitlab_token dans terraform.tfvars
terraform init && terraform apply
```

**Durée totale:** ~15-25 minutes

---

## Destruction des ressources

Pour détruire les ressources, procédez dans l'ordre inverse:

```bash
# 1. Détruire Runner + Provisionnement
cd 3_gitlab_runner_provision
terraform destroy

# 2. Détruire GitLab
cd ../2_gitlab_install
terraform destroy

# 3. Détruire Serveur + Docker + DNS
cd ../1_hcloud_server_docker_dns
terraform destroy
```

---

## Avantages de cette approche

1. **Pas de commentaires/décommentaires** : Chaque projet est indépendant
2. **Déploiement progressif** : Testez chaque étape avant de passer à la suivante
3. **Réutilisabilité** : Les modules sont partagés entre les projets
4. **Clarté** : Chaque projet a un objectif précis
5. **Flexibilité** : Déployez seulement ce dont vous avez besoin

---

## Dépendances entre projets

- **Projet 2** dépend de **Projet 1** : Le serveur doit exister
- **Projet 3** dépend de **Projet 2** : GitLab doit être installé et accessible

Les dépendances sont gérées via:
- `data "hcloud_server"` : Récupère le serveur créé au Projet 1
- Le token GitLab : Nécessaire pour communiquer avec l'API GitLab

---

## Dépannage

### Projet 2: GitLab ne démarre pas

```bash
# Connectez-vous au serveur
ssh gitlab-admin@<SERVER_IP>

# Vérifiez les logs
docker logs gitlab-ce

# Vérifiez l'état
docker ps -a
```

### Projet 3: Erreur "GitLab API not reachable"

- Vérifiez que GitLab est accessible via `gitlab_external_url`
- Vérifiez que le `gitlab_token` est valide et a les permissions `api`
- Vérifiez que le token appartient à un utilisateur administrateur (root)

### Data source ne trouve pas le serveur

Vérifiez que le `prefix` est identique dans tous les projets. Le serveur est recherché avec le nom `${prefix}-gitlab-server`.

---

## Support

Pour plus d'informations sur les modules utilisés, consultez la documentation dans `modules/*/README.md`.
