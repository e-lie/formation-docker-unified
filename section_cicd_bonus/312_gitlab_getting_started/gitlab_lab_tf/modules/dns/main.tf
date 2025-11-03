terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# ============================================================================
# Extraire le domaine et le sous-domaine depuis gitlab_external_url
# ============================================================================

locals {
  # Parse l'URL GitLab (ex: http://gitlab.example.com -> gitlab.example.com)
  gitlab_fqdn = var.gitlab_external_url != "" ? replace(replace(var.gitlab_external_url, "https://", ""), "http://", "") : ""

  # Séparer le FQDN en sous-domaine et domaine racine
  # Ex: gitlab.example.com -> subdomain=gitlab, domain=example.com
  fqdn_parts       = local.gitlab_fqdn != "" ? split(".", local.gitlab_fqdn) : []
  gitlab_subdomain = length(local.fqdn_parts) > 2 ? local.fqdn_parts[0] : "@"
  gitlab_domain    = length(local.fqdn_parts) > 2 ? join(".", slice(local.fqdn_parts, 1, length(local.fqdn_parts))) : local.gitlab_fqdn

  # Déterminer si le DNS doit être créé
  should_create_dns = var.digitalocean_token != "" && local.gitlab_fqdn != ""
}

# Vérifier que le domaine existe dans DigitalOcean
data "digitalocean_domain" "gitlab" {
  count = local.should_create_dns ? 1 : 0
  name  = local.gitlab_domain
}

# ============================================================================
# Enregistrements DNS
# ============================================================================

# Enregistrement A pour GitLab (IPv4)
resource "digitalocean_record" "gitlab_a" {
  count = local.should_create_dns ? 1 : 0

  domain = data.digitalocean_domain.gitlab[0].name
  type   = "A"
  name   = local.gitlab_subdomain
  value  = var.server_ipv4
  ttl    = var.dns_ttl

  depends_on = [data.digitalocean_domain.gitlab]
}

# Enregistrement AAAA pour GitLab (IPv6)
resource "digitalocean_record" "gitlab_aaaa" {
  count = local.should_create_dns ? 1 : 0

  domain = data.digitalocean_domain.gitlab[0].name
  type   = "AAAA"
  name   = local.gitlab_subdomain
  value  = var.server_ipv6
  ttl    = var.dns_ttl

  depends_on = [data.digitalocean_domain.gitlab]
}
