# Haushalts-App – Spezifikation

Stand: 6. November 2026

## 1. Ziel und Rahmen

Eine Haushaltsverwaltungs-App für zwei Personen (Garrit und Lia), crossplattform, mit gemeinsamer Einkaufsliste, Rezepten und Wochenplan. Später um weitere Module erweiterbar.

- Gebaut für den eigenen Haushalt. SaaS ist eine mögliche Ausbaustufe, aber kein Ziel.
- Der **Haushalt** ist von Anfang an die zentrale Einheit: Jedes Datum gehört genau einem Haushalt.
- Leitprinzip: **so einfach wie möglich**. Kein zusätzlicher Dienst im Kern.

### Offline-Definition

Im Supermarkt ohne Empfang muss Folgendes funktionieren: Liste lesen, Einträge abhaken, Einträge hinzufügen. Alles synchronisiert sich, sobald wieder Netz da ist. Konflikte werden pro Feld nach „letzter Schreibzugriff gewinnt“ aufgelöst.

## 2. Nicht-Ziele

Bewusst nicht Teil des Projekts (bis auf Weiteres):

- SaaS-Funktionen: Billing, Signup-Flows jenseits Google-Login, Admin-Oberflächen
- CRDTs oder eigene Sync-Engine
- Vorratsverwaltung mit Beständen und Mengen
- Kaufvorhersagen, Preisvergleiche
- Nährwerte, Schwierigkeitsgrade, Timer pro Schritt
- Feste Mahlzeiten-Slots (Frühstück/Mittag/Abend)
- Globale Lebensmitteldatenbank
- Von der AI frei erfundene Rezepte
- Plugin-System mit dynamisch nachladbaren Modulen
- Cloud Functions und Cloud Storage im MVP

## 3. Architekturentscheidungen

| Thema | Entscheidung | Begründung |
|---|---|---|
| Client | Expo (React Native) mit TypeScript, Development Build | Eine Sprache für App und Schema, Android/iOS/Web möglich |
| Backend | Firebase: Auth + Firestore | Offline-Cache, Schreib-Queue und Realtime eingebaut, kein zusätzlicher Dienst |
| Firebase-SDK | `react-native-firebase` | Das Web-SDK hat in React Native keine echte Offline-Persistenz |
| Login | Nur Google Sign-In | Beide nutzen Android, kein Passwort nötig |
| Firestore-Region | `europe-west3` (Frankfurt) | **Nicht nachträglich änderbar** |
| Tarif | Spark (kostenlos) | Kein Bedarf an Functions oder Storage im MVP |
| Umgebungen | Zwei Projekte: `dev` und `prod`, lokal Firebase Emulator | Keine Tests an der produktiv genutzten Liste |
| Rezeptformat | schema.org/Recipe plus dokumentierte Erweiterung | Etablierter Standard, Rezeptseiten liefern ihn bereits |
| Schema-Definition | Einmal in Zod, daraus JSON Schema generiert | Eine Quelle der Wahrheit für App, n8n und LLM-Ausgabe |
| AI/Automatisierung | n8n als optionaler Zulieferer | App funktioniert vollständig ohne n8n |
| Verteilung | Google Play, interner Test-Track; EAS Build; EAS Update | Normale Installation und automatische Updates, schnelle Hotfixes |

## 4. Grundregeln

Diese Regeln gelten für den Kern und jedes Modul:

1. **Alles liegt unter `households/{householdId}/`.** Keine haushaltsübergreifenden Daten außer Einladungen.
2. **Einträge werden angehängt, Summen und Zustände berechnet.** Mengen auf der Einkaufsliste, Salden, Fortschritt werden nie als gemeinsam bearbeitetes Feld gespeichert. Neue Dokumente kollidieren offline nie.
3. **Module verweisen auf Personen (`personId`), nie direkt auf Accounts (`uid`).**
4. **Module ändern keine Daten anderer Module.** Einzige Ausnahme: Die Einkaufsliste stellt eine definierte Funktion zum Hinzufügen bereit (siehe 6.4).
5. **Alles, was von außen kommt (URL-Import, n8n), ist zuerst ein Entwurf** und wird vor dem Speichern geprüft.

