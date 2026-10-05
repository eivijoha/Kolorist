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

## Svar (2026-10-05)

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

- **RGB-verdier etter bitdybde (1.3):** Studio, Fargestyring og profilkonvertering kan nå vise RGB som 8 bit (0–255),
  10 bit (0–1023), 16 bit (0–65 535) eller desimal (0–1), og CMYK, metning og lysstyrke vises i prosent. Kan være nyttig i
  forelesningen om bitdybde.
