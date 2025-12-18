---
title: "Faire tourner des application GUI dans docker engine avec x11docker"
description: "Guide Faire tourner des application GUI dans docker engine avec x11docker"
sidebar:
  order: 309
---


**x11docker est un script bash qui fait 3 choses principales :**

1. **Démarre un serveur X isolé** (Xephyr, nxagent, ou réutilise votre X existant)

2. **Configure les permissions et l'authentification** (gère automatiquement `.Xauthority`, les sockets X11, les cookies d'authentification)

3. **Lance le conteneur Docker avec les bons paramètres** (monte les sockets, définit `DISPLAY`, gère les utilisateurs/groupes)

**En une ligne :**
x11docker crée un pont sécurisé entre votre serveur X11 et le conteneur Docker pour que les applications GUI fonctionnent comme si elles étaient natives.

**Schéma simplifié :**
```
Application dans conteneur → x11docker → Serveur X → Votre écran (i3)
                              ↑
                         Gère la plomberie
                    (sockets, auth, isolation)
```

Sans x11docker, vous devriez manuellement gérer les montages de `/tmp/.X11-unix`, les variables `DISPLAY`, les permissions, l'isolation de sécurité, etc. x11docker automatise tout ça avec des options de sécurité en plus (conteneurs non-root, isolation réseau, etc.).


## Installation

Voir le readme github :

https://github.com/mviereck/x11docker?tab=readme-ov-file#tldr

## Pour l'utiliser

Avec une image prébuildé : x11docker x11docker/xfce thunar
Images de base x11docker : https://hub.docker.com/search?q=x11docker

## Créer une image dérivée de x11docker/xfce avec Firefox

**Dockerfile :**

```dockerfile
FROM x11docker/xfce

# Installer Firefox
RUN apt-get update && \
    apt-get install -y firefox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Optionnel : définir Firefox comme commande par défaut
CMD ["firefox"]
```

**Construction de l'image :**
```bash
# Sauvegarder le Dockerfile ci-dessus
docker build -t mon-xfce-firefox .
```

**Utilisation :**

```bash
# Méthode 1 : Lancer juste Firefox (en fenêtre)
x11docker mon-xfce-firefox

# Méthode 2 : Lancer Firefox avec des options utiles
x11docker --clipboard --pulseaudio --network mon-xfce-firefox

# Méthode 3 : Lancer le bureau XFCE complet avec Firefox disponible
x11docker --desktop mon-xfce-firefox startxfce4

# Méthode 4 : Firefox avec accès à un dossier de téléchargements
x11docker --share ~/Downloads:/home/Downloads --network mon-xfce-firefox
```
