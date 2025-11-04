---
title: "Scan d'Images Docker : Détection des Vulnérabilités"
description: "Guide complet sur le scan de sécurité des images Docker avec Trivy, Clair, Harbor et autres outils"
sidebar:
  order: 310
---


## Objectifs pédagogiques
  - Comprendre l'importance du scan de vulnérabilités des images
  - Maîtriser Trivy pour scanner les images Docker
  - Connaître les alternatives : Clair, Grype, Snyk, etc.
  - Intégrer le scan dans les pipelines CI/CD
  - Mettre en place des politiques de sécurité

---

# Introduction : Pourquoi Scanner les Images Docker ?

## Le problème de la supply chain des conteneurs

Une image Docker typique contient :
- Un système d'exploitation de base (Ubuntu, Alpine, etc.)
- Des dépendances système (libc, openssl, curl, etc.)
- Des runtimes (Python, Node.js, Java, etc.)
- Des bibliothèques applicatives (pip packages, npm modules, etc.)
- Votre code applicatif

**Chaque couche peut contenir des vulnérabilités !**

```
┌─────────────────────────────────────────────────────┐
│                  Votre Image Docker                 │
├─────────────────────────────────────────────────────┤
│  Votre code (app.py)                    ← 1 CVE ?  │
│  ├─ requirements.txt                                │
│  │  ├─ flask==2.0.1                     ← 5 CVEs   │
│  │  ├─ requests==2.25.1                 ← 2 CVEs   │
│  │  └─ pillow==8.2.0                    ← 3 CVEs   │
│  ├─ Python 3.9.5                         ← 0 CVE    │
│  ├─ openssl 1.1.1k                       ← 7 CVEs!  │
│  ├─ curl 7.68.0                          ← 4 CVEs   │
│  └─ Ubuntu 20.04 base                    ← 50+ CVEs │
└─────────────────────────────────────────────────────┘
         Total : ~72 vulnérabilités potentielles !
```

## Statistiques réelles

D'après les études de sécurité (Snyk, Aqua Security) :
- **80% des images Docker** sur Docker Hub contiennent des vulnérabilités connues
- **40%** contiennent des vulnérabilités **critiques** ou **hautes**
- En moyenne, une image contient **30-50 vulnérabilités**
- La plupart sont dans les **dépendances OS**, pas le code applicatif

**Exemple réel** : En 2021, la vulnérabilité Log4Shell (CVE-2021-44228) a affecté des millions de conteneurs Java.

---

# Trivy : Le Scanner de Référence

## Présentation de Trivy

**Trivy** (de Aqua Security) est l'outil de scan le plus populaire et complet.

### Caractéristiques

✅ **Open Source** (Apache 2.0)
✅ **Rapide** : scan en quelques secondes
✅ **Complet** : détecte les vulnérabilités dans :
  - OS packages (Alpine, Debian, Ubuntu, RHEL, etc.)
  - Langages de programmation (Python, Node.js, Ruby, Go, Rust, etc.)
  - IaC (Infrastructure as Code) : Terraform, Kubernetes manifests, Dockerfiles
  - Secrets (clés API, tokens, mots de passe)
  - Misconfigurations

✅ **Précis** : très peu de faux positifs
✅ **Bases de données à jour** : synchronisation quotidienne avec NVD, Red Hat, Debian, Alpine, etc.

### Installation

```bash
# Installation via script (Linux/macOS)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Vérifier l'installation
trivy version

# Via apt (Debian/Ubuntu)
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Via Docker (pas d'installation requise)
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image nginx:latest
```

---

## Utilisation de Trivy

### 1. Scanner une Image Docker Locale

```bash
# Scan basique
trivy image nginx:alpine

# Sortie typique :
# nginx:alpine (alpine 3.18.4)
# Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
```

### 2. Scanner une Image avec Vulnérabilités

