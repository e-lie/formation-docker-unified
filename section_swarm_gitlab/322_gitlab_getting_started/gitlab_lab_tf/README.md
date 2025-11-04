# 🚀 GitLab CE - Déploiement Automatisé avec Terraform

Projet Terraform pour déployer automatiquement une instance GitLab CE complète sur **Hetzner Cloud** avec HTTPS, DNS et GitLab Runner.

## ✨ Fonctionnalités

- 🏗️ **Infrastructure automatique** : Serveur Hetzner Cloud + Docker
- 🔒 **HTTPS automatique** : Certificats Let's Encrypt avec renouvellement auto
- 🌐 **DNS automatique** : Enregistrements A/AAAA sur DigitalOcean
- 🚀 **GitLab auto-démarré** : Lancé automatiquement après le déploiement
- 🏃 **Runner auto-enregistré** : Runner Docker configuré via l'API GitLab
- 📦 **Approche modulaire** : 6 modules Terraform réutilisables

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 1 : Infrastructure (terraform apply #1)              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. hcloud_serveur    → Serveur Ubuntu 24.04 (Hetzner)     │
│  2. docker_install    → Docker + Docker Compose             │
│  3. gitlab_install    → GitLab CE (auto-démarré)           │
│  4. dns               → gitlab.dopl.uk → IP serveur         │
│                                                              │
│  Résultat : GitLab accessible via https://gitlab.dopl.uk    │
│             (attendre 15-20 min pour démarrage complet)     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Phase 2 : Runner (terraform apply #2)                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  5. gitlab_runner     → Runner Docker auto-enregistré       │
│  6. gitlab_provision  → Groupes/Users/Projets (optionnel)  │
│                                                              │
│  Résultat : Runner actif, prêt à exécuter les pipelines     │
└─────────────────────────────────────────────────────────────┘
```

### Modules

| Module | Rôle | Auto-activé |
|--------|------|-------------|
| `hcloud_serveur` | Création serveur Hetzner | ✅ Phase 1 |
| `docker_install` | Installation Docker | ✅ Phase 1 |
| `gitlab_install` | Déploiement GitLab | ✅ Phase 1 |
| `dns` | Configuration DNS | ✅ Phase 1 (si token DO) |
| `gitlab_runner` | Runner auto-enregistré | ⏸️ Phase 2 (commenté) |
| `gitlab_provision` | Provisioning GitLab | ⏸️ Phase 3 (optionnel) |

---

## 📋 Prérequis

### Obligatoires

- [Hetzner Cloud Account](https://console.hetzner.cloud/) + Token API
- Terraform >= 1.0
- Clé SSH ajoutée à Hetzner Cloud
- [DigitalOcean Account](https://cloud.digitalocean.com/) + Token (pour DNS auto)
- Serveur recommandé : 4 vCPU, 8 GB RAM

---

## 🚀 Installation Rapide

### Phase 1 : Déploiement initial (~20 minutes)

#### 1. Cloner et configurer

```bash
cd gitlab_tf
cp terraform.tfvars.dist terraform.tfvars
```

#### 2. Éditer `terraform.tfvars`

```hcl
# === Infrastructure ===
hcloud_token = "VOTRE_TOKEN_HETZNER"
hcloud_ssh_keys = ["nom_de_votre_cle_ssh"]

# === DNS (optionnel) ===
digitalocean_token = "VOTRE_TOKEN_DIGITALOCEAN"

# === GitLab ===
gitlab_external_url = "https://gitlab.dopl.uk"
gitlab_root_password = "VotreMotDePasseSecurise123!"
letsencrypt_email = "votre.email@example.com"

# === Auto-installation ===
auto_install_gitlab = true   # GitLab démarre automatiquement
enable_https = true           # HTTPS avec Let's Encrypt
```

#### 3. Déployer

```bash
terraform init
terraform apply
```

**✅ Résultat attendu :**
```
Apply complete! Resources: 6 added

Outputs:
gitlab_url = "https://gitlab.dopl.uk"
dns_enabled = true
server_info = {
  ipv4 = "47.62.242.100"
  name = "lab-gitlab-server"
}
```

#### 4. Attendre le démarrage de GitLab (15-20 min)

```bash
# Suivre les logs en temps réel
ssh gitlab-admin@<IP_SERVEUR>
cd ~/gitlab
docker compose logs -f gitlab

# GitLab est prêt quand vous voyez :
# "gitlab Reconfigured!"
```

#### 5. Accéder à GitLab

```
URL      : https://gitlab.dopl.uk
Username : root
Password : VotreMotDePasseSecurise123!
```

---

### Phase 2 : Runner GitLab (~5 minutes)

#### 1. Créer un Personal Access Token

1. Connectez-vous à GitLab (root)
2. **User Settings** → **Access Tokens**
3. Créez un token :
   - Name: `Terraform`
   - Scopes: `api` ✅
   - Role: Administrator
4. **Copiez le token** : `glpat-xxxxxxxxxxxxx`

#### 2. Configurer le token

Dans `terraform.tfvars`, ajoutez :

```hcl
gitlab_token = "glpat-xxxxxxxxxxxxx"
```

#### 3. Activer le runner

Dans `main.tf`, **décommentez** (2 blocs) :

**Bloc 1** - Provider GitLab (~ligne 38) :
```terraform
provider "gitlab" {
  base_url = var.gitlab_url != "" ? var.gitlab_url : var.gitlab_external_url
  token    = var.gitlab_token
}
```

**Bloc 2** - Module gitlab_runner (~ligne 138) :
```terraform
module "gitlab_runner" {
  source = "./modules/gitlab_runner"
  # ... (garder tout le reste)
}
```

**Optionnel** - Outputs dans `outputs.tf` (~ligne 49)

#### 4. Déployer le runner

```bash
terraform apply
```

**✅ Résultat :**
```
Apply complete! Resources: 2 added

Outputs:
runner_created = true
runner_info = {
  id = "r_12345"
  description = "Docker Runner - Auto-configured"
  status = "active"
  tags = ["docker", "auto", "shared"]
}
```

#### 5. Vérifier

**Dans GitLab :**
- **Admin Area** → **CI/CD** → **Runners**
- Vous devriez voir votre runner avec un point vert ✅

**Tester avec un pipeline :**
Créez `.gitlab-ci.yml` dans un projet :
```yaml
test:
  tags: [docker]
  script:
    - echo "Hello from GitLab Runner!"
```

---

## 📁 Structure du Projet

```
gitlab_tf/
├── main.tf                    # Orchestration des modules
├── variables.tf               # Variables globales
├── outputs.tf                 # Outputs Terraform
├── terraform.tfvars.dist      # Template de configuration
├── terraform.tfvars           # Votre configuration (à créer)
├── README.md                  # Ce fichier
├── DEPLOYMENT_GUIDE.md        # Guide détaillé en 2 phases
│
└── modules/
    ├── hcloud_serveur/        # Serveur Hetzner Cloud
    ├── docker_install/        # Installation Docker
    ├── gitlab_install/        # Déploiement GitLab
    ├── dns/                   # DNS DigitalOcean
    ├── gitlab_runner/         # Runner auto-enregistré
    └── gitlab_provision/      # Provisioning GitLab (optionnel)
```

---

## ⚙️ Configuration Avancée

### Variables Principales

| Variable | Défaut | Description |
|----------|--------|-------------|
| `gitlab_external_url` | `""` | URL GitLab (ex: https://gitlab.example.com) |
| `enable_https` | `true` | Active Let's Encrypt automatiquement |
| `auto_install_gitlab` | `true` | Lance GitLab automatiquement |
| `auto_install_runner` | `true` | Enregistre le runner automatiquement |
| `server_type` | `cpx31` | Type de serveur Hetzner |
| `runner_executor` | `docker` | Type d'executor (docker/shell) |
| `runner_tags` | `["docker","auto","shared"]` | Tags du runner |

### DNS Automatique

Si vous fournissez `digitalocean_token`, le module DNS crée automatiquement :
- Enregistrement **A** : `gitlab.dopl.uk` → IPv4 du serveur
- Enregistrement **AAAA** : `gitlab.dopl.uk` → IPv6 du serveur

Sans token DigitalOcean, configurez votre DNS manuellement.

### HTTPS / Let's Encrypt

HTTPS est **activé par défaut** si :
- `gitlab_external_url` commence par `https://`, OU
- `enable_https = true`

Let's Encrypt génère automatiquement un certificat valide 90 jours avec renouvellement auto.

---

## 🛠️ Commandes Utiles

### Terraform

```bash
# Initialiser
terraform init

# Voir le plan
terraform plan

# Appliquer
terraform apply

# Détruire (⚠️ supprime tout)
terraform destroy

# Forcer la recréation d'une ressource
terraform taint 'module.gitlab_install.null_resource.gitlab_start[0]'
terraform apply
```

### GitLab

```bash
# SSH vers le serveur
ssh gitlab-admin@<IP>

# Logs GitLab
cd ~/gitlab
docker compose logs -f gitlab

# Status des services
docker exec -it gitlab gitlab-ctl status

# Redémarrer GitLab
docker compose restart gitlab

# Reconfigurer GitLab
docker exec -it gitlab gitlab-ctl reconfigure
```

### Runner

```bash
# Logs du runner
docker logs -f gitlab-runner

# Lister les runners
docker exec -it gitlab-runner gitlab-runner list

# Vérifier la config
docker exec -it gitlab-runner cat /etc/gitlab-runner/config.toml
```

---

## 🔍 Dépannage

### GitLab ne démarre pas

```bash
# Vérifier les logs
docker compose logs gitlab | grep -i error

# Problème courant : external_url vide
# → Vérifier terraform.tfvars : gitlab_external_url doit être renseigné
```

### Let's Encrypt échoue

```bash
# Vérifier le DNS
dig gitlab.dopl.uk +short
# Doit retourner l'IP de votre serveur

# Vérifier que le port 80 est accessible
curl -I http://gitlab.dopl.uk
```

### Runner non visible dans GitLab

1. Vérifier que `gitlab_token` a le scope `api`
2. Vérifier que le provider et le module sont décommentés
3. Vérifier les logs : `docker logs gitlab-runner`

### Erreur "no such host" au premier apply

✅ **Normal** si le provider GitLab n'est pas commenté lors du premier déploiement.

➡️ **Solution** : Commentez le provider et le module runner (c'est déjà fait par défaut).

---

## 📚 Documentation

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Guide complet en 2 phases
- **[modules/dns/README.md](modules/dns/README.md)** - Configuration DNS
- [Documentation GitLab](https://docs.gitlab.com/ee/install/)
- [Provider Terraform GitLab](https://registry.terraform.io/providers/gitlabhq/gitlab/)

---

## 🎯 Exemples de Cas d'Usage

### 1. Lab de formation (par défaut)

```hcl
server_type = "cpx31"
auto_install_gitlab = true
enable_https = true
runner_executor = "docker"
```

### 2. Production simple

```hcl
server_type = "cpx41"  # 8 vCPU, 16 GB RAM
gitlab_external_url = "https://gitlab.monentreprise.com"
enable_https = true
runner_tags = ["production", "docker"]
```

### 3. Développement local (sans DNS)

```hcl
gitlab_external_url = "http://192.168.1.100"
enable_https = false
digitalocean_token = ""  # Pas de DNS auto
```

---

## 🤝 Contribution

Ce projet est un lab de formation. Pour toute question ou amélioration :
1. Ouvrez une issue
2. Proposez une pull request
3. Consultez la documentation des modules

---

## 📝 Licence

Projet éducatif - Utilisation libre pour vos labs et formations.

---

## ⚡ Résumé en 3 commandes

```bash
# 1. Configurer
cp terraform.tfvars.dist terraform.tfvars
# Éditer terraform.tfvars avec vos tokens

# 2. Déployer
terraform init && terraform apply

# 3. Attendre 15-20 min, puis accéder à :
# https://gitlab.dopl.uk (root / VotreMotDePasse)
```

**Pour le runner** : Suivez les instructions de la Phase 2 ci-dessus.

---

**🎉 Votre GitLab est maintenant prêt à l'emploi !**
