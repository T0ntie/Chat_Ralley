
```
open ios/Runner.xcworkspace
```


![[Pasted image 20250621084742.png|300]]

Unter Product > Scheme > Manage Schemes…
![[Pasted image 20250621085650.png|300]]
RUN und Archive auf DevDebug und DevRelease  bzw. ProdDebug und ProdRelease umstellen
![[Pasted image 20250621085945.png|300]]

GoogleService-Info.plist

In der firebase console beim DEV Projekt googleservice-info runterladen
![[Pasted image 20250621090807.png|300]]

mit ln-s einen symlink zur aktuelen GoogleService-Info anlegen
ln -s ../firebase/dev/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

Buildscript in Xcode ergänzen:

- Klicke in der linken Leiste auf `Runner` (unter TARGETS)
    
- Dann oben auf den Tab **„Build Phases“**
    
- Klicke auf **„+“ > „New Run Script Phase“**
    
- Ziehe die neue Phase **vor „Compile Sources“**

```
echo "🏗 Setze GoogleService-Info.plist anhand Build-Konfiguration..."

FLAVOR=$(echo "${CONFIGURATION}" | sed -E 's/(Dev|Prod)(Debug|Release)/\1/')
SRC="${PROJECT_DIR}/firebase/${FLAVOR,,}/GoogleService-Info.plist"
DEST="${PROJECT_DIR}/Runner/GoogleService-Info.plist"

if [ ! -f "$SRC" ]; then
  echo "❌ Plist-Datei nicht gefunden für Flavor: $FLAVOR"
  exit 1
fi

cp -f "$SRC" "$DEST"
echo "✅ $SRC → $DEST"

# ✅ Jetzt Validierung
echo "🔍 Prüfe auf gültige Firebase-Konfiguration..."
if ! plutil -lint "$DEST"; then
  echo "❌ plist ist ungültig!"
  exit 1
fi

# Optional: inhaltliche Prüfung auf z. B. Projekt-ID
if ! plutil -p "$DEST" | grep -q '"PROJECT_ID"'; then
  echo "⚠️ Warnung: PROJECT_ID nicht gefunden – ist das die richtige Datei?"
fi

```

Iphone an USB anhängen, Entwicklermodus aktivieren in den Einstellungen unter Datenschutz und Sicherheit, im Xcode unter Window > Devices and Simulators

XCode Settings Accounts - anmelden mit Apple ID

![[Pasted image 20250621143350.png|300]]
Account bei Team eintragen

![[Pasted image 20250621143446.png|300]]
Mac Passwort eingeben

```
gernot@MacBook-Air-von-Gernot aitrailsgo % cd ios 
gernot@MacBook-Air-von-Gernot ios % pod install

```

im Podfile:
```
platform :ios, '13.0'
```

danach

```
cd ios
flutter clean
flutter pub get
pod install
```

unter ios/Flutter die Files
devdebug, devrelease, proddebug und prodrelease.xcconfig anpassen.

z.B. im prodrelease.xcconfig so:
```
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.prodrelease.xcconfig"  
#include "Generated.xcconfig"
```
Am Iphone unter
`Einstellungen` → `Allgemein` → **VPN & Geräteverwaltung** 
auf App AI Trails GO vertrauen drücken

## Doku vom Chat GPT 

# 📱 iOS Build-Setup für Flutter-Projekt mit Firebase, Flavors und Location

## 1. 🔧 Flutter Projekt vorbereiten
- Android funktioniert bereits mit Flavors (`dev`, `prod`)
- iOS benötigt noch Setup

---

## 2. 🍎 Firebase für iOS einrichten
- Firebase-Projekt um iOS-App ergänzen:
  - Bundle Identifier: z. B. `com.aitrailsgo.app`
- `GoogleService-Info.plist` herunterladen (für jede Flavor-Umgebung separat)

---

## 3. 🗂️ Struktur im Projekt anlegen
Im Verzeichnis `ios/`:

```
firebase/
├── dev/
│   └── GoogleService-Info.plist
├── prod/
│   └── GoogleService-Info.plist
```

---

## 4. 📝 Script zur Plist-Auswahl hinzufügen
In Xcode → "Runner" Target → *Build Phases* → *+* → *New Run Script Phase*

**Script-Inhalt:**
```bash
#!/bin/bash

FLAVOR=$(echo "${CONFIGURATION}" | sed -E 's/(Dev|Prod)(Debug|Release)/\1/')
SRC="${PROJECT_DIR}/firebase/${FLAVOR,,}/GoogleService-Info.plist"
DEST="${PROJECT_DIR}/Runner/GoogleService-Info.plist"

if [ ! -f "$SRC" ]; then
  echo "❌ Plist-Datei nicht gefunden für Flavor: $FLAVOR"
  exit 1
fi

cp -f "$SRC" "$DEST"
echo "✅ $SRC → $DEST"

# Validierung
plutil -lint "$DEST"
```

✅ Dieser Schritt ersetzt das manuelle Kopieren oder Setzen eines Symlinks.

---

## 5. 🔑 Code Signing & Team einrichten (Xcode)
- Öffne `ios/Runner.xcworkspace` in Xcode
- Wähle das richtige Team unter **Signing & Capabilities**
- „Automatically manage signing“ aktivieren

---

## 6. 🍭 CocoaPods Abhängigkeiten aktualisieren
Im `ios/Podfile` sicherstellen:
```ruby
platform :ios, '13.0'
```

Dann im Terminal:
```sh
cd ios
pod install
```

---

## 7. 📦 Xcode-Projekt mit Pods verbinden
Wenn Fehlermeldungen à la „base config not set“ erscheinen:

### In den `.xcconfig` Dateien:
Am Ende hinzufügen:
```xcconfig
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.${CONFIGURATION}.xcconfig"
```

Beispiel für `Flutter/Debug.xcconfig`:
```xcconfig
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.devdebug.xcconfig"
```

---

## 8. 📍 Standortberechtigungen in Info.plist setzen
In `ios/Runner/Info.plist` einfügen:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Die App benötigt Zugriff auf deinen Standort.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Standortzugriff wird für Hintergrundnutzung benötigt.</string>
```

---

## 9. 📲 iPhone für Entwicklung vertrauen
Auf dem Gerät:
- **Einstellungen → Allgemein → VPN & Geräteverwaltung**
- Developer-Zertifikat **vertrauen**

---

## ✅ 10. Build & Run
- Stelle das gewünschte Scheme ein (z. B. `DevDebug`)
- Klicke auf ▶️ Run in Xcode
- App wird gebaut, deployed und gestartet

---

## ✅ Ergebnis
- App startet auf dem echten Gerät
- Firebase ist konfiguriert
- Standortzugriff funktioniert
- Flavor wird berücksichtigt
