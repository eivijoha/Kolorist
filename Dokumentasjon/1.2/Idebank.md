# Idébank for 1.2 og senere – lys og fargemåling

Eivind prioriterte (2026-10-03):

1. **Kompensere plukkede farger for lysforholdene** (hovedsak).
2. **Lagrede lysmiljøer** – «se denne fargen i [lagret lysmiljø]» (sekundært).

**Fargereferansekort med 24 felt** (Eivind har et ColorChecker-kort; i tekster uten merkenavn). Referanseverdiene
følger ikke med (rettigheter) – brukeren importerer sin egen CGATS-fil:
- Karakterisere iPhone-kameraet én gang under godt lys → deretter holder et gråkort på stedet.
- Den nøytrale raden gir kameraets tonekurve, hvitpunkt og lux.
- Presisjonsmodus med kortet i bildet (kortet er lite og raskt å bruke på stedet), typisk snitt-ΔE00 ≈ 2–3.
- Lysmiljøer kan lagre hele korreksjonen, ikke bare Kelvin og lux.
- Dokumentert nøyaktighet («snitt ΔE00 x, maks y»), og et grovt varsel om lys med dårlig fargegjengivelse.
- Senere: større kort (IT8.7/2) med samme CGATS-import.

Øvrige muligheter som skal tas opp igjen senere:

- **Lysmåler (lux) for rommet** med referansekort, sammenlignet med anbefalte nivåer (f.eks. NS-EN 12464-1:
  kontor 500 lx, lesing 300–500 lx, korridor ≈ 100 lx) – særlig relevant for universell utforming.
- **Målt luminanskontrast mellom flater i rommet** (dør mot vegg i faktisk belysning), som supplement til
  LRV-kontrasten etter NS 11001.
- **Dokumentasjon av lysforhold** sammen med plukkede farger og kontrastmålinger («≈ 3200 K, ≈ 450 lx»).
- **Paletter som tåler lyset**: varsle om farger som endrer karakter mye under varmt/kaldt lys, og foreslå justering.
- **Fargetemperatur som verdi** for hvite og nesten hvite farger (lysdesign, «varme» og «kalde» hvite).
- **Lysstyrkens effekt på fargeinntrykk** (Hunt- og Stevens-effekten, CAM16) – inngår delvis i lagrede lysmiljøer.
- **Eksterne fargemålere** for det kameraet ikke kan måle: fargegjengivelse (CRI) og metameri (spektralmåling).
- **Telefonen som kolorimeter for skjermer og projektorer** (kanskje egen app): vise testfelt på skjermen/projektoren
  og måle med kameraet. Gir bare relative målinger (hvitpunkt, gråbalanse, ensartethet, grov gamma), ikke presis
  profilering – kameraets spektralfølsomhet avviker fra CIE-observatøren. Egen app eller senere modul.

Tekniske forutsetninger: iOS gir ikke tilgang til omgivelseslyssensoren; kameraet (AVFoundation) gir
hvitbalanse (Kelvin og tint) og eksponering. Mac med innebygd kamera gir ikke hvitbalansedata.

## Harmonier (2026-10-04)

Tatt inn i 1.2: triade og kvadrat som egne harmonier, analog med komplementær aksent, og naturlig/omvendt
lyshetsrekkefølge. Lagt hit for senere:

- **Harmonipoeng etter Ou og Luo (2006)** i Vurdering: en modell fra observatørforsøk som anslår hvor harmonisk
  to- og tre-fargekombinasjoner oppleves, ut fra lyshet, kroma og kulør i CIELab. Egen oppføring under Metoder.
- **Harmonisering etter kulørmaler** (Matsuda; Cohen-Or mfl. 2006): dytt en eksisterende palett – for eksempel
  plukket med kameraet – til nærmeste harmonimal med minst mulig endring.

## Samspill med Windows fra iPhone/iPad (2026-10-04: delingsmappa er erstattet av «Lagre som»)

