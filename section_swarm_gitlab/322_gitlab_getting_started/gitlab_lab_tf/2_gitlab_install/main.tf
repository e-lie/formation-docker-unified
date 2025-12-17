terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# ==============================================================================
# Data source pour récupérer le serveur existant
# ==============================================================================
data "hcloud_server" "gitlab_server" {
  name = "${var.prefix}-gitlab-server"
}

# ==============================================================================
# MODULE : Installation de GitLab
# ==============================================================================
module "gitlab_install" {
  source = "../modules/gitlab_install"

  server_id       = data.hcloud_server.gitlab_server.id
  server_ip       = data.hcloud_server.gitlab_server.ipv4_address
  username        = var.username
  ssh_user        = var.ssh_user
  ssh_private_key = var.ssh_private_key

  gitlab_hostname              = var.gitlab_hostname
  gitlab_external_url          = var.gitlab_external_url
  gitlab_root_password         = var.gitlab_root_password
  enable_https                 = var.enable_https
  letsencrypt_email            = var.letsencrypt_email
  auto_install                 = var.auto_install_gitlab
  docker_installation_complete = true
}
