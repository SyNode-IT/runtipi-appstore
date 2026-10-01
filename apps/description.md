# RustDesk Server

Serveur open source pour [RustDesk](https://rustdesk.com), l'outil de prise en main à distance auto-hébergé.

- **hbbs** : annuaire d'ID, mise en relation des postes (NAT traversal).
- **hbbr** : relais des sessions quand une connexion directe est impossible.

## Réseau

Les deux services tournent en réseau `host` (recommandation officielle RustDesk). Ports utilisés sur l'hôte :

| Port  | Protocole | Service | Rôle                                   |
|-------|-----------|---------|----------------------------------------|
| 21115 | TCP       | hbbs    | Test du type de NAT                    |
| 21116 | TCP + UDP | hbbs    | Enregistrement des ID, mise en relation |
| 21117 | TCP       | hbbr    | Relais                                 |
| 21118 | TCP       | hbbs    | Client web                             |
| 21119 | TCP       | hbbr    | Client web (relais)                    |

Ces ports ne passent pas par Traefik : redirigez-les directement (NAT) vers l'hôte Runtipi.

## Données

`${APP_DATA_DIR}/data` contient la paire de clés du serveur (`id_ed25519`, `id_ed25519.pub`) et la base `db_v2.sqlite3`.
**Conservez ces fichiers** : les clients sont configurés avec la clé publique ; la perdre oblige à reconfigurer tous les postes.

## Configuration des clients

- Serveur ID : nom de domaine du serveur
- Clé : contenu de `id_ed25519.pub`