Delingsmappa (fast mappe som holdes oppdatert) ble droppet: iOS gir ikke apper fast mappetilgang hos OneDrive,
Jottacloud m.fl. I stedet «Lagre som …» på paletter og farger: velg formater (samme på alle plattformer), lagre i en
mappe via systemets lagringsdialog (iOS) eller Finder (Mac), eller del filene. Teksten under er historikk.


Mange samarbeidspartnere (særlig i arkitektur) sitter på Windows. Palettene ligger i SwiftData/CloudKit og er ikke
lesbare utenfor Apple-enheter; ICC-profiler og fargekart ligger allerede som filer i appens iCloud Drive-mappe.

Avklart med Eivind: **ingen QR-kode og ingen serverløsning** (verken egen server, lokal webserver eller nettvisning).
Bluetooth er ikke mulig (iOS sender ikke filer over Bluetooth til andre enn Apple-enheter).

**Valgt retning: delingsmappe i valgfri skytjeneste.** Brukeren peker én gang ut en mappe i Filer – OneDrive,
Google Drive, Dropbox, Box, iCloud Drive eller en nettverksdisk – og Kolorist skriver palettene dit som filer. Ingen
innlogging eller SDK i Kolorist: tjenestens egen app laster opp. Personvernet er uendret.

- Ingen Windows-app og ingen nye formater (Eivind): bare de eksisterende eksportformatene – ASE, ACO, DTCG-JSON,
  CSS, GPL, SVG, hex-liste og A4-PDF – skrevet til mappa. Brukeren velger hvilke.
- Speiling av valgte paletter ved endring (debouncet), og en knapp for å dele én palett dit.
- Sletter aldri filer i mappa (som i Studieblikk: logg, ikke slett).
- Status i én modell: koblet / mangler tilgang / mappa er borte → «Koble til på nytt».
- Senere: lese ICC-profiler og fargekart som kolleger legger i mappa.

Gjenbruk fra Studieblikk (`SharedFolderStore`):
- `coordinatedRead`/`coordinatedWrite` (NSFileCoordinator, atomisk erstatning) og `writeFileOffMain`
  (sikkerhetsscope og I/O på en frakoblet oppgave, så en kald skymappe ikke fryser UI).
- Bokmerkeoppløsning med fornying når bokmerket er utdatert (`resolveURL`). På iOS uten `.withSecurityScope`.
- `isConflictedCopyFilename` og hopp over symlenker; utvid med Google Drives «(1)»-kopier.
- Én «Koble til»-funksjon og én statusmodell (`OneDriveStatus`/`kobleTilMappe`).
- Ikke aktuelt: FSEvents-overvåking (bare macOS), Teams-stier og treveis-fletting.

## Lenker til andre Kolorist-brukere, med visning på kolorist.no (vurdert 2026-10-04)

Eivind ønsker å dele enkeltfarger, paletter, harmonier, gradienter m.m. som lenker. Vurdert, ikke implementert.

**Anbefaling: universelle lenker `https://kolorist.no/l#…` med en statisk visningsside.**
- Innholdet ligger etter `#` og sendes aldri til nettstedet. Ingen server, ingen lagring, personvernet uendret.
- Har mottakeren appen (iPhone, iPad, Mac), åpner systemet lenken rett i Kolorist; siden lastes ikke.
- Uten appen – også på Windows – viser siden fargene i nettleseren. I innebygde nettlesere (Teams, Outlook) har siden
  «Åpne i Kolorist» (`kolorist://`) og Apples appbanner med lenken som argument.
- `kolorist://` i tillegg, for Snarveier og innebygde nettlesere.

**Hva som deles:** enkeltfarger (navn og fargemodell, også CMYK i profil), paletter (med gradienter), harmonier
(oppsett, så mottakeren kan jobbe videre), overganger (endepunkter, antall, lysere/mørkere), lysmiljøer og
kontrastpar. Ikke referansekort (referanseverdiene er rettighetsbelagt).

