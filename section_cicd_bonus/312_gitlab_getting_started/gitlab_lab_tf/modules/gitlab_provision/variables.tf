variable "groups" {
  description = "Groupes GitLab à créer"
  type = map(object({
    name                   = string
    path                   = string
    description            = string
    visibility_level       = string
    request_access_enabled = optional(bool, true)
  }))
  default = {}
}

variable "users" {
  description = "Utilisateurs GitLab à créer"
  type = map(object({
    name             = string
    username         = string
    email            = string
    password         = string
    is_admin         = optional(bool, false)
    projects_limit   = optional(number, 100)
    can_create_group = optional(bool, true)
  }))
  default   = {}
  sensitive = true
}

variable "group_memberships" {
  description = "Associations utilisateurs-groupes avec niveaux d'accès"
  type = map(object({
    group_key    = string
    user_key     = string
    access_level = string
  }))
  default = {}
}

variable "demo_projects" {
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
