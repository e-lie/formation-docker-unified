variable "server_name" {
  description = "Nom du serveur"
  type        = string
}

variable "username" {
  description = "Nom d'utilisateur à créer sur le serveur"
  type        = string
}

variable "server_type" {
  description = "Type de serveur Hetzner Cloud"
  type        = string
  default     = "cpx31"
}

variable "image" {
  description = "Image du serveur"
  type        = string
  default     = "ubuntu-24.04"
}

variable "location" {
  description = "Localisation du serveur"
  type        = string
  default     = null
}

variable "hcloud_ssh_keys" {
  description = "Liste des noms de clés SSH Hetzner Cloud"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels pour le serveur"
  type        = map(string)
  default     = {}
}

variable "additional_user_data" {
  description = "User data additionnel à exécuter après le bootstrap"
  type        = string
  default     = ""
}
