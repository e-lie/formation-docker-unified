# Cours 108 : Architecture des Runtime de Conteneurs

Ce cours explore en profondeur les architectures Docker, containerd et Podman, ainsi que les fondations Linux sur lesquelles reposent les conteneurs.

## Contenu du Cours

### 📘 Cours Principal

**[0_architecture_runtime.md](0_architecture_runtime.md)** - Cours complet couvrant :

#### Partie 1 : Fondations Linux
- **Namespaces** : Isolation des ressources (PID, NET, MNT, UTS, IPC, USER, CGROUP, TIME)
- **Cgroups** : Limitation et mesure des ressources (CPU, RAM, I/O, PIDs)
- **Capabilities** : Granularité des privilèges root
- **Union Filesystems** : Système de fichiers en couches

#### Partie 2 : Architecture Docker
- Schéma complet : CLI → dockerd → containerd → containerd-shim → runc
- Rôle de chaque composant
- Flux d'exécution détaillé

#### Partie 3 : Architecture containerd
- Utilisation standalone
- Intégration Kubernetes (CRI)
- Plugins et architecture modulaire

#### Partie 4 : Architecture Podman
- Approche sans daemon
- Mode rootless avec User Namespaces
- conmon vs containerd-shim
- Avantages sécurité

#### Partie 5 : Comparaison
- Tableau comparatif complet
- Cas d'usage recommandés
- Standard OCI

#### Partie 6 : Exercices Pratiques
- Explorer les namespaces
- Tester les limites cgroups
- Comparer Docker et Podman
- Manipuler les capabilities

### 🛠️ Scripts de Démonstration

Ces scripts interactifs permettent de visualiser concrètement les concepts.

#### [demo-namespaces.sh](demo-namespaces.sh)
Démonstration des 7 types de namespaces :
- PID : Isolation des processus
- NET : Isolation réseau
- MNT : Isolation système de fichiers
- UTS : Isolation hostname
- USER : Rootless avec Podman
- Et plus...

```bash
./demo-namespaces.sh
```

#### [demo-cgroups.sh](demo-cgroups.sh)
Démonstration des Control Groups :
- Limitation mémoire (OOM kill)
- Limitation CPU
- Limitation I/O disque
- Limitation nombre de processus
- Cgroups v1 vs v2

```bash
./demo-cgroups.sh
```

#### [demo-architecture.sh](demo-architecture.sh)
Observation de l'architecture en action :
- Chaîne de processus Docker
- Interaction avec containerd (via ctr)
- Vérification de runc
- Comparaison avec Podman
- Communication CLI → daemon

```bash
./demo-architecture.sh
```

## Prérequis

### Logiciels Requis

- **Docker** : Installation standard
  ```bash
  sudo apt install docker.io
  sudo usermod -aG docker $USER
  ```

- **Podman** (optionnel, pour comparaison) :
  ```bash
  sudo apt install podman
  ```

- **Outils système** (généralement pré-installés) :
  - `ps`, `pstree`, `ip`
  - `sudo` (pour accéder aux cgroups/namespaces)

### Permissions

Certaines commandes nécessitent `sudo` pour accéder aux informations kernel :
- Lecture des namespaces : `/proc/<PID>/ns/`
- Lecture des cgroups : `/sys/fs/cgroup/`

## Quick Start

### 1. Lire le Cours Théorique

```bash
# Ouvrir le cours principal
cat 0_architecture_runtime.md

# Ou avec un visualiseur markdown
mdcat 0_architecture_runtime.md  # si installé
```

### 2. Exécuter les Démonstrations

```bash
# Rendre les scripts exécutables (si nécessaire)
chmod +x demo-*.sh

# Démonstration des namespaces
./demo-namespaces.sh

# Démonstration des cgroups
./demo-cgroups.sh

# Démonstration de l'architecture complète
./demo-architecture.sh
```

### 3. Expérimenter

Essayez les commandes suivantes pour approfondir :

```bash
# Explorer les namespaces d'un conteneur
docker run -d --name test nginx:alpine
PID=$(docker inspect -f '{{.State.Pid}}' test)
sudo ls -l /proc/$PID/ns/

# Tester les limites de ressources
docker run --rm --memory="100m" --cpus="0.5" alpine free -m

# Observer la hiérarchie de processus
pstree -p | grep docker

# Utiliser containerd directement
sudo ctr --namespace moby containers list

# Comparer avec Podman (rootless)
podman run --rm alpine id
```