## 5. Datenmodell (Firestore)

### Übersicht

```
households/{householdId}
  people/{personId}
  ingredients/{ingredientId}
  shoppingItems/{itemId}
  recipes/{recipeId}
  recipeDrafts/{draftId}
  mealPlanEntries/{entryId}
  private/integration
invites/{code}
```

### Typen

```ts
type Unit =
  | 'g' | 'kg' | 'ml' | 'l'
  | 'stk' | 'bund' | 'dose' | 'packung'
  | 'el' | 'tl' | 'prise';

// Umrechnung nur innerhalb einer Dimension:
// Masse: g <-> kg, Volumen: ml <-> l. Alle anderen Einheiten werden nie umgerechnet.
// Gespeichert wird in Basiseinheit (g, ml), angezeigt sinnvoll gerundet (1500 g -> 1,5 kg).

interface Household {
  name: string;
  memberUids: string[];        // Zugriff, Grundlage der Security Rules
  activeModules: string[];     // z. B. ['shopping', 'recipes', 'mealplan']
  deletedAt?: Timestamp;       // Soft Delete, wenn das letzte Mitglied verlässt
  createdAt: Timestamp;
}

interface Person {
  displayName: string;
  uid?: string;                // verknüpfter Account; fehlt bei Gästen ohne App
}

interface Ingredient {
  name: string;
  nameNormalized: string;      // klein, getrimmt, für Abgleich
  aliases: string[];           // normalisiert
  category: string;            // z. B. 'Obst & Gemüse', 'Kühlregal', 'Drogerie'
  defaultUnit?: Unit;
  pantryStaple: boolean;       // Grundvorrat: wird nie automatisch auf die Liste gesetzt
}

type ShoppingSource =
  | { type: 'manual' }
  | { type: 'mealPlan'; mealPlanEntryId: string; recipeId: string };

interface ShoppingItem {
  ingredientId: string;
  amount?: number;             // in Basiseinheit; optional ("Brot" ohne Menge ist gültig)
  unit?: Unit;
  source: ShoppingSource;
  checkedAt?: Timestamp | null;
  checkedBy?: string;          // personId
  createdAt: Timestamp;
  createdBy: string;           // personId
}

type MealPlanStatus = 'suggested' | 'planned' | 'transferred' | 'cooked';

interface MealPlanEntry {
  recipeId?: string;           // gesetzt bei Rezept
  recipeDraftId?: string;      // gesetzt, wenn n8n ein neues Rezept vorschlägt
  title?: string;              // Freitext ohne Rezept ("Pizza bestellen")
  servings?: number;
  date?: string;               // 'YYYY-MM-DD', optional
  status: MealPlanStatus;
  suggestedBy?: 'n8n';
  createdAt: Timestamp;
}

interface Invite {
  householdId: string;
  createdBy: string;           // uid
  expiresAt: Timestamp;        // wenige Stunden
  usedAt?: Timestamp;
}
```

Rezepte und Rezept-Entwürfe: siehe Abschnitt 7.

### Security Rules (Grundidee)

```
function isMember(hid) {
  return request.auth != null
    && request.auth.uid in get(/databases/$(database)/documents/households/$(hid)).data.memberUids;
}

match /households/{hid}/{document=**} {
  allow read, write: if isMember(hid);
}
```

Beitritt per Einladung: Ein Nicht-Mitglied darf nur seine eigene `uid` zu `memberUids` hinzufügen und muss dabei den Einladungscode mitschreiben. Die Rule prüft per `get()` auf `invites/{code}`, dass `householdId` passt und `expiresAt` in der Zukunft liegt.

## 6. Features

### 6.1 Haushalt, Personen, Einladung

