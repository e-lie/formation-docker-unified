output "dns_enabled" {
  description = "Indique si le DNS a été configuré"
  value       = length(digitalocean_record.gitlab_a) > 0
}

output "fqdn" {
  description = "FQDN complet de GitLab"
  value       = var.gitlab_external_url != "" ? replace(replace(var.gitlab_external_url, "https://", ""), "http://", "") : null
}

output "ipv4" {
  description = "Adresse IPv4 du serveur"
  value       = var.server_ipv4
}

output "ipv6" {
  description = "Adresse IPv6 du serveur"
  value       = var.server_ipv6
}

output "records_created" {
  description = "Liste des enregistrements DNS créés"
  value = length(digitalocean_record.gitlab_a) > 0 ? {
    a_record    = "A record created for ${replace(replace(var.gitlab_external_url, "https://", ""), "http://", "")} -> ${var.server_ipv4}"
    aaaa_record = "AAAA record created for ${replace(replace(var.gitlab_external_url, "https://", ""), "http://", "")} -> ${var.server_ipv6}"
  } : null
}
