# Plan for 1.2: lys og fargemåling

Mål: Kolorist skal kunne gi **fargen til selve flaten**, uavhengig av lyset den ble plukket i, og vise hvordan farger
og paletter **oppleves i et bestemt lysmiljø**. Med et fargereferansekort blir målingene sporbare og nøyaktigheten
dokumentert med et fargereferansekort – et steg mot et profesjonelt verktøy for designere, arkitekter og interiørarkitekter.

Bakgrunn og øvrige ideer: `Idebank.md`. Arkitekturen drøftes for seg (se «Spørsmål til arkitekturdrøftingen»).

---

## 1. Funksjoner

### 1.1 Kompensere plukkede farger for lyset (hovedsak)

En farge plukket med kameraet lagres i dag slik den så ut i lyset der og da. I 1.2 kan Kolorist regne ut fargen til
selve flaten, uttrykt i et standardlys (D65 for skjerm, D50 for trykk og Lab).

Tre nivåer, valgt etter hva brukeren har tilgjengelig:

| Nivå | Brukeren gjør | Kolorist gjør | Forventet nøyaktighet |
|---|---|---|---|
| **A. Automatisk** | Ingenting | Leser kameraets estimat av lyset (Kelvin og tint) og gjør kromatisk tilpasning til standardlys | Fjerner tydelige fargestikk; ΔE00 typisk 4–8 |
| **B. Gråkort / hvitt ark** | Trykker på referansen i bildet | Hvitpunkt og eksponering fra referansen; med kamerakarakterisering (1.3) også riktig tonekurve | ΔE00 typisk 2–4 (med karakterisering) |
| **C. Referansekort i bildet** | Har fargereferansekortet (24 felt) i bildet | Full korreksjon for akkurat dette lyset og dette kameraet | ΔE00 snitt ≈ 2–3 |

Plukkede farger får to verdier: **slik den så ut** og **fargen selv** (kompensert), og brukeren kan veksle mellom dem.
Lysforholdene (Kelvin, tint, lux, nivå, referanse) lagres sammen med fargen.

**Estimert LRV for eksisterende flater:** med gråkort eller referansekort får lysheten absolutt mening, og Kolorist kan gi et
estimat av lysrefleksjonsverdien – nyttig for arkitekter som skal vurdere eksisterende dører, vegger og gulv.

### 1.2 Lagrede lysmiljøer (sekundært)

Et **lysmiljø** beskriver lyset et sted: «Stua om kvelden», «Kontor, nordvindu», «Butikken».

- **Innhold:** navn, hvitpunkt (xy / Kelvin og tint), lysstyrke (lux), dato, valgfritt miniatyrbilde og – når det er
  målt med referansekort – korreksjonen for det lyset. Ingen posisjon.
- **Kilder:** målt med kameraet (biprodukt av 1.1), standardlys (glødelampe/CIE A 2856 K, LED 2700/3000/4000 K, D50,
  D65, typisk lysrør) eller lagt inn manuelt (Kelvin og lux).
- **«Se i lys: [lysmiljø]»** i Studio, paletter, harmonier og overganger: fargene vises slik de oppleves i det lyset,
  med fargeutseendemodellen CAM16 (både lysets farge og lysstyrke; ufullstendig tilpasning gir et realistisk varmt skjær
  i varmt lys, og svakt lys gir mørkere, mindre mettede farger).
- **Side om side:** samme palett i to–tre lysmiljøer.
- **Hovedscenario:** plukk en flis i butikken (1.1 fjerner butikklyset) → se den i lagret «Stua om kvelden» (1.2).

### 1.3 Fargereferansekort med 24 felt (pro)

Eivind har et **ColorChecker-kort med 24 felt** (6 × 4: 18 fargefelt og en nøytral rad fra hvitt til sort). I
brukerrettede tekster skrives «fargereferansekort» uten merkenavn. Importen bygger på det åpne **CGATS**-formatet, så
større kort (f.eks. IT8.7/2) kan støttes senere med samme kode.

**Rettigheter:** referanseverdiene tilhører leverandøren. Kolorist følger samme prinsipp som for fargebiblioteker:
**ingen referansedata følger med appen eller ligger i kodelageret** – brukeren importerer sin egen fil. Koden kjenner
bare formatet og kortets oppsett. Enhetstester bruker **syntetiske** filer med samme struktur og kjent fasit; den
ekte filen brukes bare lokalt under testing på enhet (mappen `Lokalt/`, som er utelatt fra git).

1. **Importere referanseverdiene** under «Mine fargerom» (samme flyt som ICC-profiler og fargebiblioteker; formatet
   gjenkjennes på innholdet).
