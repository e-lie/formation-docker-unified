terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

# Script de bootstrap pour la création d'utilisateur et setup système
data "template_file" "bootstrap" {
  template = file("${path.module}/bootstrap.sh")
  vars = {
    username = var.username
  }
}

# Combinaison avec user_data supplémentaire si fourni
data "template_file" "user_data" {
  template = <<-EOT
    #!/bin/bash
    set -e

    # Bootstrap système
    ${data.template_file.bootstrap.rendered}

    # User data additionnel
    ${var.additional_user_data}
  EOT
}

# Création du serveur pour GitLab
resource "hcloud_server" "server" {
  name        = var.server_name
  image       = var.image
  server_type = var.server_type
  location    = var.location

  ssh_keys = var.hcloud_ssh_keys

  user_data = data.template_file.user_data.rendered

  labels = var.labels
}
