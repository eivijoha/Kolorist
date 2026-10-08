# Endringer

API-endringer per versjon, for dem som bygger på pakken (som Kolorist utdanning). Nyeste først.

## Ikke publisert

- **Skriftfarger i paletter:** `Palett.tekstfarger` (valgfritt, kodes bare når det finnes; eldre data leses) og
  `PalettFarge.tekstfarge: UUID?` (valgt skriftfarge, `nil` = automatisk). `Skriftfarger.beste(for:blant:)` velger den som
  leses best etter APCA blant dem som når 4,5:1 (WCAG), ellers høyest WCAG-forhold; `Skriftfarger.vurdering`,
  `Skriftfarger.forslag(for:)` (L* 97 og 14 med svakt kulørpreg) og `Palett.skriftfarge(for:)`.
- `Farge.lStjerne`: CIE L* fra luminansen Y (D65), altså samme størrelse som WCAG-kontrasten bygger på. (`cieLab` er D50 og
  gir litt annen L* for mettede farger.)
- `Farge.medLStjerne(_:kroma:kulør:gamut:)`: fargen med gitt OKLCH-kroma og -kulør og eksakt L* (`lStjerne`, binærsøk i
  OKLCH L).
- **Toneskala forankret i L*:** `Toneskala.kontrastLStjerne` (11 trinn, 50–950: 97, 93, 86, 76, 61, 54, 48, 38, 28, 18, 10),
  `Toneskala.jevnLStjerne(antall:)` og `toner(for:lStjerne:)`. Like trinn får samme L* for alle kulører, så kontrasten
  mot hvit og sort blir lik: trinn 400 holder minst 3:1 og 600 minst 4,5:1 mot hvit, også etter avrunding til hex.
- Eksport med skriftfarger: CSS (`--farge-on`), DTCG (egen gruppe `<palett>-tekst` med `on`-alias), SwiftUI (`fargeOn`),
  Figma- og Tokens Studio-grupper `tekst` og `on`, ASE (egen fargegruppe), GPL. Uten skriftfarger er eksporten som før.
  SwiftUI-eksporten gir nå unike Swift-navn også når fargenavn kolliderer.

- `Harmoni.tonebane` (i første gruppe sammen med `.monokrom`) og `Monokromstrek.toner(fraKulør:spenn:antall:gamut:)`:
  toner langs streken i lyshet–metning-planet der kuløren også går `spenn` grader rundt OKLCH-sirkelen fra startkuløren,
  i retningen fortegnet sier og opptil en hel runde (ikke korteste vei). Brytende for uttømmende `switch` på `Harmoni`.

## 0.3.0 – 2026-10-06

- **Rettet: luminanskontrast etter norsk praksis.** `Flatekrav.luminans04`/`.luminans08` regnes nå med Weber,
  |Yo − Yb| / Yb med bakgrunnen (`b`) som referanse, slik TEK17, NS 11001 og Byggforsk 220.114 gjør (kontrollert mot
  NBKF Faglig veileder 3-2024). Før ble Michelson brukt, som ga andre svar. Kravene har fått riktige navn: 0,4 for
  orientering og veifinning, 0,8 for trapp, håndløper og farefelt (ikke «skilt og tekst»).
- `Flatekontrastmetode` (`.lrvForskjell`, `.weber`, `.michelson`) med `navn`, `formel` og `krav`;
  `Flatekontrast.weber`, `.verdi(_:)` og de statiske `weber(objekt:bakgrunn:)` og `michelson(_:_:)`.
- Nye krav: `Flatekrav.lrv20` (BS 8300: store flater eller over 200 lux), `.michelson30` og `.michelson60`
  (ISO 21542, verdier etter CAN-ASC-2.4-utkastet). `Flatekrav.metode` og `.minimum`. **Merk:** `Flatekrav.allCases`
  inneholder nå krav for alle metodene – bruk `metode.krav` for kravene til én metode.
- `Farge.medAPCA(mot:minst:)`: justerer lysheten (OKLCH) til APCA-lesekontrasten |Lc| når et mål, med minst mulig
  endring – som `medKontrast(mot:minst:)` gjør for WCAG 2.
- Testvektorene har fått `lrvForskjell`, `weberFlatePaaBakgrunn` og `michelson` for hvert par.

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
