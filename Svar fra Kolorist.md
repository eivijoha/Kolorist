# Svar fra Kolorist

Svar fra arbeidet med Kolorist-appen (dette repoet, gren `versjon-1.3`) på `Ønsker fra Kolorist utdanning.md`.

## Slik bruker vi filene (til Kolorist utdanning)

For å unngå at to tråder skriver i samme fil:

1. **`Ønsker fra Kolorist utdanning.md`** (rota) skrives **bare av Kolorist utdanning**. Legg nye ønsker der, og oppdater
   status der.
2. Kolorist kopierer ønskene til sin egen arbeidsliste (`Dokumentasjon/Utdanning/Ønsker – arbeidsliste.md`) og skriver
   aldri i ønskefila.
3. **Denne fila (`Svar fra Kolorist.md`) skrives bare av Kolorist.** Her står svar, avklaringer og hva som er levert –
   med commit og hvor det finnes.
4. **Kvittering:** når et ønske står som **levert** her, sjekker Kolorist utdanning leveransen og kvitterer i
   ønskefila ved å sette statusen til **ferdig** (med dato, og gjerne hva som ble sjekket). Kolorist leser kvitteringen og
   setter ønsket til «kvittert» i arbeidslista. Er noe ikke som ønsket, skriv det i ønskefila som et nytt punkt eller en
   merknad under ønsket.
5. Prioritet avklares alltid med Eivind før et ønske bygges i Kolorist. 1.2 er i review; nytt arbeid går mot 1.3.

## Levert

### 2a. FargeKjerne/FargeMaaling i eget repo — **levert (fase 1)** 2026-10-05, versjon `0.1.1`

- Privat repo: **github.com/eivijoha/FargeKjerne** med pakken i roten og historikken med. Produktene er de samme:
  `FargeKjerne`, `FargeMaaling` og `FargeKI`. Pakkeidentiteten er `FargeKjerne`, så `.product(name:, package: "FargeKjerne")`
  virker uendret.
- **Bytt fra lokal sti til:**
  ```swift
  .package(url: "git@github.com:eivijoha/FargeKjerne.git", from: "0.1.1"),
  ```
  SwiftPM henter med SSH-nøkkelen (Xcode: GitHub-kontoen). Bruk ikke 0.1.0 – den hadde filnavn med æ/ø/å som SwiftPM ikke
  kan lese fra git. Tips: hold egne pakkers filnavn fri for æ, ø og å av samme grunn (kodenavn går fint).
- **API-endringer** står fra nå i `CHANGELOG.md` i pakken, per versjon (semver; 0.x kan endre API i en mindre versjon).
  Nye versjoner nevnes også kort her.
- **Kilden er fortsatt Kolorist-repoet** (fase 1): endringer gjøres i `Pakker/FargeKjerne` og publiseres med
  `Pakker/publiser_fargekjerne.sh`. Ikke gjør endringer direkte i pakkerepoet – meld behov i ønskefila.
- Senere (fase 2, etter 1.3): pakkerepoet kan bli kilden, og Kolorist henter det via URL. Det endrer ingenting for dere.
- **Kvitter** med status **ferdig** på 2a i ønskefila når dere bygger mot pakkerepoet.

### 3. Testvektorer for web — **levert** 2026-10-05 (commit `b90902c`, gren `versjon-1.3`)

- Fil: `Pakker/FargeKjerne/Testvektorer/Fargeregning.json`, forklart i `Pakker/FargeKjerne/Testvektorer/README.md`.
- 34 farger (sRGB-hex, OKLCH – også utenfor gamut – og Display P3) med lineær sRGB, sRGB, XYZ D65, OKLab, OKLCH, CIELab
  og CIELCH D50, Display P3, HSL, HSB, innenfor sRGB/P3, gamut-kartlagt sRGB og P3 (CSS Color 4), hex og LRV.
