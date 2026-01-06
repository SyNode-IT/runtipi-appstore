# MediaMTX 1.15.6 pour Runtipi

Serveur de streaming multimédia moderne, performant et prêt à l'emploi.

**Version:** MediaMTX 1.15.6
**Plateforme:** Runtipi
**Status:** ✅ Stable

---

## 📖 Qu'est-ce que MediaMTX ?

**MediaMTX** (anciennement rtsp-simple-server) est un serveur de streaming multimédia puissant et facile à utiliser qui supporte de multiples protocoles:

### Protocoles Supportés

- **RTSP** - Real-Time Streaming Protocol
- **RTMP** - Real-Time Messaging Protocol
- **HLS** - HTTP Live Streaming
- **WebRTC** - Web Real-Time Communication
- **SRT** - Secure Reliable Transport
- **MPEG-TS** - MPEG Transport Stream
- **UDP/RTP** - User Datagram Protocol / Real-time Transport Protocol

### Caractéristiques Principales

- ✅ **Zero Configuration** - Fonctionne immédiatement sans configuration
- ✅ **Conversion Automatique** - Conversion transparente entre tous les protocoles
- ✅ **Enregistrement Intégré** - Sauvegarde des streams en MP4 ou MPEG-TS
- ✅ **Performance Optimale** - Écrit en Go, faible consommation de ressources
- ✅ **API REST Complète** - Contrôle programmatique via HTTP
- ✅ **Metrics Prometheus** - Surveillance et monitoring intégrés
- ✅ **Multi-plateforme** - Linux, Windows, macOS, ARM

### Cas d'Usage

- **Surveillance vidéo** - Caméras IP (RTSP/ONVIF)
- **Streaming en direct** - Diffusion d'événements, conférences
- **Broadcasting** - OBS Studio, FFmpeg, GStreamer
- **Visioconférence** - WebRTC pour applications web
- **IoT et drones** - Transmission vidéo temps réel
- **Enregistrement DVR** - Sauvegarde de flux vidéo

---

## 🏗️ Architecture

MediaMTX fonctionne comme un serveur central qui accepte des connexions entrantes (publishers) et redistribue les streams aux clients (viewers):

