output "gitlab_files_ready" {
  description = "Indique si les fichiers GitLab sont prêts"
  value       = null_resource.gitlab_prepare.id != "" ? true : false
}

output "gitlab_directory" {
  description = "Répertoire contenant les fichiers GitLab"
  value       = "/home/${var.username}/gitlab"
}

output "auto_installed" {
  description = "Indique si GitLab a été lancé automatiquement"
  value       = var.auto_install
}

locals {
  auto_install_message = <<-EOT
    GitLab a été lancé automatiquement !

    Il est en cours de démarrage (10-15 minutes).

    Pour suivre les logs :
      ssh ${var.username}@${var.server_ip}
      cd ~/gitlab
      docker compose logs -f gitlab

    GitLab sera accessible à : ${var.gitlab_external_url}
  EOT

  manual_install_message = <<-EOT
    Pour installer GitLab, connectez-vous au serveur et exécutez :

    ssh ${var.username}@${var.server_ip}
    cd ~/gitlab
    ./install-gitlab.sh

    Puis pour installer le runner :
    ./install-runner.sh
  EOT
}

output "install_instructions" {
  description = "Instructions pour installer GitLab"
  value       = var.auto_install ? local.auto_install_message : local.manual_install_message
}