- Beim ersten Login wird automatisch ein Haushalt angelegt, mit einer Person für den Nutzer.
- Einladen: Mitglied erzeugt einen kurzen Code oder QR-Code. Die andere Person meldet sich an und gibt den Code ein.
- Ein beim ersten Login automatisch angelegter, noch leerer Haushalt wird beim Beitritt verworfen.
- MVP: ein Haushalt pro Nutzer. Das Modell erlaubt mehrere (Liste `memberUids`).
- Personen ohne Account (z. B. Freunde im Urlaub) können angelegt werden. Tritt eine solche Person später bei, wird `uid` an ihrer bestehenden Person gesetzt; alle bisherigen Einträge gehören damit automatisch ihr.

### 6.2 Einkaufsliste (MVP)

- Eingabe als Freitext, z. B. „2 l Milch“. Ein **gemeinsamer Parser** zerlegt in Menge, Einheit und Name. Derselbe Parser wird beim Rezept-Import verwendet.
- Der Name wird über `nameNormalized` und `aliases` im Zutaten-Katalog gesucht. Gibt es keinen Treffer, wird ein neuer Katalog-Eintrag angelegt und die Kategorie einmalig abgefragt.
- Doppelte Katalog-Einträge können zusammengeführt werden; einer wird zum Alias des anderen.
- **Gespeichert wird ein Eintrag pro Herkunft. Zusammengefasst wird nur in der Anzeige:**
  - Gruppierung nach `ingredientId`, innerhalb davon Summe pro Dimension.
  - Nicht umrechenbare Einheiten erscheinen nebeneinander: „Petersilie – 200 g + 1 Bund“.
  - Gruppe ist aufklappbar und zeigt die Quellen.
- Sortierung nach Kategorie.
- Abhaken einer Gruppe setzt `checkedAt` auf allen offenen Einträgen der Gruppe.
- Braucht ein neues Rezept eine bereits abgehakte Zutat, entsteht ein neuer, offener Eintrag.

### 6.3 Rezepte

- **Import per URL, komplett in der App:** HTML laden, schema.org-JSON-LD auslesen, Zutatenzeilen mit dem gemeinsamen Parser zerlegen, auf den Katalog abbilden. Ergebnis ist ein Entwurf im Prüf-Bildschirm.
- Portionen skalieren: Jedes Rezept hat Basis-Portionen; skaliert wird in der Anzeige und bei der Übernahme auf die Einkaufsliste.
- **Kochmodus:** ein Schritt pro Bildschirm, große Schrift, Display bleibt an, Wischen zum nächsten Schritt. Oben die Zutaten des Schritts. Fehlt die Verknüpfung im Rezept, wird sie per Namensabgleich im Schritttext ermittelt.
- Bild: Link aus den schema.org-Daten. Eigene Fotos erst später (erfordert Storage und Blaze-Tarif).

### 6.4 Wochenplan

- Liste geplanter Gerichte, Datum optional. Freitext-Einträge ohne Rezept sind erlaubt und erzeugen keine Einkaufsliste-Einträge.
- Status-Übergänge:
  - `suggested` → `planned` (annehmen) oder löschen
  - `planned` → `transferred` (auf Einkaufsliste übernommen)
  - `transferred` → `cooked`
- **Übernahme auf die Einkaufsliste:**
  1. Alle Einträge mit Status `planned` und Rezept sammeln.
  2. Zutatenmengen mit `servings / recipe.servings` skalieren.
  3. Zutaten mit `pantryStaple: true` weglassen.
  4. Prüfschritt: Liste der Zutaten mit Häkchen, abwählen, was noch da ist.
  5. Pro Zutat und Plan-Eintrag ein `ShoppingItem` mit `source.type = 'mealPlan'` anlegen.
  6. Plan-Einträge auf `transferred` setzen.
