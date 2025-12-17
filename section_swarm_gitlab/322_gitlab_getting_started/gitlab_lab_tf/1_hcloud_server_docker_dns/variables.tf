variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "Préfixe pour les noms des ressources"
  type        = string
  default     = "lab"
}

variable "username" {
  description = "Nom d'utilisateur à créer sur le serveur"
  type        = string
  default     = "gitlab-admin"
}

variable "server_type" {
  description = "Type de serveur Hetzner Cloud (cpx31 recommandé pour GitLab)"
  type        = string
  default     = "cpx31"
}

variable "hcloud_ssh_keys" {
  description = "Liste des noms de clés SSH Hetzner Cloud"
  type        = list(string)
  default     = []
}

# Variables SSH
variable "ssh_user" {
  description = "Utilisateur SSH pour les connexions (root ou username)"
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  description = "Clé privée SSH pour la connexion (laisser vide pour utiliser l'agent SSH)"
  type        = string
  sensitive   = true
  default     = ""
}

# Variables DNS
variable "digitalocean_token" {
  description = "Token API DigitalOcean pour la gestion DNS (laisser vide pour désactiver le DNS)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitlab_external_url" {
  description = "URL externe de GitLab (utilisée pour la configuration DNS)"
  type        = string
  default     = ""
}

variable "dns_ttl" {
  description = "TTL des enregistrements DNS en secondes"
  type        = number
  default     = 300
}
