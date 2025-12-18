---
title:  Connecter un périphérique USB à un conteneur Docker
weight: 35
---

## Qu'est-ce qu'un device sur Linux ?

### Concept de base

**Un device (périphérique) sur Linux est représenté par un fichier spécial** dans `/dev/` qui permet de communiquer avec le matériel.

**Philosophie Unix :** "Tout est un fichier" - même le matériel !

### Types de devices

**1. Block devices (périphériques bloc) - `b`**
```bash
# Disques durs, clés USB, partitions
ls -l /dev/sda
brw-rw---- 1 root disk 8, 0 déc 18 10:30 /dev/sda

# Lisent/écrivent par blocs de données
# Exemples : /dev/sda, /dev/sdb1, /dev/nvme0n1
```

**2. Character devices (périphériques caractère) - `c`**
```bash
# Périphériques série, souris, clavier
ls -l /dev/ttyUSB0
crw-rw---- 1 root dialout 188, 0 déc 18 10:30 /dev/ttyUSB0

# Lisent/écrivent caractère par caractère (flux de données)
# Exemples : /dev/ttyUSB0, /dev/random, /dev/null
```

### Exemples concrets

```bash
# Disques et partitions
/dev/sda         # Premier disque SATA
/dev/sda1        # Première partition
/dev/nvme0n1     # Disque NVMe
/dev/loop0       # Périphérique loop (montage d'images ISO)

# USB
/dev/ttyUSB0     # Port série USB (Arduino, GPS)
/dev/ttyACM0     # Port ACM USB (modem, Arduino)
/dev/bus/usb/    # Bus USB complet

# Vidéo
/dev/video0      # Webcam
/dev/fb0         # Framebuffer (écran)
/dev/dri/card0   # Carte graphique (GPU)

# Audio
/dev/snd/        # Périphériques son

# Input
/dev/input/      # Clavier, souris, joystick
/dev/input/mouse0

# Spéciaux
/dev/null        # Trou noir (ignore toutes les données)
/dev/zero        # Source infinie de zéros
/dev/random      # Générateur aléatoire
/dev/urandom     # Générateur pseudo-aléatoire
```

### Structure d'un device

```bash
ls -l /dev/sda
brw-rw---- 1 root disk 8, 0 déc 18 10:30 /dev/sda
│││││││││  │ │    │    │  │
│││││││││  │ │    │    │  └─ Minor number (identifie le device)
│││││││││  │ │    │    └──── Major number (identifie le driver)
│││││││││  │ │    └─────────── Groupe
│││││││││  │ └──────────────── Propriétaire
│││││││││  └─────────────────── Nombre de liens
││││││││└────────────────────── Permissions (rw-)
│││││││└─────────────────────── Groupe (rw-)
││││││└──────────────────────── Autres (---)
│││││└───────────────────────── Sticky/SGID/SUID
││││└────────────────────────── Type : b=bloc, c=caractère
```

### Commandes utiles

```bash
# Lister tous les devices blocs
lsblk

# Lister les devices USB
lsusb

# Lister les devices PCI
lspci

# Voir les devices connectés en temps réel
udevadm monitor

# Informations sur un device
udevadm info /dev/sda

# Créer manuellement un device (rarement nécessaire)
sudo mknod /dev/mondevice c 123 0
```

### udev : Le gestionnaire de devices

**udev** crée automatiquement les fichiers dans `/dev/` quand du matériel est branché :

```bash
# Règles udev dans
/etc/udev/rules.d/

# Exemple de règle : donner un nom fixe à une clé USB
# /etc/udev/rules.d/99-usb.rules
KERNEL=="sd?1", ATTRS{serial}=="123456", SYMLINK+="ma_cle_usb"
```

### En résumé

Un device Linux = **interface fichier** pour communiquer avec le **matériel physique**, géré par le **noyau** via des **drivers**, et créé/géré automatiquement par **udev**.

## Comment connecter un péphérique usb ou autre dans Docker

### 1 - Monter un périphérique spécifique

```bash
# Trouver votre périphérique USB
lsusb
ls -l /dev/bus/usb/

# Monter un périphérique spécifique (ex: /dev/ttyUSB0)
docker run --device=/dev/ttyUSB0 mon_image

# Ou avec plusieurs périphériques
docker run --device=/dev/ttyUSB0 --device=/dev/ttyACM0 mon_image
```

### 2 - Donner accès à tous les périphériques USB

```bash
# Monter tout le bus USB (moins sécurisé)
docker run -v /dev/bus/usb:/dev/bus/usb --privileged mon_image

# Ou spécifiquement
docker run --device=/dev/bus/usb mon_image
```

### 3 - Autres périphériques courants

**Clé USB / Disque externe :**
```bash
# Identifier
lsblk

# Monter (ex: /dev/sdb1)
docker run --device=/dev/sdb1 -v /mnt/usb:/mnt/usb mon_image
```

**Webcam :**
```bash
docker run --device=/dev/video0 mon_image
```

**Imprimante USB :**
```bash
docker run --device=/dev/usb/lp0 mon_image
```

### Avec Docker Compose

```yaml
version: '3'
services:
  mon_service:
    image: mon_image
    devices:
      - "/dev/ttyUSB0:/dev/ttyUSB0"
      - "/dev/video0:/dev/video0"
    privileged: true  # Si nécessaire à éviter si on veut garder les conteneurs comme une isolation de sécu
```

### Gestion des permissions

Le problème : quand vous montez un device USB dans Docker, **le conteneur hérite des permissions du fichier device de l'hôte** :

```bash
# Sur l'hôte
ls -l /dev/ttyUSB0
crw-rw---- 1 root dialout 188, 0 déc 18 10:30 /dev/ttyUSB0
          │      │
          │      └─ Seul le groupe 'dialout' peut lire/écrire
          └──────── Seul root peut lire/écrire
```

L'utilisateur dans le conteneur n'est ni `root` ni dans le groupe `dialout` → **Permission denied !**

`dialout` est le nom du group sur debian mais peut être différent sur d'autre linux (`uccp` sur mon archlinux)

### Solutions

Ajouter l'utilisateur du conteneur au groupe :

```bash
cat /etc/group
ls -l /dev/ # lister les périphériques avec leur owner

# Vérifier le GID sur votre système
getent group dialout
# dialout:x:986:

# Lancer le conteneur
docker run -it --rm \
  --device=/dev/ttyUSB0 \
  --group-add 986 \
  ubuntu bash

# Dans le conteneur, vérifier
groups
# Affiche : root 986
id
# uid=0(root) gid=0(root) groups=0(root),986
```


Solution 2 : changer les permissions du device (MOINS SÉCURISÉ)

```bash
# Donner les permissions (temporaire)
sudo chmod 666 /dev/ttyUSB0

# Lancer le conteneur (pas besoin de --group-add)
docker run -it --rm --device=/dev/ttyUSB0 ubuntu bash

# Pas de permission denied
echo "test" > /dev/ttyUSB0 
```