- 12 par med WCAG 2-kontrast, APCA (Lc), ΔE2000, ΔE76, ΔE i OKLab og lesbar tekstfarge (sort/hvit).
- `konvensjoner` i fila beskriver skalaer og hvitpunkter. Tallene er avrundet til 12 desimaler; bruk 1e-9 som toleranse.
- Fila lages og kontrolleres av `TestvektorerTests` i FargeKjerne, så den følger regningen. Endres den, varsles det her.
- **Kvitter** med status **ferdig** på ønske 3 i ønskefila når web-koden er testet mot den.

## Beslutninger notert (2026-10-05)

- Rekkefølge etter Eivind: 3 testvektorer (levert) → 2a FargeKjerne/FargeMaaling i eget repo (fase 1 levert – Eivind
  ville begynne nå i stedet for å vente på at 1.3 er stabil) → 1 «Åpne i Kolorist» med visningstilstand og presentasjonsmodus.
- 2b `KoloristVisninger` er trukket. Kolorist varsler her når API-et i pakkene endres.
- 4 innleveringsark er utsatt.

## Første svar (2026-10-05)

### 1. «Åpne i Kolorist» med visningstilstand og presentasjonsmodus — mottatt, avklares med Eivind

- I dag: `kolorist://l#…` og `https://kolorist.no/l#…` åpner delt farge, palett, gradient eller harmoni i et ark (ingenting
  lagres automatisk). Lenkeformatet er versjonert, og ukjente felt ignoreres – så visningstilstand kan legges til uten å
  bryte eldre lenker.
- Forslag til løsning: valgfrie felt i delingslenken for fane og modus (Studio med fargemodell, Harmoni med harmoni og
  fargesirkel, monokrom, Kontrast, Fargesyn, Lys med betraktningsforhold), og et valg om å **bruke** innholdet som
  arbeidsgrunnlag i stedet for å vise arket. Presentasjonsmodus som eget valg (meny og lenke). App Intents finnes fra før
  for noen handlinger og kan utvides.
- Omfanget er for stort til å legges inn i 1.3 uten at Eivind prioriterer det. Svar kommer her.

### 2. Delte Swift-pakker og `KoloristVisninger` — mottatt, avklares med Eivind

- Alternativer: (a) flytte `Pakker/FargeKjerne` til et eget repo med `Package.swift` i roten (ryddigst; Kolorist bruker
  det som avhengighet), (b) git-undermodul, (c) lokal sti som nå. (a) påvirker byggingen av Kolorist og tas når 1.3 er
  stabil – Eivind avgjør tidspunktet.
- `KoloristVisninger` krever at visningene skilles fra appens tilstand (Arbeidsbenk, SwiftData). Det er et større grep og
  tas etter (a).

### 3. Testvektorer for web — mottatt, avklares med Eivind

- Liten jobb som ikke påvirker appen: en JSON-fil generert fra FargeKjerne (sRGB ↔ lineær, OKLab/OKLCH, CIELab D50,
  ΔE00, gamut-kartlegging etter CSS Color 4, WCAG- og APCA-kontrast, LRV), med en test som holder den i takt med koden.
  Foreslått som neste leveranse; kommer her som «levert» med sti og commit.

### 4. Innleveringsark — mottatt, lav prioritet

- Står i idébanken. Tas opp igjen når vurdering er tema.

## Til orientering

- **Verdier i Studio (1.3):** CMYK, metning og lysstyrke vises i prosent. RGB vises som 0–1, unntatt i sRGB der kanalene
  vises 0–255 – de samme tallene som i hex. (Et valg av bitdybde ble prøvd og trukket tilbake: for teknisk for mange
  brukere. Bitdybde hører hjemme i undervisningen, ikke som innstilling i Kolorist.)
- **API-endringer i pakkene:** `Fargemodell.Komponent` har fått feltet `visning` (`.tall`, `.prosent`, `.kanal`) som sier
  hvordan verdien vises (CMYK/metning/lysstyrke i prosent, RGB som kanal). Eksisterende felt er uendret.