```bash
# Scanner une vieille image Ubuntu
trivy image ubuntu:18.04

# Résultat (exemple) :
# ubuntu:18.04 (ubuntu 18.04)
# Total: 87 (UNKNOWN: 0, LOW: 43, MEDIUM: 31, HIGH: 12, CRITICAL: 1)
#
# ┌───────────────┬────────────────┬──────────┬───────────────────┬───────────────┬────────────────────────────────────────────────┐
# │   Library     │ Vulnerability  │ Severity │ Installed Version │ Fixed Version │                     Title                       │
# ├───────────────┼────────────────┼──────────┼───────────────────┼───────────────┼────────────────────────────────────────────────┤
# │ openssl       │ CVE-2022-0778  │ CRITICAL │ 1.1.1-1ubuntu2.1  │ 1.1.1-1ubuntu14.2 │ openssl: Infinite loop in BN_mod_sqrt() ...  │
# │ curl          │ CVE-2021-22946 │ HIGH     │ 7.58.0-2ubuntu3   │ 7.58.0-2ubuntu3.16 │ curl: Requirement to use TLS not enforced...│
# │ libc6         │ CVE-2020-1751  │ MEDIUM   │ 2.27-3ubuntu1     │ 2.27-3ubuntu1.4   │ glibc: array overflow in backtrace...        │
# └───────────────┴────────────────┴──────────┴───────────────────┴───────────────┴────────────────────────────────────────────────┘
```

### 3. Filtrer par Sévérité

```bash
# Afficher uniquement les vulnérabilités CRITICAL et HIGH
trivy image --severity CRITICAL,HIGH ubuntu:18.04

# Afficher uniquement CRITICAL
trivy image --severity CRITICAL ubuntu:18.04

# Ignorer les vulnérabilités non fixées (pas de patch disponible)
trivy image --ignore-unfixed nginx:1.21

# Exit code 1 si des vulnérabilités sont trouvées (utile en CI/CD)
trivy image --exit-code 1 --severity CRITICAL nginx:latest
```

### 4. Formats de Sortie

```bash
# Format JSON
trivy image --format json -o results.json nginx:alpine

# Format SARIF (pour GitHub Security)
trivy image --format sarif -o results.sarif nginx:alpine

# Format table (par défaut)
trivy image --format table nginx:alpine

# Format template personnalisé
trivy image --format template --template "@contrib/html.tpl" -o report.html nginx:alpine
```

### 5. Scanner les Secrets et Misconfigurations

```bash
# Scanner les secrets dans une image
trivy image --scanners secret nginx:latest

# Scanner les misconfigurations (Dockerfile, etc.)
trivy image --scanners config nginx:latest

# Scanner TOUT (vulnérabilités + secrets + misconfigurations)
trivy image --scanners vuln,secret,config nginx:latest
```

### 6. Scanner un Dockerfile (avant le build)

```bash
# Scanner un Dockerfile
trivy config Dockerfile

# Exemple de résultat :
# Dockerfile (dockerfile)
#
# Tests: 23 (SUCCESSES: 20, FAILURES: 3, EXCEPTIONS: 0)
# Failures: 3 (UNKNOWN: 0, LOW: 1, MEDIUM: 1, HIGH: 1, CRITICAL: 0)
#
# MEDIUM: Specify a tag in the 'FROM' statement for image 'ubuntu'
# ════════════════════════════════════════
# Using the latest tag is prone to errors if the image is updated
# ────────────────────────────────────────
# Dockerfile:1
# ────────────────────────────────────────
#  1 [ FROM ubuntu
# ────────────────────────────────────────
```

### 7. Scanner un Fichier de Dépendances

```bash
# Scanner requirements.txt (Python)
trivy fs --scanners vuln requirements.txt

# Scanner package.json (Node.js)
trivy fs --scanners vuln package.json

# Scanner un répertoire complet
trivy fs --scanners vuln,secret,config ./my-app
```

---

## Exemples Pratiques avec Trivy

### Exemple 1 : Comparer Deux Images

```bash
# Scanner alpine vs ubuntu
echo "=== Alpine ==="
trivy image --severity HIGH,CRITICAL alpine:3.18

echo -e "\n=== Ubuntu 22.04 ==="
trivy image --severity HIGH,CRITICAL ubuntu:22.04

# Alpine aura généralement BEAUCOUP moins de vulnérabilités !
```

**Résultat typique** :
- Alpine 3.18 : 0-5 vulnérabilités HIGH/CRITICAL
- Ubuntu 22.04 : 20-40 vulnérabilités HIGH/CRITICAL

