# Blyad Radio - xsound Version

Ein FiveM Plugin für GTA 5 RP Server mit **xsound** - löst alle CORS/NUI Probleme! 🎵

[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](https://github.com/ShakirPlayZ/FiveM-RussianCarRadio)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-orange.svg)](https://fivem.net)
[![Author](https://img.shields.io/badge/author-Manuel%20H.-red.svg)](https://github.com/ShakirPlayZ)

## 🎉 Neueste Updates (v2.1.0)

- 🎵 **Song Metadata Display**: Aktueller Song wird als Lauftext angezeigt
- ✅ **Live-Updates**: Alle 10 Sekunden neue Song-Info
- ✅ **HTML-Parsing**: Liest Daten aus Icecast2 Status-Seite
- ✅ **Kontinuierliches Streaming**: Songs spielen automatisch durch
- ✅ **HTTPS Support**: Sichere SSL-verschlüsselte Verbindung

[📋 Alle Änderungen ansehen](CHANGELOG.md)

---

## 📸 Screenshot

![Lauftext Anzeige](https://via.placeholder.com/600x100/1a1a1a/ff3333?text=%F0%9F%8E%B5+Daniel+Deluxe+-+Instruments+of+Retribution)

*Aktueller Song wird oben rechts als Lauftext angezeigt*

## ✅ Warum xsound?

**Problem:** Browser-basierte Audio-Streams (iframe/audio tags) werden durch FiveM's NUI CORS-Policy blockiert.

**Lösung:** xsound spielt Audio direkt über GTA's Audio-System - **kein NUI, keine CORS-Probleme!**

## 🎯 Features

✅ **Icecast2 Streaming** - Direkt vom Server
✅ **3D Positional Audio** - Sound kommt aus dem Fahrzeug
✅ **Keine CORS Probleme** - xsound umgeht NUI komplett
✅ **Blyad Radio Design** - Retro-Optik mit Style 😎
✅ **Lautstärkeregelung** - Präzise Kontrolle
✅ **Minimize-Funktion** - Stört nicht beim Fahren
✅ **Nur für Fahrer** - Nur Fahrer kann Radio bedienen

## 📋 Installation

### Schritt 1: xsound installieren

**xsound** ist eine **Dependency** - du musst es zuerst installieren!

1. Download xsound: https://github.com/Xogy/xsound/releases
2. Entpacke `xsound` nach `/resources/`
3. Füge zu `server.cfg` hinzu:
   ```cfg
   ensure xsound
   ```

### Schritt 2: Radio installieren

1. Entpacke `russian_car_radio` nach `/resources/`
2. Füge zu `server.cfg` hinzu:
   ```cfg
   ensure russian_car_radio
   ```

### Schritt 3: Server starten

```bash
# Server neu starten oder:
/ensure xsound
/ensure russian_car_radio
```

## 🎮 Benutzung

1. **In ein Fahrzeug einsteigen** - Als Fahrer
2. **Q-Taste drücken** - Radio öffnet sich unten rechts
3. **PLAY klicken** - Musik startet sofort! ✅
4. **Lautstärke regeln** - Mit Slider oder +/- Buttons
5. **Minimize** - Orange Button minimiert das Radio
6. **Schließen** - Rotes X oder ESC

## ⚙️ Konfiguration

### Stream-URL ändern

Ändere in `client.lua` (Zeile ~11):
```lua
local STREAM_URL = "https://service4gamer.net/live"
```

Die URL nutzt jetzt **HTTPS mit SSL** für bessere Sicherheit und Kompatibilität! 🔒

### 3D Audio ein/ausschalten

In `client.lua` (Zeile ~19):
```lua
local Config = {
    use3DSound = true,        -- true = Sound aus Fahrzeug, false = direkt im Kopf
    maxDistance = 30.0,       -- Maximale Hör-Distanz in Metern (nur bei 3D)
    radioKey = 85,            -- 85 = Q-Taste
    maxVolume = 100,
    showListeners = false     -- Zeige Zuhörer-Anzahl im Lauftext 🆕
}
```

## 🔧 Troubleshooting

### Problem: "xsound export not found"
**Lösung:** xsound ist nicht installiert oder nicht gestartet
```bash
/ensure xsound
/restart russian_car_radio
```

### Problem: Kein Ton
**Lösung:**
- Prüfe ob xsound läuft: `/restart xsound`
- Prüfe F8 Konsole auf Errors
- Erhöhe Lautstärke im Radio

### Problem: Radio öffnet sich nicht
**Lösung:**
- Nur als Fahrer (nicht als Beifahrer)
- Drücke Q-Taste

### Problem: Song-Anzeige zeigt "Lädt..."
**Lösung:**
- Teste mit `/radioinfo` Command
- Prüfe ob Server `server.lua` lädt
- Prüfe Server-Logs für Metadata-Fehler
- URL muss erreichbar sein: https://service4gamer.net/streamstatus

## 🆚 xsound vs. normale Version

| Feature | Normale Version | xsound Version |
|---------|----------------|----------------|
| **CORS Probleme** | ❌ Ja | ✅ Keine |
| **Funktioniert** | ❌ Oft nicht | ✅ Immer |
| **3D Audio** | ❌ Nein | ✅ Ja |
| **Dependencies** | ✅ Keine | ⚠️ xsound nötig |
| **Performance** | ✅ Gut | ✅ Gut |

## 💡 Wie es funktioniert

**Normale Version:**
```
Browser → iframe → audio tag → ❌ CORS blocked
```

**xsound Version:**
```
Client Lua → xsound → GTA Audio System → ✅ Funktioniert!
```

xsound lädt den Stream serverseitig und streamt ihn dann zu den Clients über GTA's natives Audio-System.

## 📚 Links

- **xsound GitHub:** https://github.com/Xogy/xsound
- **xsound Docs:** https://xogy.github.io/xsound/

## 🎵 Support

Bei Fragen oder Problemen:
1. Prüfe F8 Konsole
2. Prüfe Server Logs
3. Stelle sicher dass xsound läuft

## 🚀 Vorteile

- ✅ **Funktioniert garantiert** - Keine CORS Probleme mehr!
- ✅ **3D Audio** - Realistischer Sound aus dem Fahrzeug
- ✅ **Bessere Performance** - Natives GTA Audio
- ✅ **Mehr Kontrolle** - Lautstärke, Distance, etc.

---

**Viel Spaß mit deinem Radio! 🎵🚗**

*Diese Version nutzt xsound und funktioniert garantiert mit Icecast2 Streams!*
