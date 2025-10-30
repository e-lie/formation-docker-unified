---
title: TP - Installer un cluster swarm de dev avec incus
# sidebar_class_name: hidden
---


## Installer incus

- Observer le script `/opt/incus_for_swarm.sh`

Incus permet de faire des conteneur qui se comportent comme des vm linux complètes. Contrairement à Docker les conteneurs incus disposent par exemple de systemd configuré à l'intérieur. 

Il faut activer l'option de nesting des conteneur incus pour pouvoir créer des conteneur docker dans les conteneurs incus

- Lancez le script qui devrait créer 5 conteneurs et installer docker à l'intérieur

## Installer swarm

Connectez vous au swarm

## configurer le client docker pour le swarm

Pour trouver l'ip du swarm manager lancez : `incus list` et récupérez l'ip en 10.x.y.z

Pour se connecter au cluster: 

Créez un ficher `docker_env` puis sourcez le (la passphrase ssh est la même que le mdp utilisateur):

```sh
ssh-add ~/.ssh/id_stagiaire
export DOCKER_HOST="ssh://stagiaire@<ip swarm manager>"
```


Déployez la stack Swarm d'exemple suivante en suivant le readme: https://github.com/dockersamples/example-voting-app


## Autre version avec deploy section:

Source : https://devopstuto-docker.readthedocs.io/en/latest/samples/labs/votingapp/votingapp.html


```yaml
version: "3"
services:

  redis:
        image: redis:alpine
        ports:
          - "6379"
        networks:
          - frontend
        deploy:
          replicas: 1
          update_config:
                parallelism: 2
                delay: 10s
          restart_policy:
                condition: on-failure
  db:
        image: postgres:9.4
        volumes:
          - db-data:/var/lib/postgresql/data
        networks:
          - backend
        deploy:
          placement:
                constraints: [node.role == manager]
  vote:
        image: dockersamples/examplevotingapp_vote:before
        ports:
          - 5000:80
        networks:
          - frontend
        depends_on:
          - redis
        deploy:
          replicas: 2
          update_config:
                parallelism: 2
          restart_policy:
                condition: on-failure
  result:
        image: dockersamples/examplevotingapp_result:before
        ports:
          - 5001:80
        networks:
          - backend
        depends_on:
          - db
        deploy:
          replicas: 1
          update_config:
                parallelism: 2
                delay: 10s
          restart_policy:
                condition: on-failure

  worker:
        image: dockersamples/examplevotingapp_worker
        networks:
          - frontend
          - backend
        deploy:
          mode: replicated
          replicas: 1
          labels: [APP=VOTING]
          restart_policy:
                condition: on-failure
                delay: 10s
                max_attempts: 3
                window: 120s
          placement:
                constraints: [node.role == manager]

  visualizer:
        image: dockersamples/visualizer:stable
        ports:
          - "8080:8080"
        stop_grace_period: 1m30s
        volumes:
          - "/var/run/docker.sock:/var/run/docker.sock"
        deploy:
          placement:
                constraints: [node.role == manager]

networks:
  frontend:
  backend:

volumes:
  db-data:
```