# Wazuh 4.14.1 pour Runtipi

Déploiement de Wazuh, la plateforme open-source de sécurité unifiée (XDR et SIEM), sur Runtipi.

**Version:** Wazuh 4.14.1
**Plateforme:** Runtipi 4.6.5
**Status:** ✅ Stable

⚠️ **IMPORTANT SÉCURITÉ:** Les mots de passe par défaut DOIVENT être changés avant la mise en production. Voir la section "Configuration des Identifiants" ci-dessous.

---

## 📖 Qu'est-ce que Wazuh ?

**Wazuh** est une plateforme de sécurité open-source qui fournit:

- **SIEM (Security Information and Event Management)** - Centralisation et analyse des logs de sécurité
- **XDR (Extended Detection and Response)** - Détection et réponse aux menaces
- **Conformité** - Vérification de conformité (PCI DSS, HIPAA, GDPR, etc.)
- **Détection des vulnérabilités** - Scan et gestion des vulnérabilités
- **Détection d'intrusion** - Monitoring temps réel des fichiers système
- **Réponse aux incidents** - Automatisation des réponses de sécurité

### Ressources Officielles

- **Site Web:** https://wazuh.com/
- **Documentation:** https://documentation.wazuh.com/current/
- **GitHub Wazuh:** https://github.com/wazuh/wazuh
- **Wazuh Docker:** https://github.com/wazuh/wazuh-docker
- **Community:** https://groups.google.com/g/wazuh

---

## 🏗️ Architecture

Ce projet déploie une stack Wazuh complète sur Runtipi avec 5 conteneurs Docker:

```
┌──────────────────────────────────────────────────────────────┐
│                    Votre Infrastructure                      │
│                                                              │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐  │
│   │ Serveur  │   │ Serveur  │   │ Desktop  │   │  Cloud   │  │
│   │  Linux   │   │ Windows  │   │  MacOS   │   │ Instance │  │
│   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘  │
│        │              │              │              │        │
│        │         Wazuh Agents (1514 / 1515)         │        │
│        └──────────────┬──────────────┬──────────────┘        │
└───────────────────────┼──────────────┼───────────────────────┘
                        ▼              │
┌───────────────────────┼──────────────┼───────────────────────┐
│                   Stack Wazuh (Runtipi)                      │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │     Wazuh Manager (Ports 1514 / 1515 / 55000)          │  │
│  │  - Collecte des événements                             │  │
│  │  - Analyse & corrélation                               │  │
│  │  - Règles de détection                                 │  │
│  │  - API REST                                            │  │
│  └────────────────────┬───────────────────────────────────┘  │
│                       │ (Filebeat)                           │
│                       ▼                                      │
│  ┌────────────────────────────────────────────────────────┐  │
│  │     Wazuh Indexer (OpenSearch - Port 9200)             │  │
│  │  - Stockage & indexation                               │  │
│  │  - Recherches rapides                                  │  │
│  │  - Statistiques / agrégations                          │  │
│  └────────────────────┬───────────────────────────────────┘  │
│                       │                                      │
│                       ▼                                      │
│  ┌────────────────────────────────────────────────────────┐  │
│  │     Wazuh Dashboard (Port 5601) - Interface Web        │  │
│  │  - Visualisation des alertes                           │  │
│  │  - Tableaux de bord                                    │  │
│  │  - Gestion des agents                                  │  │
│  │  - Configuration / Admin                               │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  Services additionnels :                                     │
│   • wazuh-certs : génération certificats SSL/TLS             │
│   • wazuh-indexer-init : initialisation sécurité OpenSearch  │
└──────────────────────────────────────────────────────────────┘
                        │
                        ▼
              Accès via navigateur
              https://VOTRE_IP:5601
```

### Composants

1. **Wazuh Manager** - Analyse les événements de sécurité collectés par les agents
2. **Wazuh Indexer** - Base de données OpenSearch pour stocker et indexer les événements
3. **Wazuh Dashboard** - Interface web pour visualiser et gérer la sécurité
4. **Wazuh Certs Generator** - Génère les certificats SSL/TLS pour les communications sécurisées
5. **Wazuh Indexer Init** - Initialise la configuration de sécurité d'OpenSearch

---

