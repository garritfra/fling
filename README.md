# Fling

Haushalts-App für Garrit und Lia: gemeinsame Einkaufsliste, später Rezepte und Wochenplan.
Expo (React Native, TypeScript) + Firebase Auth/Firestore über `react-native-firebase`.

Die Spezifikation liegt in [`docs/spezifikation.md`](docs/spezifikation.md).
Umgesetzt ist **Roadmap-Schritt 1**: Einkaufsliste mit Google-Login, Haushalt, Personen,
Einladungscode, Zutaten-Katalog, Parser, Kategorien und Offline-Betrieb.

## Struktur

```
schema/                  Zod-Datenmodell (einzige Quelle der Wahrheit)
firestore.rules          Security Rules
src/app/                 Routen (Expo Router) – nur dünne Re-Exports
src/core/                Kern: Firebase, Login, Session, Haushalt, Personen, Einladung
src/catalog/             Zutaten-Katalog (geteilt von allen Modulen)
src/lib/                 Reine Logik: Parser, Einheiten, Katalog-Abgleich, Kategorien
src/modules/shopping/    Modul Einkaufsliste (api.ts = öffentliche Schnittstelle für andere Module)
src/modules/index.ts     Modul-Registry (Tab pro Modul, gesteuert über household.activeModules)
test/unit/               Unit-Tests (vitest)
test/rules/              Security-Rules-Tests gegen den Firestore-Emulator
```

## Entwicklung

Voraussetzungen: Node 22, Java 21 (Firestore-Emulator), Android SDK für lokale Builds
oder ein EAS-Account für Cloud-Builds.

```bash
npm install
npm run typecheck && npm run lint
npm test                # Parser, Einheiten, Gruppierung, Katalog-Abgleich
npm run test:rules      # Security Rules im Emulator
```

### Firebase-Projekte

| Variante | `APP_VARIANT` | Firebase-Projekt | Android-Paket | Konfiguration |
|---|---|---|---|---|
| development (Standard) | `development` | neues `dev`-Projekt | `de.garritfra.fling.dev` | `firebase/dev/google-services.json` |
| production | `production` | `fling-list` | `de.garritfra.fling` | `firebase/prod/google-services.json` |

Einmalig für das **dev-Projekt**:

1. Firebase-Projekt anlegen, Firestore in **`europe-west3`** erstellen (nicht nachträglich änderbar).
2. Authentication → Google als Anbieter aktivieren.
3. Android-App `de.garritfra.fling.dev` registrieren, SHA-1 des Debug-/EAS-Keystores eintragen
   (`npx eas-cli credentials` zeigt den EAS-Fingerprint).
4. `google-services.json` nach `firebase/dev/google-services.json` legen.
5. `.firebaserc` um `"dev": "<projekt-id>"` ergänzen, Rules deployen:
   `npx firebase deploy --only firestore --project dev`.

Die Web-Client-ID für Google Sign-In wird beim Build automatisch aus der jeweiligen
`google-services.json` gelesen (siehe `app.config.ts`).

### App starten

Die App braucht einen Development Build (native Module), Expo Go reicht nicht.

```bash
npx expo run:android          # lokal bauen und installieren
npm start                     # Metro für den Development Build
```

### Mit Emulator

```bash
npx firebase emulators:start --project <dev-projekt-id>
EXPO_PUBLIC_USE_EMULATOR=true npm start
# Physisches Gerät statt Android-Emulator: EXPO_PUBLIC_EMULATOR_HOST=<IP des Rechners>
```

## Builds und Verteilung (EAS)

Einmalig: `npx eas-cli init`, dann die Projekt-ID als `EAS_PROJECT_ID` in den EAS-Umgebungsvariablen
und lokal setzen (aktiviert EAS Update in `app.config.ts`).

```bash
npx eas-cli build --profile development --platform android   # Dev-Client für dev-Projekt
npx eas-cli build --profile production --platform android    # AAB für Google Play
npx eas-cli submit --profile production --platform android   # interner Test-Track
npx eas-cli update --channel production                      # OTA-Hotfix
```

Der Production-Build nutzt dasselbe Paket `de.garritfra.fling` wie die bisherige Flutter-App
(letzter versionCode: 24). Vor dem ersten Upload den EAS-versionCode höher setzen:
`npx eas-cli build:version:set --platform android`.
Den SHA-1 des EAS-Upload-Keys bzw. des Play-App-Signing-Keys im Firebase-Projekt `fling-list` eintragen,
sonst schlägt Google Sign-In fehl.

## Hinweise

- **Rules erst beim Umstieg nach `fling-list` deployen.** Die neuen Rules ersetzen die der bisherigen
  App; deren Daten (`households/{id}/members`, `lists`) wären danach nicht mehr erreichbar.
  Bis dahin nur gegen das dev-Projekt und den Emulator arbeiten.
- Der Firestore-Emulator-Test nutzt `firebase@13.1.0` als devDependency. Die Version muss zu der von
  `@react-native-firebase/app` mitgebrachten passen, sonst lädt `@firebase/rules-unit-testing` zwei
  Kopien des compat-SDKs.
- iOS ist nicht eingerichtet (fehlende `GoogleService-Info.plist`, „Sign in with Apple“ für den App Store).
