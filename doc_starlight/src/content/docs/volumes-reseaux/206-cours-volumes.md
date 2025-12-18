---
title: "Cours - les volumes"
description: "Guide Cours - les volumes"
sidebar:
  order: 206
---


<!-- ## Objectifs pédagogiques
  - Savoir utiliser la commande VOLUME
  - Comprendre la persistance de données
  - Comprendre le montage dans les systèmes de fichier Linux
  - Savoir monter un volume dans un conteneur Docker
  - Savoir utiliser les commandes volume (create, ls, rm, prune)
  - Savoir monter des volumes de persistance locaux et distants
-->

## Cycle de vie d'un conteneur

- Un conteneur a un cycle de vie très court: il doit pouvoir être créé et supprimé rapidement même en contexte de production.

Conséquences :

- On a besoin de mécanismes d'autoconfiguration, en particuler réseau car les IP des différents conteneur changent tout le temps.
- On ne peut pas garder les données persistantes dans le conteneur.

Solutions :

- Des réseaux dynamiques par défaut automatiques (DHCP mais surtout DNS automatiques)
- Des volumes (partagés ou non, distribués ou non) montés dans les conteneurs

## Volumes

Un volume est utile pour tout ce qui est "stateful" dans un conteneur :

* fichiers de config
* stockages de base de données
* certificats SSL
* etc.

## L'instruction `VOLUME` dans un `Dockerfile`

```dockerfile
VOLUME ["/data"]
```
L'instruction `VOLUME` dans un `Dockerfile` permet de désigner les volumes qui devront être créés lors du lancement du conteneur. 

Même si on ne le précise pas, Docker **crée quand même un volume Docker au nom généré aléatoirement**, un volume "caché".

Exemple :

```dockerfile
FROM ubuntu
VOLUME /myvol
# la CMD par défaut récupère la date et heure courante et l'écrit dans un fichier dans le volume
CMD ["bash", "-c", "date | tee /myvol/created_at.txt"]
```

```shell
docker build -t created_at
docker volume ls
docker run created_at
docker container inspect created_at # chercher la section Mount et le hash du volume
docker volume ls # le docker run a entrainé la création d'un volume anonyme dont le nom est un hash
sudo ls /var/lib/docker/volumes/<hash_du_volume>/_data # les données sont stockée par défaut en local dans docker
```

## Les volumes Docker via la sous-commande `volume`

- `docker volume create`
- `docker volume ls`
- `docker volume inspect`
- `docker volume rm`
- `docker volume prune`

## Un volume nommé avec la commande create

On crée un volume nommé avec

```shell 
docker volume create redis_data
docker run --rm -d -v redis_data:/data redis
```

Ici le point de montage `/data` est spécifique à l'image `redis`

```shell
docker image history redis 
...
<missing>      2 days ago   /bin/sh -c #(nop)  VOLUME [/data]               0B        
<missing>      2 days ago   /bin/sh -c mkdir /data && chown redis:redis …   0B        
...
```

## Bind mounting : un dossier partagé avec le conteneur

Le bind mounting n'est **pas un volume à proprement parler**

Lorsqu'un répertoire hôte spécifique est utilisé dans un volume (la syntaxe `-v HOST_DIR:CONTAINER_DIR`), elle est souvent appelée **bind mounting** ("montage lié").

La particularité, c'est que le point de montage sur l'hôte est explicite plutôt que caché dans un répertoire appartenant à Docker.

Exemple :

```shell
# Sur l'hôte
docker run -it -v /home/user/app/config.conf:/config/main.conf:ro -v /home/user/app/data:/data ubuntu /bin/bash

# Dans le conteneur
cd /data/
touch testfile
exit

# Sur l'hôte
ls /home/user/app/data:
```

### Partager des données avec un volume

**Pour partager des données on peut monter le même volume dans plusieurs conteneurs.**

Pour lancer un conteneur avec les volumes d'un autre conteneur déjà montés on peut utiliser `--volumes-from <container>`

On peut aussi créer le volume à l'avance et l'attacher après coup à un conteneur.

Par défaut le driver de volume est `local` c'est-à-dire qu'un dossier est créé sur le disque de l'hôte.

```shell
docker volume create tmp
docker run -d --name conteneur_1 -v tmp:/data ubuntu bash -c "while true; do date; ls /data; sleep 1; done"
docker run -d --name conteneur_2 -v tmp:/data ubuntu bash -c "while true; do date; ls /data; sleep 1; done"
docker exec conteneur_1 touch /data/file_1
docker exec conteneur_2 touch /data/file_2
docker logs conteneur_1 
```

### L'argument verbeux : `docker run --mount`

Cette option plus verbeuse que "-v" est préconisée car elle permet de bien spécifier les types de points de montage.

```shell
--mount type=TYPE, TYPE-SPECIFIC-OPTION[,...]
           Attacher un montage de système de fichiers au conteneur
           
       type=bind,source=/path/on/host,destination=/path/in/container
       type=volume,source=myvolume,destination=/path/in/container,volume-label="color=red",volume-label="shape=round"
       type=tmpfs,tmpfs-size=512M,destination=/path/in/container

```


