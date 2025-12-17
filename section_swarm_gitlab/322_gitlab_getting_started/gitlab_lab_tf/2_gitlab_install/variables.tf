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

# Variables GitLab Installation
variable "gitlab_hostname" {
  description = "Nom d'hôte pour GitLab (généralement le nom du serveur)"
  type        = string
  default     = "gitlab"
}

variable "gitlab_external_url" {
  description = "URL externe de GitLab"
  type        = string
  default     = ""
}

variable "gitlab_root_password" {
  description = "Mot de passe root pour GitLab"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

variable "enable_https" {
  description = "Activer HTTPS avec Let's Encrypt (nécessite un domaine valide)"
  type        = bool
  default     = true
}

variable "letsencrypt_email" {
  description = "Email pour Let's Encrypt (requis si enable_https = true)"
  type        = string
  default     = "cto@dopl.uk"
}

variable "auto_install_gitlab" {
  description = "Lancer automatiquement GitLab après le terraform apply"
  type        = bool
  default     = true
}
