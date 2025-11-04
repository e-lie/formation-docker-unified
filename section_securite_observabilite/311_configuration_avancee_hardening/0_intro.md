---
title: "Configuration avancée de Docker et Hardening"
description: "Guide complet sur la configuration avancée du daemon Docker, containerd, et le durcissement de l'installation"
sidebar:
  order: 311
---

## Objectifs pédagogiques
  - Comprendre la configuration du daemon Docker et ses options avancées
  - Maîtriser les liens entre Docker et containerd
  - Connaître les bonnes pratiques de hardening d'une installation Docker
  - Savoir configurer les runtimes et les options de sécurité

---

# Configuration avancée du daemon Docker

## Architecture de configuration

Docker utilise plusieurs fichiers de configuration selon la plateforme :

- **Linux** : `/etc/docker/daemon.json` (configuration principale)
- **Systemd** : `/etc/systemd/system/docker.service.d/` (overrides systemd)
- **Windows** : `C:\ProgramData\docker\config\daemon.json`

### Structure du fichier daemon.json

Le fichier `daemon.json` permet de configurer de nombreux aspects du daemon Docker :

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "default-address-pools": [
    {
      "base": "172.80.0.0/16",
      "size": 24
    }
  ],
  "data-root": "/var/lib/docker",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "icc": false,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
```

---

## Options de configuration essentielles

### 1. Gestion des logs

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "compress": "true"
  }
}
```

**Drivers de logs disponibles** :
- `json-file` : Par défaut, stocke les logs en JSON
- `syslog` : Envoie vers syslog
- `journald` : Utilise systemd-journald
- `gelf` : Graylog Extended Log Format
- `fluentd` : Envoie vers Fluentd
- `awslogs` : AWS CloudWatch Logs
- `splunk` : Splunk Enterprise

**Pourquoi limiter les logs ?** Sans limite, les logs peuvent remplir le disque et causer des pannes système !

### 2. Storage Driver et performance

```json
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "data-root": "/mnt/docker-data"
}
```

**Storage drivers disponibles** :
- `overlay2` : **Recommandé** - Le plus performant et moderne
- `aufs` : Ancien, obsolète
- `devicemapper` : Pour les vieux kernels
- `btrfs` : Pour filesystem Btrfs
- `zfs` : Pour filesystem ZFS

**Bonnes pratiques** :
- Utilisez toujours `overlay2` sauf besoin spécifique
- Montez `data-root` sur un volume dédié avec suffisamment d'espace
- Surveillez l'utilisation disque avec `docker system df`

### 3. Gestion réseau avancée

```json
{
  "bip": "192.168.1.1/24",
  "default-address-pools": [
    {
      "base": "172.80.0.0/16",
      "size": 24
    },
    {
      "base": "172.90.0.0/16",
      "size": 24
    }
  ],
  "fixed-cidr": "192.168.1.0/25",
  "userland-proxy": false,
  "icc": false,
  "ip-forward": true,
  "iptables": true,
  "ip-masq": true
}
```

**Explications** :
- `bip` : Bridge IP pour le réseau bridge par défaut
- `default-address-pools` : Pools d'adresses pour les réseaux custom
- `userland-proxy` : Désactiver améliore les performances (utilise iptables directement)
- `icc` (Inter-Container Communication) : `false` isole les conteneurs entre eux par défaut
- `ip-forward` : Active le forwarding IP (nécessaire pour NAT)

### 4. Options de sécurité

```json
{
  "no-new-privileges": true,
  "selinux-enabled": true,
  "userns-remap": "default",
  "seccomp-profile": "/etc/docker/seccomp-custom.json",
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Soft": 64000
    },
    "nproc": {
      "Hard": 4096,
      "Soft": 2048
    }
  }
}
```