## 🚀 Installation

### Prérequis

- **Runtipi 4.6.5+** installé et fonctionnel
- **4GB RAM minimum** (8GB recommandés)
- **20GB espace disque** disponible
- **Accès root** au serveur Runtipi

**⚠️ IMPORTANT - Configuration système requise:**

Avant l'installation, exécutez cette commande sur votre serveur:

```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

Cette configuration est **obligatoire** pour le bon fonctionnement d'OpenSearch (le moteur d'indexation de Wazuh). Sans elle, le conteneur `wazuh-indexer` ne démarrera pas correctement.

### Étape 1: Installer via Runtipi

1. **Ouvrir l'interface Runtipi** dans votre navigateur
2. **Aller dans "App Store"**
3. **Rechercher "Wazuh"**
4. **Cliquer sur "Install"**
5. **⚠️ IMPORTANT : Attendre 5 minutes complètes.**

> [!WARNING]
> Le déploiement de Wazuh est lourd. Le service `wazuh-dashboard` peut redémarrer plusieurs fois pendant les 5 premières minutes le temps que l'indexeur soit prêt.
> Si vous voyez le statut "Rebooting" ou "Starting", **ne touchez à rien** et patientez. C'est le comportement normal du script de surveillance (Watchdog).

C'est tout! L'installation est **100% automatique** ✅

### Étape 2: Vérifier l'Installation

Connectez-vous en SSH au serveur Runtipi:

```bash
# Vérifier que tous les services sont démarrés et healthy
docker ps -a | grep wazuh
```

**Résultat attendu:**

Vous devriez voir 5 conteneurs:
- ✅ **wazuh-certs** - Up X min (healthy)
- ✅ **wazuh-indexer** - Up X min (healthy)
- ✅ **wazuh-indexer-init** - Up X min (healthy)
- ✅ **wazuh-manager** - Up X min (healthy)
- ✅ **wazuh-dashboard** - Up X min (healthy)

**Note:** Le conteneur `wazuh-indexer-init` reste running avec un health check (adaptation Runtipi). Il initialise la sécurité OpenSearch au démarrage, crée un fichier marker `.init-complete`, puis reste en veille. Le statut "healthy" confirme que l'initialisation est terminée.

### Étape 3: Accéder au Dashboard

1. **Ouvrir votre navigateur**
2. **Aller à:** `https://VOTRE_IP_SERVEUR:5601`
3. **Se connecter avec les credentials par défaut**

## 🔐 Configuration des Identifiants

### Variables d'Environnement

Lors de l'installation via Runtipi, vous pouvez configurer les identifiants dans l'interface GUI:

| Variable             | Description                                    | Valeur par défaut    |
|----------------------|------------------------------------------------|----------------------|
| `INDEXER_USERNAME`   | Nom d'utilisateur admin de l'indexer          | `admin`              |
| `INDEXER_PASSWORD`   | Mot de passe admin de l'indexer               | `admin`     |
| `DASHBOARD_USERNAME` | Utilisateur interne dashboard→indexer         | `kibanaserver`       |
| `DASHBOARD_PASSWORD` | Mot de passe interne dashboard→indexer        | `kibanaserver`       |
| `API_PASSWORD`       | Mot de passe de l'API REST (user: wazuh-wui)  | `MyS3cr37P450r.*-`   |

### Credentials par Défaut

Si vous utilisez les valeurs par défaut:

| Service       | Username       | Password             | Usage                          |
|---------------|----------------|----------------------|--------------------------------|
| Dashboard     | `admin`        | `admin`     | Interface web principale       |
| API           | `wazuh-wui`    | `MyS3cr37P450r.*-`   | API REST du manager            |
| Kibanaserver  | `kibanaserver` | `kibanaserver`       | Connexion dashboard→indexer    |

**⚠️ IMPORTANT:** Pour une utilisation en production, modifiez ces mots de passe **avant** l'installation via l'interface Runtipi!

### Étape 4: Changer les Mots de Passe (Recommandé pour Production)

#### Méthode 1: Avant l'Installation (Recommandé)

La manière la plus sûre est de définir des mots de passe forts **avant** l'installation via l'interface Runtipi:

