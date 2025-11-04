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

# Variables GitLab Installation
variable "gitlab_hostname" {
  description = "Nom d'hôte pour GitLab (généralement le nom du serveur)"
  type        = string
  default     = "gitlab"
}

variable "gitlab_external_url" {
  description = "URL externe de GitLab (sera calculée automatiquement avec l'IP du serveur)"
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

# Variables GitLab Provider
variable "gitlab_url" {
  description = "URL de l'instance GitLab (sera http://IP_DU_SERVEUR après installation)"
  type        = string
  default     = ""
}

variable "gitlab_token" {
  description = "Token d'accès GitLab (Personal Access Token avec scope api)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitlab_groups" {
  description = "Groupes GitLab à créer"
  type = map(object({
    name             = string
    path             = string
    description      = string
    visibility_level = string
  }))
  default = {}
}

variable "gitlab_users" {
  description = "Utilisateurs GitLab à créer (nom, username, email personnalisables)"
  type = map(object({
    name     = string
    username = string
    email    = string
  }))
  default = {
    stagiaire1 = {
      name     = "Stagiaire 1"
      username = "stagiaire1"
      email    = "stagiaire1@lab.local"
    }
    stagiaire2 = {
      name     = "Stagiaire 2"
      username = "stagiaire2"
      email    = "stagiaire2@lab.local"
    }
    stagiaire3 = {
      name     = "Stagiaire 3"
      username = "stagiaire3"
      email    = "stagiaire3@lab.local"
    }
    stagiaire4 = {
      name     = "Stagiaire 4"
      username = "stagiaire4"
      email    = "stagiaire4@lab.local"
    }
  }
}

variable "gitlab_group_memberships" {
  description = "Associations utilisateurs-groupes"
  type = map(object({
    group_key    = string
    user_key     = string
    access_level = string
  }))
  default = {}
}

variable "gitlab_demo_projects" {
  description = "Projets de démonstration à créer"
  type = map(object({
    name                   = string
    group_key              = string
    description            = string
    visibility_level       = optional(string, "private")
    initialize_with_readme = optional(bool, true)
  }))
  default = {}
}

# ============================================================================
# Variables DNS (DigitalOcean)
# ============================================================================

variable "digitalocean_token" {
  description = "Token API DigitalOcean pour la gestion DNS (laisser vide pour désactiver le DNS)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "dns_ttl" {
  description = "TTL des enregistrements DNS en secondes"
  type        = number
  default     = 300
}

# ============================================================================
# Variables GitLab Runner
# ============================================================================

variable "auto_install_runner" {
  description = "Installer et enregistrer automatiquement un runner GitLab (nécessite gitlab_token)"
  type        = bool
  default     = true
}

variable "runner_description" {
  description = "Description du runner GitLab"
  type        = string
  default     = "Docker Runner - Auto-configured"
}

variable "runner_tags" {
  description = "Tags pour le runner GitLab"
  type        = list(string)
  default     = ["docker", "auto", "shared"]
}

variable "runner_executor" {
  description = "Type d'executor pour le runner (docker ou shell)"
  type        = string
  default     = "docker"
  validation {
    condition     = contains(["docker", "shell"], var.runner_executor)
    error_message = "L'executor doit être 'docker' ou 'shell'"
  }
}