**Conclusion** : Préférer les images minimales comme Alpine ou Distroless.

### Exemple 2 : Trouver une Image Sécurisée

```bash
# Tester plusieurs versions de Python
for tag in 3.11-slim 3.11-alpine 3.11-slim-bullseye; do
  echo "=== python:$tag ==="
  trivy image --severity CRITICAL --quiet python:$tag | grep Total
done

# Résultat (exemple) :
# === python:3.11-slim ===
# Total: 0 (CRITICAL: 0)
#
# === python:3.11-alpine ===
# Total: 0 (CRITICAL: 0)
#
# === python:3.11-slim-bullseye ===
# Total: 2 (CRITICAL: 2)
```

**Conseil** : Utilisez les tags `-slim` ou `-alpine` récents.

### Exemple 3 : Détecter des Secrets

```bash
# Créer un Dockerfile avec un secret (ne JAMAIS faire ça en vrai !)
cat > Dockerfile.bad <<EOF
FROM alpine
RUN echo "API_KEY=sk_live_51Abc123..." > /app/.env
EOF

# Scanner
trivy config Dockerfile.bad --scanners secret

# Résultat :
# Dockerfile.bad (secrets)
#
# Tests: 1 (SUCCESSES: 0, FAILURES: 1, EXCEPTIONS: 0)
# Failures: 1 (CRITICAL: 1)
#
# CRITICAL: Stripe API key detected
# ════════════════════════════════════════
# Dockerfile.bad:2
# ────────────────────────────────────────
#  2 [ RUN echo "API_KEY=sk_live_51Abc123..." > /app/.env
# ────────────────────────────────────────
```

---

## Intégrer Trivy dans un Pipeline CI/CD

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - build
  - scan
  - deploy

docker-build:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

trivy-scan:
  stage: scan
  image: aquasec/trivy:latest
  script:
    # Scanner l'image buildée
    - trivy image --exit-code 0 --severity LOW,MEDIUM $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  # Générer un rapport
  artifacts:
    reports:
      container_scanning: gl-container-scanning-report.json
```

### GitHub Actions

```yaml
# .github/workflows/trivy.yml
name: Trivy Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  trivy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

### Jenkins

```groovy
// Jenkinsfile
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'docker build -t myapp:${BUILD_NUMBER} .'
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy:latest image \
                      --exit-code 0 --severity LOW,MEDIUM \
                      myapp:${BUILD_NUMBER}

                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy:latest image \
                      --exit-code 1 --severity HIGH,CRITICAL \
                      myapp:${BUILD_NUMBER}
                '''
            }
        }

        stage('Deploy') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                sh 'docker push myapp:${BUILD_NUMBER}'
            }
        }
    }
}
```

---

# Alternatives à Trivy

## 1. Clair (CoreOS / Red Hat)

**Clair** est un scanner de vulnérabilités open source développé par CoreOS (Red Hat).

### Caractéristiques

- **Architecture** : Client-serveur (API REST)
- **Forces** :
  - Intégration native avec Quay.io
  - Base de données riche (NVD, Red Hat, Debian, Ubuntu, Alpine, etc.)
  - Analyse statique des layers
- **Faiblesses** :
  - Plus complexe à déployer (nécessite PostgreSQL)
  - CLI moins convivial que Trivy
  - Moins de fonctionnalités (pas de scan de secrets, IaC, etc.)

### Installation et Utilisation

```bash
# Déployer Clair avec Docker Compose
git clone https://github.com/quay/clair.git
cd clair
docker-compose up -d

# Utiliser clairctl (CLI)
go install github.com/jgsqware/clairctl@latest

# Scanner une image
clairctl analyze myapp:latest
clairctl report myapp:latest
```

**Cas d'usage** : Idéal si vous utilisez déjà Quay.io comme registry.

---

## 2. Grype (Anchore)

**Grype** est le scanner open source d'Anchore, rapide et simple.

### Caractéristiques

- **Forces** :
  - Très rapide (comparable à Trivy)
  - Simple à utiliser
  - Bonne détection des dépendances applicatives
- **Faiblesses** :
  - Moins de scanners que Trivy (pas de secrets, IaC)
  - Base de données moins riche

