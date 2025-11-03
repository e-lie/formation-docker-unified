# Validation pour empêcher l'utilisation de Swarm avec Docker rootless
resource "null_resource" "validate_swarm_rootless" {
  count = var.enable_swarm && var.docker_mode == "rootless" ? 1 : 0

  lifecycle {
    precondition {
      condition     = !(var.enable_swarm && var.docker_mode == "rootless")
      error_message = "Docker Swarm (enable_swarm=true) n'est pas compatible avec le mode rootless (docker_mode='rootless'). Utilisez docker_mode='standard' pour activer Swarm."
    }
  }
}
