# n8n Sandbox Service

Sandbox auto-hébergé pour l'**AI Assistant** de n8n (setup « Self-host the sandbox manually » de la doc n8n). L'app déploie les trois services de la stack officielle :

| Service | Rôle |
|---|---|
| `sandbox-certs` | Job one-shot : génère la CA privée et les certificats mTLS, puis s'arrête. |
| `sandbox-api` | Point d'entrée HTTP (`:8080`) que n8n appelle pour exécuter du code. |
| `sandbox-runner-1` | Docker-in-Docker **privileged** : crée et exécute les conteneurs sandbox. |

## Après l'installation

Lors de l'installation, choisir une clé forte dans le champ **Clé API partagée avec n8n**. Dans l'app officielle **n8n** (paramètres ou `app.env`), ajouter le bloc suivant en recopiant cette même clé :

```
N8N_ENABLED_MODULES=instance-ai
N8N_INSTANCE_AI_SANDBOX_ENABLED=true
N8N_INSTANCE_AI_SANDBOX_PROVIDER=n8n-sandbox
N8N_INSTANCE_AI_SANDBOX_IMAGE=n8nio/n8n-sandbox-service-sandbox:1.3.0
N8N_SANDBOX_SERVICE_URL=http://sandbox-api:8080
N8N_SANDBOX_SERVICE_API_KEY=<même valeur que « Clé API partagée avec n8n »>
N8N_PROXY_HOPS=1
```

Puis redémarrer n8n et vérifier depuis son conteneur :

```
wget -qO- http://sandbox-api:8080/healthz    # {"status":"ok"}
```

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
