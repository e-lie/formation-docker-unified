variable "users" {
  description = "Liste des utilisateurs à créer"
  type = map(object({
    name     = string
    username = string
    email    = string
  }))
}

variable "user_password" {
  description = "Mot de passe pour tous les utilisateurs de lab"
  type        = string
  default     = "P}K1%,neA9v]6H1D"
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Clé SSH publique à ajouter à tous les utilisateurs"
  type        = string
}
