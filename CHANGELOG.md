# Changelog

## [2.1.0] - 2024-12-03

### 🎵 NEW: Song Metadata Display
- ✅ **Lauftext-Anzeige**: Aktueller Song wird oben rechts angezeigt
- ✅ **Live-Updates**: Metadata wird alle 10 Sekunden vom Server aktualisiert
- ✅ **HTML-Parsing**: Liest Daten direkt aus Icecast2 Status-Seite
- ✅ **Optional**: Zeige auch Zuhörer-Anzahl

### ⚙️ Customization
- ✅ **Radio-Name**: "Blyad Radio" statt "Russian Car Radio"
- ✅ **Taste geändert**: Q-Taste (85) statt E-Taste (38)
- ✅ **Author**: Manuel H.

### 🔧 Fixed
- ✅ **xsound Loop**: loop=false für Streams (loop=true verursachte Probleme)
- ✅ **Auto-Reconnect**: xsound onPlayEnd Event für automatischen Neustart
- ✅ **Stream-Stabilität**: Besseres Handling bei Stream-Unterbrechungen

### 📝 Details

#### Was wird angezeigt:
```
🎵 Daniel Deluxe - Instruments of Retribution (Full Album - 2017)
```

#### Wie es funktioniert:
1. Server fetcht HTML von `https://service4gamer.net/streamstatus`
2. Parsed "Currently playing" aus dem HTML
3. Sendet Metadata an Client alle 10 Sekunden
4. Client zeigt Lauftext oben rechts

#### Neue Dateien:
- `server.lua` - Metadata-Fetching vom Icecast2 Server

#### Neue Config-Option:
```lua
showListeners = false  -- Zeige Zuhörer-Anzahl im Lauftext
```

#### Test-Command:
```
/radioinfo
```
Zeigt aktuellen Song und Zuhörer im Chat

---

## [2.0.1] - 2024-12-03

### 🔄 Fixed: Kontinuierliches Streaming
- ✅ **Loop-Parameter aktiviert**: Songs spielen jetzt automatisch durch
- ✅ **Auto-Reconnect**: Stream verbindet sich automatisch neu bei Unterbrechung
- ✅ Stream läuft jetzt ununterbrochen - kein manuelles PLAY mehr nötig!

### 🔒 Improved: HTTPS Support
- ✅ **URL aktualisiert**: Jetzt mit HTTPS statt HTTP
- ✅ **Bessere Sicherheit**: SSL-verschlüsselte Verbindung
- ✅ **Keine Mixed-Content-Warnungen** mehr

### 📝 Details

#### Was wurde geändert:
```lua
// ALT:
exports.xsound:PlayUrl(SOUND_ID, STREAM_URL, volume, false)
//                                                    ^^^^^
//                                                    Kein Loop

// NEU:
exports.xsound:PlayUrl(SOUND_ID, STREAM_URL, volume, true)
//                                                    ^^^^
//                                                    Loop aktiviert!
```

#### Stream URL:
```lua
// ALT: 
local STREAM_URL = "http://service4gamer.net:8000/live"

// NEU:
local STREAM_URL = "https://service4gamer.net/live"
```

### 🎯 Erwartetes Verhalten:

**Vorher:**
```
Song 1 spielt → STOP → Manuell PLAY drücken → Song 2 → STOP...
```

**Jetzt:**
```
Song 1 → Song 2 → Song 3 → Song 4 → ... (automatisch!)
```

---

## [2.0.0] - 2024-12-02

### 🎉 Initial Release
- ✅ xsound Integration
- ✅ 3D Positional Audio
- ✅ Russisches Radio-Design
- ✅ Minimize-Funktion
- ✅ Lautstärkeregelung
- ✅ Icecast2 Streaming Support