**Visningssiden** (én HTML-side med lite skript, ~20–40 kB, ingen avhengigheter – ikke en web-app):
- Viser farger (hex, OKLCH, CIELab, egen modell), paletter som rutenett, gradienter som CSS i OKLab, harmonier og
  kontrastpar med WCAG-tall. Lysmiljøer bare som parametre (K, lux) – «Se i lys» krever spektre og CAM16.
- Munsell- og CMYK-verdier ligger ferdig utregnet i lenken som tekst, så siden ikke trenger egen fargevitenskap.
- «Kopier som hex/CSS». Filnedlasting overlates til delingsmappa (unngå to implementasjoner av formatene).

**Forutsetninger og risiko**
- `/.well-known/apple-app-site-association` på kolorist.no (JSON, uten omdirigering – sjekk at one.com leverer
  `.well-known` riktig) og Associated Domains (`applinks:kolorist.no`) i appen.
- Ett lenkeformat med versjonsnummer, lest av både Swift og JavaScript: felles testlenker som begge sjekkes mot
  (som `WindowsSamsvarTests` i Studieblikk). Bare bakoverkompatible endringer.
- Lenker kan lages av hvem som helst: navn settes inn som tekst (aldri HTML), grenser for antall farger og lengde,
  og appen lagrer aldri automatisk – mottaksark med forhåndsvisning og «Legg til» / «Åpne i Studio» / «Avbryt».
- Lengde: ~600–800 tegn for ti farger; over ~64 farger er delingsmappa bedre.
- iOS kan huske «Åpne i Safari», og universelle lenker utløses ikke når adressen limes inn i adressefeltet –
  visningssiden fanger begge.

**Omfang:** appen (lenkeformat, delingsknapper, mottaksark) er det største; visningssiden og AASA-fila er små;
felles testlenker binder dem sammen.

Ikke aktuelt (Eivind): QR-kode og serverløsninger.

## Flere fargestopp i gradienter (i kø, 2026-10-04)

Eivind: gradienter med flere enn to fargestopp. I dag har en gradient «Fra» og «Til» (`Gradientoppsett`), med toner i
like OKLab-steg mellom dem. Ting å avklare når den tas opp:
- Stoppene som liste (minst to), med valgfri posisjon (0–100 %) eller jevnt fordelt; interpolasjon i OKLab mellom
  nabostopp.
- Lagring: `Gradientoppsett` kodes i paletter og synkroniseres – nye felt må være valgfrie, så eldre versjoner leser
  dagens to stopp uendret (jf. `TolerantListe`).
- Overgang-visningen: legge til, flytte og fjerne stopp; lyshetsstigen og «Flytt lysheten» med flere grunntoner.
- Eksport: CSS-gradienter med flere stopp (oklab og sRGB-reserve), kopi til andre programmer, A4-PDF.
- Lenkeformatet (se «Lenker til andre Kolorist-brukere») bør ha plass til flere stopp fra start.

## Filamentfarger for 3D-print (tatt inn i 1.2, 2026-10-04)

Innebygde bibliotek fra FilamentColors.xyz (CC BY 4.0), ett per materialgruppe, med kilde (produsent, navn,
materiale, lenke til prøven, målt/anslått, TD) på hver farge. Uttrekk med `Pakker/FargeKjerne/Verktøy/hent_filamentfarger.py`;
Lab er D65/10° (fra kildekoden deres). Senere:
- Import av SpoolmanDB og Open Filament Database (MIT, bare hex – merkes som omtrentlige).
- Filter på produsent i «Vis som» og ved nærmeste tone (biblioteket har ~150 produsenter).
- OpenPrintTag (NFC på spolen): lese fargen rett fra spolen med iPhone – sjekk hvordan fargen er kodet i spesifikasjonen.
- Vurder å publisere det bearbeidede uttrekket åpent på kolorist.no (CC BY 4.0), for åpenhet og fordi CC BY 4.0
  ikke tillater tekniske begrensninger som hindrer bruken av dataene.

