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
- **Ressources minimales:**
  - **CPU:** 2 cores minimum (4 cores recommandés)
  - **RAM:** 4GB minimum (8GB recommandés pour production)
  - **Disque:** 20GB minimum (60GB+ recommandé pour production avec agents)
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

**⚠️ AVERTISSEMENT:** Ces mots de passe par défaut sont publics. Vous **DEVEZ** les changer immédiatement après l'installation en suivant la procédure officielle ci-dessous.

### Étape 4: Changer les Mots de Passe (OBLIGATOIRE pour Production)

⚠️ **AVERTISSEMENT DE SÉCURITÉ:** Les mots de passe par défaut sont publics et constituent une vulnérabilité critique. Vous **DEVEZ** les changer après l'installation.

⚠️ **Source officielle:** [Wazuh Documentation - Changing Default Passwords](https://documentation.wazuh.com/current/deployment-options/docker/changing-default-password.html)

**Note importante pour Runtipi:** La configuration des mots de passe via les variables d'environnement Runtipi AVANT installation ne suffit PAS. Vous devez impérativement suivre la procédure officielle ci-dessous APRÈS l'installation pour sécuriser votre déploiement.

#### Procédure Officielle de Changement des Mots de Passe

**A. Changer le mot de passe des utilisateurs Indexer (admin/kibanaserver):**

1. **Se déconnecter du dashboard Wazuh** pour éviter les conflits de session

2. **Générer le hash du nouveau mot de passe:**
   ```bash
   docker run --rm -ti wazuh/wazuh-indexer:4.14.1 bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh
   ```

   **Exemple d'interaction:**
   ```
   [Password:]
   $2y$12$aBcDeFgHiJkLmNoPqRsTuVwXyZ123456789abcdefghijklmnopqr
   ```

   ⚠️ **IMPORTANT:** Copiez le hash complet (commence par `$2y$12$...`). Vous en aurez besoin à l'étape suivante.

3. **Éditer le fichier internal_users.yml:**

   Le wildcard `*` fonctionne directement avec nano:
   ```bash
   nano /opt/runtipi/app-data/*/wazuh-runtipi/data/indexer-security/internal_users.yml
   ```

   **Pour changer le mot de passe admin:**
   - Trouvez la section `admin:`
   - Remplacez le hash dans la ligne `hash:` par le nouveau hash généré
   - Exemple:
   ```yaml
   admin:
     hash: "$2y$12$VOTRE_NOUVEAU_HASH_ICI"
     reserved: true
     backend_roles:
     - "admin"
     description: "Demo admin user"
   ```

   **Pour changer le mot de passe kibanaserver:**
   - Trouvez la section `kibanaserver:`
   - Remplacez le hash de la même manière

   Sauvegardez: `Ctrl+X`, puis `y`, puis `Entrée`

5. **Redémarrer l'application via l'interface Runtipi:**
   - Allez dans Runtipi → Apps → Wazuh
   - Cliquez sur "Arreter"
   - Attendez quelques secondes
   - Cliquez sur "Démarrer"

6. **Appliquer les changements avec securityadmin.sh:**
   ```bash
   # Se connecter au conteneur wazuh-indexer
   docker exec -it wazuh-runtipi_*-wazuh-indexer-1 bash
   ```

   **Une fois dans le conteneur:**
   ```bash
   # Configurer les variables d'environnement
   export INSTALLATION_DIR=/usr/share/wazuh-indexer
   export JAVA_HOME=/usr/share/wazuh-indexer/jdk

   # Exécuter securityadmin.sh
   bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
     -cd /usr/share/wazuh-indexer/opensearch-security/ \
     -cacert /usr/share/wazuh-indexer/config/certs/root-ca.pem \
     -cert /usr/share/wazuh-indexer/config/certs/admin.pem \
     -key /usr/share/wazuh-indexer/config/certs/admin-key.pem \
     -p 9200 -nhnv -icl
   ```

   **Résultat attendu:**
   ```
   Will update '_all' config types
   SUCC: Configuration for 'config' created or updated
   SUCC: Configuration for 'roles' created or updated
   SUCC: Configuration for 'rolesmapping' created or updated
   SUCC: Configuration for 'internalusers' created or updated
   ...
   Done with success
   ```

   Quittez le conteneur: `exit`

7. **Mettre à jour les variables d'environnement Runtipi:**
   - Allez dans Runtipi → Apps → Wazuh → Paramètres
   - Modifiez `INDEXER_USERNAME` et `INDEXER_PASSWORD` avec vos nouveaux identifiants
   - Modifiez aussi `DASHBOARD_USERNAME` et `DASHBOARD_PASSWORD` si vous avez changé kibanaserver
   - Cliquez sur "Mettre à jour" puis "Redémarrer" l'application

8. **Tester les nouveaux mots de passe:**

   **Test admin (Dashboard - interface web):**
   ```bash
   # Ouvrir dans le navigateur
   https://VOTRE_IP:5601
   # Connectez-vous avec: admin / VOTRE_NOUVEAU_MOT_DE_PASSE
   ```
   ✅ Succès si vous pouvez vous connecter au dashboard

   **Test admin (API OpenSearch - depuis le conteneur):**
   ```bash
   # Le port 9200 n'est PAS exposé à l'hôte (sécurité)
   # Il faut tester depuis un conteneur Wazuh
   docker exec -it wazuh-runtipi_*-wazuh-indexer-1 bash -c \
     "curl -ks https://wazuh.indexer:9200/_cluster/health?pretty -u admin:VOTRE_NOUVEAU_MOT_DE_PASSE"
   ```
   ✅ Succès si vous voyez: `"cluster_name" : "wazuh-cluster"`

   **Test kibanaserver:**
   ```bash
   docker exec -it wazuh-runtipi_*-wazuh-dashboard-1 bash -c \
     "curl -ks https://wazuh.indexer:9200 -u kibanaserver:VOTRE_NOUVEAU_MOT_DE_PASSE"
   ```
   ✅ Succès si vous voyez: `"name" : "wazuh.indexer"`

   **⚠️ Test de sécurité (vérifier que les anciens mots de passe ne fonctionnent PLUS):**
   ```bash
   docker exec -it wazuh-runtipi_*-wazuh-indexer-1 bash -c \
     "curl -ks https://wazuh.indexer:9200 -u admin:admin"
   ```
   ✅ Succès si vous voyez: `"type":"security_exception","reason":"Unauthorized"`

**B. Changer le mot de passe de l'API Wazuh (wazuh-wui):**

**⚠️ Source officielle:** [Wazuh Documentation - Changing API Password](https://documentation.wazuh.com/current/deployment-options/docker/changing-default-password.html)

**⚠️ Exigences du mot de passe:** 8-64 caractères avec majuscules, minuscules, chiffres ET symboles

1. **Choisir un nouveau mot de passe fort:**
   - Exemple: `MyN3wP@ssw0rd!2024`
   - Doit respecter les critères ci-dessus

2. **Mettre à jour le fichier wazuh.yml dans le conteneur dashboard:**

   **Méthode recommandée - Utiliser sed (une seule commande):**
   ```bash
   # Remplacer l'ancien mot de passe par le nouveau dans wazuh.yml
   docker exec -it wazuh-runtipi_*-wazuh-dashboard-1 bash -c \
     "sed -i 's|password: MyS3cr37P450r\.\*-|password: VOTRE_NOUVEAU_MOT_DE_PASSE|g' \
     /usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml"
   ```

   **⚠️ IMPORTANT:** Remplacez `VOTRE_NOUVEAU_MOT_DE_PASSE` par votre mot de passe réel (sans guillemets)

   **Vérifier que le changement a été effectué:**
   ```bash
   docker exec -it wazuh-runtipi_*-wazuh-dashboard-1 bash -c \
     "grep 'password:' /usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml"
   ```

   Vous devriez voir votre nouveau mot de passe dans la sortie.

   **Alternative - Méthode manuelle (si sed ne fonctionne pas):**
   ```bash
   # Se connecter au conteneur dashboard
   docker exec -it wazuh-runtipi_*-wazuh-dashboard-1 bash

   # Afficher le fichier pour voir son contenu
   cat /usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml

   # Utiliser sed directement dans le conteneur (sans guillemets)
   sed -i 's|password: MyS3cr37P450r\.\*-|password: VOTRE_NOUVEAU_MOT_DE_PASSE|g' \
     /usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml

   # Vérifier le changement
   grep 'password:' /usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml

   # Quitter le conteneur
   exit
   ```

3. **Mettre à jour la variable d'environnement dans Runtipi:**
   - Allez dans Runtipi → Apps → Wazuh → Paramètres
   - Trouvez `API_PASSWORD`
   - Remplacez `MyS3cr37P450r.*-` par votre nouveau mot de passe
   - Cliquez sur "Mettre à jour"

4. **Redémarrer l'application:**
   - Cliquez sur "Arreter"
   - Attendez quelques secondes
   - Cliquez sur "Démarrer"

5. **Vérifier que le changement est effectif:**
   ```bash
   # Tester l'API avec le nouveau mot de passe
   curl -k -u wazuh-wui:VOTRE_NOUVEAU_MOT_DE_PASSE https://VOTRE_IP:55000/security/user/authenticate
   ```

   **Résultat attendu:**
   ```json
   {
     "data": {
       "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
     }
   }
   ```

   ✅ Si vous obtenez un token, le changement est réussi!

**⚠️ NOTE IMPORTANTE:** Le fichier `wazuh.yml` est stocké dans `/usr/share/wazuh-dashboard/data/` qui n'est PAS un volume persistant. Cela signifie que si vous **supprimez complètement l'application** (pas juste un redémarrage), vous devrez refaire cette modification. Pour un simple redémarrage ou mise à jour, le fichier est préservé.

---

**⚠️ RÉCAPITULATIF IMPORTANT:**

Pour les mots de passe **Indexer (admin/kibanaserver):**
- Il n'existe **aucun moyen** de contourner la procédure `hash.sh` + `securityadmin.sh`
- Même si vous définissez des mots de passe dans le formulaire Runtipi avant l'installation, vous devrez **obligatoirement** exécuter cette procédure
- C'est la **seule méthode officielle** supportée par Wazuh pour OpenSearch

Pour le mot de passe **API Wazuh (wazuh-wui):**
- La modification via variables d'environnement Runtipi est **suffisante**
- Pas besoin de `securityadmin.sh` pour l'API

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
- ✅ Utilisation disque (7 GB attendu pour installation fraîche)
- ✅ Présence des 8 fichiers de sécurité OpenSearch
- ✅ Connectivité réseau entre conteneurs
- ✅ Configuration du dashboard et manager
- ✅ Variables d'environnement SSL Filebeat (méthode officielle)
- ✅ Initialisation de la sécurité OpenSearch

### Vérification via l'Interface Web

Après l'installation, vous pouvez également vérifier la santé de votre déploiement directement dans l'interface Wazuh:

**URL de vérification:** `https://VOTRE_IP:5601/app/logs#/health-check`

Cette page affiche:
- État des services Wazuh (indexer, manager, dashboard)
- Statistiques de performance en temps réel
- Alertes de santé du cluster
- Métriques de connectivité des agents

**Note:** Remplacez `VOTRE_IP` par l'adresse IP de votre serveur Runtipi. Si vous utilisez un proxy inverse avec un nom de domaine, utilisez celui-ci à la place.

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

### Variables d'Environnement Techniques

En plus des variables de configuration utilisateur, le déploiement utilise ces variables techniques (configurées automatiquement):

**Indexer:**
- `OPENSEARCH_JAVA_OPTS`: `-Xms1g -Xmx1g -Dlog4j2.formatMsgNoLookups=true`
  - Configure le heap Java (1GB) et active la protection contre la vulnérabilité Log4j
- `DISABLE_INSTALL_DEMO_CONFIG`: `true`
  - Désactive la configuration de démonstration (sécurité)
- `bootstrap.memory_lock`: `true`
  - Verrouille la mémoire pour éviter le swapping (performance)

**Manager:**
- `WAZUH_NODE_TYPE`: `master`
  - Définit explicitement le type de nœud (single-node deployment)
- `FILEBEAT_SSL_VERIFICATION_MODE`: `full`
  - Active la vérification SSL complète pour Filebeat
- `SSL_CERTIFICATE_AUTHORITIES`, `SSL_CERTIFICATE`, `SSL_KEY`
  - Chemins vers les certificats SSL générés automatiquement

**Dashboard:**
- `SERVER_SSL_ENABLED`: `true`
  - Active explicitement le SSL pour le serveur web
- `SERVER_SSL_CERTIFICATE`, `SERVER_SSL_KEY`
  - Certificats SSL pour HTTPS

**Note de sécurité:** Le flag `-Dlog4j2.formatMsgNoLookups=true` protège contre CVE-2021-44228 (Log4Shell). Cette configuration suit les recommandations de sécurité officielles de Wazuh.

### Limites de Ressources

Configuration par défaut des conteneurs basée sur les recommandations Kubernetes de Wazuh:

**Indexer:**
- **CPU:** Réservé: 0.5 / Limite: 1.0 core
- **RAM:** Réservé: 1GB / Limite: 2GB
- Java heap: 1GB min/max (variable `OPENSEARCH_JAVA_OPTS: -Xms1g -Xmx1g -Dlog4j2.formatMsgNoLookups=true`)
- Memory lock: illimité (ulimits memlock: -1)
- File descriptors: 65536
- **Sécurité:** Log4j vulnerability mitigation activé

**Manager:**
- **CPU:** Réservé: 1.0 / Limite: 2.0 cores
- **RAM:** Réservé: 1GB / Limite: 2GB
- Memory lock: illimité (ulimits memlock: -1)
- File descriptors: 655360
- **Type de nœud:** Master (single-node deployment)

**Dashboard:**
- **CPU:** Réservé: 0.2 / Limite: 0.4 core
- **RAM:** Réservé: 512MB / Limite: 2GB
- **SSL:** Activé explicitement via `SERVER_SSL_ENABLED: true`

**Note:** Ces limites sont configurées dans la section `deploy.resources` du fichier `docker-compose.json`. Les limites CPU et RAM sont basées sur les configurations de production Kubernetes de Wazuh pour assurer une stabilité optimale.

### Espace Disque

**Utilisation disque:**
- Installation fraîche: **7 GB**
- **Production recommandée (basée sur les configurations Kubernetes):**
  - **Indexer:** 10Gi minimum pour stockage des indices OpenSearch
  - **Manager:** 50Gi minimum pour logs, queue et données d'agents
  - **Dashboard:** Aucun stockage persistant requis (service sans état)

L'espace augmente avec:
- Nombre d'agents connectés
- Volume d'événements générés
- Période de rétention des logs (7 jours par défaut)

**Volumes critiques à sauvegarder:**
- `indexer-data` - État du cluster et indices OpenSearch
- `manager-logs` - Logs d'événements de sécurité
- `manager-queue` - Queue de données des agents

Pour surveiller:
```bash
# Vérifier la taille totale (incluant data/)
du -sh /opt/runtipi/app-data/*/wazuh-runtipi

# Vérifier uniquement les données persistantes
du -sh /opt/runtipi/app-data/*/wazuh-runtipi/data

# Vérifier par composant
du -sh /opt/runtipi/app-data/*/wazuh-runtipi/data/indexer-data
du -sh /opt/runtipi/app-data/*/wazuh-runtipi/data/manager-logs
du -sh /opt/runtipi/app-data/*/wazuh-runtipi/data/manager-queue
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
- **Manager Watchdog** : Surveille le démarrage de wazuh-db et rend ossec.conf persistant via symlink
- **Sécurité OpenSearch** : Les 8 fichiers dans `indexer-security/` sont automatiquement copiés au premier démarrage et **préservés** lors des mises à jour

---

## 📊 Considérations de Production et Scaling

### Limitations du Déploiement Single-Node

Ce déploiement est optimisé pour les **environnements de petite à moyenne taille**:

**✅ Adapté pour:**
- PME avec 10-50 agents
- Environnements de test/développement
- Labs de sécurité personnels
- Monitoring de petites infrastructures

**⚠️ Non recommandé pour:**
- Grandes entreprises (>100 agents)
- Environnements critiques nécessitant haute disponibilité
- Charges de travail très élevées (>10000 événements/seconde)

### Haute Disponibilité (HA)

Pour des déploiements haute disponibilité, Wazuh recommande Kubernetes avec:

**Configuration HA recommandée (basée sur wazuh-kubernetes):**
- **Indexer:** 3 nœuds en cluster (quorum)
- **Manager:** 1 Master + 2+ Workers avec pod anti-affinity
- **Dashboard:** 2+ réplicas avec load balancing
- **Network Policies:** Segmentation réseau zero-trust
- **Persistent Volumes:** Stockage distribué (EBS, Ceph, etc.)

**Référence:** Le dossier `data/ressources/wazuh-kubernetes-main/` contient les configurations officielles Kubernetes de Wazuh pour déploiements HA.

### Recommandations de Scaling

Si vous atteignez les limites du déploiement single-node:

1. **Migration vers Kubernetes**
   - Utilisez les manifests dans `wazuh-kubernetes-main/`
   - Configurations pré-configurées pour AWS EKS, GKE, AKS
   - Support pour multi-nodes et auto-scaling

2. **Optimisation du Déploiement Actuel**
   - Augmentez les ressources CPU/RAM si nécessaire
   - Ajustez la période de rétention des logs
   - Configurez l'archivage des anciens événements
   - Optimisez les règles de détection (désactiver celles non utilisées)

3. **Monitoring des Performances**
   ```bash
   # Surveiller l'utilisation du CPU/RAM
   docker stats

   # Vérifier la santé du cluster OpenSearch
   curl -k -u admin:admin https://localhost:9200/_cluster/health?pretty

   # Analyser les logs du manager
   docker logs wazuh-runtipi-wazuh-manager-1
   ```

### Sécurité en Production

**✅ Checklist de sécurité:**
- [ ] Changer TOUS les mots de passe par défaut
- [ ] Activer le pare-feu (exposer uniquement ports 5601, 1514, 1515)
- [ ] Configurer HTTPS avec certificats valides (non auto-signés)
- [ ] Limiter les accès SSH au serveur
- [ ] Activer les backups automatiques des volumes critiques
- [ ] Configurer la rotation des logs
- [ ] Activer l'authentification multi-facteurs si possible
- [ ] Surveiller les alertes de sécurité Wazuh pour le serveur lui-même

**Backup recommandé:**
```bash
# Script de backup des volumes critiques
BACKUP_DIR="/backup/wazuh-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Indexer data
tar czf "$BACKUP_DIR/indexer-data.tar.gz" \
  /opt/runtipi/app-data/*/wazuh-runtipi/data/indexer-data

# Manager logs et queue
tar czf "$BACKUP_DIR/manager-data.tar.gz" \
  /opt/runtipi/app-data/*/wazuh-runtipi/data/manager-logs \
  /opt/runtipi/app-data/*/wazuh-runtipi/data/manager-queue

# Security configs
tar czf "$BACKUP_DIR/security-config.tar.gz" \
  /opt/runtipi/app-data/*/wazuh-runtipi/data/indexer-security \
  /opt/runtipi/app-data/*/wazuh-runtipi/data/config
```

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
# Attend que le processus wazuh-db soit démarré
while [ $ELAPSED -lt $TIMEOUT ]; do
    if pgrep -x "wazuh-db" > /dev/null 2>&1; then
        # wazuh-db running, attendre 5s pour stabilité
        sleep 5
        break
    fi
    sleep 2
done
```

**init-dashboard.sh** :
```bash
# Pas de watchdog - exécute simplement l'entrypoint officiel
# La configuration est créée via symlink vers opensearch_dashboards.yml
exec /entrypoint.sh
```

Cette approche garantit :
- 🚀 **Démarrage rapide** sur machines performantes
- ⏱️ **Patience suffisante** sur machines plus lentes
- 📊 **Logs précis** avec temps réels écoulés

### Gestion de la Persistance Manager

Le watchdog du manager (init-manager.sh) rend la configuration ossec.conf persistante :

1. **Attente** : Surveille le démarrage du processus wazuh-db (un des derniers services à démarrer)
2. **Stabilité** : Attend 5 secondes supplémentaires après détection du processus
3. **Persistance** : Copie ossec.conf vers /var/ossec/etc/custom/ si nécessaire
4. **Symlink** : Crée un lien symbolique pour garantir la persistance entre redémarrages

Cette logique garantit que les modifications de configuration survivent aux redémarrages de conteneurs.

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
