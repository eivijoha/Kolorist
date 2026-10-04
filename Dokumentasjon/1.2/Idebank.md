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
