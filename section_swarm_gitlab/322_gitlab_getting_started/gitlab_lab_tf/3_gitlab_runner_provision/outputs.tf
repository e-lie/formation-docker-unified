output "server_info" {
  description = "Informations sur le serveur GitLab"
  value = {
    name = data.hcloud_server.gitlab_server.name
    ipv4 = data.hcloud_server.gitlab_server.ipv4_address
    ipv6 = data.hcloud_server.gitlab_server.ipv6_address
  }
}

output "runner_created" {
  description = "Indique si un runner a été créé automatiquement"
  value       = module.gitlab_runner.runner_created
}

output "runner_info" {
  description = "Informations sur le runner GitLab"
  value       = module.gitlab_runner.runner_info
}

output "runner_status" {
  description = "Statut du runner GitLab"
  value       = module.gitlab_runner.runner_status
}

output "gitlab_users" {
  description = "Utilisateurs GitLab créés"
  value       = module.gitlab_provision.users
  sensitive   = true
}