- Wird ein Plan-Eintrag entfernt, werden seine Einkaufsliste-Einträge gelöscht. Manuelle Einträge bleiben unberührt.
- Die Einkaufsliste stellt dafür eine Funktion bereit, z. B. `addShoppingItems(items, source)` und `removeShoppingItemsBySource(mealPlanEntryId)`. Andere Module schreiben nie direkt in `shoppingItems`.

## 7. Rezeptformat

### Vertrag

**Jede Quelle liefert ein schema.org/Recipe als JSON-LD.** URL-Import, n8n-Foto-Parsing und alle späteren Quellen nutzen dasselbe Format. Eine neue Quelle anzubinden heißt immer: schema.org/Recipe erzeugen und als Entwurf ablegen.

### Gespeicherte Felder

Aus schema.org (Auszug):

- `name`, `description`
- `image` (URL)
- `recipeYield`
- `recipeIngredient: string[]` (Originalzeilen, bleiben erhalten)
- `recipeInstructions: HowToStep[]`
- `isBasedOn` (Quell-URL)

Erweiterung unter einem eigenen Schlüssel, z. B. `ext`:

```ts
interface RecipeExtension {
  servings: number;                    // Basis-Portionen, normalisiert aus recipeYield
  ingredients: Array<{
    raw: string;                       // Originalzeile aus recipeIngredient
    ingredientId: string | null;       // null nur im Entwurf, wenn noch nicht zugeordnet
    suggestedName?: string;            // Vorschlag für neuen Katalog-Eintrag
    amount?: number;                   // pro Basis-Portionen, in Basiseinheit
    unit?: Unit;
    stepIndices?: number[];            // optional: in welchen Schritten gebraucht
  }>;
}
```

### Entwürfe

```ts
interface RecipeDraft {
  recipe: SchemaOrgRecipe & { ext: RecipeExtension };
  source:
    | { type: 'url'; url: string }
    | { type: 'n8n'; input: 'image' | 'text' | 'url' | 'search' };
  status: 'pending' | 'accepted' | 'discarded';
  createdAt: Timestamp;
}
```

Beim Annehmen werden alle `ingredientId: null` aufgelöst (vorhandene Zutat wählen oder neue anlegen), dann wird ein `Recipe` gespeichert.

### Schema als Code

- Definition einmal in Zod (z. B. Paket `schema/` im Repo).
- Daraus generiertes JSON Schema für n8n und als Structured-Output-Schema für LLMs.
- Die Dokumentation des Formats ist dieses Schema plus dieser Abschnitt.

## 8. n8n-Integration (nach dem MVP)

### Muster

1. Die App (oder eine andere Quelle) ruft einen n8n-Webhook auf und wartet nicht auf das Ergebnis.
2. n8n verarbeitet und schreibt per Service-Account direkt in Firestore.
3. Die App zeigt das Ergebnis per Realtime-Listener an.

### Absicherung

- Der Service-Account umgeht die Security Rules. Deshalb hat jeder Haushalt ein geheimes Token in `households/{id}/private/integration`.
- Die App schickt `householdId` und Token mit; n8n liest das Dokument und vergleicht, bevor es schreibt.
- n8n schreibt ausschließlich in den Haushalt des geprüften Tokens.

### Geplante Workflows

**Rezept parsen**
- Eingabe: Foto, Text oder URL
- Ausgabe: `recipeDrafts` mit vollständigem schema.org/Recipe inklusive `ext` (gern mit `stepIndices`)

**Wochenplan vorschlagen**
- Eingabe: Anzahl Gerichte und freie Vorgabe, z. B. `{ count: 4, constraints: "ballaststoffreich" }`
- Ausgabe: `mealPlanEntries` mit Status `suggested`
- Quellen, in dieser Rangfolge:
  1. Eigene Rezeptsammlung. Abwechslung über die zuletzt als `cooked` markierten Einträge.
  2. Nur wenn die Sammlung nicht reicht: Web-Suche nach echten Rezeptseiten, Import per schema.org, Ablage als `recipeDraft`. Der Plan-Eintrag verweist dann über `recipeDraftId` darauf.

