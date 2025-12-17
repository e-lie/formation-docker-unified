output "server_info" {
  description = "Informations sur le serveur GitLab"
  value = {
    name = data.hcloud_server.gitlab_server.name
    ipv4 = data.hcloud_server.gitlab_server.ipv4_address
    ipv6 = data.hcloud_server.gitlab_server.ipv6_address
  }
}

output "gitlab_url" {
  description = "URL d'accès à GitLab"
  value       = var.gitlab_external_url != "" ? var.gitlab_external_url : "http://${data.hcloud_server.gitlab_server.ipv4_address}"
}

output "ssh_connection" {
  description = "Commande SSH pour se connecter au serveur"
  value       = "ssh ${var.username}@${data.hcloud_server.gitlab_server.ipv4_address}"
}

output "next_steps" {
  description = "Prochaines étapes après le déploiement"
  value       = module.gitlab_install.install_instructions
}
