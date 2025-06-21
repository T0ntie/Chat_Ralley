# 🧰 Flutter App Setup unter macOS (Apple Silicon)

Dies ist die Zusammenfassung aller Schritte, um ein bestehendes Flutter-Projekt von Windows auf macOS (Apple Silicon – z. B. M3 MacBook Air) erfolgreich zu migrieren und lauffähig zu machen.

---

## 🔧 Systemvoraussetzungen

- macOS 15.5 (Sonoma oder neuer)
- Apple Silicon (ARM64, z. B. M1–M3)
- Admin-Zugriff auf das System
- Bestehendes Flutter-Projekt mit `flavors` & `firebase_options.dart`

---

## 1. 📦 Grundinstallation

### Homebrew installieren
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Terminalkonfiguration (`~/.zprofile`)
```bash
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

---

## 2. 🛠 Flutter & Tools

### Flutter installieren
```bash
brew install flutter
```

### Flutter PATH prüfen
```bash
flutter --version
```

### Android Studio installieren
Von [https://developer.android.com/studio](https://developer.android.com/studio) oder via DMG.

---

## 3. ✅ Android Setup

### Android SDK installieren
- Android Studio öffnen → **Preferences** → `Languages & Frameworks` → `Android SDK`
- Unter **SDK Tools**:
  - ☑️ Android SDK Command-line Tools (latest)
  - ☑️ Android SDK Platform-Tools
  - ☑️ Android Emulator

### Lizenzen akzeptieren
```bash
flutter doctor --android-licenses
```

---

## 4. 🍎 macOS/iOS Vorbereitung (optional)

### Xcode installieren
- Aus dem Mac App Store: **Xcode**
- Danach im Terminal:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### CocoaPods installieren
```bash
sudo gem install cocoapods
```

---

## 5. 🔌 Firebase & Flavors

### Firebase CLI
```bash
brew install firebase-cli
firebase login
```

### FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
flutterfire --version
```

📝 *Keine neuen `firebase_options.dart` generieren, sondern bestehende übernehmen.*

---

## 6. 🧪 Projekt aus Git laden

```bash
git clone <dein-projekt>
cd <dein-projekt>
flutter pub get
```

Optional: Android Emulator starten oder physisches Gerät via USB (USB-Debugging am Gerät freigeben).

---

## 7. 🧠 Wichtig: Schlüsseldateien

Falls `key.properties` fehlt:
```kotlin
// in android/app/build.gradle.kts:
val keystorePropertiesFile = rootProject.file("../key.properties")
```

Stelle sicher, dass `key.properties` lokal vorhanden ist, aber nicht im Git-Repository (→ .gitignore).

---

## 8. 🚀 Build & Run

- Android Studio öffnen
- `main.dart` laden
- Gerät auswählen (USB oder Emulator)
- `Run` > `Run main.dart`

---

## 9. 🛠 DevTools

- Flutter DevTools werden automatisch in Android Studio geladen.
- Alternativ:
```bash
flutter pub global run devtools
```

---

## 💡 Troubleshooting

| Problem | Lösung |
|--------|--------|
| `Dart SDK not configured` | Flutter-Plugin aktivieren, ggf. Projekt neu öffnen |
| DevTools Timeout | Ignorierbar, wenn DevTools im Studio funktionieren |
| Gerät wird nicht erkannt | USB-Debugging erneut autorisieren, ggf. anderes Kabel |
| Flavors funktionieren nicht | `--flavor` beim Run/Build verwenden |
| Firebase nicht erreichbar | `firebase_options.dart` und `google-services.json` prüfen |

---

## 🧾 Nützliche Flutter-Kommandos

```bash
flutter clean
flutter pub get
flutter doctor -v
flutter run --flavor dev
flutter build apk --flavor prod
```

---

## ✅ Fazit

Mit diesen Schritten ist ein vollständiges Flutter-Projekt (inkl. Firebase, Flavors, Android & macOS Support) einsatzbereit auf einem neuen Mac – inklusive Debugging, DevTools & physischem Gerät.