## Til 1.3: CMYK-profil som kildeprofil (2026-10-04)

I dag kan en CMYK-profil bare være målprofil («Vis som» / fargestyring), ikke kilde. Når farger redigeres i CMYK-modellen,
bør vi også der kunne velge kildeprofilen – CMYK-verdiene betyr noe bare i en bestemt trykkprosess (FOGRA, GRACoL,
avispapir …).

- Velg kildeprofil for CMYK-verdier, og regn dem om til Kolorists kanoniske farge gjennom profilen.
- Da kan en CMYK-profils papirhvitt (hvitpunktet) gjengis i en annen ICC-profils fargerom med absolutt kolorimetrisk
  gjengivelse – for eksempel hvordan avispapiret ser ut på skjermen eller i en annen trykkprofil.
- Henger sammen med «rene CMYK-verdier» og fargekart i CMYK: verdiene må tolkes i samme profil som de er laget i.

## Til 1.3: Lim inn farger og gradienter fra de samme programmene som «Kopier til» (2026-10-05)

I dag leser «Lim inn» fargeobjekter og hex/CSS-tekst. Målet er å ta imot farger *og gradienter* fra de programmene vi
kopierer til, slik at veien går begge veier: lim inn en gradient fra Keynote eller Illustrator, og få den som gradient
i Overgang (eller i en palett), med endepunkter og stopp.

**Utklippsformatene vi kjenner fra arbeidet med «Kopier til» (1.2)**
- **Pages/Keynote/Numbers (og trolig Freeform):** `com.apple.apps.content-language.canvas-object-1.0` – JSON med
  figurer, fyll (farge eller gradient med stopp, P3/sRGB og vinkel). Lettest å lese. Radiell gradient kommer ut som
  lineær i JSON-en (iWork skriver den slik), så formen må gjettes fra bildet eller utelates.
- **Illustrator:** SVG-kode som tekst og `public.svg-image` (gradient med stopp), PDF med skyggelegging (ShadingType 2/3)
  og AICB (PostScript). SVG er enklest å tolke.
- **InDesign:** PDF på utklippstavlen. Eget utvekslingsformat finnes, men leveres bare på forespørsel og var tomt i test.
  PDF-ens skyggelegging (ShadingType 2/3, FunctionType 2/3) kan tolkes, men det er mer arbeid.
- **Figma og Sketch/Affinity:** sjekkes. Figma legger eget, lukket format i HTML på utklippstavlen; «Copy as SVG» og
  «Copy as CSS» fra Figma er trolig realistiske veier.
- **Photoshop:** sjekkes (forventet bilde/PDF; farger kanskje bare som tekst).
- **CSS og SwiftUI:** tekst – `linear-gradient(...)`/`radial-gradient(...)` og `Color(...)`/`LinearGradient(...)` kan
  tolkes med Fargetolk utvidet til gradienter.

**Hensyn**
- iOS spør «Tillat innliming?» når vi leser innhold fra andre apper. Knappen «Lim inn» kan vises ut fra hvilke typer
  som finnes (uten å lese dem), og innholdet leses først når brukeren trykker.
- Farger fra en gradient eller figur kan også gå til en palett (stoppene som farger).
- Gradienter med flere enn to stopp henger sammen med «Flere fargestopp i gradienter» over: inntil det finnes, blir
  innlimte gradienter forenklet til endepunktene (eller tonene som palett).
- Testes på samme måte som «Kopier til»: kopier fra programmet, les utklippstavlen og sammenlign med det vi selv lager.

## App Clip for delingslenker (vurdert 2026-10-04 – lagt til side)

**Beslutning (Eivind, 2026-10-04): droppet for nå.** Lenkene brukes nok oftest på desktop, der App Clips ikke finnes.
Visningssiden på kolorist.no er veien for mottakere uten appen. Vurderingen under står igjen til en eventuell senere runde.