### Installation et Utilisation

```bash
# Installation
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Scanner une image
grype nginx:latest

# Format JSON
grype nginx:latest -o json

# Filtrer par sévérité
grype nginx:latest --fail-on high
```

**Cas d'usage** : Alternative simple à Trivy, surtout si vous utilisez Anchore Engine.

---

## 3. Snyk Container

**Snyk** est une plateforme commerciale de sécurité avec une version gratuite.

### Caractéristiques

- **Forces** :
  - Interface web très riche
  - Excellente UX
  - Conseils de remédiation intelligents
  - Intégration native dans GitHub, GitLab, etc.
  - Base de données propriétaire très complète
- **Faiblesses** :
  - **Payant** au-delà de 200 tests/mois (version gratuite limitée)
  - Nécessite un compte Snyk

### Installation et Utilisation

```bash
# Installation
npm install -g snyk

# Authentification
snyk auth

# Scanner une image
snyk container test nginx:latest

# Monitorer en continu
snyk container monitor nginx:latest --project-name=nginx-prod
```

**Cas d'usage** : Équipes qui veulent une solution clé en main avec support commercial.

---

## 4. Docker Scout (Docker Inc.)

**Docker Scout** est la solution native de Docker Inc. (intégré depuis 2023).

### Caractéristiques

- **Forces** :
  - Intégré directement dans Docker Desktop et Docker Hub
  - Interface simple
  - Gratuit pour usage personnel
- **Faiblesses** :
  - Moins mature que Trivy
  - Fonctionnalités limitées en version gratuite
  - Nécessite Docker Desktop ou CLI récent

### Utilisation

```bash
# Scanner une image (Docker CLI >= 24.0)
docker scout cves nginx:latest

# Recommandations
docker scout recommendations nginx:latest

# Comparer deux images
docker scout compare --to nginx:alpine nginx:latest

# Interface web
# → Se connecter sur scout.docker.com
```

**Cas d'usage** : Développeurs utilisant déjà Docker Desktop.

---

## 5. Harbor (CNCF)

**Harbor** est un registry Docker privé open source avec scan intégré.

### Caractéristiques

- **Forces** :
  - Registry complet (stockage + scan + RBAC + replication)
  - Scan automatique à chaque push
  - Policies de sécurité (bloquer les images vulnérables)
  - Intègre Trivy ou Clair comme moteur de scan
  - Interface web complète
- **Faiblesses** :
  - Infrastructure à déployer et maintenir
  - Overkill si vous voulez juste scanner des images

### Déploiement

```bash
# Via Docker Compose
wget https://github.com/goharbor/harbor/releases/download/v2.9.0/harbor-offline-installer-v2.9.0.tgz
tar xvf harbor-offline-installer-v2.9.0.tgz
cd harbor

# Configurer
cp harbor.yml.tmpl harbor.yml
nano harbor.yml  # Modifier hostname, mot de passe admin, etc.

# Installer
sudo ./install.sh --with-trivy

# Accéder à l'interface
# → http://your-harbor-domain
# Login: admin / Harbor12345 (à changer !)
```

**Interface Harbor** :
- **Scan automatique** : Chaque image pushée est automatiquement scannée
- **Policies** : Bloquer le pull des images avec vulnérabilités CRITICAL
- **Rapports** : Vue d'ensemble des vulnérabilités par projet

**Cas d'usage** : Organisations qui veulent un registry privé sécurisé.

---

## Comparaison des Outils

| Outil | Type | Gratuit | Facilité | Complet | CI/CD | Web UI | Cas d'usage |
|-------|------|---------|----------|---------|-------|--------|-------------|
| **Trivy** | CLI | ✅ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ | ❌ | **Recommandé pour la plupart des cas** |
| **Clair** | API | ✅ | ⭐⭐ | ⭐⭐⭐⭐ | ✅ | ❌ | Si vous utilisez Quay.io |
| **Grype** | CLI | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ | ❌ | Alternative simple à Trivy |
| **Snyk** | Cloud | ⚠️ Limité | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ | ✅ | Équipes avec budget |
| **Docker Scout** | CLI/Web | ⚠️ Limité | ⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ | ✅ | Utilisateurs Docker Desktop |
| **Harbor** | Registry | ✅ | ⭐⭐ | ⭐⭐⭐⭐ | ✅ | ✅ | Registry privé d'entreprise |

