output "groups" {
  description = "Groupes GitLab créés"
  value = {
    for key, group in gitlab_group.groups :
    key => {
      id               = group.id
      name             = group.name
      path             = group.path
      full_path        = group.full_path
      web_url          = group.web_url
      visibility_level = group.visibility_level
    }
  }
}

output "users" {
  description = "Utilisateurs GitLab créés"
  value = {
    for key, user in gitlab_user.users :
    key => {
      id       = user.id
      username = user.username
      email    = user.email
      is_admin = user.is_admin
    }
  }
  sensitive = true
}

output "group_memberships" {
  description = "Associations utilisateurs-groupes"
  value = {
    for key, membership in gitlab_group_membership.memberships :
    key => {
      group_id     = membership.group_id
      user_id      = membership.user_id
      access_level = membership.access_level
    }
  }
}

output "demo_projects" {
  description = "Projets de démonstration créés"
  value = {
    for key, project in gitlab_project.demo_projects :
    key => {
      id       = project.id
      name     = project.name
      web_url  = project.web_url
      ssh_url  = project.ssh_url_to_repo
      http_url = project.http_url_to_repo
    }
  }
}
