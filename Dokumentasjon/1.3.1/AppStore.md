# App Store Connect – Kolorist 1.3.1

Retteversjon for iOS, iPadOS og macOS (2026-10-10): **APCA og Munsell er tatt ut av appen.** APCA (Myndex) er
lisensbelagt – lisensen gjelder bare nettinnhold under W3C-avtalen, og kommersiell bruk krever egen avtale. Munsell er et
registrert varemerke (X-Rite), og de ekstrapolerte renotasjonsdataene har uklart opphav. Kolorist skal ikke ha
lisensbelagte modeller eller data, eller bruke andres varemerker som navn på funksjoner.

- Kontrastsjekken har WCAG 2.2 og LRV (valget APCA, Lc og «Rett opp» etter APCA er fjernet).
- Tekst på fargeflater er sort eller hvit etter høyest kontrastforhold etter WCAG 2 (som før 1.3).
- Skriftfarger i paletter og designsystemet velges etter høyest WCAG-kontrast; Lc vises ikke lenger.
- Fargemodellen og fargesirkelen med kulør, valør og kroma (Munsell) er fjernet, og feltet for fargeverdi leser ikke
  lenger notasjonen («5R 4/14»). Lagrede farger og delingslenker med modellen åpnes som vanlige farger.
- Metoder og kilder, nettsiden (alle versjoner) og App Store-tekstene nevner verken APCA eller Munsell.

Resten av tekstene er som i `Dokumentasjon/1.3/AppStore.md` (rettet uten APCA og Munsell). **Oppdater i App Store
Connect** for både iOS og macOS: reklameteksten, beskrivelsen, nøkkelordene og Notes for App Review – de nevnte APCA eller
Munsell.

## Nytt i denne versjonen (iOS og macOS)

```
• Spisset utvalg av modeller: kontrastsjekken bygger på WCAG 2.2 og LRV, standardene regelverket for universell utforming viser til, og fargemodellen og fargesirkelen med kulør, valør og kroma er tatt ut.
• Tekst på fargeflater velges som sort eller hvit etter WCAG-kontrast.
• Mindre rettelser.
```

```
• A more focused set of models: the contrast check is based on WCAG 2.2 and LRV, the standards accessibility regulations refer to, and the colour model and colour wheel with hue, value and chroma have been removed.
• Text on colour fields is chosen as black or white by WCAG contrast.
• Minor fixes.
```

## Notes for App Review (iOS og macOS)

Kort og saklig – hva som er endret, rammet inn som et spisset utvalg av modeller:

```
1.3.1 refines the set of models included in the app. The contrast check now uses WCAG 2.2 and LRV only, and one colour model (hue, value and chroma) has been removed together with its colour wheel. No new features, permissions or data collection.
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

## Skjermbilder

Hele settet for 1.3.1 ligger i `Dokumentasjon/1.3.1/Skjermbilder/`, uten APCA og Munsell (kontrollert med
tekstgjenkjenning 2026-10-10):

| Mappe | Enhet | Størrelse |
|---|---|---|
| `nb/`, `en/` | iPhone 6,5″ | 1284 × 2778 |
| `iphone63-nb/`, `iphone63-en/` | iPhone 6,3″ | 1206 × 2622 |
| `ipad-nb/`, `ipad-en/` | iPad 13″ | 2064 × 2752 |
| `mac-nb/`, `mac-en/` | Mac | 2880 × 1800 |
| `header-*.png`, `sokeresultat-*.png` | Header og søkeresultat | |

Endret siden 1.3: Studio-bildet i alle settene (`studio.png`, `5-studio.png` for 6,3″) – metodelinja nevnte Munsell.

## Før du sender inn

- [ ] `MARKETING_VERSION` 1.3.1, `CURRENT_PROJECT_VERSION` 13 (satt i prosjektet).
- [ ] Ny versjon 1.3.1 for iOS og macOS, med «Nytt i denne versjonen» over.
- [ ] Studio-bildet byttet i alle settene (iPhone 6,5″ og 6,3″, iPad, Mac; norsk og engelsk).
- [ ] Reklametekst, beskrivelse, nøkkelord og Notes for App Review byttet til tekstene uten APCA og Munsell
      (`Dokumentasjon/1.3/AppStore.md`; nøkkelordet Munsell er byttet med harmoni/palette).
- [ ] iOS: 1.3 ligger til gjennomgang – trekk den («Remove from Review») og send inn 1.3.1 i stedet, eller send 1.3.1
      rett etter at 1.3 er godkjent.
- [x] Nettsiden uten APCA (rota, /neste/ og historisk/), lastet opp 2026-10-10.
- [ ] Nettsiden uten Munsell (rota, /neste/ og historisk/).
- [x] CloudKit-skjemaet er uendret siden 1.3.