---

# Bonnes Pratiques de Scan d'Images

## 1. Scanner Tôt et Souvent ("Shift Left")

```
┌─────────────────────────────────────────────────────────────┐
│           Pipeline de Sécurité "Shift Left"                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Développement  →  Build  →  Test  →  Registry  →  Deploy  │
│       ↓             ↓        ↓         ↓           ↓        │
│    Scan IDE    Scan Docker  Scan CI   Scan        Runtime  │
│                file         Image      auto        scan     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Recommandations** :
1. **Pré-commit** : Scanner le Dockerfile et dépendances localement
2. **CI/CD** : Scanner l'image buildée automatiquement
3. **Registry** : Re-scanner périodiquement (nouvelles CVEs)
4. **Runtime** : Monitorer les conteneurs en production

## 2. Définir des Politiques de Sécurité

Exemple de politique :

```yaml
# security-policy.yml
scan_policy:
  # Bloquer le déploiement si :
  fail_on:
    - severity: CRITICAL
      count: 1       # Au moins 1 vulnérabilité critique
    - severity: HIGH
      count: 5       # Plus de 5 vulnérabilités hautes

  # Alerter mais ne pas bloquer si :
  warn_on:
    - severity: MEDIUM
      count: 10

  # Ignorer les vulnérabilités sans fix disponible
  ignore_unfixed: true

  # Timeout du scan
  timeout: 5m
```

Implémentation avec Trivy :

```bash
#!/bin/bash
# scan-and-enforce.sh

IMAGE=$1
CRITICAL=$(trivy image --severity CRITICAL --quiet --format json $IMAGE | jq '.Results[].Vulnerabilities | length')
HIGH=$(trivy image --severity HIGH --quiet --format json $IMAGE | jq '.Results[].Vulnerabilities | length')

if [ "$CRITICAL" -gt 0 ]; then
  echo "❌ ÉCHEC : $CRITICAL vulnérabilités CRITICAL trouvées"
  exit 1
fi

if [ "$HIGH" -gt 5 ]; then
  echo "❌ ÉCHEC : $HIGH vulnérabilités HIGH trouvées (limite : 5)"
  exit 1
fi

echo "✅ Image conforme à la politique de sécurité"
exit 0
```

## 3. Utiliser des Images de Base Sécurisées

**Recommandations par ordre de préférence** :

1. **Distroless** (Google) : images minimales sans shell, package manager
   ```dockerfile
   FROM gcr.io/distroless/python3-debian11
   ```

2. **Alpine** : distribution Linux minimale (~5 MB)
   ```dockerfile
   FROM python:3.11-alpine
   ```

3. **Slim** : variantes Debian allégées
   ```dockerfile
   FROM python:3.11-slim-bookworm
   ```

4. **Chainguard Images** : images ultra-sécurisées avec SBOMs
   ```dockerfile
   FROM cgr.dev/chainguard/python:latest
   ```

**Éviter** :
- Images `latest` (pas de version fixe)
- Images Ubuntu/Debian complètes (trop de packages)
- Images anciennes (Ubuntu 18.04, Debian Stretch)

## 4. Nettoyer les Images

```dockerfile
# ❌ MAUVAIS : Garde les caches et fichiers temporaires
FROM python:3.11-slim
RUN apt-get update && apt-get install -y build-essential
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

# ✅ BON : Nettoie les caches
FROM python:3.11-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
```

## 5. Scanner en Continu

Les vulnérabilités évoluent constamment. Une image sûre aujourd'hui peut devenir vulnérable demain.

**Solution** : Re-scanner périodiquement les images en production

```bash
#!/bin/bash
# cron-scan.sh - À exécuter quotidiennement via cron

# Lister toutes les images en production
IMAGES=$(docker ps --format "{{.Image}}" | sort -u)

for IMAGE in $IMAGES; do
  echo "=== Scanning $IMAGE ==="
  trivy image --severity HIGH,CRITICAL $IMAGE

  if [ $? -ne 0 ]; then
    # Envoyer alerte (email, Slack, etc.)
    curl -X POST https://hooks.slack.com/... \
      -d "{\"text\": \"⚠️ Vulnérabilités trouvées dans $IMAGE\"}"
  fi
