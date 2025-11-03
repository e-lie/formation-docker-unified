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
