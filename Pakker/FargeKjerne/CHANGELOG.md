# Endringer

API-endringer per versjon, for dem som bygger på pakken (som Kolorist utdanning). Nyeste først.

## 0.2.0 – 2026-10-05

- **Visningstilstand i delingslenker:** `DeltVisning` og `DeltInnhold.visning` (nøkkel `vs` i lenkeformatet) – fane,
  modus i Studio, fargemodell, del av Vurdering, bakgrunn i kontrastsjekken, `bruk` (ta innholdet i bruk direkte) og
  `presentasjon`. Alle felt er valgfrie; ukjente verdier ignoreres, og en ugyldig visningstilstand droppes uten at innholdet
  går tapt. Formatversjonen er fortsatt 1 – eldre lesere (og visningssiden på kolorist.no) ignorerer feltet.
- `Delingslenke.appLenke(_:)`: lenke som åpner appen direkte (`kolorist://l#…`), med samme innhold som `lenke(_:)`.
- `DeltInnhold.init` har fått parameteren `visning:` (standard `nil`) – eksisterende kall virker uendret.

## 0.1.1 – 2026-10-05

- Filnavn uten æ, ø og å (`Verktoy/`, `FargebibliotekSokTests.swift`), så SwiftPM kan hente pakken over git. 0.1.0 kan
  ikke brukes som avhengighet – bruk 0.1.1 eller nyere.

## 0.1.0 – 2026-10-05

Første utgivelse som egen pakke (speilet fra Kolorist 1.3 under utvikling).

- Produktene `FargeKjerne`, `FargeMaaling` og `FargeKI`.
- `Fargemodell.Komponent.visning` (`.tall`, `.prosent`, `.kanal`): hvordan en komponent vises – CMYK, metning og
  lysstyrke i prosent, RGB som kanal (0–255 i sRGB, ellers 0–1 i Kolorist). Eksisterende felt er uendret.
- `Testvektorer/Fargeregning.json` med testvektorer for fargeregningen.
