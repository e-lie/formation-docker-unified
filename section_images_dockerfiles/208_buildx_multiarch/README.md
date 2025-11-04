# TP 208 - Multi-Architecture Builds avec Docker Buildx

Ce TP contient une application complète composée de :
- **Backend** : API FastAPI (Python)
- **Frontend** : Application Svelte

## Structure du projet

```
208_buildx_multiarch/
├── app/
│   ├── backend/
│   │   ├── Dockerfile
│   │   ├── main.py
│   │   └── requirements.txt
│   └── frontend/
│       ├── Dockerfile
│       ├── nginx.conf
│       ├── package.json
│       ├── vite.config.js
│       └── src/
│           ├── App.svelte
│           └── main.js
├── docker-compose.yml
└── README.md
```

## Prérequis

- Docker 19.03+
- Docker Buildx activé
- (Optionnel) Accès à un registry Docker (Docker Hub, ghcr.io, etc.)

## Démarrage rapide en local

```bash
# Lancer l'application avec docker-compose
docker-compose up --build

# Accéder à l'application
# Frontend: http://localhost
# Backend API: http://localhost:8000
# Documentation API: http://localhost:8000/docs
```

## Objectifs du TP

1. Comprendre Docker Buildx et le multi-architecture
2. Builder des images pour AMD64 et ARM64
3. Pousser les images sur un registry
4. Tester les images sur différentes architectures

## Instructions détaillées

Voir le fichier `0_intro.md` pour les instructions complètes du TP.
