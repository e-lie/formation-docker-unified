terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Installation de Docker via SSH
resource "null_resource" "docker_install" {
  triggers = {
    server_id = var.server_id
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = var.ssh_private_key != "" ? var.ssh_private_key : null
    timeout     = "5m"
  }

  # Attendre que le serveur soit prêt
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || true",
      "echo 'Server is ready'"
    ]
  }

  # Copier le script d'installation
  provisioner "file" {
    source      = "${path.module}/install_docker.sh"
    destination = "/tmp/install_docker.sh"
  }

  # Exécuter l'installation
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_docker.sh",
      "sudo /tmp/install_docker.sh ${var.username}",
      "rm /tmp/install_docker.sh"
    ]
  }
}
