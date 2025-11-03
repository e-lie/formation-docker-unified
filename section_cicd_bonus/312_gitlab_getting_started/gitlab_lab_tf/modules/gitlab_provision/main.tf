terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
  }
}

# Configuration GitLab - Groupes
resource "gitlab_group" "groups" {
  for_each = var.groups

  name             = each.value.name
  path             = each.value.path
  description      = each.value.description
  visibility_level = each.value.visibility_level

  # Optionnel : configuration avancée
  request_access_enabled = lookup(each.value, "request_access_enabled", true)
}

# Configuration GitLab - Utilisateurs
resource "gitlab_user" "users" {
  for_each = var.users

  name             = each.value.name
  username         = each.value.username
  email            = each.value.email
  password         = each.value.password
  is_admin         = lookup(each.value, "is_admin", false)
  projects_limit   = lookup(each.value, "projects_limit", 100)
  can_create_group = lookup(each.value, "can_create_group", true)
  skip_confirmation = true
}

# Ajout des utilisateurs aux groupes
resource "gitlab_group_membership" "memberships" {
  for_each = var.group_memberships

  group_id     = gitlab_group.groups[each.value.group_key].id
  user_id      = gitlab_user.users[each.value.user_key].id
  access_level = each.value.access_level

  depends_on = [
    gitlab_group.groups,
    gitlab_user.users
  ]
}

# Optionnel : Création de projets de démonstration
resource "gitlab_project" "demo_projects" {
  for_each = var.demo_projects

  name                   = each.value.name
  namespace_id           = gitlab_group.groups[each.value.group_key].id
  description            = each.value.description
  visibility_level       = lookup(each.value, "visibility_level", "private")
  initialize_with_readme = lookup(each.value, "initialize_with_readme", true)

  depends_on = [gitlab_group.groups]
}