2. **Karakterisere kameraet én gang** i jevnt, godt lys: den nøytrale raden gir kameraets **tonekurve** og hvitpunkt,
   og de 24 feltene gir en **fargekorreksjon** fra kamerafarge til XYZ. Med 24 felt holdes korreksjonen enkel
   (3 × 3-matrise etter linearisering, eventuelt rot-polynomisk av lav orden) så den ikke tilpasses bare kortets felt.
   Lagres per enhetsmodell og kamera (vidvinkel/ultravid/tele har ulik respons).
3. **Presisjonsmodus på stedet:** kortet er lite og har store felt, så det er raskt å ha med i bildet. Gir korreksjon
   for det aktuelle lyset (nivå C), **lux** fra den nøytrale raden (kjent refleksjon), og kan lagres som lysmiljø.
4. **Dokumentert nøyaktighet:** etter hver karakterisering/måling vises «snitt ΔE00 x, maks y» mot kortets felt
   (helst kryssvalidert: hvert felt vurdert med en korreksjon beregnet uten det). Store gjenstående avvik gir et varsel
   om at lyset gjengir farger dårlig (ikke CRI, men en nyttig indikator).

**Fotografering:** kortet midt i bildet, lys fra siden (ca. 45°) uten gjenskinn, låst eksponering og hvitbalanse.
Feltene finnes ved at brukeren markerer de fire hjørnene (alternativt automatisk med Vision – rutenettet 6 × 4 er
lett å finne), og bildet rettes ut før gjennomsnittet i midten av hvert felt leses.

---

## 2. Metoder (dokumenteres i «Metoder og kilder»)

| Behov | Metode | Kilde |
|---|---|---|
| Lysets hvitpunkt fra kameraet | AVFoundation: hvitbalanseforsterkning → Kelvin og tint | Apple, AVCaptureDevice |
| Kromatisk tilpasning | CAT16 (og Bradford, som brukes i dag for D65↔D50) | Li mfl. 2017 |
| Fargeutseende i lysmiljø | CAM16 med visningsforhold (hvitpunkt, adapterende luminans fra lux, omgivelse) | Li mfl. 2017; CIE 248:2022 |
| Kamerakarakterisering | Linearisering fra den nøytrale raden + 3 × 3-matrise / rot-polynomisk regresjon av lav orden til XYZ | Finlayson mfl. 2015 |
| Referansedata | CGATS.17-tekstformat (gjelder også større kort som IT8.7/2 / ISO 12641) | ANSI, ISO |
| Lux fra eksponering | Eksponeringsverdi fra blender, lukkertid og ISO, med referanse av kjent refleksjon | ISO 2720 (lysmåling) |
| Nøyaktighet | ΔE2000 mot referansefeltene | CIE 142 |

Alle beregninger kjøres på enheten. Kamerabilder lagres ikke (unntatt valgfrie miniatyrer i lysmiljøer).

---

## 3. Brukerflyter (skisse)

- **Utplukk › kamera:** knappen «Lys» viser målt Kelvin, tint og lux, og velger nivå: *Automatisk* / *Kalibrer mot
  hvitt eller grått* (trykk på referansen) / *Referansekort i bildet*. Statuslinje: «Kompensert for ≈ 3200 K · ≈ 450 lx».
  «Lagre som lysmiljø …».
- **Plukkede farger og paletter:** en farge målt med kompensasjon viser et lite lysmerke; detaljer viser begge verdier
  og lysforholdene.
- **Studio, paletter, harmonier, overganger:** velger «Se i lys: [lysmiljø]» (som «Vis som»), og side om side for
  paletter.
- **Mine fargerom:** ny seksjon «Referansekort» (CGATS-filer) og «Kamera» (karakteriseringer med dato og nøyaktighet),
  og «Lysmiljøer» (eller egen oversikt – avklares).
- **Karakterisering:** veiviser i tre steg – plasser kortet og lyset, ta bildet og marker hjørnene, se resultatet
  (nøyaktighet og avvikende felt) og lagre.

Tekstene i appen og markedsføringen beskriver hva man oppnår (se tekstreglene).

---

## 4. Plattformer

- **iPhone og iPad:** alle funksjoner (kamera med hvitbalanse- og eksponeringsdata, RAW der det finnes).
- **Mac:** innebygd kamera gir ikke hvitbalansedata. Lysmiljøer og «Se i lys» virker fullt (synkronisert), og
  **karakterisering/presisjonsmåling fra et bilde** (DNG/ProRAW eller JPEG/HEIC tatt med iPhone og importert) kan
  gjøres på alle plattformer. iPhone som kamera (Continuity Camera) undersøkes.

---

## 5. Faser

