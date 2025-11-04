variable "server_id" {
  description = "ID du serveur sur lequel installer GitLab"
  type        = string
}

variable "server_ip" {
  description = "Adresse IP du serveur"
  type        = string
}

variable "username" {
  description = "Nom d'utilisateur système"
  type        = string
}

variable "gitlab_hostname" {
  description = "Nom d'hôte pour GitLab"
  type        = string
}

variable "gitlab_external_url" {
  description = "URL externe de GitLab"
  type        = string
}

variable "gitlab_root_password" {
  description = "Mot de passe root pour GitLab"
  type        = string
  sensitive   = true
}

variable "ssh_user" {
  description = "Utilisateur SSH pour la connexion"
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  description = "Clé privée SSH pour la connexion"
  type        = string
  sensitive   = true
  default     = ""
}

variable "docker_installation_complete" {
  description = "Indique si Docker est installé (dépendance)"
  type        = bool
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

variable "auto_install" {
  description = "Lancer automatiquement GitLab après la préparation des fichiers"
  type        = bool
  default     = true
}
