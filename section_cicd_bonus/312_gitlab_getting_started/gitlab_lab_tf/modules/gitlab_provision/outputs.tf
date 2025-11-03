output "users" {
  description = "Utilisateurs GitLab créés avec leurs informations"
  value = {
    for key, user in gitlab_user.lab_users : key => {
      id       = user.id
      username = user.username
      email    = user.email
      name     = user.name
    }
  }
}

output "user_count" {
  description = "Nombre d'utilisateurs créés"
  value       = length(gitlab_user.lab_users)
}

output "ssh_keys_added" {
  description = "Nombre de clés SSH ajoutées"
  value       = length(gitlab_user_sshkey.lab_user_keys)
}

output "projects" {
  description = "Projets gitlab-tp créés pour chaque utilisateur"
  value = {
    for key, project in gitlab_project.user_lab_project : key => {
      id       = project.id
      name     = project.name
      web_url  = project.web_url
      ssh_url  = project.ssh_url_to_repo
      http_url = project.http_url_to_repo
    }
  }
}

output "projects_count" {
  description = "Nombre de projets créés"
  value       = length(gitlab_project.user_lab_project)
}
