output "server_id" {
  description = "ID du serveur"
  value       = hcloud_server.server.id
}

output "server_name" {
  description = "Nom du serveur"
  value       = hcloud_server.server.name
}

output "server_ipv4" {
  description = "Adresse IPv4 du serveur"
  value       = hcloud_server.server.ipv4_address
}

output "server_ipv6" {
  description = "Adresse IPv6 du serveur"
  value       = hcloud_server.server.ipv6_address
}
