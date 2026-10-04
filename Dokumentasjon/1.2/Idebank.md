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

## Samspill med Windows fra iPhone/iPad (tatt inn i 1.2, 2026-10-04: `Delingsmappe`)

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