1. Dans Runtipi, avant de cliquer sur "Install"
2. Configurer les variables d'environnement:
   - `INDEXER_PASSWORD` - Mot de passe admin de l'indexer (au lieu de "admin")
   - `DASHBOARD_PASSWORD` - Mot de passe dashboard→indexer (au lieu de "kibanaserver")
   - `API_PASSWORD` - Mot de passe API REST (au lieu de "MyS3cr37P450r.*-")
3. Utiliser des mots de passe forts (minimum 12 caractères, majuscules, minuscules, chiffres, symboles)
4. Procéder à l'installation

#### Méthode 2: Après l'Installation

Si vous avez déjà installé Wazuh avec les mots de passe par défaut, vous devez les changer:

**A. Changer le mot de passe admin du dashboard:**

1. Se connecter au dashboard: `https://VOTRE_IP:5601`
2. Login: `admin` / `admin`
3. Cliquer sur le menu **☰** (hamburger) en haut à gauche
4. Aller dans **Security → Internal users**
5. Cliquer sur l'utilisateur **admin**
6. Cliquer sur **Edit**
7. Entrer un **nouveau mot de passe fort**
8. Cliquer sur **Save**

**B. Mettre à jour les variables d'environnement dans Runtipi:**

1. Dans l'interface Runtipi, aller dans l'application Wazuh
2. Cliquer sur "Settings" ou "Configuration"
3. Mettre à jour `INDEXER_PASSWORD` avec le nouveau mot de passe
4. Redémarrer l'application pour appliquer les changements

**C. Changer les autres utilisateurs internes (optionnel mais recommandé):**

Dans le dashboard, sous **Security → Internal users**, vous pouvez également modifier:
- `kibanaserver` - Utilisateur technique dashboard→indexer
- `wazuh-wui` - Utilisateur API REST
- `logstash` - Utilisateur Filebeat→Indexer (si utilisé)

**Note:** Après modification des mots de passe, assurez-vous de mettre à jour les variables d'environnement correspondantes dans Runtipi et redémarrer les conteneurs pour synchroniser les configurations.

---

## 🔍 Validation Post-Installation

### Diagnostic Automatique

Un script de diagnostic complet est fourni pour vérifier la santé de votre installation:

```bash
# Se connecter en SSH au serveur
ssh user@VOTRE_SERVEUR

# Exécuter le diagnostic
bash /opt/runtipi/app-data/*/wazuh-runtipi/data/debug/wazuh-health-check.sh
```

**Ce script vérifie automatiquement:**
- ✅ Santé de tous les services (healthy/unhealthy)
- ✅ Utilisation disque (~7-8GB attendu pour installation fraîche)
- ✅ Présence des 8 fichiers de sécurité OpenSearch
- ✅ Connectivité réseau entre conteneurs
- ✅ Configuration du dashboard et manager
- ✅ Variables d'environnement SSL Filebeat (méthode officielle)
- ✅ Initialisation de la sécurité OpenSearch

---

## 📱 Déployer des Agents Wazuh

Une fois Wazuh installé, vous devez déployer des agents sur vos serveurs/postes à surveiller.

### Architecture Agent ↔ Manager

```
Serveur/Desktop à surveiller          Serveur Wazuh (Runtipi)
┌─────────────────────┐               ┌────────────────────┐
│                     │               │                    │
│   Wazuh Agent  ─────┼──────────────►│   Wazuh Manager    │
│   (Service)         │   Port 1514   │   (Collecte)       │
│                     │   1515        │                    │
│   - Logs système    │               │   - Analyse        │
│   - Fichiers        │               │   - Corrélation    │
│   - Processus       │               │   - Alertes        │
│   - Réseau          │               │                    │
└─────────────────────┘               └────────────────────┘
```

### Agent Linux (Debian/Ubuntu)

```bash
# 1. Télécharger l'agent
wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.14.1-1_amd64.deb

# 2. Installer
sudo dpkg -i wazuh-agent_4.14.1-1_amd64.deb

# 3. Configurer l'adresse du manager (remplacer VOTRE_IP par l'IP de votre serveur Runtipi)
sudo sed -i "s/<address>MANAGER_IP<\/address>/<address>VOTRE_IP<\/address>/" /var/ossec/etc/ossec.conf

# 4. Démarrer l'agent
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# 5. Vérifier le statut
sudo systemctl status wazuh-agent
```

