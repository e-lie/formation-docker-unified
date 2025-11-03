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
