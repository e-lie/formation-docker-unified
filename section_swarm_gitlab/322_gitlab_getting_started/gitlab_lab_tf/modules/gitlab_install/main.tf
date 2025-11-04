terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Détection automatique si HTTPS doit être activé
locals {
  # Activer HTTPS si l'URL commence par https:// ou si enable_https est explicitement true
  use_https = var.enable_https || (length(regexall("^https://", var.gitlab_external_url)) > 0)

  # Si HTTPS est activé, forcer l'URL à commencer par https://
  final_external_url = local.use_https ? replace(var.gitlab_external_url, "http://", "https://") : var.gitlab_external_url
}

# Génération du fichier docker-compose.yml pour GitLab
data "template_file" "docker_compose" {
  template = file("${path.module}/docker-compose.yml.tpl")
  vars = {
    gitlab_hostname      = var.gitlab_hostname
    gitlab_external_url  = local.final_external_url
    gitlab_root_password = var.gitlab_root_password
    enable_https         = local.use_https
    letsencrypt_email    = var.letsencrypt_email
  }
}

# Installation de GitLab via docker-compose
resource "null_resource" "gitlab_prepare" {
  triggers = {
    server_id        = var.server_id
    docker_installed = var.docker_installation_complete
    compose_content  = data.template_file.docker_compose.rendered
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = var.ssh_private_key != "" ? var.ssh_private_key : null
    timeout     = "5m"
  }

  # Créer le répertoire pour GitLab
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${var.username}/gitlab",
      "chown -R ${var.username}:${var.username} /home/${var.username}/gitlab"
    ]
  }

  # Copier les fichiers de configuration
  provisioner "file" {
    content     = data.template_file.docker_compose.rendered
    destination = "/home/${var.username}/gitlab/docker-compose.yml"
  }

  provisioner "file" {
    source      = "${path.module}/install-gitlab.sh"
    destination = "/home/${var.username}/gitlab/install-gitlab.sh"
  }

  provisioner "file" {
    source      = "${path.module}/install-runner.sh"
    destination = "/home/${var.username}/gitlab/install-runner.sh"
  }

  # Rendre les scripts exécutables
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.username}/gitlab/*.sh",
      "chown -R ${var.username}:${var.username} /home/${var.username}/gitlab"
    ]
  }
}

# Lancement automatique de GitLab (si activé)
resource "null_resource" "gitlab_start" {
  count = var.auto_install ? 1 : 0

  triggers = {
    gitlab_prepared = null_resource.gitlab_prepare.id
    compose_content = data.template_file.docker_compose.rendered
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = var.ssh_private_key != "" ? var.ssh_private_key : null
    timeout     = "5m"
  }

  # Lancer GitLab
  provisioner "remote-exec" {
    inline = [
      "echo '======================================'",
      "echo '  Lancement automatique de GitLab'",
      "echo '======================================'",
      "cd /home/${var.username}/gitlab",
      "docker compose down 2>/dev/null || true",
      "docker compose up -d",
      "echo ''",
      "echo 'GitLab est en cours de demarrage...'",
      "echo 'Cela peut prendre 10-15 minutes.'",
      "echo ''",
      "echo 'Pour suivre les logs :'",
      "echo '  docker compose logs -f gitlab'",
      "echo ''",
      "echo 'Pour verifier le statut :'",
      "echo '  docker compose ps'",
      "echo '  docker exec -it gitlab gitlab-ctl status'",
      "echo ''",
      "echo 'GitLab sera accessible a : ${local.final_external_url}'",
      "echo ''",
    ]
  }

  depends_on = [null_resource.gitlab_prepare]
}
