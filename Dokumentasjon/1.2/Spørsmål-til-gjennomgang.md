# Spørsmål til gjennomgang – lys og fargemåling (1.2)

Samlet under implementeringen (2026-10-04) i stedet for å spørre underveis. Hvert punkt beskriver valget som er
gjort, så det kan godtas eller endres.

## Beslutninger (gjennomgang 2026-10-04)

| Punkt | Beslutning |
|---|---|
| 1 | Egen modul `FargeMaaling` – godtatt. |
| 2 | Beholde iCloud nøkkel–verdi. |
| 3 | De sju standardene holder. |
| 4 | «Se i lys» også for **hele paletten**, i **Vurdering** og for **LRV** (flater). Ikke for WCAG – det gjelder skjermfarger. |
| 5 | Standardvisning «Slik øyet ser det». |
| 6 | Beholde skjermreferansen (D65, 160 cd/m²). |
| 7 | Beholde spektral vei, men **forklare tydeligere** ved lysrør/LED at spekteret er anslått (metameri). |
| 8 | Terskel 3 ΔE00. |
| 9 | Mac: visning; Continuity-kamera med gråkort/referansekort uten lysmåling – godtatt. |
| 10 | Beholde «For lyset kameraet måler». |
| 11 | **Lux bare med kort**, merket «≈». |
| 12 | **«Eget kort …»** med egen refleksjon. |
| 13 | Låsing av eksponering – godtatt. |
| 14 | **Automatisk forslag til hjørner** (Vision), som brukeren kan justere. |
| 15 | **Automatisk modellvalg**: beregn begge, bruk lavest kryssvalidert ΔE00, vis hvilken. |
| 16 | **«Karakteriser én gang, deretter gråkort» med i 1.2.** |
| 17 | Anslått fargegjengivelse vises både for kjente spektre og fra kameramåling, merket «anslått». |
| 18 | Lystype vises som **«sannsynligvis …»**, bare når målingen har kort. |
| 19 | Rekkefølgeheuristikken – godtatt. |
| 20 | **Vis tolkningen** («Tolket som Lab D50») i kortets detaljer, med bytte til XYZ. |
| 21 | Ikke Argyll .cht. |
| 22 | Slipp av tekst/XML som referanseverdier – godtatt. |
| 23 | **Strengere kryssvalidering**: også tonekurven tilpasses uten feltet. |
| 24 | Lysmiljø fra kameramåling med hvitpunkt – godtatt. |
| 25 | **Kompensasjon for bilder** med gråkort og referansekort (uten lysmåling). |
| 26 | Engelsk: **«viewing condition»** i stedet for «light environment». |
| 27 | Sitatet er riktig: Burns, Color Research & Application 45(1), 8–21, 2020 (metode 1, LLSS). |

### Oppgaver fra gjennomgangen

- [x] 26 Engelsk «viewing condition(s)»
- [x] 7 Merknad om anslått spekter ved lysrør/LED
- [x] 11 Lux bare med kort
- [x] 12 Eget gråkort
- [x] 15 Automatisk modellvalg
- [x] 18 Lystype «sannsynligvis», bare med kort
- [x] 20 Vis tolkningen av tre kolonner, med bytte Lab/XYZ
- [x] 23 Strengere kryssvalidering
- [x] 4 Se i lys for hele paletten, i Vurdering og for LRV
- [x] 16 Karakteriser én gang, deretter gråkort
- [x] 25 Kompensasjon for bilder
- [x] 14 Automatisk forslag til hjørner (Vision)

## Arkitektur og lagring

1. **Ny modul `FargeMaaling`** i pakken FargeKjerne: spektre, CIE-data (`CIEData.json`, 380–780 nm/5 nm),
   fargetemperatur (Ohno), CAT16/CAM16, refleksjonsanslag (LLSS), lysmiljø, lyskompensasjon, referansekort,
   import og kamerakarakterisering. Egen modul eller del av FargeKjerne?
