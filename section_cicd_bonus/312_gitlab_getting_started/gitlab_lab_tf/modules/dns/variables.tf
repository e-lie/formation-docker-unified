variable "digitalocean_token" {
  description = "Token API DigitalOcean pour la gestion DNS (laisser vide pour désactiver)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitlab_external_url" {
  description = "URL externe de GitLab (ex: http://gitlab.example.com)"
  type        = string
}

variable "server_ipv4" {
  description = "Adresse IPv4 du serveur GitLab"
  type        = string
}

variable "server_ipv6" {
  description = "Adresse IPv6 du serveur GitLab"
  type        = string
}

variable "dns_ttl" {
  description = "TTL des enregistrements DNS en secondes"
  type        = number
  default     = 300
}