Idé: en App Clip – en liten del av appen som åpnes uten installasjon – for mottakere av `kolorist.no/l#…` som ikke har
Kolorist på iPhone eller iPad.

**Hva den kan gi utover visningssiden på nettet**
- Fargene vist riktig i Display P3 (nettleseren klipper ofte til sRGB) og med appens egne verdier (Munsell, CMYK i profil).
- «Kopier til» og «Lagre som» med appens egne formater – ASE, design tokens, gradienter til designprogrammer – rett fra
  lenken, uten å lage formatene på nytt i JavaScript.
- Kort vei til full app: App Clip-kortet viser appen, og fargene kan følge med over når appen installeres (felles
  app-gruppe).

**Begrensninger**
- Bare iPhone og iPad. Mac og Windows får fortsatt visningssiden.
- Lite lagring og ingen iCloud-synk; paletter kan ikke lagres i App Clip-en, bare vises, kopieres og eksporteres.
- Størrelsesgrense for App Clips: FargeKjerne med Munsell-data, ICC og eksport må holde seg under. Filamentdata og
  KI-biblioteket utelates.
- Eget mål i prosjektet, egen gjennomgang hos Apple og «App Clip-opplevelse» i App Store Connect (bilde, tekst, knapp).

**Må sjekkes før vi bestemmer oss**
- Størrelsesgrensen for App Clips på iOS 26, og hva FargeKjerne og et minimalt grensesnitt veier.
- At App Clip-en får hele adressen, også delen etter `#` (innholdet ligger bare der).
- AASA-fila trenger nøkkelen `appclips` i tillegg til `applinks`, og visningssiden en meta-tag for App Clip-banneret.
- Hvordan App Clip-kortet og visningssiden spiller sammen: kortet vises i Safari og Meldinger, siden fortsatt for alle
  andre.

**Vurdering:** Verdien er størst om lenker deles mye til folk uten appen, og kopiering rett inn i designverktøy er det
som skiller den fra visningssiden. Alternativet er å la visningssiden få «Last ned ASE» og «Kopier som …» – billigere,
og virker også på Mac og Windows. Mulig rekkefølge: først visningssiden, App Clip etterpå hvis lenkene brukes mye.

**Eivinds vinkel (2026-10-04): App Clip som smakebit – la folk se verdien av appen.** Det endrer vurderingen: målet er
ikke å vise lenkede farger, men å la noen prøve det Kolorist gjør bedre enn andre, på sekunder og uten installasjon.

- *Innganger:* delingslenker (den som får en palett, ser den i appen med en gang), appbanneret på kolorist.no («Prøv»
  rett fra nettsiden – da blir nettsiden selv en inngang, ikke bare lenkene), og Meldinger. (QR- og NFC-koder er mulig
  for App Clips, men ikke aktuelt – se over.)
- *Innhold – én kort oppgave, ikke hele appen:* åpne en farge eller palett og
  - se den i OKLCH, Munsell og CMYK side om side,
  - se harmonier rundt den,
  - sjekke kontrast mot hvitt/sort,
  - se den i et par lysmiljøer,
  - kopiere til designprogram.
  Uten lenke: start med en eksempelfarge eller plukk en farge med kameraet.
- *Vei videre:* Apples overlegg for å hente full app (SKOverlay), og fargene følger med over til appen.
- *Pass på:* Apple beskriver App Clips som raske, avgrensede oppgaver – en ren prøveversjon kan få avslag. «Se og bruk
  en farge du har fått eller plukket» er en oppgave og passer; sjekk retningslinjene (App Review 2.5.16 og HIG for App
  Clips) før vi bestemmer omfang. Størrelsesgrensen avgjør hvor mye av Studio som kan være med.
- *Mac:* App Clips finnes ikke på Mac; der er appen selv inngangen.

Vurdering etter denne vinkelen: App Clip er verdt å prioritere i 1.3 – foran utvidelser av visningssiden – hvis vi
klarer å holde den liten og oppgaveformet.
