terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
  }
}

# ============================================================================
# Création d'un runner au niveau instance (admin)
# ============================================================================

# Créer un instance runner (nécessite un Personal Access Token admin)
resource "gitlab_user_runner" "main" {
  count = var.gitlab_token != "" ? 1 : 0

  runner_type     = "instance_type"
  description     = var.runner_description
  tag_list        = var.runner_tags
  untagged        = var.run_untagged
  locked          = var.locked
  access_level    = var.access_level
  maximum_timeout = var.maximum_timeout
  paused          = false
}

# ============================================================================
# Installation et enregistrement du runner sur le serveur
# ============================================================================

resource "null_resource" "install_runner" {
  count = var.gitlab_token != "" && var.auto_install_runner ? 1 : 0

  triggers = {
    runner_id       = gitlab_user_runner.main[0].id
    runner_token    = gitlab_user_runner.main[0].token
    gitlab_url      = var.gitlab_url
    docker_executor = var.docker_executor
    default_image   = var.default_docker_image
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = var.ssh_private_key != "" ? var.ssh_private_key : null
    timeout     = "5m"
  }

  # Installer et configurer le runner
  provisioner "remote-exec" {
    inline = [
      "echo '=========================================='",
      "echo '  Installation GitLab Runner automatique'",
      "echo '=========================================='",
      "echo ''",

      # Créer le volume pour la config du runner
      "docker volume create gitlab-runner-config 2>/dev/null || true",

      # Arrêter et supprimer l'ancien runner s'il existe
      "docker stop gitlab-runner 2>/dev/null || true",
      "docker rm gitlab-runner 2>/dev/null || true",

      # Démarrer le nouveau runner
      "docker run -d \\",
      "  --name gitlab-runner \\",
      "  --restart always \\",
      "  -v /var/run/docker.sock:/var/run/docker.sock \\",
      "  -v gitlab-runner-config:/etc/gitlab-runner \\",
      "  gitlab/gitlab-runner:latest",

      "echo ''",
      "echo 'Attente du démarrage du runner...'",
      "sleep 5",

      # Enregistrer le runner avec le token (nouveau workflow GitLab 16+)
      # Les options --locked, --run-untagged, --tag-list, etc. sont gérées via l'API (gitlab_user_runner)
      var.docker_executor ? "docker exec gitlab-runner gitlab-runner register --non-interactive --url '${var.gitlab_url}' --token '${gitlab_user_runner.main[0].token}' --executor 'docker' --docker-image '${var.default_docker_image}'" : "docker exec gitlab-runner gitlab-runner register --non-interactive --url '${var.gitlab_url}' --token '${gitlab_user_runner.main[0].token}' --executor 'shell'",

      "echo ''",
      "echo '✅ Runner enregistré avec succès !'",
      "echo ''",

      # Vérifier l'enregistrement
      "docker exec gitlab-runner gitlab-runner list",

      "echo ''",
      "echo 'Runner ID: ${gitlab_user_runner.main[0].id}'",
      "echo 'Description: ${var.runner_description}'",
      "echo 'Tags: ${join(", ", var.runner_tags)}'",
      "echo 'Executor: ${var.docker_executor ? "docker" : "shell"}'",
      "echo ''",
    ]
  }

  depends_on = [gitlab_user_runner.main]
}
