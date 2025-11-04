# Déploiement de Serveurs Ubuntu Noble avec Docker sur Hetzner Cloud

Ce projet Terraform déploie automatiquement des serveurs Ubuntu 24.04 (Noble) sur Hetzner Cloud avec Docker préinstallé.

## Prérequis

1. Un compte Hetzner Cloud
2. Un token API Hetzner Cloud ([générer ici](https://console.hetzner.cloud/))
3. Terraform installé (version >= 1.0)
4. Une clé SSH ajoutée à votre compte Hetzner Cloud

## Configuration

1. Créez un fichier `terraform.tfvars` avec vos informations :

```hcl
hcloud_token    = "votre_token_hetzner_cloud"
prefix          = "prod"                    # Préfixe pour les noms (permet de déployer plusieurs environnements)
username        = "votre_nom_utilisateur"   # Utilisateur à créer sur les serveurs
server_type     = "cx22"                    # Type de serveur Hetzner Cloud
node_count      = 3                         # Nombre de nœuds à déployer
docker_mode     = "standard"                # "standard" ou "rootless"
enable_swarm    = false                     # Activer Docker Swarm
hcloud_ssh_keys = ["nom-de-votre-cle-ssh"] # Noms de vos clés SSH (optionnel)
```

### Variables disponibles

**Infrastructure Hetzner Cloud :**
- `hcloud_token` (requis) : Token API Hetzner Cloud
- `prefix` (optionnel, défaut: "ubuntu") : Préfixe pour les noms des serveurs et labels
- `username` (requis) : Nom d'utilisateur à créer sur les serveurs (sera ajouté au groupe docker avec accès sudo)
- `server_type` (optionnel, défaut: "cx22") : Type de serveur Hetzner Cloud
- `node_count` (optionnel, défaut: 3) : Nombre de nœuds Docker à déployer (1-100)
- `hcloud_ssh_keys` (optionnel) : Liste des noms de clés SSH Hetzner Cloud

**Docker & Swarm :**
- `docker_mode` (optionnel, défaut: "standard") : Mode d'installation de Docker ("standard" ou "rootless")
- `enable_swarm` (optionnel, défaut: false) : Activer Docker Swarm (incompatible avec mode rootless)

**DNS DigitalOcean (optionnel) :**
- `enable_dns` (optionnel, défaut: true) : Activer la création automatique des enregistrements DNS
- `digitalocean_token` (requis si enable_dns = true) : Token API DigitalOcean
- `dns_domain` (optionnel, défaut: "dopl.uk") : Domaine racine dans DigitalOcean
- `dns_subdomain` (optionnel, défaut: "swarm") : Sous-domaine (ex: swarm.dopl.uk)
- `dns_ttl` (optionnel, défaut: 300) : TTL des enregistrements DNS en secondes
- `dns_create_wildcard` (optionnel, défaut: true) : Créer des enregistrements wildcard par nœud

### Types de serveurs disponibles

Quelques exemples de types de serveurs Hetzner Cloud :

| Type | vCPU | RAM | Disque | Prix/mois (approx.) |
|------|------|-----|--------|---------------------|
| cx22 | 2 | 4 GB | 40 GB | ~7,50€ |
| cx32 | 4 | 8 GB | 80 GB | ~15€ |
| cx42 | 8 | 16 GB | 160 GB | ~30€ |
| cpx11 | 2 | 2 GB | 40 GB | ~5€ |
| cpx21 | 3 | 4 GB | 80 GB | ~10€ |
| cpx31 | 4 | 8 GB | 160 GB | ~20€ |

Pour voir tous les types disponibles :
```bash
curl -H "Authorization: Bearer votre_token" https://api.hetzner.cloud/v1/server_types
```

**Note:** Pour lister vos clés SSH, utilisez la commande :
```bash
curl -H "Authorization: Bearer votre_token" https://api.hetzner.cloud/v1/ssh_keys
```

## Utilisation

### Déploiement simple

1. Initialisez Terraform :
```bash
terraform init
```

2. Vérifiez le plan de déploiement :
```bash
terraform plan
```

3. Déployez l'infrastructure :
```bash
terraform apply
```

4. Les adresses IP des serveurs s'afficheront à la fin du déploiement.

### Déployer plusieurs environnements

Vous pouvez déployer plusieurs environnements en utilisant des workspaces ou des préfixes différents :

**Exemple avec différents fichiers tfvars :**

```bash
# Environnement de production
terraform apply -var-file="prod.tfvars"

# Environnement de test
terraform apply -var-file="test.tfvars"
```

**Exemple avec workspaces :**

```bash
# Créer et utiliser un workspace pour la production
terraform workspace new prod
terraform apply -var="prefix=prod"

# Créer et utiliser un workspace pour le test
terraform workspace new test
terraform apply -var="prefix=test"
```

Les serveurs seront nommés selon le préfixe et le nombre de nœuds :
- Avec `prefix = "prod"` et `node_count = 3` : prod-server-1, prod-server-2, prod-server-3
- Avec `prefix = "test"` et `node_count = 5` : test-server-1, test-server-2, test-server-3, test-server-4, test-server-5

## Ressources créées

- N serveurs Ubuntu 24.04 (Noble Numbat) selon `node_count` (défaut: 3)
- Type de serveur : configurable (défaut: cx22 - 2 vCPU, 4 GB RAM, 40 GB SSD)
- Localisation : automatique (Hetzner choisit le datacenter optimal)
- Docker CE installé et configuré sur chaque serveur
- Utilisateur personnalisé créé avec accès sudo et docker

## Architecture de provisionnement

Le projet utilise une approche en trois étapes pour configurer les serveurs :

### Étape 1 : Bootstrap (Cloud-Init / user_data)

Le script **[bootstrap.sh](bootstrap.sh)** est exécuté automatiquement au premier démarrage via cloud-init :
- Mise à jour du système
- Installation des dépendances de base (curl, git, vim, htop, etc.)
- Création de l'utilisateur personnalisé
- Configuration de sudo sans mot de passe
- Copie des clés SSH

### Étape 2 : Installation Docker (null_resource via SSH)

Après le bootstrap, Terraform se connecte en SSH pour installer Docker :

**Mode standard** - **[install_docker.sh](install_docker.sh)** :
- Ajout du dépôt officiel Docker
- Installation de Docker CE et Docker Compose
- Configuration et démarrage du service
- Ajout de l'utilisateur au groupe docker
- Docker s'exécute avec les privilèges root (mode classique)

**Mode rootless** - **[install_docker_rootless.sh](install_docker_rootless.sh)** :
- Installation de Docker sans privilèges root
- Configuration des namespaces utilisateur
- Docker s'exécute sous le compte utilisateur (plus sécurisé)
- Isolation complète sans accès root
- Parfait pour les environnements multi-tenants

### Étape 3 : Docker Swarm (null_resource via SSH - optionnel)

Si `enable_swarm = true`, le script **[swarm_install.sh](swarm_install.sh)** configure le cluster :
- Initialisation de Docker Swarm sur le premier nœud (manager)
- Génération des tokens de jonction
- Création de scripts helper pour rejoindre le swarm
- Compatible uniquement avec `docker_mode = "standard"`

### Avantages de cette approche

- ✅ **Séparation des responsabilités** : Bootstrap rapide, puis installation détaillée
- ✅ **Meilleure observabilité** : Les logs Terraform montrent la progression de chaque étape
- ✅ **Flexibilité** : Possibilité de réexécuter Docker/Swarm sans recréer les serveurs
- ✅ **Débogage facilité** : Erreurs plus faciles à identifier et corriger

### Comparaison Docker Standard vs Rootless

| Caractéristique | Standard | Rootless |
|----------------|----------|----------|
| Privilèges | Nécessite root | Aucun privilège root |
| Sécurité | Standard | Meilleure isolation |
| Performance | Maximale | Légèrement réduite |
| Compatibilité | 100% | ~95% des cas d'usage |
| Ports < 1024 | Oui | Non (utiliser > 1024) |
| Docker Swarm | ✅ Compatible | ❌ Incompatible |
| Recommandé pour | Production classique | Environnements partagés |

## Docker Swarm

Lorsque `enable_swarm = true`, le projet configure automatiquement un cluster Docker Swarm :

- Le **premier nœud** (server-1) est initialisé comme **manager**
- Les autres nœuds sont configurés comme **workers** potentiels
- Les tokens de jonction sont générés automatiquement

### Configuration Swarm

1. Activez Swarm dans votre `terraform.tfvars` :
```hcl
enable_swarm = true
docker_mode  = "standard"  # IMPORTANT: Swarm nécessite le mode standard
node_count   = 3           # Au moins 3 nœuds recommandés pour la haute disponibilité
```

2. Déployez l'infrastructure :
```bash
terraform apply
```

3. Connectez-vous au manager (premier serveur) :
```bash
ssh <username>@<manager-ip>
```

4. Récupérez les informations du cluster :
```bash
# Voir les informations du swarm
cat /root/swarm-info.txt

# Obtenir le token pour les workers
docker swarm join-token worker

# Obtenir le token pour les managers
docker swarm join-token manager
```

5. Sur les autres nœuds, utilisez le script helper :
```bash
ssh <username>@<worker-ip>
sudo /root/join-swarm.sh <manager-ip> <join-token>
```

### Vérification du cluster

```bash
# Sur le manager, lister les nœuds
docker node ls

# Déployer un service de test
docker service create --name nginx --replicas 3 -p 80:80 nginx

# Vérifier les services
docker service ls
docker service ps nginx
```

### Notes importantes

- ⚠️ **Swarm est incompatible avec le mode rootless** : Terraform affichera une erreur si vous tentez d'activer les deux
- 🔒 Le premier nœud est automatiquement le manager initial
- 📝 Les tokens et commandes de jonction sont sauvegardés dans `/root/swarm-info.txt` sur le manager
- 🔄 Pour un cluster hautement disponible, configurez au moins 3 managers

## DNS DigitalOcean (Optionnel)

Le projet peut créer automatiquement des enregistrements DNS dans DigitalOcean pointant vers vos serveurs Hetzner.

### Configuration DNS

1. Activez le DNS dans votre `terraform.tfvars` :
```hcl
enable_dns         = true
digitalocean_token = "votre_token_digitalocean"
dns_domain         = "dopl.uk"
dns_subdomain      = "swarm"
prefix             = "prod"
```

2. Le projet créera automatiquement :
   - **Un enregistrement par serveur** : `prod-server-1.swarm.dopl.uk`, `prod-server-2.swarm.dopl.uk`, etc.
   - **Un enregistrement principal** : `prod.swarm.dopl.uk` → pointe vers le manager (serveur 1)
   - **Un wildcard principal** : `*.prod.swarm.dopl.uk` → pointe vers le manager
   - **Un wildcard par serveur** : `*.prod-server-1.swarm.dopl.uk`, `*.prod-server-2.swarm.dopl.uk`, etc.

### Exemples d'utilisation

Avec `prefix = "prod"`, `dns_subdomain = "swarm"`, `dns_domain = "dopl.uk"` :

| Type | Domaine | Pointe vers |
|------|---------|-------------|
| Principal | `prod.swarm.dopl.uk` | Manager (server-1) |
| Wildcard principal | `*.prod.swarm.dopl.uk` | Manager (server-1) |
| Serveur 1 | `prod-server-1.swarm.dopl.uk` | Serveur 1 |
| Wildcard serveur 1 | `*.prod-server-1.swarm.dopl.uk` | Serveur 1 |
| Serveur 2 | `prod-server-2.swarm.dopl.uk` | Serveur 2 |
| Wildcard serveur 2 | `*.prod-server-2.swarm.dopl.uk` | Serveur 2 |

### Cas d'usage

Les enregistrements wildcard sont parfaits pour :
- 🌐 **Traefik** : Router automatiquement les sous-domaines vers les services
- 🐳 **Docker Swarm services** : Exposer des services avec des sous-domaines dynamiques
- 📦 **Multi-tenancy** : Chaque utilisateur/client a son propre sous-domaine

### Prérequis DNS

- Votre domaine (`dopl.uk`) doit être configuré dans DigitalOcean
- Le token DigitalOcean doit avoir les permissions d'écriture sur les DNS

## Outputs

Le projet affiche deux outputs :

- `server_ips` : Dictionnaire avec les adresses IPv4 et IPv6 de chaque serveur
- `server_ips_list` : Liste simple des adresses IPv4

## Connexion aux serveurs

Vous pouvez vous connecter avec l'utilisateur créé ou avec root :

```bash
# Avec votre utilisateur personnalisé
ssh <username>@<ip_address>

# Ou avec root
ssh root@<ip_address>
```

Pour vérifier que Docker est installé et accessible :
```bash
# L'utilisateur peut utiliser docker sans sudo
ssh <username>@<ip_address> "docker --version"
ssh <username>@<ip_address> "docker ps"
```

**Note:** Les clés SSH configurées dans Hetzner Cloud sont automatiquement copiées pour l'utilisateur créé.

## Nettoyage

Pour détruire toutes les ressources créées :
```bash
terraform destroy
```

## Coût estimé

Le type de serveur cx22 coûte environ 0,01€/heure par serveur (soit ~7,50€/mois par serveur).
Pour 3 serveurs : ~22,50€/mois.