### Agent Windows

1. **Télécharger** l'installeur: https://packages.wazuh.com/4.x/windows/wazuh-agent-4.14.1-1.msi

2. **Ouvrir PowerShell en tant qu'Administrateur** et exécuter:

```powershell
# Installer (remplacer VOTRE_IP par l'IP de votre serveur Runtipi)
msiexec /i wazuh-agent-4.14.1-1.msi /q WAZUH_MANAGER="VOTRE_IP"

# Démarrer le service
NET START WazuhSvc

# Vérifier le statut
Get-Service WazuhSvc
```

### Agent MacOS

```bash
# 1. Télécharger l'agent
curl -O https://packages.wazuh.com/4.x/macos/wazuh-agent-4.14.1-1.pkg

# 2. Installer
sudo installer -pkg wazuh-agent-4.14.1-1.pkg -target /

# 3. Configurer (remplacer VOTRE_IP)
sudo sed -i '' "s/<address>MANAGER_IP<\/address>/<address>VOTRE_IP<\/address>/" /Library/Ossec/etc/ossec.conf

# 4. Démarrer
sudo /Library/Ossec/bin/wazuh-control start
```

### Vérifier les Agents dans le Dashboard

1. **Se connecter au dashboard** Wazuh
2. **Cliquer sur** ☰ → **Agents**
3. **Vérifier** que vos agents apparaissent avec le statut **"Active"** (après 1-2 minutes)

Chaque agent doit montrer:
- ✅ **Status:** Active (point vert)
- ✅ **IP Address:** L'IP de la machine
- ✅ **Version:** 4.14.1
- ✅ **Last keep alive:** < 1 minute

---

## 🎯 Utilisation du Dashboard

### Sections Principales

1. **Overview / Vue d'ensemble**
   - Résumé des alertes de sécurité
   - Événements récents
   - Top agents
   - Statistiques globales

2. **Agents**
   - Liste de tous les agents
   - Statut (actif/déconnecté)
   - Détails par agent
   - Déploiement de nouveaux agents

3. **Security Events / Événements**
   - Alertes de sécurité en temps réel
   - Filtrage par sévérité, agent, règle
   - Timeline des événements
   - Détails complets des alertes

4. **Compliance / Conformité**
   - PCI DSS
   - GDPR
   - HIPAA
   - NIST 800-53
   - CIS benchmarks

5. **Vulnerability Detection**
   - CVE détectées sur vos systèmes
   - Score CVSS
   - Packages vulnérables
   - Recommandations de mise à jour

6. **File Integrity Monitoring (FIM)**
   - Changements de fichiers système
   - Modifications non autorisées
   - Ajouts/suppressions de fichiers

### Exemple: Voir les Alertes de Sécurité

1. **Menu** ☰ → **Security Events**
2. **Filtrer par sévérité:** Sélectionner "High" ou "Critical"
3. **Cliquer sur une alerte** pour voir les détails complets:
   - Description de la menace
   - Agent source
   - Fichiers/processus impliqués
   - Actions recommandées
   - Contexte MITRE ATT&CK

---

## 🔧 Configuration Avancée

### Ports Utilisés

| Port | Protocole | Service | Usage |
|------|-----------|---------|-------|
| **5601** | HTTPS | Dashboard | Interface web (publique) |
| **9200** | HTTPS | Indexer | API OpenSearch (interne) |
| **1514** | TCP | Manager | Communication avec les agents (publique) |
| **1515** | TCP | Manager | Enrollment des agents (publique) |
| **514** | UDP | Manager | Collection Syslog |
| **55000** | HTTPS | Manager | API REST (interne) |

**Note:** Seul les ports **5601**, **1514**, **1515** (Dashboard et les agents) sont à exposer publiquement. Les autres ports sont utilisés pour la communication interne entre les composants Wazuh et les agents.

### Limites de Ressources

Configuration par défaut des conteneurs:

| Conteneur | RAM Min | RAM Max | CPU |
|-----------|---------|---------|-----|
| **Indexer** | 1GB | 4GB | 2 cores |
| **Manager** | 512MB | 2GB | 1 core |
| **Dashboard** | 512MB | 1GB | 1 core |

