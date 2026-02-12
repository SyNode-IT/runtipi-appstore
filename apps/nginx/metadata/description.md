# Nginx Custom

Serveur web **Nginx** avec configuration entièrement personnalisable via des volumes montés.

## Volumes disponibles

| Chemin dans le conteneur | Description |
|--------------------------|-------------|
| `/etc/nginx/nginx.conf` | Fichier de configuration principal |
| `/etc/nginx/conf.d/` | Configurations des virtual hosts |
| `/var/www/` | Contenu de vos sites web |
| `/usr/share/nginx/html/` | Dossier html par défaut de Nginx |
| `/var/log/nginx/` | Logs d'accès et d'erreur |
| `/etc/nginx/ssl/` | Certificats SSL (lecture seule) |

## Utilisation

### Accéder aux fichiers

Les fichiers sont stockés dans le dossier `app-data` de votre installation Runtipi :

```
runtipi/app-data/<app-store>/nginx-custom/
├── conf.d/          # Vos configurations de sites
│   └── default.conf
├── nginx.conf       # Config principale
├── www/             # Vos fichiers web
├── html/            # Dossier html par défaut
├── logs/            # Logs nginx
└── ssl/             # Certificats SSL
```

### Ajouter un nouveau site

1. Créez un fichier `.conf` dans `conf.d/`
2. Placez vos fichiers dans `www/monsite/`
3. Redémarrez l'application depuis Runtipi

### Exemple de configuration

```nginx
server {
    listen 80;
    server_name monsite.local;
    root /var/www/monsite;
    index index.html index.php;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

## Notes

- Les modifications de configuration nécessitent un redémarrage de l'app
- Pour le SSL, placez vos certificats dans le dossier `ssl/`
- Les logs sont persistés et accessibles dans `logs/`