```
┌──────────────────────────────────────────────────────────────┐
│                        Publishers                             │
│                                                              │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐  │
│   │  Caméra  │   │   OBS    │   │ FFmpeg   │   │  Drone   │  │
│   │   IP     │   │  Studio  │   │          │   │          │  │
│   │  (RTSP)  │   │  (RTMP)  │   │  (SRT)   │   │ (WebRTC) │  │
│   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘  │
│        │              │              │              │        │
└────────┼──────────────┼──────────────┼──────────────┼────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
┌──────────────────────────────────────────────────────────────┐
│                      MediaMTX Server                         │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │   Protocol Conversion & Stream Distribution           │  │
│  │   RTSP (8554) │ RTMP (1935) │ HLS (8888) │ WebRTC    │  │
│  │   SRT (8890)  │ API (9997)  │ Metrics (9998)          │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │   Enregistrement (optionnel)                           │  │
│  │   Formats: fMP4, MPEG-TS                               │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
┌──────────────────────────────────────────────────────────────┐
│                          Viewers                              │
│                                                              │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐  │
│   │   VLC    │   │Navigateur│   │  Mobile  │   │ Lecteur  │  │
│   │ (RTSP)   │   │  (HLS)   │   │ (WebRTC) │   │ (RTMP)   │  │
│   └──────────┘   └──────────┘   └──────────┘   └──────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## 🚀 Installation

### Prérequis

- **Runtipi** installé et fonctionnel
- **Ressources minimales:**
  - **CPU:** 1 core (2+ recommandés)
  - **RAM:** 512MB minimum (2GB recommandés pour production)
  - **Disque:** 1GB + espace pour enregistrements (si activé)
- **Ports réseau** accessibles (voir tableau des ports)

### Installation via Runtipi

1. **Ouvrir l'interface Runtipi** dans votre navigateur
2. **Aller dans "App Store"**
3. **Rechercher "MediaMTX"**
4. **Cliquer sur "Install"**
5. **Configurer les options** (optionnel):
   - Authentification API (username/password)
   - Activer l'enregistrement des streams
6. **Cliquer sur "Installer"**

L'application démarre automatiquement et est prête à recevoir des streams !

---

## 🔐 Configuration

### Ports Exposés

| Port | Protocole | Usage | Accès |
|------|-----------|-------|-------|
| **8554** | TCP/UDP | RTSP | Public |
| **1935** | TCP | RTMP | Public |
| **8888** | TCP | HLS | Public |
| **8889** | TCP | WebRTC (Signaling) | Public |
| **8890** | UDP | WebRTC/SRT Media | Public |
| **8189** | UDP | WebRTC ICE | Public |
| **9997** | TCP | API REST | Interne/Admin |
| **9998** | TCP | Metrics Prometheus | Interne/Monitoring |

### Variables d'Environnement

Configurables via l'interface Runtipi:

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `MTX_API_USERNAME` | Nom d'utilisateur API | *(vide - auth désactivée)* |
| `MTX_API_PASSWORD` | Mot de passe API | *(vide)* |
| `MTX_RECORD_ENABLED` | Activer enregistrement | `false` |

**Paramètres Automatiques** (pré-configurés):

- `MTX_PROTOCOLS=tcp` - Protocoles Docker-friendly
- `MTX_LOGLEVEL=info` - Niveau de log
- `MTX_LOGDESTINATIONS=stdout` - Logs vers Docker
- Tous les ports configurés automatiquement

### Authentification API

Pour sécuriser l'API REST:

1. **Aller dans Runtipi → Apps → MediaMTX → Paramètres**
2. **Définir `MTX_API_USERNAME`** (ex: `admin`)
3. **Définir `MTX_API_PASSWORD`** (ex: mot de passe fort)
4. **Redémarrer l'application**

L'API nécessitera ensuite une authentification HTTP Basic:

```bash
curl -u admin:PASSWORD http://localhost:9997/v3/config/get
```

### Enregistrement des Streams

Pour activer l'enregistrement automatique:

1. **Cocher "Activer l'enregistrement des streams"** lors de l'installation
2. Les enregistrements seront sauvegardés dans:
   ```
   /opt/runtipi/app-data/*/mediamtx/data/recordings/
   ```
3. **Format:** fMP4 (fragmenté MP4, compatible avec tous les lecteurs)
4. **Nom des fichiers:** `{stream-name}/{date}_{heure}.mp4`

**Exemple de structure:**
```
recordings/
├── camera1/
│   ├── 2025-01-06_14-30-00-000.mp4
│   └── 2025-01-06_15-00-00-000.mp4
└── stream2/
    └── 2025-01-06_14-45-00-000.mp4
```

---

## 📹 Utilisation

### 1. Publier un Stream (Publisher)

#### Depuis OBS Studio (RTMP)

1. **Ouvrir OBS Studio**
2. **Paramètres → Stream**
3. **Service:** Personnalisé
4. **Serveur:** `rtmp://VOTRE_IP:1935/`
5. **Clé de stream:** `nom_du_stream`
6. **Démarrer le streaming**

#### Depuis FFmpeg (RTSP)

```bash
ffmpeg -re -i video.mp4 -c copy -f rtsp rtsp://VOTRE_IP:8554/mon_stream
```

#### Depuis une Caméra IP (RTSP)

Redirigez le stream de votre caméra:

```bash
ffmpeg -i rtsp://camera_ip:554/stream \
  -c copy \
  -f rtsp rtsp://VOTRE_IP:8554/camera1
```

#### Depuis FFmpeg (RTMP)

```bash
ffmpeg -re -i video.mp4 -c copy -f flv rtmp://VOTRE_IP:1935/mon_stream
```

### 2. Lire un Stream (Viewer)

#### Dans VLC (RTSP)

1. **Ouvrir VLC**
2. **Média → Ouvrir un flux réseau**
3. **URL:** `rtsp://VOTRE_IP:8554/nom_du_stream`
4. **Lire**

#### Dans un Navigateur (HLS)

Créez un fichier HTML:

```html
<!DOCTYPE html>
<html>
<head>
  <title>MediaMTX Stream</title>
  <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
</head>
<body>
  <video id="video" controls width="640" height="480"></video>
  <script>
    const video = document.getElementById('video');
    const url = 'http://VOTRE_IP:8888/nom_du_stream/index.m3u8';

    if (Hls.isSupported()) {
      const hls = new Hls();
      hls.loadSource(url);
      hls.attachMedia(video);
    }
  </script>
</body>
</html>
```

#### Dans un Navigateur (WebRTC)

```html
<!DOCTYPE html>
<html>
<head>
  <title>MediaMTX WebRTC</title>
</head>
<body>
  <video id="video" controls autoplay playsinline></video>
  <script src="https://unpkg.com/@pion/webrtc@latest/dist/whip-whep.js"></script>
  <script>
    const video = document.getElementById('video');
    const pc = new RTCPeerConnection();

    pc.ontrack = (event) => {
      video.srcObject = event.streams[0];
    };

    fetch('http://VOTRE_IP:8889/nom_du_stream/whep', {
      method: 'POST',
      headers: { 'Content-Type': 'application/sdp' },
      body: await pc.createOffer()
    })
    .then(res => res.text())
    .then(sdp => pc.setRemoteDescription({ type: 'answer', sdp }));
  </script>
</body>
</html>
```

#### Avec FFplay

```bash
ffplay rtsp://VOTRE_IP:8554/nom_du_stream
```

#### Avec curl (test rapide)

```bash
curl http://VOTRE_IP:8888/nom_du_stream/index.m3u8
```

---

## 🔧 API REST

MediaMTX expose une API REST complète sur le port **9997**.

### Endpoints Principaux

#### Lister les Streams Actifs

```bash
curl http://localhost:9997/v3/paths/list
```

**Réponse:**
```json
{
  "itemCount": 2,
  "pageCount": 1,
  "items": [
    {
      "name": "camera1",
      "source": {
        "type": "rtspSession",
        "id": "abc123"
      },
      "ready": true,
      "tracks": ["H264", "AAC"],
      "bytesReceived": 1234567,
      "bytesSent": 7654321,
      "readers": [
        {
          "type": "hlsConn",
          "id": "xyz789"
        }
      ]
    }
  ]
}
```

#### Obtenir la Configuration

```bash
curl http://localhost:9997/v3/config/get
```

#### Modifier la Configuration

```bash
curl -X POST http://localhost:9997/v3/config/set \
  -H "Content-Type: application/json" \
  -d '{"logLevel": "debug"}'
```

#### Redémarrer le Serveur

```bash
curl -X POST http://localhost:9997/v3/config/restart
```

#### Forcer la Fermeture d'un Stream

```bash
curl -X POST http://localhost:9997/v3/paths/kick/camera1
```

### Avec Authentification

Si vous avez activé l'authentification API:

```bash
curl -u admin:PASSWORD http://localhost:9997/v3/paths/list
```

---

## 📊 Monitoring avec Prometheus

MediaMTX expose des métriques Prometheus sur le port **9998**.

### Accéder aux Métriques

```bash
curl http://localhost:9998/metrics
```

### Métriques Disponibles

```
# Streams actifs
mediamtx_paths{state="ready"} 5

# Données reçues (bytes)
mediamtx_paths_bytes_received{name="camera1"} 1234567890

# Données envoyées (bytes)
mediamtx_paths_bytes_sent{name="camera1"} 9876543210

# Nombre de lecteurs par stream
mediamtx_paths_readers{name="camera1"} 3
```

### Configuration Prometheus

```yaml
scrape_configs:
  - job_name: 'mediamtx'
    static_configs:
      - targets: ['localhost:9998']
```

---

## 🎯 Exemples d'Utilisation

### Caméra IP ONVIF/RTSP

Relayer une caméra IP vers HLS pour lecture navigateur:

```bash
# La caméra publie automatiquement sur RTSP
# MediaMTX rend disponible en HLS:
http://VOTRE_IP:8888/camera1/index.m3u8
```

### Streaming depuis Webcam

```bash
ffmpeg -f v4l2 -i /dev/video0 \
  -f alsa -i hw:0 \
  -c:v libx264 -preset ultrafast -tune zerolatency \
  -c:a aac \
  -f rtsp rtsp://localhost:8554/webcam
```

### Restreamer YouTube Live

```bash
ffmpeg -i rtsp://VOTRE_IP:8554/mon_stream \
  -c copy \
  -f flv rtmp://a.rtmp.youtube.com/live2/VOTRE_CLE_STREAM
```

### Enregistrement Planifié (Cron)

```bash
# Enregistrer pendant 1 heure
ffmpeg -i rtsp://localhost:8554/camera1 \
  -c copy \
  -t 3600 \
  /recordings/$(date +%Y-%m-%d_%H-%M-%S).mp4
```

### Stream Multi-Protocole

Un seul stream source est automatiquement disponible sur tous les protocoles:

- **RTSP:** `rtsp://VOTRE_IP:8554/stream1`
- **RTMP:** `rtmp://VOTRE_IP:1935/stream1`
- **HLS:** `http://VOTRE_IP:8888/stream1/index.m3u8`
- **WebRTC:** `http://VOTRE_IP:8889/stream1`

---

## 🐛 Dépannage

### Le Stream ne s'Affiche Pas

**Vérifier que le stream est actif:**
```bash
curl http://localhost:9997/v3/paths/list
```

**Vérifier les logs Docker:**
```bash
docker logs $(docker ps --filter "name=mediamtx" --format "{{.Names}}")
```

**Tester la connectivité:**
```bash
# RTSP
ffprobe rtsp://localhost:8554/nom_du_stream

# HLS
curl http://localhost:8888/nom_du_stream/index.m3u8
```

### Problèmes WebRTC

WebRTC nécessite une configuration NAT supplémentaire. Si vous êtes derrière un NAT/routeur:

1. **Configurer le port forwarding** pour les ports UDP 8890, 8189
2. **Ajouter votre IP publique** dans la configuration

### Latence Élevée

Pour réduire la latence:

- **Utiliser RTSP** avec UDP (latence ~200ms)
- **Utiliser WebRTC** (latence <100ms)
- Éviter HLS (latence 6-30 secondes)

### Performances Dégradées

**Vérifier l'utilisation des ressources:**
```bash
docker stats $(docker ps --filter "name=mediamtx" --format "{{.Names}}")
```

**Augmenter les ressources** si nécessaire dans Runtipi → Apps → MediaMTX → Paramètres.

---

## 📚 Ressources

### Documentation Officielle

- **Site Web:** https://mediamtx.org
- **Documentation:** https://mediamtx.org/docs/
- **GitHub:** https://github.com/bluenviron/mediamtx
- **Discord Community:** https://discord.gg/MmAErXH

### Outils Compatibles

**Publishers:**
- OBS Studio
- FFmpeg
- GStreamer
- v4l2rtspserver
- Caméras IP (ONVIF/RTSP)
- Drones (Tello, DJI)

**Viewers:**
- VLC Media Player
- FFplay
- Navigateurs web (HLS/WebRTC)
- Applications mobiles (RTSP/HLS)
- Appareils IPTV

---

## 📄 Licence

**MediaMTX** est un logiciel open-source sous licence **MIT**.

- **Développeur:** bluenviron (formerly Aler9)
- **Version:** 1.15.6
- **Dernière mise à jour:** 28 décembre 2024

Cette application Runtipi utilise l'image Docker officielle de MediaMTX.

---

**🎉 Votre serveur de streaming MediaMTX est maintenant prêt !**

Commencez à publier et lire des streams en quelques commandes.