Pour modifier, éditer le fichier `docker-compose.json` section `deploy.resources.limits`.

### Espace Disque

Utilisation disque normale: **~7-8GB** pour une installation fraîche

L'espace augmente avec:
- Nombre d'agents connectés
- Volume d'événements générés
- Période de rétention des logs (7 jours par défaut)

Pour surveiller:
```bash
# Vérifier la taille totale (incluant data/)
du -sh /opt/runtipi/app-data/*/wazuh-runtipi

# Vérifier uniquement les données persistantes
du -sh /opt/runtipi/app-data/*/wazuh-runtipi/data
```

### Personnalisation du Manager

Fichier de configuration principal: `/var/ossec/etc/ossec.conf`

Exemples de personnalisation:
- Règles de détection personnalisées
- Alertes par email
- Intégrations (Slack, PagerDuty, etc.)
- Configuration FIM (File Integrity Monitoring)
- Politique de rétention des logs

Voir la documentation officielle: https://documentation.wazuh.com/current/user-manual/reference/ossec-conf/

---

## 🔄 Mises à Jour

Runtipi gère automatiquement les mises à jour de l'application Wazuh.

### Processus de Mise à Jour

1. **Runtipi détecte** une nouvelle version dans son repository
2. **Télécharge** le nouveau `docker-compose.json`
3. **Redémarre** les conteneurs avec la nouvelle configuration
4. **Préserve** vos données et configurations

**Aucune action manuelle requise!** ✅

### Vérification Post-Mise à Jour

```bash
# Attendre 2-3 minutes après la mise à jour

# Vérifier que tous les services sont healthy
docker ps -a | grep wazuh

# Diagnostic complet
bash /opt/runtipi/app-data/*/wazuh-runtipi/data/debug/wazuh-health-check.sh
```

---

## 🆘 Dépannage

### Le Dashboard n'est pas Accessible

**Symptôme:** Impossible d'accéder à `https://VOTRE_IP:5601`

**Solutions:**
```bash
# 1. Vérifier que le conteneur dashboard est running
docker ps | grep dashboard

# 2. Vérifier les logs du dashboard
docker logs wazuh-runtipi_*-wazuh-dashboard-1

# 3. Vérifier que le port 5601 est bien exposé
docker port wazuh-runtipi_*-wazuh-dashboard-1

# 4. Tester depuis le serveur
curl -I http://localhost:5601 || curl -I https://localhost:5601
```

### Un Service est "Unhealthy"

**Symptôme:** `docker ps` montre un conteneur avec `(unhealthy)`

**Solutions:**
```bash
# 1. Voir les logs du service problématique
docker logs wazuh-runtipi_*-wazuh-SERVICE-1

# Exemples:
docker logs wazuh-runtipi_*-wazuh-indexer-1
docker logs wazuh-runtipi_*-wazuh-manager-1
docker logs wazuh-runtipi_*-wazuh-dashboard-1

# 2. Redémarrer le service
docker restart wazuh-runtipi_*-wazuh-SERVICE-1

# 3. Si le problème persiste, redémarrer toute la stack
docker restart $(docker ps -q --filter "name=wazuh-runtipi")
```

### Les Agents n'Apparaissent Pas

**Symptôme:** Agents installés mais invisibles dans le dashboard

**Vérifications:**

1. **Sur la machine agent:**
```bash
# Linux/MacOS
sudo /var/ossec/bin/agent-auth -m VOTRE_IP
sudo systemctl restart wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log

# Windows (PowerShell Admin)
Restart-Service WazuhSvc
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 20 -Wait
```

2. **Sur le serveur Wazuh:**
```bash
# Vérifier les logs du manager
docker logs wazuh-runtipi_*-wazuh-manager-1 | grep -i "agent"

# Vérifier que les ports 1514/1515 sont bien ouverts
docker port wazuh-runtipi_*-wazuh-manager-1
```

### Utilisation Disque Anormalement Élevée

**Symptôme:** Plus de 20GB utilisés

