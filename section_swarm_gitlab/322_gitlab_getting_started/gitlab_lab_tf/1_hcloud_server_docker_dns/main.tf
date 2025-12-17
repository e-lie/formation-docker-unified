terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
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

provider "digitalocean" {
  token = var.digitalocean_token
}

# ==============================================================================
# MODULE 1 : Création du serveur Hetzner Cloud
# ==============================================================================
module "hcloud_serveur" {
  source = "../modules/hcloud_serveur"

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
  source = "../modules/docker_install"

  server_id       = module.hcloud_serveur.server_id
  server_ip       = module.hcloud_serveur.server_ipv4
  username        = var.username
  ssh_user        = var.ssh_user
  ssh_private_key = var.ssh_private_key

  depends_on = [module.hcloud_serveur]
}

# ==============================================================================
# MODULE 3 : Configuration DNS (optionnel)
# ==============================================================================
module "dns" {
  source = "../modules/dns"

  digitalocean_token  = var.digitalocean_token
  gitlab_external_url = var.gitlab_external_url
  server_ipv4         = module.hcloud_serveur.server_ipv4
  server_ipv6         = module.hcloud_serveur.server_ipv6
  dns_ttl             = var.dns_ttl

  depends_on = [module.hcloud_serveur]
}