2. **Lagring i iCloud nøkkel–verdi (JSON)**, ikke SwiftData: `Lysbibliotek` lagrer lysmiljøer, referansekort og
   siste karakterisering per kort. Slipper ny utrulling av CloudKit-skjemaet. Grensen er 1 MB totalt (et kort med
   24 spektre er ≈ 15 KB). En liste som ikke kan leses (fra en nyere versjon), overskrives ikke. Godt nok, eller
   SwiftData/CloudKit?
3. **Innebygde lysmiljøer**: *Standarder* – Grafisk vurdering, kritisk (ISO 3664 P1: D50, 2000 lx) og praktisk
   (P2: D50, 500 lx); Kontor og arbeidsplass (NS-EN 12464-1: 500 lx), Klasserom (300 lx) og Korridor (100 lx), alle
   med nøytral LED 4000 K; Museum, malerier (CIE 157: 200 lx) og lysfølsomme gjenstander (50 lx), varmt lys 3000 K.
   *Eksempler* – Stue om kvelden (2700 K, 100 lx), Varmhvit LED (200 lx), Lysrør (FL11, 400 lx), Dagslys inne
   (D65, 1000 lx), Overskyet ute (7500 K, 10 000 lx). Belysningsstyrken følger standardene; spekteret er et typisk
   valg. Riktige verdier, og flere (f.eks. sykehus, butikk, NS 11001 for universell utforming)?

## Se i lys

4. **Plassering**: nytt panel «Se i lys» i Studio › Farge (sammenleggbart og flyttbart som de andre panelene).
   Også for hele paletten, kontrastvisningen eller i Vurdering?
5. **Visning**: «Slik øyet ser det» (CAM16; øyet tilpasser seg ≈ 84 % ved vanlig innelys, så forskjellen blir
   subtil) eller «Som et foto» (lysets fulle stikk). Standarden nå er «Slik øyet ser det». Riktig?
6. **Skjermreferansen**: D65, 160 cd/m² (L_A = 32), gjennomsnittlig omgivelse. Et D65-miljø ved ≈ 500 lx gir da
   uendret farge. Riktig referanse?
7. **Spektral vei for farger uten spekter**: et glatt anslått refleksjonsspekter (Burns LLSS) gjør at lysrør og
   LED kan endre enkelte farger mer enn fargetemperaturen tilsier (metameri-lignende). Det er et anslag. Skal det
   stå tydeligere, eller skal man kunne velge bort den spektrale veien?
8. **Fargeskift**: ΔE00 mellom fargen i dagslys og under lyset etter full tilpasning; oransje over 3. Riktig terskel?

## Kompensasjon i Utplukk

9. **Hvitbalanse**: Ved kompensasjon låses hvitbalansen til D65 (iPhone/iPad), og Kolorist kompenserer selv.
   *Avklart 2026-10-04:* På Mac er visning det viktige – «Se i lys» med eksempler og lysmiljøer lagret på iOS
   (synkronisert via iCloud). Referansekort kan importeres på Mac og synkroniseres til iOS.
   *Continuity-kamera (2026-10-04):* Med iPhone som kamera på Mac vises Lys-menyen med gråkort og referansekort
   (kameravalg i verktøylinjen; iPhone foretrekkes når den er tilkoblet). macOS gir ikke tilgang til hvitbalanse,
   ISO eller lukkertid (`API_UNAVAILABLE(macos)`), og bildet kommer ferdig hvitbalansert. Derfor låses bare gjeldende
   hvitbalanse og eksponering, og kompensasjonen retter restfargestikk og lyshet – men **lyset kan ikke måles**
   (ingen Kelvin, lux eller fargegjengivelse) fra Macen. Lysmiljøer måles med Kolorist på iPhone. Godt nok?
10. **«For lyset kameraet måler»** bruker kromatisiteten fra kameraets automatiske hvitbalanse (før låsing) og
    CAT16. Resultatet ligner det kameraet gjør selv, men med vist fargetemperatur og konsekvent metode. Nyttig,
    eller forvirrende ved siden av «Som kameraet ser fargene»?
