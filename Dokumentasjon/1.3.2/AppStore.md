# App Store Connect – Kolorist 1.3.2

Retteversjon for iOS, iPadOS og macOS (2026-10-12): **riktig språk.** Kolorist ble vist på norsk på enheter som verken er
satt opp på norsk eller engelsk, fordi iOS og macOS faller tilbake til utviklingsspråket (norsk). Nå velger Kolorist
språket ved oppstart: norsk på enheter som er satt opp på norsk, svensk eller dansk, ellers engelsk. Har brukeren valgt
språk for Kolorist selv (Innstillinger › Kolorist › Språk), respekteres det. Se `Kolorist/App/Sprakvalg.swift`.

Alle andre tekster, skjermbilder og nøkkelord er som for 1.3.1 (`Dokumentasjon/1.3.1/AppStore.md`).

## Nytt i denne versjonen (iOS og macOS)

```
• Kolorist vises nå på engelsk på enheter som ikke er satt opp på norsk, svensk eller dansk.
```

```
• Kolorist now appears in English on devices not set up in Norwegian, Swedish or Danish.
```

## Notes for App Review

```
1.3.2 fixes the app language: devices set to a language other than Norwegian, Swedish or Danish now get English instead of Norwegian. No other changes.
```

## Før du sender inn

- [ ] Xcode på grenen `versjon-1.3.2`; `MARKETING_VERSION` 1.3.2, `CURRENT_PROJECT_VERSION` 15 (satt i prosjektet).
- [ ] Ny versjon 1.3.2 for iOS og macOS med teksten over; resten som 1.3.1.
