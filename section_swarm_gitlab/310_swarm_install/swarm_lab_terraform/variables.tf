variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "Préfixe pour les noms des ressources (permet de déployer plusieurs environnements)"
  type        = string
  default     = "ubuntu"
}

variable "username" {
  description = "Nom d'utilisateur à créer sur les serveurs (sera ajouté au groupe docker)"
  type        = string
}

variable "server_type" {
  description = "Type de serveur Hetzner Cloud (ex: cx22, cx32, cpx11, etc.)"
  type        = string
  default     = "cx22"
}

variable "node_count" {
  description = "Nombre de nœuds Docker à déployer"
  type        = number
  default     = 3
  validation {
    condition     = var.node_count > 0 && var.node_count <= 100
    error_message = "node_count doit être entre 1 et 100."
  }
}

variable "docker_mode" {
  description = "Mode d'installation de Docker : 'standard' ou 'rootless'"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "rootless"], var.docker_mode)
    error_message = "docker_mode doit être 'standard' ou 'rootless'."
  }
}

variable "enable_swarm" {
  description = "Activer Docker Swarm (incompatible avec mode rootless)"
  type        = bool
  default     = false
}

variable "hcloud_ssh_keys" {
  description = "Liste des noms de clés SSH Hetzner Cloud"
  type        = list(string)
  default     = []
}

# Variables DNS DigitalOcean
variable "enable_dns" {
  description = "Activer la création automatique des enregistrements DNS via DigitalOcean"
  type        = bool
  default     = true
}

variable "digitalocean_token" {
  description = "Token API DigitalOcean (requis si enable_dns = true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "dns_domain" {
  description = "Domaine racine dans DigitalOcean (ex: dopl.uk)"
  type        = string
  default     = "dopl.uk"
}

variable "dns_subdomain" {
  description = "Sous-domaine pour les serveurs (ex: swarm créera swarm.dopl.uk)"
  type        = string
  default     = "swarm"
}

variable "dns_ttl" {
  description = "TTL des enregistrements DNS en secondes"
  type        = number
  default     = 300
}

variable "dns_create_wildcard" {
  description = "Créer un enregistrement wildcard *.subdomain.domain pointant vers tous les serveurs"
  type        = bool
  default     = false
}
