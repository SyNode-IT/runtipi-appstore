# n8n Sandbox Service

Sandbox auto-hébergé pour l'**AI Assistant** de n8n (configuration « Self-host the sandbox manually » de la documentation n8n). L'app déploie les trois services de la stack officielle :

| Service | Rôle |
|---|---|
| `sandbox-certs` | Initialise la CA privée et les certificats mTLS, puis reste inactif et sain pour que Runtipi conserve l'app au statut « Démarré ». |
| `sandbox-api` | Point d'entrée HTTP interne (`:8080`) que n8n appelle pour exécuter du code. |
| `sandbox-runner-1` | Docker-in-Docker **privileged** : crée et exécute les conteneurs sandbox. |

## Après l'installation

Pendant l'installation, choisir une clé forte dans le champ **Clé API partagée avec n8n** et la conserver dans un gestionnaire de mots de passe.

Dans l'application officielle **n8n**, activer la **configuration utilisateur Docker Compose**, puis ajouter :

```yaml
# Add your docker-compose overrides here.
# The overrides will be merged with the generated docker-compose.yml file.

# Heure de Paris
services:
  n8n-2:
    environment:
      - GENERIC_TIMEZONE=Europe/Paris

      # AI Assistant et Sandbox externe
      - N8N_ENABLED_MODULES=instance-ai
      - N8N_INSTANCE_AI_SANDBOX_ENABLED=true
      - N8N_INSTANCE_AI_SANDBOX_PROVIDER=n8n-sandbox
      - N8N_INSTANCE_AI_SANDBOX_IMAGE=n8nio/n8n-sandbox-service-sandbox:1.3.0
      - N8N_SANDBOX_SERVICE_URL=http://sandbox-api:8080
      - N8N_SANDBOX_SERVICE_API_KEY=<clé choisie lors de l’installation>
```

Remplacer entièrement `<clé choisie lors de l’installation>` par la vraie clé, sans conserver les caractères `<` et `>`. Ne jamais publier cette valeur.

Le port de `N8N_SANDBOX_SERVICE_URL` reste `8080` : il s'agit du port interne du service Docker, pas du port éventuellement choisi dans l'interface Runtipi.

Enregistrer la configuration, puis redémarrer l'application **n8n**. Pour vérifier la communication depuis son conteneur :

```sh
wget -qO- http://sandbox-api:8080/healthz
```

La réponse attendue est `{"status":"ok"}`.

## Recherche web avec SearXNG (facultatif)

SearXNG est une application séparée et n'est pas nécessaire au fonctionnement du sandbox. L'installer seulement si les workflows ou outils IA de n8n doivent effectuer des recherches web.

Pour autoriser les réponses JSON de SearXNG, modifier :

```sh
sudo nano /opt/runtipi/app-data/migrated/searxng/data/settings.yml
```

Conserver les autres réglages existants et vérifier que le fichier contient :

```yaml
use_default_settings: true

search:
  formats:
    - html
    - json
```

Contrôle facultatif du contenu et des fins de ligne :

```sh
sudo cat -A /opt/runtipi/app-data/migrated/searxng/data/settings.yml
```

Redémarrer ensuite l'application **SearXNG**, puis redémarrer **n8n** si sa configuration a également été modifiée.

## Données persistantes

Tout est sous `app-data/<store>/n8n-sandbox/data/` :

- `tls/` : certificats mTLS (contient la clé de la CA, à traiter comme un secret)
- `api/` : base SQLite de l'API
- `runner-state/` : base SQLite du runner
- `runner-docker/` : `/var/lib/docker` du DinD (cache de l'image sandbox, peut peser plusieurs Go ; vidable sans perte)

## Sécurité

- Aucun port n'est publié sur l'hôte. `sandbox-api:8080` est joignable par les autres apps Runtipi via `tipi_main_network`, protégé uniquement par la clé API.
- Le runner est `privileged` : équivalent root sur l'hôte. Ne jamais l'exposer.
- n8n recommande cette stack pour le développement/test et Daytona pour la production.

## Notes

- Les noms `sandbox-api` et `sandbox-runner-1` sont les SAN des certificats : ne pas les renommer.
- Les certificats ne se renouvellent pas seuls. Pour les régénérer, supprimer `data/tls/` et redémarrer l'app.
- L'image sandbox est téléchargée par le runner au premier usage.