**Solutions:**
```bash
# 1. Vérifier la taille actuelle
du -sh /opt/runtipi/app-data/*/wazuh-runtipi/data

# 2. Vérifier la taille des indices OpenSearch
docker exec wazuh-runtipi_*-wazuh-indexer-1 curl -k -u admin:admin https://localhost:9200/_cat/indices?v

# 3. Réduire la période de rétention (connexion dashboard)
# Settings → Indices → wazuh-alerts-* → Modifier la rétention
```

### "Index Pattern Warning" dans le health-check

**Symptôme:** Message `No template found for [wazuh-alerts-*]`

**Explication:** C'est **normal** pour une installation fraîche sans agents!

Les indices `wazuh-alerts-*` sont créés automatiquement quand:
1. Des agents Wazuh sont connectés
2. Ces agents génèrent des événements/alertes
3. Le manager envoie les données à l'indexer

**Solution:** Déployez votre premier agent Wazuh. L'alerte disparaîtra automatiquement.


---

## 📚 Documentation et Ressources

### Documentation Wazuh Officielle

- **Getting Started:** https://documentation.wazuh.com/current/getting-started/
- **User Manual:** https://documentation.wazuh.com/current/user-manual/
- **Installation Guide:** https://documentation.wazuh.com/current/installation-guide/
- **API Reference:** https://documentation.wazuh.com/current/user-manual/api/
- **Ruleset:** https://documentation.wazuh.com/current/user-manual/ruleset/

### Projets Source

- **Wazuh (Core):** https://github.com/wazuh/wazuh
- **Wazuh Docker:** https://github.com/wazuh/wazuh-docker
- **Wazuh Kubernetes:** https://github.com/wazuh/wazuh-kubernetes
- **Wazuh Documentation:** https://github.com/wazuh/wazuh-documentation

### Communauté et Support

- **Google Group:** https://groups.google.com/g/wazuh
- **Slack Community:** https://wazuh.com/community/join-us-on-slack/
- **GitHub Issues:** https://github.com/wazuh/wazuh/issues

### Formations et Certifications

- **Wazuh Free Training:** https://wazuh.com/platform/siem/
- **YouTube Channel:** https://www.youtube.com/@wazuh

---

## 📁 Structure du Projet

```
wazuh-runtipi/
├── docker-compose.json                ← Configuration Docker Compose
├── config.json                        ← Configuration Runtipi
│
├── data/
│   ├── config/
│   │   └── certs.yml                  ← Configuration certificats SSL
│   │
│   ├── scripts/                       ← Scripts d'initialisation
│   │   ├── init-certs.sh              │  Génération certificats SSL
│   │   ├── init-indexer-init.sh       │  Initialisation sécurité OpenSearch
│   │   ├── init-manager.sh            │  Configuration manager + Filebeat
│   │   └── init-dashboard.sh          │  Configuration dashboard + Watchdog
│   │
│   ├── debug/
│   │   └── wazuh-health-check.sh      ← Script de diagnostic complet
│   │
│   ├── indexer-security/              ← Configuration sécurité OpenSearch
│   │   └── .gitkeep                   │  (Dossier vide - tous les fichiers
│   │                                  │   sont copiés depuis le Docker au
│   │                                  │   premier démarrage)
│   │
│   │   # Les 8 fichiers suivants sont automatiquement copiés
│   │   # depuis l'image wazuh-indexer lors du premier démarrage:
│   │   # - config.yml
│   │   # - roles.yml
│   │   # - roles_mapping.yml
│   │   # - internal_users.yml
│   │   # - action_groups.yml
│   │   # - tenants.yml
│   │   # - nodes_dn.yml
│   │   # - whitelist.yml
│
└── metadata/
    ├── description.md                 ← Documentation complète (ce fichier)
    └── logo.jpg                       ← Logo de l'application
```

**Notes importantes:**

- **Scripts d'initialisation** dans `data/scripts/` sont montés dans les conteneurs et exécutés au démarrage
- **Architecture simple** : Un script init par conteneur (init-certs.sh, init-indexer-init.sh, init-manager.sh, init-dashboard.sh)
- **Configuration persistante** via symlinks vers les dossiers personnalisés
- **Filebeat** : Configuration automatique via variables d'environnement officielles (FILEBEAT_SSL_VERIFICATION_MODE, SSL_CERTIFICATE_AUTHORITIES, SSL_CERTIFICATE, SSL_KEY)
- **Dashboard Watchdog** surveille le démarrage et gère automatiquement les blocages de migration `.kibana_1`
- **Sécurité OpenSearch** : Les 8 fichiers dans `indexer-security/` sont automatiquement copiés au premier démarrage et **préservés** lors des mises à jour

