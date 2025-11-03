output "runner_created" {
  description = "Indique si le runner a été créé"
  value       = length(gitlab_user_runner.main) > 0
}

output "runner_id" {
  description = "ID du runner GitLab"
  value       = length(gitlab_user_runner.main) > 0 ? gitlab_user_runner.main[0].id : null
}

output "runner_token" {
  description = "Token d'authentification du runner (sensible)"
  value       = length(gitlab_user_runner.main) > 0 ? gitlab_user_runner.main[0].token : null
  sensitive   = true
}

output "runner_status" {
  description = "Statut du runner"
  value       = length(gitlab_user_runner.main) > 0 ? (gitlab_user_runner.main[0].paused ? "paused" : "active") : "not_created"
}

output "runner_info" {
  description = "Informations sur le runner"
  value = length(gitlab_user_runner.main) > 0 ? {
    id          = gitlab_user_runner.main[0].id
    description = gitlab_user_runner.main[0].description
    paused      = gitlab_user_runner.main[0].paused
    tags        = gitlab_user_runner.main[0].tag_list
    executor    = var.docker_executor ? "docker" : "shell"
    installed   = var.auto_install_runner
  } : null
}
