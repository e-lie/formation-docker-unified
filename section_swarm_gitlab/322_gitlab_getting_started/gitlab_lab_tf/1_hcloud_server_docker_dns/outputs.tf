output "server_info" {
  description = "Informations sur le serveur GitLab"
  value = {
    name = module.hcloud_serveur.server_name
    ipv4 = module.hcloud_serveur.server_ipv4
    ipv6 = module.hcloud_serveur.server_ipv6
    id   = module.hcloud_serveur.server_id
  }
}

output "ssh_connection" {
  description = "Commande SSH pour se connecter au serveur"
  value       = "ssh ${var.username}@${module.hcloud_serveur.server_ipv4}"
}

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

output "docker_installation_complete" {
  description = "Indique si l'installation de Docker est terminée"
  value       = module.docker_install.installation_complete
}