## Concepts Clés

### Namespaces : L'Isolation

Les namespaces créent des **vues isolées** des ressources système :

```
Hôte :  [PID 1, 2, 3, ..., 1234, 1235, ...]
           │                  │
           └──────────────────┴── Namespace PID

Container: [PID 1, 2]  (vue isolée)
```

### Cgroups : Les Limites

Les cgroups imposent des **limites de ressources** :

```
┌─────────────────────────┐
│  Conteneur              │
│  Limite : 512 MB        │  ← Cgroup Memory
├─────────────────────────┤
│  Limite : 1 CPU         │  ← Cgroup CPU
├─────────────────────────┤
│  Limite : 100 processus │  ← Cgroup PIDs
└─────────────────────────┘
```

### Architecture Docker

```
docker run
    ↓
dockerd (daemon)
    ↓
containerd
    ↓
containerd-shim
    ↓
runc
    ↓
Processus conteneur (isolé par namespaces + limité par cgroups)
```

### Architecture Podman

```
podman run
    ↓
libpod (pas de daemon !)
    ↓
conmon
    ↓
runc/crun
    ↓
Processus conteneur (rootless possible avec User Namespace)
```

## Exercices Suggérés

### Niveau 1 : Observation

1. Lancer un conteneur et identifier tous ses namespaces
2. Vérifier les limites cgroups d'un conteneur dans `/sys/fs/cgroup/`
3. Tracer la hiérarchie de processus avec `pstree`

### Niveau 2 : Expérimentation

1. Créer un conteneur qui dépasse sa limite mémoire (OOM kill)
2. Limiter un conteneur à 0.1 CPU et observer avec `docker stats`
3. Comparer les processus Docker vs Podman (utilisateur propriétaire)

### Niveau 3 : Approfondissement

1. Utiliser `ctr` pour interagir directement avec containerd
2. Explorer les capabilities d'un conteneur avec `capsh`
3. Créer un conteneur Podman rootless et vérifier le mapping UID

## Diagrammes

Le cours inclut des diagrammes Mermaid pour visualiser les architectures :

- Architecture Docker complète
- Architecture containerd standalone
- Architecture Podman sans daemon
- Flux d'exécution `docker run`

Ces diagrammes sont rendus automatiquement dans les visualiseurs markdown modernes.

## Ressources Complémentaires

### Documentation Officielle

- [OCI Specifications](https://opencontainers.org/)
- [Docker Architecture](https://docs.docker.com/get-started/overview/#docker-architecture)
- [containerd](https://containerd.io/)
- [Podman Documentation](https://docs.podman.io/)

### Man Pages Linux

```bash
man 7 namespaces
man 7 cgroups
man 7 capabilities
```

### Articles Approfondis

- [Linux Namespaces](https://man7.org/linux/man-pages/man7/namespaces.7.html)
- [cgroups v2](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html)
- [OCI Runtime Spec](https://github.com/opencontainers/runtime-spec)

## Dépannage

### Les scripts nécessitent sudo

Certaines opérations (lecture des namespaces/cgroups) nécessitent des privilèges élevés :

```bash
sudo ./demo-namespaces.sh
sudo ./demo-cgroups.sh
```

### Cgroups v1 vs v2

Le chemin des cgroups diffère selon la version :

- **v1** : `/sys/fs/cgroup/<controller>/docker/<container-id>/`
- **v2** : `/sys/fs/cgroup/system.slice/docker-<container-id>.scope/`

Vérifier la version :
```bash
mount | grep cgroup
```

### containerd namespace

Docker utilise le namespace `moby` dans containerd :

```bash
# Correct
sudo ctr --namespace moby containers list

# Incorrect (namespace vide)
sudo ctr containers list
```

## Conclusion

Ce cours vous a permis de :

✅ Comprendre les **fondations Linux** des conteneurs (namespaces, cgroups, capabilities)
✅ Décortiquer l'**architecture Docker** en plusieurs couches
✅ Découvrir **containerd** comme runtime standalone
✅ Explorer **Podman** et son approche rootless sans daemon
✅ Comparer les architectures et choisir le bon outil

Les conteneurs ne sont pas "magiques" - ce sont des processus Linux normaux avec une isolation intelligente !

## Auteur & Contributions

Ce cours fait partie de la formation Docker unifiée.

Pour signaler des erreurs ou suggérer des améliorations, créez une issue dans le dépôt du cours.
