output "server_info" {
  description = "Informations sur le serveur GitLab"
  value = {
    name = module.hcloud_serveur.server_name
    ipv4 = module.hcloud_serveur.server_ipv4
    ipv6 = module.hcloud_serveur.server_ipv6
  }
}

output "gitlab_url" {
  description = "URL d'accès à GitLab"
  value       = var.gitlab_external_url != "" ? var.gitlab_external_url : "http://${module.hcloud_serveur.server_ipv4}"
}

output "ssh_connection" {
  description = "Commande SSH pour se connecter au serveur"
  value       = "ssh ${var.username}@${module.hcloud_serveur.server_ipv4}"
}

output "next_steps" {
  description = "Prochaines étapes après le déploiement"
  value       = module.gitlab_install.install_instructions
}

# ==============================================================================
# Outputs DNS
# ==============================================================================

output "dns_enabled" {
  description = "Indique si le DNS a été configuré automatiquement"
  value       = module.dns.dns_enabled
}

output "dns_records" {
  description = "Détails des enregistrements DNS créés"
  value       = module.dns.records_created
}

output "gitlab_fqdn" {
  description = "FQDN complet de GitLab (si configuré)"
  value       = module.dns.fqdn
}

# ==============================================================================
# Outputs GitLab Runner
# ==============================================================================
# Décommentez ces outputs en même temps que le module gitlab_runner dans main.tf


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


# Outputs pour le module gitlab_provision (décommentez après l'installation de GitLab)
/*
output "gitlab_groups" {
  description = "Groupes GitLab créés"
  value       = module.gitlab_provision.groups
}

output "gitlab_users" {
  description = "Utilisateurs GitLab créés"
  value       = module.gitlab_provision.users
  sensitive   = true
}

output "gitlab_projects" {
  description = "Projets de démonstration créés"
  value       = module.gitlab_provision.demo_projects
}
*/