## 9. Modul-Konvention

Ein Modul besteht aus:

- einem Ordner im Code (Screens, Logik)
- einer oder mehreren Collections unter `households/{id}/`
- optional eigenen n8n-Workflows nach dem Muster aus Abschnitt 8
- einem Eintrag in `household.activeModules`

Der Kern umfasst nur Login, Haushalt, Personen und Navigation.

### Absehbare Module (nicht im MVP)

| Modul | Skizze | Interaktion |
|---|---|---|
| Notizen | Eigene Collection | Optionaler Verweis auf Rezept o. Ä. |
| Finanzen/Schulden | Jede Ausgabe ein Eintrag (wer zahlte, Aufteilung auf `personId`s); Salden nur berechnet | „Ausgabe erfassen?“ nach abgeschlossenem Einkauf; relevant für Urlaubs-Haushalte mit Freunden |
| Pflanzen gießen | Wiederkehrende Aufgaben, lokale Benachrichtigungen auf dem Gerät | Baustein „wiederkehrende Aufgabe“ wird erst herausgelöst, wenn ein zweites Modul (z. B. Putzplan) ihn braucht |
| Haushalts-Switcher | Erstellen, Wechseln, Verlassen; letztes Mitglied → `deletedAt` | Aktiver Haushalt pro Gerät; relevant für Urlaub mit Freunden |

## 10. Technische Hinweise

- **Firestore-Schreibvorgänge im UI nicht `await`en.** Das Promise löst erst nach Server-Bestätigung auf und hängt offline. Lokaler Cache und Listener zeigen die Änderung sofort.
- Offline-Persistenz ist in `react-native-firebase` standardmäßig aktiv. Der Cache ist erst nach dem ersten Online-Laden gefüllt.
- Transaktionen funktionieren offline nicht und sollten in Offline-Pfaden (Einkaufsliste) nicht verwendet werden.
- Google Sign-In über `@react-native-google-signin/google-signin` mit Firebase Auth.
- Soll die App für iOS in den App Store, ist zusätzlich „Sign in with Apple“ nötig.
- Beim Wechsel auf den Blaze-Tarif sofort ein Budget-Limit mit Alarm setzen.

## 11. Roadmap

Jeder Schritt ist erst fertig, wenn sein Erfolgskriterium im Alltag erfüllt ist.

1. **Einkaufsliste mit Login und Einladungscode**
   - Umfang: Haushalt, Personen, Katalog, Parser, Kategorien, Offline
   - Erfolg: Lia nutzt die App statt der bisherigen Listen-Lösung.
2. **Rezepte**
   - Umfang: URL-Import mit Prüf-Bildschirm, Portionen, Kochmodus
   - Erfolg: Ihr kocht mindestens ein Rezept aus der App.
3. **Wochenplan**
   - Umfang: Plan-Einträge, Grundvorrat, Übernahme mit Prüfschritt
   - Erfolg: Eine komplette Woche läuft über die App.
4. **n8n-Workflows**
   - Umfang: Foto- und Text-Parsing, automatischer Wochenplan
   - Erfolg: Ein Plan aus „4 Gerichte, ballaststoffreich“ wird angenommen und gekocht.
5. **Weitere Module**
   - Umfang: Haushalts-Switcher, Finanzen, Notizen, Pflanzen
   - Erfolg: jeweils bei Bedarf festlegen

## 12. Offene Punkte

Keiner davon blockiert Schritt 1.

- Welches LLM n8n für Parsing und Planvorschläge nutzt.
- Reihenfolge der Kategorien: global oder pro Laden.
- Wann und wie abgehakte Einträge von der Liste verschwinden (automatisch nach Zeit oder per „Erledigte leeren“).
- Ob mehrtägiges Offline-Arbeiten (z. B. Urlaub ohne Netz) unterstützt werden muss, das über das Supermarkt-Szenario hinausgeht.
- Ob neben Abendessen auch Mittagessen oder Meal Prep geplant werden.
