# Tianji

**Tianji** est un hub *tout‑en‑un* : analytics sans cookies, supervision d’uptime, et statut serveur.

- Port interne : **12345**
- Base de données : **PostgreSQL** (conteneur embarqué)
- Volume des données Tianji : ` ${APP_DATA_DIR}/data `
- Volume PostgreSQL : ` ${APP_DATA_DIR}/pgdata `
- Variables utiles : `JWT_SECRET`, `ALLOW_REGISTER`, `ALLOW_OPENAPI`

Identifiants par défaut : **admin / admin** → changez le mot de passe dès la première connexion.
