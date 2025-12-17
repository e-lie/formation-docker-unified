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

# Variables GitLab Provider
variable "gitlab_url" {
  description = "URL de l'instance GitLab"
  type        = string
  default     = ""
}

variable "gitlab_external_url" {
  description = "URL externe de GitLab"
  type        = string
  default     = ""
}

variable "gitlab_token" {
  description = "Token d'accès GitLab (Personal Access Token avec scope api)"
  type        = string
  sensitive   = true
}

# Variables GitLab Runner
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

# Variables GitLab Provision
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
