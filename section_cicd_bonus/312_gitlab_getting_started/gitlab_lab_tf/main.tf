terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# ==============================================================================
# Provider GitLab
# ==============================================================================
# IMPORTANT : Commentez ce bloc lors du premier déploiement !
#
# Lors du PREMIER terraform apply :
#   - Commentez le provider gitlab ci-dessous
#   - Commentez le module gitlab_runner plus bas
#
# Après que GitLab soit démarré (15-20 min) :
#   1. Créez un Personal Access Token dans GitLab
#   2. Configurez gitlab_token dans terraform.tfvars
#   3. Décommentez le provider et le module ci-dessous
#   4. Relancez terraform apply
# ==============================================================================


provider "gitlab" {
  base_url = var.gitlab_url != "" ? var.gitlab_url : var.gitlab_external_url
  token    = var.gitlab_token
}


# ==============================================================================
# MODULE 1 : Création du serveur Hetzner Cloud
# ==============================================================================
module "hcloud_serveur" {
  source = "./modules/hcloud_serveur"

  server_name     = "${var.prefix}-gitlab-server"
  username        = var.username
  server_type     = var.server_type
  hcloud_ssh_keys = var.hcloud_ssh_keys

  labels = {
    environment = "lab"
    managed_by  = "terraform"
    prefix      = var.prefix
    service     = "gitlab"
  }
}

# ==============================================================================
# MODULE 2 : Installation de Docker
# ==============================================================================
module "docker_install" {
  source = "./modules/docker_install"

  server_id       = module.hcloud_serveur.server_id
  server_ip       = module.hcloud_serveur.server_ipv4
  username        = var.username
  ssh_user        = var.ssh_user
  ssh_private_key = var.ssh_private_key

  depends_on = [module.hcloud_serveur]
}

# ==============================================================================
# MODULE 3 : Préparation de GitLab (fichiers docker-compose et scripts)
# ==============================================================================
module "gitlab_install" {
  source = "./modules/gitlab_install"

  server_id       = module.hcloud_serveur.server_id
  server_ip       = module.hcloud_serveur.server_ipv4
  username        = var.username
  ssh_user        = var.ssh_user
  ssh_private_key = var.ssh_private_key

  gitlab_hostname              = var.gitlab_hostname
  gitlab_external_url          = var.gitlab_external_url
  gitlab_root_password         = var.gitlab_root_password
  enable_https                 = var.enable_https
  letsencrypt_email            = var.letsencrypt_email
  auto_install                 = var.auto_install_gitlab
  docker_installation_complete = module.docker_install.installation_complete

  depends_on = [module.docker_install]
}

# ==============================================================================
# MODULE 4 : Configuration DNS (optionnel)
# Ce module crée automatiquement des enregistrements DNS A et AAAA
# sur DigitalOcean si vous fournissez un token et une URL avec domaine
# ==============================================================================

# Provider DigitalOcean pour la gestion DNS (optionnel)
provider "digitalocean" {
  token = var.digitalocean_token
}

module "dns" {
  source = "./modules/dns"

  digitalocean_token  = var.digitalocean_token
  gitlab_external_url = var.gitlab_external_url
  server_ipv4         = module.hcloud_serveur.server_ipv4
  server_ipv6         = module.hcloud_serveur.server_ipv6
  dns_ttl             = var.dns_ttl

  depends_on = [module.hcloud_serveur]
}

# ==============================================================================
# MODULE 5 : GitLab Runner (auto-registration)
# ==============================================================================
# IMPORTANT : Commentez ce module lors du premier déploiement !
#
# Ce module nécessite que :
#   - GitLab soit démarré et accessible
#   - Le provider GitLab soit configuré (voir ci-dessus)
#   - Un Personal Access Token soit créé
#
# Décommentez ce bloc EN MÊME TEMPS que le provider GitLab ci-dessus
# ==============================================================================


module "gitlab_runner" {
  source = "./modules/gitlab_runner"

  gitlab_url      = var.gitlab_url != "" ? var.gitlab_url : var.gitlab_external_url
  gitlab_token    = var.gitlab_token
  server_ip       = module.hcloud_serveur.server_ipv4
  ssh_user        = var.ssh_user
  ssh_private_key = var.ssh_private_key

  runner_description  = var.runner_description
  runner_tags         = var.runner_tags
  docker_executor     = var.runner_executor == "docker"
  auto_install_runner = var.auto_install_runner

  depends_on = [module.gitlab_install]
}


# ==============================================================================
# MODULE 6 : Provisionnement GitLab (groupes, utilisateurs, projets)
# Ce module doit être appliqué APRÈS l'installation manuelle de GitLab
# Commentez ce module lors du premier apply, puis décommentez après avoir :
# 1. Installé GitLab avec les scripts manuels
# 2. Créé un Personal Access Token
# 3. Configuré les variables gitlab_url et gitlab_token
# ==============================================================================

# Décommentez le bloc ci-dessous après l'installation de GitLab
module "gitlab_provision" {
  source = "./modules/gitlab_provision"

  users = var.gitlab_users
}
