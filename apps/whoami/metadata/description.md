# Coqui TTS

Coqui TTS est une bibliothèque de synthèse vocale (Text-to-Speech) utilisant des modèles d'apprentissage profond. Elle offre des voix naturelles et expressives pour transformer du texte en parole.

## Fonctionnalités principales

- **Synthèse vocale haute qualité** : Modèles pré-entraînés pour différentes langues
- **API REST** : Interface simple pour intégration avec d'autres services
- **Modèles multilingues** : Support de nombreuses langues incluant le français
- **Clonage de voix** : Possibilité de créer des voix personnalisées
- **Interface web** : Interface utilisateur simple pour tester la synthèse

## Configuration avec N8N

Cette installation est configurée pour fonctionner avec N8N dans le même réseau Runtipi. Vous pouvez utiliser l'API Coqui TTS dans vos workflows N8N via l'URL interne : `http://coqui-tts:5002`

### Endpoints API principaux

- `GET /api/tts/models` : Liste des modèles disponibles
- `POST /api/tts` : Génération de synthèse vocale
- `GET /api/speakers` : Liste des voix disponibles

### Exemple d'utilisation dans N8N

```json
{
  "method": "POST",
  "url": "http://coqui-tts:5002/api/tts",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "text": "Bonjour, ceci est un test de synthèse vocale",
    "model_name": "tts_models/fr/css10/vits",
    "speaker_id": "0"
  }
}
```

## Stockage des données

- **Modèles** : `/app/data/models` - Modèles TTS téléchargés
- **Fichiers audio générés** : `/app/data/output` - Fichiers WAV générés
- **Configuration** : `/app/data/config` - Fichiers de configuration personnalisés

## Remarques importantes

- Le premier démarrage peut prendre du temps car les modèles sont téléchargés
- L'application nécessite des ressources importantes (CPU/RAM) pour la synthèse
- Les modèles sont conservés entre les redémarrages via les volumes persistants

## Support et documentation

- [Documentation officielle](https://tts.readthedocs.io/)
- [Dépôt GitHub](https://github.com/coqui-ai/TTS)
- [Modèles disponibles](https://github.com/coqui-ai/TTS/wiki/Released-Models)
