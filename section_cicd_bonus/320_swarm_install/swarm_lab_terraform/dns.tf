# Module DNS pour DigitalOcean (optionnel)
# Crée automatiquement des enregistrements DNS pointant vers les serveurs Hetzner

# Vérifier que le domaine existe dans DigitalOcean
data "digitalocean_domain" "main" {
  count = var.enable_dns ? 1 : 0
  name  = var.dns_domain
}

# Enregistrements A pour chaque serveur (ex: prefix-server-1.dns_subdomain.dopl.uk)
resource "digitalocean_record" "servers" {
  count = var.enable_dns ? var.node_count : 0

  domain = data.digitalocean_domain.main[0].name
  type   = "A"
  name   = "${var.prefix}-server-${count.index + 1}.${var.dns_subdomain}"
  value  = hcloud_server.ubuntu_server[count.index].ipv4_address
  ttl    = var.dns_ttl

  depends_on = [
    hcloud_server.ubuntu_server
  ]
}

# Enregistrement A pour le sous-domaine principal pointant vers le premier serveur (manager)
# Ex: prefix.dns_subdomain.dopl.uk -> premier serveur
resource "digitalocean_record" "main" {
  count = var.enable_dns ? 1 : 0

  domain = data.digitalocean_domain.main[0].name
  type   = "A"
  name   = "${var.prefix}.${var.dns_subdomain}"
  value  = hcloud_server.ubuntu_server[0].ipv4_address
  ttl    = var.dns_ttl

  depends_on = [
    hcloud_server.ubuntu_server
  ]
}

# Enregistrement wildcard pointant vers le premier serveur (manager)
# Ex: *.prefix.dns_subdomain.dopl.uk -> premier serveur
resource "digitalocean_record" "wildcard_main" {
  count = var.enable_dns && var.dns_create_wildcard ? 1 : 0

  domain = data.digitalocean_domain.main[0].name
  type   = "A"
  name   = "*.${var.prefix}.${var.dns_subdomain}"
  value  = hcloud_server.ubuntu_server[0].ipv4_address
  ttl    = var.dns_ttl

  depends_on = [
    hcloud_server.ubuntu_server
  ]
}

# Enregistrements wildcard pour chaque serveur
# Ex: *.prefix-server-1.dns_subdomain.dopl.uk -> serveur 1
resource "digitalocean_record" "wildcard_servers" {
  count = var.enable_dns && var.dns_create_wildcard ? var.node_count : 0

  domain = data.digitalocean_domain.main[0].name
  type   = "A"
  name   = "*.${var.prefix}-server-${count.index + 1}.${var.dns_subdomain}"
  value  = hcloud_server.ubuntu_server[count.index].ipv4_address
  ttl    = var.dns_ttl

  depends_on = [
    hcloud_server.ubuntu_server
  ]
}

# Outputs DNS
output "dns_records_created" {
  description = "Liste des enregistrements DNS créés"
  value = var.enable_dns ? {
    main_domain      = "${var.prefix}.${var.dns_subdomain}.${var.dns_domain}"
    wildcard_main    = var.dns_create_wildcard ? "*.${var.prefix}.${var.dns_subdomain}.${var.dns_domain}" : null
    servers = [
      for i in range(var.node_count) :
      "${var.prefix}-server-${i + 1}.${var.dns_subdomain}.${var.dns_domain}"
    ]
    wildcard_servers = var.dns_create_wildcard ? [
      for i in range(var.node_count) :
      "*.${var.prefix}-server-${i + 1}.${var.dns_subdomain}.${var.dns_domain}"
    ] : []
    manager_ip = hcloud_server.ubuntu_server[0].ipv4_address
  } : null
}

output "dns_main_fqdn" {
  description = "FQDN principal pointant vers le manager"
  value       = var.enable_dns ? "${var.prefix}.${var.dns_subdomain}.${var.dns_domain}" : null
}

output "dns_server_fqdns" {
  description = "FQDNs de tous les serveurs"
  value = var.enable_dns ? [
    for i in range(var.node_count) :
    "${var.prefix}-server-${i + 1}.${var.dns_subdomain}.${var.dns_domain}"
  ] : null
}
