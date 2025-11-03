output "server_ips" {
  description = "Adresses IP des serveurs Ubuntu"
  value = {
    for server in hcloud_server.ubuntu_server :
    server.name => {
      ipv4 = server.ipv4_address
      ipv6 = server.ipv6_address
    }
  }
}

output "server_ips_list" {
  description = "Liste des adresses IPv4 des serveurs"
  value       = [for server in hcloud_server.ubuntu_server : server.ipv4_address]
}