11. **Lux** anslås fra eksponeringen (K = 12,5). Uten kort antas et midtgrått motiv; med gråkort brukes kortets
    pikselverdi. Telefonens tonekurve gjør dette grovt (±30 % eller mer). Kalibrere mot luxmeter, eller vise lux
    bare med kort?
12. **Gråkort** har faste valg 18 % og 90 %. Behov for egen refleksjon?
13. **Låsing av eksponering** skjer når gråkortet registreres og når kortbildet tas; «Som kameraet ser fargene»
    låser opp igjen. Trykk for fokus endrer ikke eksponeringen mens den er låst.

## Referansekort

14. **Flyt**: stillbilde → dra fire hjørner (med Roter/Speil) → beregn → resultat med fasit og kompensert farge per
    felt, kryssvalidert snitt/maks ΔE00, fargetemperatur, anslått fargegjengivelse og lystype → «Bruk».
    Automatisk gjenkjenning av kortet (Vision) senere?
15. **Modell**: rotpolynom (6 ledd) for 18 felt eller flere, ellers 3×3-matrise. Syntetisk test: matrise 2,9,
    rotpolynom 1,5 i snitt-ΔE00. Skal brukeren kunne velge?
16. **Gjenbruk**: karakteriseringen lagres (siste per kort, med kameranavn), men brukes ikke automatisk i neste
    økt, siden den gjelder lyset den ble laget i. Planens «karakteriser én gang, deretter gråkort» (enhetsmodell
    under kjent lys + gråkort i nytt lys) er **ikke** implementert ennå. Prioritet?
17. **Fargegjengivelse**: 100 − 9 · snitt-ΔE00 mot et referanselys med samme fargetemperatur, kalibrert så FL2 ≈ 68
    (Ra 64) og FL11 ≈ 82 (Ra 83) med 24-felts kortet. Fra kamera med låst hvitbalanse er målingen grov. Navnet er
    «Fargegjengivelse (anslått)». Akseptabelt, eller bare vise for kjente spektre?
18. **Lystype** er en enkel heuristikk (Kelvin, Duv, fargegjengivelse). Terskler: Duv > 0,006 grønnstikk,
    < −0,008 rødlilla stikk; < 2200 K levende lys; 2200–3300 K glødelys/varmhvit LED (skilles på fargegjengivelse
    ≥ 95 eller Duv); 3300–4800 K nøytralt kunstlys; 4800–7000 K dagslys; over det overskyet.

## Import

19. **Rekkefølge**: feltene ordnes rad for rad. Ligger de nøytrale samlet på én rad, er filen radvis; ellers
    kolonnevis (som filen din, der hvert fjerde felt er grått). Kontrollert mot `Lokalt/`-filen: rad D blir
    hvit → svart. Felt uten navn får posisjonsnavn (A1 … D6); merkenavnene på feltene brukes ikke.
20. **Tre kolonner uten overskrift** tolkes som Lab hvis noen verdier er negative eller L ≤ 100, ellers som XYZ.
    XYZ uten oppgitt lys antas å være D50. Riktig standard?
21. **Formater**: CGATS, CxF3 (spekter, Lab, XYZ), CSV/TSV med overskrifter (mange kolonnenavn), ren tallmatrise
    (radvis eller kolonnevis, med eller uten bølgelengder; 16/31/36/41/81/401 verdier), ASE/ACO/ACB som Lab.
    **Argyll .cht** (kortgeometri, ikke verdier) er ikke støttet. Trengs det?
22. Tekst- og XML-filer som slippes på Mine fargerom, leses som referanseverdier.

## Detaljer

23. Kryssvalideringen bruker tonekurven tilpasset på alle feltene (litt optimistisk). Godt nok?
24. Lysmiljø lagret fra en kameramåling får bare et hvitpunkt (ikke spekter), og ses derfor med CAT16, ikke spektralt.
25. Kompensasjon gjelder bare kameraet. Også for bilder (trykk på et gråkort i bildet)?
26. Engelsk: «light environment», «See in light», «As the eye sees it» / «As a photo». Godt?
27. Sjekk sitatet for Burns (Color Research & Application 45(1), 2020) under Metoder.
