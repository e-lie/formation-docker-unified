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
  default     = "xK9#mZ2$pL7@qR5!"
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Clé SSH publique à ajouter à tous les utilisateurs"
  type        = string
}
