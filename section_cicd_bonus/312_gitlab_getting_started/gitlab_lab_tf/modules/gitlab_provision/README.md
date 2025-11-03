# Module GitLab Provision - Configuration Simplifiée

Ce module Terraform crée automatiquement des utilisateurs de lab dans GitLab avec une configuration simplifiée.

## Fonctionnalités

- Création automatique de 4 utilisateurs de lab
- Mot de passe identique pour tous : `devops101`
- Ajout automatique d'une clé SSH publique à tous les utilisateurs
- Pas de groupes (les utilisateurs sont créés directement)

## Utilisateurs créés

Le module crée les utilisateurs suivants :

| Username      | Email                   | Nom          | Mot de passe |
|---------------|-------------------------|--------------|--------------|
| stagiaire1    | stagiaire1@lab.local    | Stagiaire 1  | devops101    |
| stagiaire2    | stagiaire2@lab.local    | Stagiaire 2  | devops101    |
| stagiaire3    | stagiaire3@lab.local    | Stagiaire 3  | devops101    |
| stagiaire4    | stagiaire4@lab.local    | Stagiaire 4  | devops101    |

## Configuration

### Variables

- `user_count` (optionnel) : Nombre d'utilisateurs à créer (défaut: 4)
- `user_password` (optionnel) : Mot de passe pour tous les utilisateurs (défaut: "devops101")
- `ssh_public_key` (requis) : Clé SSH publique à ajouter à tous les utilisateurs

### Exemple d'utilisation

```hcl
module "gitlab_provision" {
  source = "./modules/gitlab_provision"

  user_count     = 4
  user_password  = "devops101"
  ssh_public_key = file("${path.module}/id_stagiaire.pub")
}
```

## Clé SSH de lab

La clé SSH publique utilisée est : `id_stagiaire.pub`

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBXHgv6fDeMM/zbqXpzdANeNbltG74+2Q1pBC9CXRc0M root@lxd-remote
```

La clé privée correspondante : `id_stagiaire` (⚠️ À ne pas committer en production!)

## Outputs

Le module expose les outputs suivants :

- `users` : Liste des utilisateurs créés avec leurs informations (id, username, email, name)
- `user_count` : Nombre total d'utilisateurs créés
- `ssh_keys_added` : Nombre de clés SSH ajoutées

## Prérequis

1. GitLab doit être installé et accessible
2. Un Personal Access Token GitLab avec les permissions nécessaires :
   - `api` (pour créer users et SSH keys)
   - `read_api`
   - `write_repository`

## Déploiement

### 1. Installation initiale de GitLab

Lors du **premier déploiement**, commentez ce module dans `main.tf` car GitLab n'est pas encore installé.

### 2. Configuration du provider GitLab

Après l'installation de GitLab :

1. Connectez-vous à GitLab en tant que root
2. Créez un Personal Access Token : Settings > Access Tokens
3. Ajoutez le token dans `terraform.tfvars` :

```hcl
gitlab_token = "votre-token-ici"
```

### 3. Application du module

Décommentez le module dans `main.tf` et lancez :

```bash
terraform init
terraform plan
terraform apply
```

## Sécurité

⚠️ **Important** : Cette configuration est conçue pour un environnement de lab/formation uniquement :

- Mot de passe identique pour tous les utilisateurs
- Clé SSH partagée et non sécurisée
- Pas de confirmation d'email (`skip_confirmation = true`)

**Ne jamais utiliser cette configuration en production !**

## Personnalisation

Pour modifier le nombre d'utilisateurs ou le mot de passe, éditez les valeurs dans l'appel du module :

```hcl
module "gitlab_provision" {
  source = "./modules/gitlab_provision"

  user_count     = 10           # Créer 10 utilisateurs
  user_password  = "autremdp"   # Autre mot de passe
  ssh_public_key = file("${path.module}/ma_cle.pub")
}
```

## Resources Terraform utilisées

- `gitlab_user` : Création des utilisateurs
- `gitlab_user_sshkey` : Ajout des clés SSH aux utilisateurs

## Documentation

- [GitLab Provider Terraform](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs)
- [Resource: gitlab_user](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/user)
- [Resource: gitlab_user_sshkey](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/user_sshkey)
