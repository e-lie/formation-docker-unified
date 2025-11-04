output "installation_complete" {
  description = "Indique si l'installation de Docker est terminée"
  value       = null_resource.docker_install.id != "" ? true : false
}

output "docker_installed_on" {
  description = "ID du serveur sur lequel Docker est installé"
  value       = var.server_id
}
