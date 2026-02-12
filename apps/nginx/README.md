# Nginx Custom pour Runtipi

Application Nginx avec volumes personnalisables pour la configuration et le contenu des sites.

## Installation

### Option 1 : App Store personnel
1. Créez votre propre app store Runtipi
2. Copiez ce dossier `nginx-custom` dans le dossier `apps/` de votre store
3. Ajoutez votre app store dans Runtipi (Settings > App Stores)
4. Installez l'app depuis l'interface

### Option 2 : Installation manuelle
1. Copiez le contenu de `data/` vers `runtipi/app-data/<store>/nginx-custom/`
2. Utilisez `user-config` pour personnaliser si nécessaire

## Structure des volumes

```
app-data/nginx-custom/
├── nginx.conf        # Configuration principale Nginx
├── conf.d/           # Virtual hosts (*.conf)
│   └── default.conf
├── www/              # Racine pour vos sites (/var/www)
├── html/             # Dossier HTML par défaut (/usr/share/nginx/html)
├── logs/             # Logs d'accès et d'erreur
└── ssl/              # Certificats SSL (lecture seule dans le conteneur)
```

## Personnalisation

### Ajouter un site

1. Créez `conf.d/monsite.conf` :
```nginx
server {
    listen 80;
    server_name monsite.local;
    root /var/www/monsite;
    index index.html;
}
```

2. Créez le dossier `www/monsite/` avec votre contenu

3. Redémarrez l'app depuis Runtipi

### Activer SSL

1. Placez vos certificats dans `ssl/` :
   - `ssl/cert.pem`
   - `ssl/key.pem`

2. Modifiez votre configuration de site :
```nginx
server {
    listen 443 ssl;
    server_name monsite.local;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    root /var/www/monsite;
}
```

## Variables d'environnement

| Variable | Description | Défaut |
|----------|-------------|--------|
| `NGINX_SERVER_NAME` | Nom du serveur | localhost |
| `NGINX_INTERNAL_PORT` | Port interne | 80 |
| `TZ` | Fuseau horaire | Europe/Paris |

## Support

- Documentation Nginx : https://nginx.org/en/docs/
- Documentation Runtipi : https://runtipi.io/docs/
