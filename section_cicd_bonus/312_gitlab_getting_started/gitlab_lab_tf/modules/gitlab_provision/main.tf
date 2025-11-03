terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
  }
}

# Configuration GitLab - Utilisateurs
resource "gitlab_user" "lab_users" {
  for_each = var.users

  name              = each.value.name
  username          = each.value.username
  email             = each.value.email
  password          = var.user_password
  is_admin          = false
  projects_limit    = 100
  can_create_group  = true
  skip_confirmation = true
}

# Ajout de la clé SSH pour chaque utilisateur
resource "gitlab_user_sshkey" "lab_user_keys" {
  for_each = var.users

  user_id = gitlab_user.lab_users[each.key].id
  title   = "Lab SSH Key"
  key     = var.ssh_public_key

  depends_on = [gitlab_user.lab_users]
}

# Création d'un projet gitlab-tp pour chaque utilisateur
resource "gitlab_project" "user_lab_project" {
  for_each = var.users

  name                   = "gitlab-tp"
  namespace_id           = gitlab_user.lab_users[each.key].namespace_id
  description            = "Projet de travaux pratiques pour ${each.value.name}"
  visibility_level       = "private"
  initialize_with_readme = true

  # Configuration pour faciliter le travail
  issues_enabled         = true
  merge_requests_enabled = true
  wiki_enabled           = false
  snippets_enabled       = true

  depends_on = [gitlab_user.lab_users]
}
