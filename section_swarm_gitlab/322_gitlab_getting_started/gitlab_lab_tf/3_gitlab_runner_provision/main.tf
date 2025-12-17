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
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "gitlab" {
  base_url = var.gitlab_url != "" ? var.gitlab_url : var.gitlab_external_url
  token    = var.gitlab_token
}

# ==============================================================================
# Data source pour récupérer le serveur existant
# ==============================================================================
data "hcloud_server" "gitlab_server" {
  name = "${var.prefix}-gitlab-server"
}

# ==============================================================================
# MODULE : GitLab Runner (auto-registration)
# ==============================================================================
module "gitlab_runner" {
  source = "../modules/gitlab_runner"

  gitlab_url      = var.gitlab_url != "" ? var.gitlab_url : var.gitlab_external_url
  gitlab_token    = var.gitlab_token
  server_ip       = data.hcloud_server.gitlab_server.ipv4_address
  ssh_user        = var.ssh_user
  ssh_private_key = var.ssh_private_key

  runner_description  = var.runner_description
  runner_tags         = var.runner_tags
  docker_executor     = var.runner_executor == "docker"
  auto_install_runner = var.auto_install_runner
}

# ==============================================================================
# MODULE : Provisionnement GitLab (groupes, utilisateurs, projets)
# ==============================================================================
module "gitlab_provision" {
  source = "../modules/gitlab_provision"

  users = var.gitlab_users

  depends_on = [module.gitlab_runner]
}
