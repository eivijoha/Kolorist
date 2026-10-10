# App Store Connect – Kolorist 1.3.1

Retteversjon for iOS, iPadOS og macOS (2026-10-10): **APCA er tatt ut av appen.** APCA (Myndex) er lisensbelagt – lisensen
gjelder bare nettinnhold under W3C-avtalen, og kommersiell bruk krever egen avtale – og Kolorist skal ikke ha
lisensbelagte modeller.

- Kontrastsjekken har WCAG 2.2 og LRV (valget APCA, Lc og «Rett opp» etter APCA er fjernet).
- Tekst på fargeflater er sort eller hvit etter høyest kontrastforhold etter WCAG 2 (som før 1.3).
- Skriftfarger i paletter og designsystemet velges etter høyest WCAG-kontrast; Lc vises ikke lenger.
- Metoder og kilder, nettsiden (alle versjoner) og App Store-tekstene nevner ikke APCA.

Resten av tekstene er som i `Dokumentasjon/1.3/AppStore.md` (rettet uten APCA). **Oppdater i App Store Connect** for
både iOS og macOS: reklameteksten, beskrivelsen og Notes for App Review – alle nevnte APCA.

## Nytt i denne versjonen (iOS og macOS)

```
• Kontrastsjekken bygger nå på WCAG 2.2 og LRV, standardene regelverket for universell utforming viser til.
• Tekst på fargeflater velges som sort eller hvit etter WCAG-kontrast.
• Mindre rettelser.
```

```
• The contrast check is now based on WCAG 2.2 and LRV, the standards accessibility regulations refer to.
• Text on colour fields is chosen as black or white by WCAG contrast.
• Minor fixes.
```

## Reklametekst (170) – oppdatert, uten APCA

```
Fra palett til designsystem: toneskalaer med lik kontrast, farger for lys og mørk modus og kontroll etter WCAG og LRV – rett inn i verktøyene du bruker.
```

```
From palette to design system: tone scales with consistent contrast, colours for light and dark mode, and checks by WCAG and LRV – straight into your tools.
```

Mac (norsk/engelsk):

```
Fra palett til designsystem: toneskalaer med lik kontrast, farger for lys og mørk modus, kontroll etter WCAG og LRV – plukk fra hele skjermen og dra fargene videre.
```

```
From palette to design system: tone scales with consistent contrast, light and dark mode, checks by WCAG and LRV – pick from anywhere on screen and drag colours on.
```

## Før du sender inn

- [ ] `MARKETING_VERSION` 1.3.1, `CURRENT_PROJECT_VERSION` 13 (satt i prosjektet).
- [ ] Ny versjon 1.3.1 for iOS og macOS, med «Nytt i denne versjonen» over.
- [ ] Reklametekst, beskrivelse og Notes for App Review byttet til tekstene uten APCA (`Dokumentasjon/1.3/AppStore.md`).
- [ ] iOS: 1.3 ligger til gjennomgang – trekk den («Remove from Review») og send inn 1.3.1 i stedet, eller send 1.3.1
      rett etter at 1.3 er godkjent.
- [x] Nettsiden uten APCA (rota, /neste/ og historisk/), lastet opp 2026-10-10.
- [x] CloudKit-skjemaet er uendret siden 1.3.
