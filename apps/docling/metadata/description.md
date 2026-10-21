# Docling

Moteur d'extraction de documents pour Open WebUI.

Dans Open WebUI : Administration > Réglages > Documents, moteur d'extraction **Docling**, URL `http://docling:5001` (ou `http://<ip-du-serveur>:5001`).

Pour que les images des PDF soient lues, les paramètres Docling d'Open WebUI envoient chaque page à un modèle vision d'Ollama (pipeline `vlm`). `DOCLING_SERVE_ENABLE_REMOTE_SERVICES` est activé pour ça.

Source : https://github.com/docling-project/docling-serve