---

## 🔧 Détails Techniques et Bonnes Pratiques

### Configuration Filebeat SSL (Méthode Officielle)

Cette implémentation utilise la **méthode officielle Wazuh** pour configurer Filebeat avec SSL, documentée sur [Docker Hub - Wazuh Manager](https://hub.docker.com/r/wazuh/wazuh-manager).

**Variables d'environnement utilisées:**
```bash
FILEBEAT_SSL_VERIFICATION_MODE=full
SSL_CERTIFICATE_AUTHORITIES=/var/ossec/etc/certs/root-ca.pem
SSL_CERTIFICATE=/var/ossec/etc/certs/server.pem
SSL_KEY=/var/ossec/etc/certs/server-key.pem
```

Le script officiel `cont-init.d/1-config-filebeat` de l'image Wazuh détecte automatiquement ces variables et génère la configuration Filebeat correcte. Cette approche est **préférable** à la création manuelle de `filebeat.yml` car :
- ✅ Respecte le workflow d'initialisation Wazuh natif
- ✅ Évite les conflits avec les scripts internes
- ✅ Simplifie la maintenance (moins de code personnalisé)
- ✅ Garantit la compatibilité avec les futures versions

### Initialisation et Boucles Logiques

Tous les scripts d'initialisation utilisent des **boucles logiques basées sur des conditions réelles** plutôt que des délais fixes, permettant une adaptation automatique à la vitesse de chaque machine :

**init-indexer-init.sh** :
```bash
# Attend la disponibilité réelle de l'API indexer
until curl -ks https://wazuh.indexer:9200; do
    sleep 5
done
```

**init-manager.sh** :
```bash
# Vérifie existence ET contenu du fichier ossec.conf
while [ $ELAPSED -lt $TIMEOUT ]; do
    if [ -f "$OSSEC_DEFAULT" ] && [ -s "$OSSEC_DEFAULT" ]; then
        break
    fi
    sleep 2
done
```

**init-dashboard.sh** :
```bash
# Vérifie l'API dashboard toutes les 10s (au lieu de 60s fixes)
# Détecte le temps réel de blocage migration avant intervention
while [ $ELAPSED -lt $TIMEOUT ]; do
    API_STATUS=$(curl -sk https://localhost:5601/api/status)
    if [[ "$API_STATUS" == "200" ]]; then
        break
    fi
    sleep 10
done
```

Cette approche garantit :
- 🚀 **Démarrage rapide** sur machines performantes
- ⏱️ **Patience suffisante** sur machines plus lentes
- 📊 **Logs précis** avec temps réels écoulés

### Gestion de la Migration Dashboard

Le watchdog du dashboard détecte et corrige automatiquement le problème connu de blocage de migration `.kibana_1` :

1. **Détection** : Vérifie la présence de l'index `.kibana_1` toutes les 10 secondes
2. **Patience** : Attend 180 secondes (3 minutes) avant d'intervenir
3. **Intervention** : Supprime l'index bloqué si nécessaire
4. **Restart** : Laisse Runtipi redémarrer automatiquement le dashboard

Cette logique évite les interventions prématurées tout en garantissant un démarrage réussi.

---

## 📄 Licence et Crédits

### Wazuh

- **Licence:** GPL v2
- **Copyright:** Wazuh, Inc.
- **Site Web:** https://wazuh.com/

### Ce Projet

- **Configuration Runtipi:** synode-it
- **Date:** 2025-12-27
- **Version:** 4.14.1

Ce projet est une configuration Docker Compose de Wazuh optimisée pour Runtipi. Il utilise les images Docker officielles de Wazuh et suit leurs bonnes pratiques de déploiement.

---

**🎉 Votre plateforme de sécurité Wazuh est maintenant prête à protéger votre infrastructure!**

Pour toute question, consultez la documentation officielle Wazuh ou rejoignez la communauté.
