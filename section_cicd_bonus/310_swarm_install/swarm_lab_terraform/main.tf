terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "digitalocean" {
  token = var.digitalocean_token
}

# Script de bootstrap pour la création d'utilisateur et setup système (cloud-init)
data "template_file" "bootstrap" {
  template = file("${path.module}/bootstrap.sh")
  vars = {
    username = var.username
  }
}

# Création des serveurs Ubuntu Noble
resource "hcloud_server" "ubuntu_server" {
  count       = var.node_count
  name        = "${var.prefix}-server-${count.index + 1}"
  image       = "ubuntu-24.04"
  server_type = var.server_type

  ssh_keys = var.hcloud_ssh_keys

  # user_data utilisé uniquement pour le bootstrap
  user_data = data.template_file.bootstrap.rendered

  labels = {
    environment = "dev"
    managed_by  = "terraform"
    prefix      = var.prefix
    swarm_role  = var.enable_swarm ? (count.index == 0 ? "manager" : "worker") : "none"
  }
}

# Installation de Docker via SSH après le bootstrap
resource "null_resource" "docker_install" {
  count = var.node_count

  depends_on = [hcloud_server.ubuntu_server]

  # Déclencher le provisioning si le serveur change
  triggers = {
    server_id = hcloud_server.ubuntu_server[count.index].id
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = hcloud_server.ubuntu_server[count.index].ipv4_address
    timeout     = "5m"
  }

  # Attendre que le bootstrap soit terminé
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for bootstrap to complete...'",
      "timeout 300 bash -c 'until [ -f /var/lib/cloud/instance/boot-finished ]; do sleep 2; done'",
      "echo 'Bootstrap completed, starting Docker installation...'"
    ]
  }

  # Copier le script Docker approprié dans /opt
  provisioner "file" {
    content = templatefile(
      var.docker_mode == "rootless" ? "${path.module}/install_docker_rootless.sh" : "${path.module}/install_docker.sh",
      {
        username = var.username
      }
    )
    destination = "/opt/install_docker.sh"
  }

  # Exécuter l'installation Docker
  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/install_docker.sh",
      "/opt/install_docker.sh"
    ]
  }
}

# Configuration de Docker Swarm - Manager (si activé)
resource "null_resource" "swarm_manager" {
  count = var.enable_swarm ? 1 : 0

  depends_on = [null_resource.docker_install]

  triggers = {
    server_id = hcloud_server.ubuntu_server[0].id
  }

  connection {
    type    = "ssh"
    user    = "root"
    host    = hcloud_server.ubuntu_server[0].ipv4_address
    timeout = "5m"
  }

  # Copier le script Swarm dans /opt pour le manager
  provisioner "file" {
    content = templatefile("${path.module}/swarm_install.sh", {
      node_index   = 0
      manager_ip   = "self"
      worker_token = "not-needed"
    })
    destination = "/opt/swarm_install.sh"
  }

  # Exécuter la configuration Swarm sur le manager
  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/swarm_install.sh",
      "/opt/swarm_install.sh"
    ]
  }
}

# Récupérer le token worker depuis le manager
data "external" "swarm_token" {
  count = var.enable_swarm ? 1 : 0

  depends_on = [null_resource.swarm_manager]

  program = ["bash", "-c", <<-EOT
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${hcloud_server.ubuntu_server[0].ipv4_address} \
      'docker swarm join-token worker -q' | jq -R '{token: .}'
  EOT
  ]
}

# Configuration de Docker Swarm - Workers (si activé)
resource "null_resource" "swarm_workers" {
  count = var.enable_swarm ? var.node_count - 1 : 0

  depends_on = [
    null_resource.docker_install,
    null_resource.swarm_manager,
    data.external.swarm_token
  ]

  triggers = {
    server_id = hcloud_server.ubuntu_server[count.index + 1].id
  }

  connection {
    type    = "ssh"
    user    = "root"
    host    = hcloud_server.ubuntu_server[count.index + 1].ipv4_address
    timeout = "5m"
  }

  # Copier le script Swarm dans /opt pour les workers
  provisioner "file" {
    content = templatefile("${path.module}/swarm_install.sh", {
      node_index   = count.index + 1
      manager_ip   = hcloud_server.ubuntu_server[0].ipv4_address
      worker_token = var.enable_swarm ? data.external.swarm_token[0].result.token : "pending"
    })
    destination = "/opt/swarm_install.sh"
  }

  # Exécuter la configuration Swarm sur le worker
  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/swarm_install.sh",
      "/opt/swarm_install.sh"
    ]
  }
}