**Détails** :
- `no-new-privileges` : Empêche l'escalade de privilèges (setuid, etc.)
- `userns-remap` : Active les user namespaces (root dans le conteneur != root sur l'hôte)
- `seccomp-profile` : Profil de filtrage des appels système
- `default-ulimits` : Limites par défaut (fichiers ouverts, processus)

### 5. Options de performance

```json
{
  "live-restore": true,
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 10,
  "max-download-attempts": 5,
  "shutdown-timeout": 15
}
```

**Explications** :
- `live-restore` : **Crucial !** Les conteneurs continuent de tourner pendant le redémarrage du daemon
- `max-concurrent-downloads` : Nombre de layers téléchargés en parallèle
- `shutdown-timeout` : Délai avant SIGKILL lors de l'arrêt (seconds)

---

# Docker et containerd : comprendre la relation

## Architecture en couches

```
┌─────────────────────────────────┐
│     Docker CLI (docker)         │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│     Docker Engine (dockerd)     │
│  - API REST                     │
│  - Images management            │
│  - Networking                   │
│  - Volumes                      │
└────────────┬────────────────────┘
             │ (gRPC)
             ▼
┌─────────────────────────────────┐
│     containerd                  │
│  - Container lifecycle          │
│  - Image pull/push              │
│  - Network namespaces           │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│     runc (ou autre runtime)     │
│  - OCI runtime                  │
│  - Création des conteneurs      │
│  - Namespaces/cgroups           │
└─────────────────────────────────┘
```

## containerd : le runtime de haut niveau

**containerd** est un daemon qui gère le cycle de vie complet des conteneurs :
- Pull et push d'images
- Stockage des images
- Exécution et supervision des conteneurs
- Gestion des snapshots de filesystem
- Networking de bas niveau

### Configuration de containerd

Fichier : `/etc/containerd/config.toml`

```toml
version = 2

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "registry.k8s.io/pause:3.9"

    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "runc"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
        runtime_type = "io.containerd.runc.v2"

        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
          SystemdCgroup = true

      # Runtime alternatif : gVisor
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
        runtime_type = "io.containerd.runsc.v1"

  [plugins."io.containerd.internal.v1.opt"]
    path = "/var/lib/containerd/opt"
```

### Interaction Docker ↔ containerd

Docker communique avec containerd via **gRPC** :

```bash
# Voir les conteneurs dans containerd
sudo ctr -n moby containers list

# Voir les tâches (processus) actives
sudo ctr -n moby tasks list

# Namespace "moby" = namespace Docker dans containerd
```

**Note importante** : Le namespace `moby` est utilisé par Docker dans containerd.

---

## runc : le runtime OCI de bas niveau

**runc** est l'implémentation de référence de l'OCI (Open Container Initiative) :
- Crée et lance les conteneurs selon la spec OCI
- Configure les namespaces, cgroups, capabilities
- Exécute le processus init du conteneur

### Tester runc directement

```bash
# Créer un bundle OCI
mkdir -p /tmp/mycontainer/rootfs
cd /tmp/mycontainer

# Extraire un rootfs
docker export $(docker create busybox) | tar -C rootfs -xvf -

# Générer la config OCI
runc spec

# Lancer le conteneur
sudo runc run mycontainer
```

---

## Runtimes alternatifs

### 1. gVisor (runsc) - Sandboxing renforcé

**gVisor** ajoute une couche de sécurité en implémentant un kernel user-space :

```json
{
  "runtimes": {
    "runsc": {
      "path": "/usr/local/bin/runsc",
      "runtimeArgs": [
        "--platform=ptrace"
      ]
    }
  }
}
```

Utilisation :
```bash
docker run --runtime=runsc -it alpine sh
```

**Avantages** :
- Isolation renforcée (kernel simulé)
- Réduit la surface d'attaque du kernel

**Inconvénients** :
- Performance réduite (~30-50% plus lent)
- Incompatibilité avec certains appels système

### 2. Kata Containers - VM légères

**Kata Containers** lance chaque conteneur dans une micro-VM :

```json
{
  "runtimes": {
    "kata-runtime": {
      "path": "/usr/bin/kata-runtime"
    }
  }
}
```

**Avantages** :
- Isolation forte (VM réelle)
- Compatible avec Kubernetes

**Inconvénients** :
- Overhead de démarrage
- Consommation mémoire plus élevée

### 3. crun - Runtime en C

Alternative à runc, écrit en C (runc est en Go) :

```json
{
  "default-runtime": "crun",
  "runtimes": {
    "crun": {
      "path": "/usr/bin/crun"
    }
  }
}
```

**Avantages** :
- Plus rapide et plus léger
- Moins de mémoire consommée

---

# Hardening d'une installation Docker

## 1. Sécuriser le daemon Docker

### Désactiver l'accès TCP non sécurisé

**❌ DANGEREUX** :
```bash
# NE JAMAIS faire ceci sans TLS !
dockerd -H tcp://0.0.0.0:2375
```

**✅ SÉCURISÉ** : Utiliser TLS
```bash
# Générer les certificats
openssl genrsa -aes256 -out ca-key.pem 4096
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem

# Certificat serveur
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=docker.example.com" -sha256 -new -key server-key.pem -out server.csr
echo subjectAltName = DNS:docker.example.com,IP:10.0.0.1 >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf

# Certificat client
openssl genrsa -out key.pem 4096
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
echo extendedKeyUsage = clientAuth >> extfile-client.cnf
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out cert.pem -extfile extfile-client.cnf
```

Configuration dans `/etc/docker/daemon.json` :
```json
{
  "hosts": ["tcp://0.0.0.0:2376"],
  "tls": true,
  "tlsverify": true,
  "tlscacert": "/etc/docker/certs/ca.pem",
  "tlscert": "/etc/docker/certs/server-cert.pem",
  "tlskey": "/etc/docker/certs/server-key.pem"
}
```

### Activer les user namespaces

Le user namespace remapping transforme l'UID root (0) du conteneur en un UID non-privilégié sur l'hôte.

```json
{
  "userns-remap": "default"
}
```

Docker créera automatiquement un utilisateur `dockremap` :

```bash
# Vérifier
cat /etc/subuid
cat /etc/subgid

# Devrait afficher
dockremap:100000:65536
```

**Impact** : root dans le conteneur = UID 100000 sur l'hôte !

```bash
# Tester
docker run --rm -it alpine id
# uid=0(root) ... dans le conteneur

# Sur l'hôte
ps aux | grep "sleep 1000"
# Processus appartient à l'UID 100000 !
```

---

## 2. Limiter les ressources (cgroups v2)

### Configuration système

Vérifier cgroups v2 :
```bash
mount | grep cgroup
# doit afficher : cgroup2 on /sys/fs/cgroup type cgroup2
```

Configuration dans `/etc/docker/daemon.json` :
```json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Soft": 32000
    },
    "nproc": {
      "Hard": 512,
      "Soft": 256
    },
    "memlock": {
      "Hard": -1,
      "Soft": -1
    }
  }
}
```

### Limites au niveau conteneur

```bash
# CPU (1 core = 1024 shares)
docker run -d --cpus="1.5" --cpu-shares=512 nginx

# Mémoire
docker run -d --memory="512m" --memory-swap="1g" --memory-reservation="256m" nginx

# IO disque
docker run -d --device-read-bps /dev/sda:10mb --device-write-bps /dev/sda:5mb nginx

# PIDs
docker run -d --pids-limit 200 nginx
```

---

## 3. Sécuriser avec AppArmor et SELinux

### AppArmor (Ubuntu/Debian)

Profil par défaut : `/etc/apparmor.d/docker`

```bash
# Vérifier AppArmor
sudo aa-status | grep docker

# Créer un profil custom
sudo nano /etc/apparmor.d/docker-custom

# Appliquer
sudo apparmor_parser -r -W /etc/apparmor.d/docker-custom
```

Utiliser un profil :
```bash
docker run --security-opt apparmor=docker-custom nginx
```

### SELinux (RHEL/CentOS/Fedora)

Activer SELinux pour Docker :
```json
{
  "selinux-enabled": true
}
```

Labels SELinux :
```bash
# Appliquer un label custom
docker run -v /data:/data:z nginx
# :z = relabel private
# :Z = relabel shared

# Vérifier
ls -lZ /data
```

---

## 4. Profil Seccomp personnalisé

Seccomp filtre les appels système autorisés. Docker utilise un profil par défaut qui bloque ~44 appels système dangereux.

### Profil custom restrictif

Créer `/etc/docker/seccomp-strict.json` :

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_AARCH64"
  ],
  "syscalls": [
    {
      "names": [
        "accept",
        "accept4",
        "access",
        "arch_prctl",
        "bind",
        "brk",
        "chdir",
        "clone",
        "close",
        "connect",
        "dup",
        "dup2",
        "dup3",
        "epoll_create",
        "epoll_create1",
        "epoll_ctl",
        "epoll_wait",
        "execve",
        "exit",
        "exit_group",
        "fchdir",
        "fchown",
        "fcntl",
        "fstat",
        "fsync",
        "futex",
        "getcwd",
        "getdents",
        "getdents64",
        "getpid",
        "getppid",
        "getuid",
        "ioctl",
        "listen",
        "lseek",
        "mmap",
        "mprotect",
        "munmap",
        "open",
        "openat",
        "pipe",
        "pipe2",
        "poll",
        "prctl",
        "read",
        "readlink",
        "recvfrom",
        "recvmsg",
        "rt_sigaction",
        "rt_sigprocmask",
        "rt_sigreturn",
        "sendmsg",
        "sendto",
        "set_robust_list",
        "set_tid_address",
        "setgid",
        "setgroups",
        "setuid",
        "socket",
        "stat",
        "statfs",
        "wait4",
        "write"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

Utiliser :
```bash
docker run --security-opt seccomp=/etc/docker/seccomp-strict.json nginx
```

---

## 5. Audit et monitoring

### Docker Bench Security

Outil officiel de Docker pour auditer la sécurité :

```bash
# Installation
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security

# Exécution
sudo ./docker-bench-security.sh
```

Analyse :
- Configuration du daemon
- Configuration réseau
- Images
- Conteneurs en cours d'exécution
- Fichiers de configuration

### Auditd pour tracer les événements Docker

```bash
# Installer auditd
sudo apt install auditd

# Règles pour Docker
sudo nano /etc/audit/rules.d/docker.rules
```

Contenu :
```
-w /usr/bin/dockerd -k docker
-w /var/lib/docker -k docker
-w /etc/docker -k docker
-w /usr/lib/systemd/system/docker.service -k docker
-w /usr/lib/systemd/system/docker.socket -k docker
-w /etc/default/docker -k docker
-w /etc/docker/daemon.json -k docker
-w /usr/bin/containerd -k docker
-w /usr/bin/runc -k docker
```

Activer :
```bash
sudo augenrules --load
sudo systemctl restart auditd

# Rechercher les événements
sudo ausearch -k docker
```

---

## 6. Bonnes pratiques générales

### Checklist de hardening

- [ ] **Désactiver l'API TCP non-TLS** ou activer TLS mutuel
- [ ] **Activer user namespaces** (`userns-remap`)
- [ ] **Limiter les ressources** (CPU, mémoire, PIDs) par défaut
- [ ] **Utiliser un runtime sécurisé** (gVisor, Kata) pour workloads sensibles
- [ ] **Activer AppArmor/SELinux**
- [ ] **Profil Seccomp restrictif** pour conteneurs sensibles
- [ ] **Ne jamais monter `/var/run/docker.sock`** dans un conteneur (ou via docker-socket-proxy)
- [ ] **Scanner les images** avec Trivy, Clair, Snyk
- [ ] **Rootless mode** pour utilisateurs non-privilégiés
- [ ] **Logs centralisés** (syslog, journald, ou driver distant)
- [ ] **Rotation des logs** configurée
- [ ] **Monitoring** (Prometheus + cAdvisor)
- [ ] **Audit régulier** avec Docker Bench Security
- [ ] **Mettre à jour** Docker et containerd régulièrement
- [ ] **Utiliser des images minimales** (Alpine, Distroless)
- [ ] **Ne pas utiliser `:latest`** en production

### Configuration production recommandée

`/etc/docker/daemon.json` :

```json
{
  "log-driver": "journald",
  "log-opts": {
    "tag": "docker/{{.Name}}"
  },
  "storage-driver": "overlay2",
  "data-root": "/mnt/docker-data",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "icc": false,
  "userns-remap": "default",
  "selinux-enabled": true,
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Soft": 64000
    },
    "nproc": {
      "Hard": 4096,
      "Soft": 2048
    }
  },
  "default-address-pools": [
    {
      "base": "172.80.0.0/16",
      "size": 24
    }
  ],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "shutdown-timeout": 15,
  "runtimes": {
    "runsc": {
      "path": "/usr/local/bin/runsc"
    }
  }
}
```

---

## 7. Ressources et outils

### Outils de sécurité

- **Trivy** : Scanner de vulnérabilités pour images et filesystems
  ```bash
  trivy image nginx:latest
  ```

- **Falco** : Détection de comportements anormaux runtime
  ```bash
  docker run -it --rm \
    --privileged \
    -v /var/run/docker.sock:/host/var/run/docker.sock \
    -v /dev:/host/dev \
    -v /proc:/host/proc:ro \
    falcosecurity/falco
  ```

- **Docker Scout** : Analyse de sécurité intégrée
  ```bash
  docker scout cves nginx:latest
  ```

### Documentation officielle

- [Docker Security](https://docs.docker.com/engine/security/)
- [Docker Daemon Configuration](https://docs.docker.com/engine/reference/commandline/dockerd/)
- [containerd Documentation](https://containerd.io/docs/)
- [OCI Runtime Specification](https://github.com/opencontainers/runtime-spec)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

---

## Exercices pratiques

### Exercice 1 : Configuration de base
1. Créer un fichier `/etc/docker/daemon.json` avec rotation de logs
2. Redémarrer Docker et vérifier la configuration
3. Lancer un conteneur et vérifier que les logs sont limités

### Exercice 2 : User namespaces
1. Activer `userns-remap`
2. Lancer un conteneur avec un processus `sleep 1000`
3. Vérifier sur l'hôte que le processus appartient à un UID > 100000

### Exercice 3 : Audit de sécurité
1. Exécuter Docker Bench Security
2. Identifier 5 recommandations
3. Implémenter les corrections

### Exercice 4 : Runtime gVisor
1. Installer gVisor (runsc)
2. Configurer Docker pour utiliser runsc
3. Comparer les performances avec runc

---

## Conclusion

La configuration avancée et le hardening de Docker sont **essentiels** pour une utilisation en production sécurisée.

**Points clés à retenir** :
- Le daemon Docker a de nombreuses options pour la sécurité, les performances et la gestion
- containerd et runc sont des couches séparées que vous pouvez configurer indépendamment
- Les user namespaces, AppArmor/SELinux, et Seccomp sont vos meilleurs alliés
- Auditez régulièrement avec Docker Bench Security
- Restez à jour et scannez vos images

**La sécurité est un processus continu, pas une configuration ponctuelle !**