done
```

**Cron job** :
```bash
# Ajouter au crontab
0 2 * * * /usr/local/bin/cron-scan.sh >> /var/log/security-scan.log 2>&1
```

---

# Exercices Pratiques

## Exercice 1 : Premier Scan avec Trivy

```bash
# 1. Installer Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# 2. Scanner plusieurs images
trivy image alpine:3.18
trivy image ubuntu:22.04
trivy image python:3.11-alpine
trivy image python:3.11

# 3. Comparer les résultats
# Question : Quelle image a le moins de vulnérabilités ?
```

## Exercice 2 : Détecter et Corriger des Vulnérabilités

```bash
# 1. Créer un Dockerfile vulnérable
cat > Dockerfile <<EOF
FROM python:3.9-slim
RUN pip install flask==1.0.0
COPY app.py .
CMD ["python", "app.py"]
EOF

# 2. Scanner
trivy config Dockerfile
docker build -t myapp:vuln .
trivy image myapp:vuln

# 3. Identifier les vulnérabilités dans Flask 1.0.0

# 4. Corriger en mettant à jour Flask
cat > Dockerfile <<EOF
FROM python:3.11-alpine
RUN pip install flask==3.0.0
COPY app.py .
CMD ["python", "app.py"]
EOF

# 5. Re-scanner
docker build -t myapp:fixed .
trivy image myapp:fixed

# Question : Combien de vulnérabilités ont été corrigées ?
```

## Exercice 3 : Intégration CI/CD

Créez un pipeline GitLab CI qui :
1. Build une image Docker
2. Scanne avec Trivy
3. Bloque le déploiement si des vulnérabilités CRITICAL sont trouvées
4. Génère un rapport en artifact

```yaml
# Votre code ici (.gitlab-ci.yml)
```

---

# Ressources et Documentation

## Outils

- **Trivy** : https://github.com/aquasecurity/trivy
- **Clair** : https://github.com/quay/clair
- **Grype** : https://github.com/anchore/grype
- **Snyk** : https://snyk.io/product/container-vulnerability-management/
- **Docker Scout** : https://docs.docker.com/scout/
- **Harbor** : https://goharbor.io/

## Bases de Données de Vulnérabilités

- **NVD** (National Vulnerability Database) : https://nvd.nist.gov/
- **CVE** : https://cve.mitre.org/
- **Debian Security** : https://www.debian.org/security/
- **Alpine Security** : https://secdb.alpinelinux.org/
- **GitHub Advisory** : https://github.com/advisories

## Bonnes Pratiques

- **OWASP Docker Security** : https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html
- **CIS Docker Benchmark** : https://www.cisecurity.org/benchmark/docker
- **NIST Container Security** : https://csrc.nist.gov/publications/detail/sp/800-190/final

---

# Conclusion

Le scan d'images Docker est **essentiel** pour sécuriser vos déploiements.

**Points clés à retenir** :
1. **Scanner tôt et souvent** : intégrer dans votre workflow dès le développement
2. **Trivy est le meilleur choix** pour la plupart des cas (gratuit, rapide, complet)
3. **Définir des politiques** : ne pas bloquer sur TOUT, mais avoir des seuils raisonnables
4. **Choisir des images de base sécurisées** : Alpine, Slim, Distroless
5. **Re-scanner en continu** : les vulnérabilités évoluent quotidiennement

**La sécurité est un processus continu, pas une configuration ponctuelle !**

---

## Checklist Scan d'Images

- [ ] Trivy installé et à jour
- [ ] Scan automatique dans le pipeline CI/CD
- [ ] Politique de sécurité définie (seuils de blocage)
- [ ] Images de base minimales (Alpine/Slim)
- [ ] Scan des Dockerfiles avant build
- [ ] Scan des dépendances (requirements.txt, package.json, etc.)
- [ ] Détection de secrets activée
- [ ] Re-scan périodique des images en production
- [ ] Alertes configurées (Slack, email, etc.)
- [ ] Documentation des exceptions (vulnérabilités acceptées)
