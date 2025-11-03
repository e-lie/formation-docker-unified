variable "server_id" {
  description = "ID du serveur sur lequel installer Docker"
  type        = string
}

variable "server_ip" {
  description = "Adresse IP du serveur"
  type        = string
}

variable "username" {
  description = "Nom d'utilisateur à ajouter au groupe docker"
  type        = string
}

variable "ssh_user" {
  description = "Utilisateur SSH pour la connexion"
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  description = "Clé privée SSH pour la connexion (optionnel si agent SSH configuré)"
  type        = string
  sensitive   = true
  default     = ""
}
