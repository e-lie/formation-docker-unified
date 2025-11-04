---
title: "TP Avancé - Déployer dans Swarm"
description: "Guide TP Avancé - Déployer dans Swarm"
sidebar:
  order: 310
---


## Objectifs

Dans ce TP, vous allez :
- Déployer automatiquement 3 serveurs Ubuntu avec Docker via Terraform
- Configurer manuellement un cluster Docker Swarm
- Comprendre l'architecture manager/worker de Swarm
- Déployer un service distribué sur le cluster

## Prérequis

- Un compte Hetzner Cloud avec un token API ([générer ici](https://console.hetzner.cloud/))
- Une clé SSH ajoutée à votre compte Hetzner Cloud
- Terraform installé sur votre machine (version >= 1.0)
- Connaissances de base en Docker

## Partie 1 : Déploiement de l'infrastructure avec Terraform

### Étape 1 : Configuration

Naviguez dans le dossier du projet :

```bash
cd swarm_lab_terraform
```

Créez un fichier `terraform.tfvars` avec la configuration suivante :

```hcl
hcloud_token    = "votre_token_hetzner_cloud"
prefix          = "votre_prefix_perso"
username        = "votre_nom_utilisateur"
server_type     = "cx22"
node_count      = 3
docker_mode     = "standard"
enable_swarm    = false
hcloud_ssh_keys = ["nom-de-votre-cle-ssh"]
enable_dns      = true

digitalocean_token  = ""               
dns_domain          = "dopl.uk"        
dns_subdomain       = "elie"
dns_create_wildcard = true
```

**Points importants :**
- `docker_mode = "standard"` : Installation Docker classique (pas rootless)
- `enable_swarm = false` : Pas de configuration automatique de Swarm (nous le ferons manuellement)
- `node_count = 3` : Déploiement de 3 serveurs
- `enable_dns = true` : Configuration DNS (optionnel)
- Le formateur va vous fournir une clé hetzner cloud et digitalocean

### Étape 2 : Déploiement

Initialisez Terraform :

```bash
terraform init
```

Vérifiez le plan de déploiement :

```bash
terraform plan
```

Déverrouilez la clé ssh stagiaire :

```bash
ssh-add ~/.ssh/id_stagiaire
```

Déployez l'infrastructure :

```bash
terraform apply
```

Confirmez avec `yes` lorsque demandé.

:::note
Le déploiement prend environ 2-3 minutes. Terraform va :
1. Créer 3 serveurs Ubuntu 24.04 sur Hetzner Cloud
2. Installer Docker CE sur chaque serveur
3. Configurer votre utilisateur avec les droits sudo et docker
:::

### Étape 3 : Récupération des adresses IP

À la fin du déploiement, notez les adresses IP affichées :

```
Outputs:

server_ips = {
  "swarm-server-1" = {
    "ipv4" = "x.x.x.x"
    "ipv6" = "..."
  }
  "swarm-server-2" = {
    "ipv4" = "y.y.y.y"
    "ipv6" = "..."
  }
  "swarm-server-3" = {
    "ipv4" = "z.z.z.z"
    "ipv6" = "..."
  }
}
```

### Étape 4 : Vérification

Testez la connexion SSH et vérifiez Docker :

```bash
# Connexion au premier serveur
ssh votre_utilisateur@<ip-server-1>

# Vérifier Docker
docker --version
docker ps

# Déconnexion
exit
```

## Partie 2 : Configuration manuelle de Docker Swarm

Maintenant que les 3 serveurs sont prêts, vous allez configurer manuellement le cluster Swarm.

### Étape 1 : Initialiser le manager

Connectez-vous au **premier serveur** (qui deviendra le manager) :

```bash
ssh votre_utilisateur@<ip-server-1>
```

Initialisez Docker Swarm :

```bash
docker swarm init --advertise-addr <ip-server-1>
```

:::tip[Résultat attendu]
Vous devriez voir un message similaire à :

```
Swarm initialized: current node (xxxxx) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-xxxxx <ip-server-1>:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```
:::

**Copiez la commande `docker swarm join`** affichée, vous en aurez besoin pour les workers.

### Étape 2 : Vérifier l'état du cluster

Toujours sur le manager, vérifiez l'état du cluster :

```bash
docker node ls
```

Vous devriez voir un seul nœud (le manager) avec le statut `Leader`.

### Étape 3 : Ajouter les workers

Ouvrez deux nouveaux terminaux et connectez-vous aux deux autres serveurs :

**Terminal 2 - Server 2 :**
```bash
ssh votre_utilisateur@<ip-server-2>

# Exécutez la commande join copiée précédemment
docker swarm join --token SWMTKN-1-xxxxx <ip-server-1>:2377
```

**Terminal 3 - Server 3 :**
```bash
ssh votre_utilisateur@<ip-server-3>

# Exécutez la même commande join
docker swarm join --token SWMTKN-1-xxxxx <ip-server-1>:2377
```

:::caution[Important]
Si vous avez perdu la commande join, vous pouvez la récupérer depuis le manager :
```bash
docker swarm join-token worker
```
:::

### Étape 4 : Vérifier le cluster complet

Retournez sur le **manager (server-1)** et vérifiez que tous les nœuds sont présents :

```bash
docker node ls
```

Vous devriez voir quelque chose comme :

```
ID                            HOSTNAME         STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
abc123 *                      swarm-server-1   Ready     Active         Leader           24.x.x
def456                        swarm-server-2   Ready     Active                          24.x.x
ghi789                        swarm-server-3   Ready     Active                          24.x.x
```

:::tip[Points clés]
- L'astérisque (*) indique le nœud sur lequel vous êtes connecté
- `MANAGER STATUS = Leader` indique le manager principal
- `STATUS = Ready` indique que le nœud est opérationnel
:::

## Partie 3 : Test du cluster avec un service

### Déployer un service Nginx

Depuis le **manager**, créez un service distribué :

```bash
docker service create \
  --name web \
  --replicas 3 \
  --publish published=8080,target=80 \
  nginx:alpine
```

Cette commande crée un service avec 3 réplicas (un par nœud).

### Vérifier le service

Lister les services :

```bash
docker service ls
```

Voir les détails et la distribution des conteneurs :

```bash
docker service ps web
```

Vous devriez voir les 3 réplicas distribués sur les différents nœuds.

### Tester l'accès

Depuis votre machine locale, testez l'accès au service :

```bash
# Le service est accessible sur n'importe quel nœud du cluster
curl http://<ip-server-1>:8080
curl http://<ip-server-2>:8080
curl http://<ip-server-3>:8080
```

Toutes les requêtes devraient retourner la page d'accueil Nginx.

:::note[Ingress Network]
Docker Swarm utilise un **ingress network** qui route automatiquement les requêtes vers un conteneur disponible, peu importe le nœud sur lequel vous faites la requête.
:::

### Scaler le service

Augmentez le nombre de réplicas :

```bash
docker service scale web=6
```

Vérifiez la nouvelle distribution :

```bash
docker service ps web
```

### Nettoyer

Supprimez le service :

```bash
docker service rm web
```

## Partie 4 : Exploration avancée (optionnel)

### Promouvoir un worker en manager

Pour la haute disponibilité, il est recommandé d'avoir plusieurs managers (nombre impair : 3, 5, 7).

Depuis le manager actuel :

```bash
# Promouvoir server-2 en manager
docker node promote swarm-server-2
```

Vérifiez :

```bash
docker node ls
```

### Drainer un nœud

Pour effectuer une maintenance sur un nœud sans impacter les services :

```bash
# Marquer le nœud comme indisponible
docker node update --availability drain swarm-server-3

# Vérifier que les conteneurs ont migré
docker service ps web

# Remettre le nœud en service
docker node update --availability active swarm-server-3
```

### Labels et contraintes

Ajouter un label à un nœud :

```bash
docker node update --label-add environment=production swarm-server-1
```

Déployer un service uniquement sur les nœuds de production :

```bash
docker service create \
  --name prod-app \
  --constraint 'node.labels.environment==production' \
  nginx:alpine
```

## Nettoyage

Une fois le TP terminé, vous pouvez détruire l'infrastructure :

```bash
cd swarm_lab_terraform
terraform destroy
```

Confirmez avec `yes`. Tous les serveurs seront supprimés de Hetzner Cloud.

## Récapitulatif

Dans ce TP, vous avez appris à :

✅ Déployer une infrastructure cloud avec Terraform
✅ Initialiser un cluster Docker Swarm manuellement
✅ Comprendre les rôles manager et worker
✅ Déployer et scaler des services distribués
✅ Utiliser l'ingress network pour le load balancing
✅ Gérer les nœuds (promotion, drain, labels)

## Pour aller plus loin

- Déployer une application multi-services avec un fichier stack
- Configurer un reverse proxy Traefik sur le cluster
- Mettre en place des secrets et configs Swarm
- Expérimenter avec les stratégies de déploiement (rolling update, rollback)