### Dans un cloud : besoin de volume réseau partager entre les serveurs hotes Docker

### Plugins de volumes

On peut utiliser d'autres systèmes de stockage en installant de nouveau plugins de driver de volume. Par exemple, le plugin `vieux/sshfs` permet de piloter un volume distant via SSH.

Exemples:

- SSHFS (utilisation d'un dossier distant via SSH)
- NFS (protocole NFS)
- BeeGFS (système de fichier distribué générique)
- Amazon EBS (vendor specific)
- etc.

```shell
docker volume create -d vieux/sshfs -o sshcmd=<sshcmd> -o allow_other sshvolume
docker run -p 8080:8080 -v sshvolume:/path/to/folder --name test someimage
```

Mais les driver Docker ne sont plus maintenus car la production cloud avec Docker est dépréciée en faveur de Kubernetes

On peut tout de même utiliser NFS manuellement pour cela : 

#### Création d’un Volume NFS avec le Driver Local

pour créer un volume NFS on peut utiliser la commande `docker volume create` avec des options spécifiques pour NFS. 

```bash
docker volume create --driver local \
  --opt type=nfs \
  --opt o=addr=ip_serveur_nfs,nolock,soft,rw \
  --opt device=:/chemin_du_dossier_nfs \
  mon_volume_nfs
```

Remplacez `ip_serveur_nfs` par l’adresse IP ou le nom d’hôte du serveur NFS et `/chemin_du_dossier_nfs` par le chemin du répertoire NFS que vous souhaitez monter.


### Permissions

Un volume est créé avec les permissions du dossier préexistant c'est à dire l'UID/GID de l'utilisateur qui a créé le dossier

```Dockerfile
FROM debian
RUN groupadd -r graphite && useradd -r -g graphite graphite
RUN mkdir -p /data/graphite && chown -R graphite:graphite /data/graphite
VOLUME /data/graphite
USER graphite
CMD ["echo", "Data container for graphite"]
```

Cela peut mener à des collisions d'UID (typiquement 1000 pour le premier utilisateur) entre l'intérieur et l'extérieur du conteneur et donc a des problèmes de permissions. Bonne pratique utiliser un UID custom pour chaque Dockerfile.

## Portainer

Si vous aviez déjà créé le conteneur Portainer, vous pouvez le relancer en faisant `docker start portainer`, sinon créez-le comme suit :

```shell
docker volume create portainer_data
docker run --detach --name portainer \
    -p 9000:9000 \
    -v portainer_data:/data \
    -v /var/run/docker.sock:/var/run/docker.sock \
    portainer/portainer-ce
```

- Remarque sur la commande précédente : pour que Portainer puisse fonctionner et contrôler Docker lui-même depuis l'intérieur du conteneur il est nécessaire de lui donner accès au socket de l'API Docker de l'hôte grâce au paramètre `--volume` ci-dessus.

- Visitez ensuite la page [http://localhost:9000](http://localhost:9000) pour accéder à l'interface.
- Créez votre user admin avec le formulaire.
- Explorez l'interface de Portainer.


### Facultatif : utiliser `VOLUME` avec `microblog`


- Clonons le repo `microblog` ailleurs :

```shell
git clone https://github.com/uptime-formation/microblog/ --branch tp2-dockerfile microblog-volume
```

- Ouvrons ça avec VSCode : `codium microblog-volume`

- Lire le `Dockerfile` de l'application `microblog`.

Un volume Docker apparaît comme un dossier à l'intérieur du conteneur.
Nous allons faire apparaître le volume Docker comme un dossier à l'emplacement `/data` sur le conteneur.

- Pour que l'app Python soit au courant de l'emplacement de la base de données, ajoutez à votre `Dockerfile` une variable d'environnement `DATABASE_URL` ainsi (cette variable est lue par le programme Python) :

```Dockerfile
ENV DATABASE_URL=sqlite:////data/app.db
```

Cela indique que l'on va demander à Python d'utiliser SQLite pour stocker la base de données comme un unique fichier au format `.db` (SQLite) dans un dossier accessible par le conteneur. On a en fait indiqué à l'app Python que chemin de la base de données est :
`/data/app.db`

- Ajouter au `Dockerfile` une instruction `VOLUME` pour stocker la base de données SQLite de l'application.

Voici le `Dockerfile` complet :

```Dockerfile
FROM python:3.9-alpine

COPY ./requirements.txt /requirements.txt
RUN pip3 install -r requirements.txt
ENV FLASK_APP microblog.py

COPY ./ /microblog
WORKDIR /microblog

ENV CONTEXT PROD

EXPOSE 5000

ENV DATABASE_URL=sqlite:////data/app.db
VOLUME ["/data"]

CMD ["./boot.sh"]
```

- Créez un volume nommé appelé `microblog_db`, et lancez un conteneur l'utilisant, créez un compte et écrivez un message.
- Vérifier que le volume nommé est bien utilisé en branchant un deuxième conteneur `microblog` utilisant le même volume nommé.

---