| Fase | Innhold | Leveranse |
|---|---|---|
| **0. Forarbeid** | Prototyp: les hvitbalanse, eksponering og (Pro)RAW på Burgund; mål stabilitet | Notat om hva kameraet faktisk gir |
| **1. Fargevitenskap i FargeKjerne** | CAT16, CAM16 med visningsforhold, standardlys, lux-estimat, CGATS-leser, regresjon og linearisering | Testdekning mot publiserte testverdier |
| **2. Kompensasjon i kameraet** | Nivå B (gråkort/hvitt), deretter A (automatisk); to verdier og lysforhold på plukkede farger | Utplukk med «Lys» |
| **3. Referansekort** | Import av referanseverdier (CGATS), hjørnemarkering og utretting, karakterisering, presisjonsmodus, lux, nøyaktighetsrapport | Veiviser og rapport |
| **4. Lysmiljøer** | Datamodell og synk, standardlys, lagre målt lys, «Se i lys», side om side | Lysmiljøer i Studio og paletter |
| **5. Ferdigstilling** | Metoder og kilder, tekster, web 1.2, skjermbilder, App Store | 1.2 klar |

Rekkefølgen kan justeres: lysmiljøer med standardlys (fase 4) kan komme før referansekortet (fase 3) hvis vi vil vise noe tidlig.

---

## 6. Testing og akseptkriterier

- **Enhetstester:** CAT16/CAM16 mot publiserte eksempelverdier; CGATS-lesing; regresjon på syntetiske data med kjent
  fasit; rundtur for linearisering.
- **Målinger med referansekortet på Burgund** under minst tre lys: dagslys, varm LED (≈ 2700 K) og kald LED/lysrør (≈ 4000 K).
- **Mål:** nivå C snitt ΔE00 ≤ 3 (kryssvalidert); nivå B (med karakterisering) snitt ΔE00 ≤ 4; nivå A merkbart bedre enn
  ukompensert. Lux innenfor ±20 % av en lysmåler med gråkort.
- **Brukertest:** flis i butikk → «Se i lys» hjemme; vurder om resultatet oppleves troverdig.

---

## 7. Risiko og åpne spørsmål

- **Tonejustering i kamerabildet** (lokal kontrast, HDR): løses med låst eksponering, linearisering fra gråskala og
  RAW der det finnes. RAW (ProRAW) bare på Pro-modeller; Bayer-RAW på flere – må kartlegges i fase 0.
- **Blandet lys og blanke flater** gir dårligere resultater; appen må si fra (varsel ved ujevnt hvitpunkt eller gjenskinn).
- **Metameri og spektrale avvik** (LED/lysrør) kan ikke måles med RGB-kamera – kommuniseres som begrensning.
- **Automatisk gjenkjenning av kortet** kan være ustabil; hjørnemarkering er reserve og første versjon.
- **Kompatibilitet med 1.1:** nye data må ikke gå tapt når en enhet med 1.1 redigerer en palett (se arkitektur).
- **CloudKit:** nye modeller/felt krever utrulling av skjemaet til produksjon før lansering.
- **App Review:** kamerabruken utvides (måling av lys) – oppdater bruksbeskrivelsen og notatene.

---

## 8. Spørsmål til arkitekturdrøftingen (senere)

1. **Ny modul i pakken?** F.eks. `FargeMåling` (CAT16/CAM16, CGATS, regresjon, lysmiljø-beregninger) atskilt fra
   `FargeKjerne`, eller som del av den.
2. **Kamerarørledningen:** dele `KameraFargeplukker` i opptak, måling (låsing, RAW, statistikk over felt) og plukking.
3. **Datamodell og synk:**
   - `Lysmiljø` og `Kamerakarakterisering` som nye SwiftData-modeller (karakterisering per enhetsmodell og kamera –
     synkroniseres eller holdes lokalt?).
   - Lysforhold per plukket farge: lagres **i et eget felt på paletten** (slik gradienter fikk `gradientData`), ikke
     inne i `PalettFarge` – ellers fjerner 1.1 dem når en farge lagres på nytt fra en eldre enhet.
4. **Hvor «Se i lys» bor:** én felles visningstransformasjon (som «Vis som») som Studio, paletter, harmonier og
   utskrift bruker, i stedet for logikk spredt i hver visning.
5. **Utskrift/PDF:** skal lysforhold og «sett i lysmiljø» kunne skrives ut (f.eks. side om side i CIELab)?
6. **Ytelse:** CAM16 for mange farger og ringen i fargesirkelen – mellomlagring som for Munsell.
7. **Personvern:** miniatyrbilder og eventuelle stedsnavn – hva lagres og synkroniseres.
