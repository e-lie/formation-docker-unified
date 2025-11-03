variable "gitlab_url" {
  description = "URL de l'instance GitLab"
  type        = string
}

variable "gitlab_token" {
  description = "Personal Access Token GitLab (admin avec scope api)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "server_ip" {
  description = "Adresse IP du serveur"
  type        = string
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

# Configuration du runner

variable "runner_description" {
  description = "Description du runner"
  type        = string
  default     = "Docker Runner - Auto-configured"
}

variable "runner_tags" {
  description = "Tags pour le runner"
  type        = list(string)
  default     = ["docker", "auto", "shared"]
}

variable "run_untagged" {
  description = "Autoriser le runner à exécuter des jobs sans tags"
  type        = bool
  default     = true
}

variable "locked" {
  description = "Verrouiller le runner au projet/groupe"
  type        = bool
  default     = false
}

variable "access_level" {
  description = "Niveau d'accès du runner (not_protected ou ref_protected)"
  type        = string
  default     = "not_protected"
}

variable "maximum_timeout" {
  description = "Timeout maximum pour les jobs (en secondes)"
  type        = number
  default     = 3600
}

variable "docker_executor" {
  description = "Utiliser l'executor Docker (sinon shell)"
  type        = bool
  default     = true
}

variable "default_docker_image" {
  description = "Image Docker par défaut pour les jobs"
  type        = string
  default     = "alpine:latest"
}

variable "auto_install_runner" {
  description = "Installer et enregistrer automatiquement le runner"
  type        = bool
  default     = true
}
