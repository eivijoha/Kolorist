# Fargeforståelse – fra lys til opplevelse

Utredning av en læringsmodul i Kolorist (utforsking, ikke vedtatt; skrevet 2026-10-05). Modulen tar brukeren gjennom
fargens vei fra lys via øyet og hjernen til opplevelsen i rommet – med øvelser som bruker appens egne verktøy, og
visualiseringer som gjør det usynlige synlig.

## Formål og prinsipper

- **For hvem:** designere og arkitekter som vil forstå hvorfor farger oppfører seg som de gjør, studenter (Institutt for
  design, NTNU) og alle som bruker Kolorist og lurer på «hvorfor».
- **Lære ved å gjøre** (Albers): hvert tema bygger på øvelser i ekte verktøy, ikke tekst. Teorien kommer etter erfaringen.
- **Bygger på det appen kan:** OKLab/OKLCH, CIELab, Munsell, ICC og gamut, betraktningsforhold og spektre, fargesyn,
  kontrast, harmonier og monokrome serier. Modulen er en vei inn i verktøyene, ikke et eget produkt ved siden av.
- **Vitenskap og tradisjon skilles tydelig:** fargevitenskap (CIE, fargeutseendemodeller) presenteres som målbar
  kunnskap; Goethe, Itten og andre som perspektiver og tradisjon.
- **Ærlig om grensene:** f.eks. at spektre anslått fra fargeverdier ikke kan avsløre metameri, og at fargesyns-
  simulering ikke er diagnose.
- **Alt på enheten:** data (CIE-tabeller, spektre) følger med appen, som resten av Kolorist.

## Oppbygning

Ni kapitler i en naturlig rekkefølge – men hvert kan stå alene og nås fra verktøyet det hører til («Lær mer» ved et
ⓘ). Hvert kapittel har: kjernebegreper, personer og historie, visualiseringer, øvelser og «dette tar du med deg».

### 1. Lys og spekter – Newton og Maxwell

- **Kjerne:** Hvitt lys er en blanding av bølgelengder. Farge er ikke i lyset, men i møtet mellom lys, flate og øye.
  Additiv blanding (lys) mot subtraktiv (pigment, trykk).
- **Historie:** Newtons prismeforsøk og den første fargesirkelen (*Opticks*, 1704) – blanding som tyngdepunkt mellom
  fargene; Maxwells fargematching med tre lys og det første fargefotografiet (1861).
- **Visualiseringer:** interaktiv spekterstripe; spektral effektfordeling for lyskildene appen kjenner (D50, D65,
  standardlys A, lysrør, LED-typer, målt lys); Maxwell-trekant for blanding av tre lys.
- **Øvelser:**
  - *Match fargen med tre lys:* bland rødt, grønt og blått lys (lineært) til du treffer en målfarge – ΔE00 viser hvor nær
    du er. Hvorfor er noen farger umulige å treffe?
  - *Sammenlign lyskildene:* legg D65, varmhvit LED og lysrør over hverandre. Hvilket spekter har «hull»?
- **Tar med deg:** Lysets spekter avgjør hva som kan sees. Skjermen blander lys; trykk filtrerer det bort.

### 2. Øyet – tre tapper og to motfarger (Young, Helmholtz, Hering)

- **Kjerne:** Tre typer tapper (L, M, S) fanger lyset; nervesystemet regner om til motfargekanaler (rød–grønn,
  gul–blå, lys–mørk). Begge teoriene stemmer – på hvert sitt nivå.
- **Visualiseringer:** tappenes følsomhet over spekteret (CIE 2006-tapper); en farge som tre søyler (L, M, S) og som tre
  motfargesignaler; Herings sirkel med de fire elementærfargene.
- **Øvelser:**
  - *Din unike gul:* finn den gule som verken heller mot rødt eller grønt – og sammenlign med gjennomsnittet. Det samme for
    unik grønn, blå og rød. (Menneskers unike kulører varierer – det er poenget.)
  - *Se motfargene:* hvorfor finnes ikke «rødlig grønn» eller «gulaktig blå»?
- **Tar med deg:** Fargesynet er en sammenligning, ikke en måling – og det er derfor fargeavvik oppstår.

### 3. Kromatisitetsdiagrammet – et kart over alle farger

- **Kjerne:** CIE 1931 xy (og u′v′, mer jevnt) viser kromatisitet uavhengig av lyshet. Spektralfargene danner kanten;
  alle virkelige farger ligger innenfor. Fargerom er trekanter (eller former) inni.
- **Visualiseringer (se katalogen):** spektrallokus med bølgelengder; Planck-kurven (sortlegemer) og dagslyskurven med
  lyskildene; gamut for sRGB, Display P3, Adobe RGB, Rec. 2020 og valgt CMYK-profil; aktiv farge og palettens farger
  som punkter; MacAdam-ellipser som viser at diagrammet ikke er perseptuelt jevnt.
- **Øvelser:**
  - *Hvor ligger fargen din?* Flytt fargen i Studio og se punktet vandre. Når forlater den sRGB?
  - *Finn en farge som bare finnes på P3-skjermer* – og se hvorfor den ikke kan trykkes.
  - *Plasser lyset du målte:* se lyset fra Utplukk › Lys på Planck-kurven, med fargetemperatur og avvik (Duv).
  - *Hvorfor OKLab?* Sammenlign like store skritt i xy og i OKLab ved hjelp av ellipsene.
- **Tar med deg:** Gamut-varsler og «utenfor sRGB» blir forståelige når man ser kartet.

### 4. Fargerom i 3D

- **Kjerne:** Farge har tre dimensjoner. Fargerom er former – og formen avslører hvordan rommet er bygget.
- **Visualiseringer:** interaktive 3D-modeller av OKLab/OKLCH, CIELab, Munsell-treet, sRGB-kuben, HSL/HSB, Runges
  fargekule (historisk); gamut-skall for sRGB, P3 og CMYK-profiler; palettens farger som punkter i rommet; den
  monokromatiske flaten som et snitt; harmonier som punkter rundt kuløraksen.
- **Øvelser:**
  - *Hvorfor er gul spiss?* Se sRGB-kuben i OKLab: gul når høy lyshet med mye kroma, blå ikke.
  - *Ditt snitt:* se kvadratet fra Monokromatisk som et snitt gjennom fargelegemet, og drei kuløren.
  - *Skjerm mot trykk:* hvor mye av skjermens gamut dekker CMYK-profilen – og hvor?
  - *Runge (1810) og OKLab (2020):* to kuler, to hundre år imellom.
- **Tar med deg:** Lyshet, kroma og kulør henger sammen; ikke alle kombinasjoner finnes.

### 5. Fargesyn og fargesynsavvik – Dalton

- **Kjerne:** Rundt 8 % av menn har rød–grønn-avvik. Farger som ligger på samme forvekslingslinje, kan ikke skilles.
- **Historie:** John Dalton beskrev sitt eget avvik (1794) – «daltonisme».
- **Visualiseringer:** forvekslingslinjer i kromatisitetsdiagrammet, som stråler fra de kopunktale punktene for protan,
  deutan og tritan; palettens farger som punkter, med varsel når to ligger nær samme linje; simulert visning (som i
  Fargesyn i dag).
- **Øvelser:**
  - *Ligger to på samme linje?* Plasser palettens farger og se hvilke par som forveksles – og flytt én langs lyshets-
    aksen til de skilles.
  - *Lag en palett som tåler deuteranopi* uten å miste karakteren.
- **Tar med deg:** Lyshet er den tryggeste skillelinjen. Ikke en diagnose – en forståelse.

### 6. Fargens relativitet – Chevreul, Goethe og Albers

- **Kjerne:** Ingen farge sees alene. Simultankontrast, assimilering (Bezold), vibrerende kanter, gjennomsiktighet.
- **Historie:** Chevreuls lov om simultankontrast (1839), Goethes fysiologiske farger og etterbilder, Albers'
  *Interaction of Color* (1963).
- **Visualiseringer:** fargen på flere bakgrunner med beregnet forskyvning (fargeutseendemodell, CAM16); etterbilde;
  palett som komposisjon med innfelte kvadrater (inspirert av Albers – uten å gjengi verkene).
- **Øvelser:**
  - *Én farge blir to:* Kolorist foreslår to bakgrunner som får samme farge til å se ulik ut. Kan du finne bedre?
  - *To blir én:* få to ulike farger til å se like ut.
  - *Gjennomsiktighet:* finn mellomfargen som får to flater til å se ut som de overlapper (utgangspunkt: midtpunktet i
    OKLab).
  - *Vibrerende kanter:* to farger med lik lyshet og motsatt kulør.
- **Tar med deg:** Fargen du velger, er ikke fargen som sees – omgivelsen er en del av fargen.

### 7. Lys og betraktningsforhold – konstans, metameri og opplevd farge

- **Kjerne:** Øyet tilpasser seg lyset (fargekonstans, von Kries); kameraet gjør det ikke. Lysstyrken endrer metning
  (Hunt) og lyshet (Helmholtz–Kohlrausch). Fargen en flate *har*, og fargen den *ser ut til å ha*, er ikke det samme.
- **Metameri:** to farger like under ett lys, ulike under et annet (lysmetameri); like for én person, ulike for en annen
  (observatørmetameri – øker med smalbåndet lys og brede skjermer); like for øyet, ulike for kameraet (apparat-
  metameri).
- **Historie:** Edwin Land (retinex), Hunt; nordisk forskning på opplevd farge i arkitektur (f.eks. Karin Fridell Anter
  om fasadefarger).
- **Visualiseringer:** «Slik øyet ser det» mot «Som et foto»; et metamert par som to ulike spektre som krysser hverandre,
  og ΔE00 mellom dem under hvert lys; observatørmetameri med CIE 2006-observatør for ulike aldre; samme farge i
  morgen-, kontor- og kveldslys.
- **Øvelser:**
  - *Hvilken farge har huset?* Se samme fasadefarge under dagslys, overskyet vær og gatelys.
  - *Finn paret som skiller lag i butikklys* (med ekte eller konstruerte spektre).
  - *Mål lyset der du er* og se paletten din i det.
- **Ærlig grense:** spektre anslått fra fargeverdier gir to like skjermfarger samme spekter – metameri mellom fysiske
  prøver krever målte spektre. Modulen bør si det tydelig.
- **Tar med deg:** En fargematch gjelder alltid for ett lys og én observatør.

### 8. Orden og harmoni – fra Newton til Munsell

- **Kjerne:** Fargesirkler og fargesystemer er ulike svar på hva «motsatt» og «jevnt» betyr.
- **Historie:** Newton, Goethe, Runge, Munsell (valør og kroma), Ostwald (skyggeserier), Itten (sju kontraster), Hering.
- **Visualiseringer:** samme farge og dens komplementærfarge i seks sirkler (OKLCH, CIE LCH, HSL, RYB, Munsell,
  Hering, Goethe); Ittens kontraster for en palett som et diagram; arealbalanse etter lyshet.
- **Øvelser:**
  - *Finn komplementærfargen i fem sirkler* – hvorfor blir svaret ulikt?
  - *Lag en skyggeserie* (Ostwald) med Monokromatisk.
  - *Balanser arealene:* gi lyse farger mindre plass (Goethes lysverdier, Ittens kvantitetskontrast).
  - *Abney-effekten:* lysne blått i HSL og i OKLCH – hvorfor blir HSL-tonene fiolette?
- **Tar med deg:** Harmoni er orden i et valgt system – velg systemet med vilje.

### 9. Fra skjerm til materiale

- **Kjerne:** ICC-fargestyring, gamut, gjengivelseshensikter, papirhvitt og betraktningsforhold i praksis; filament og
  maling.
- **Øvelser:** *Se papirhvitt* (absolutt kolorimetrisk), *hvorfor blir trykket matt?*, *finn nærmeste filament og se
  avviket*.
- **Tar med deg:** Hva som skjer med fargen på veien ut av skjermen.

## Visualiseringskatalog

| Visualisering | Viser | Brukes i | Teknisk grunnlag |
|---|---|---|---|
| Spekterstripe og spektral effektfordeling | Lysets sammensetning; lyskildenes spektre | 1, 7 | Spektre i FargeMaaling (CIE-dagslys, A, FL, LED, målt) |
| Maxwell-trekant | Additiv blanding av tre lys | 1 | Lineær RGB, OKLab for avstand |
| Tappenes følsomhet (LMS) | Hvordan øyet deler opp spekteret | 2, 5 | CIE 2006-tapper (CVRL-data, åpne) |
| Kromatisitetsdiagram (xy, u′v′) | Alle farger på ett kart | 3, 5, 7 | CIE 1931/1964 fargematchingsfunksjoner |
| Gamut-trekanter og -former | sRGB, P3, Adobe RGB, Rec. 2020, CMYK-profil | 3, 9 | Primærer; CMYK-gamut ved prøving gjennom profilen |
| Planck- og dagslyskurve | Lyskildenes plass; CCT og Duv | 3, 7 | Sortlegemeformel; CIE-dagslys; målt lys |
| MacAdam-ellipser | At xy ikke er perseptuelt jevnt | 3 | Publiserte ellipser |
| Forvekslingslinjer | Hvilke farger som forveksles ved protan, deutan, tritan | 5 | Kopunktale punkter (u′v′/xy), linjer gjennom palettens farger |
| 3D-fargelegemer | OKLab, CIELab, Munsell, sRGB-kube, HSL, Runges kule | 4, 8 | Gitter i fargerommet; mesh av gamut-kanten |
| Gamut-skall i 3D | Hva skjerm og trykk kan vise | 4, 9 | `maksKroma` per lyshet og kulør; ICC-prøving for CMYK |
| Snittplan | Monokromatisk flate som snitt | 4, 8 | Kuløren fra Monokromatisk |
| Bakgrunnsforskyvning | Simultankontrast beregnet | 6 | Fargeutseendemodell (CAM16) med bakgrunn |
| Metamert par | To spektre, samme farge – til lyset endres | 7 | Konstruerte eller målte refleksjonsspektre |
| Observatør etter alder | Observatørmetameri | 7 | CIE 2006 aldersavhengig observatør |
| Abney-stripe | Kulørdrift i HSL mot OKLCH | 8 | HSL og OKLCH |
| Kontrastdiagram (Itten) | Hvilke kontraster en palett bruker | 8 | Lyshet, kroma, kulør og areal i OKLCH |

**Plattform:** 2D tegnes med SwiftUI Canvas (som flatene i dag). 3D kan bygges med RealityKit eller Swift Charts
(3D-diagrammer er tilgjengelige i nyere iOS og macOS); begge virker på iPhone, iPad og Mac. Visualiseringene bør
følge aktiv farge og palett, så de er knyttet til arbeidet brukeren gjør.

## Øvelsesformat

Hver øvelse har samme form:

1. **Mål** – én setning om hva du skal se eller oppnå.
2. **Oppgave** – med verktøyet åpnet riktig (f.eks. Studio i Monokromatisk med en gitt farge).
3. **Sjekk** – automatisk der det går (ΔE00 innenfor et mål, to farger på hver sin forvekslingslinje), ellers egen
   vurdering.
4. **Hvorfor** – kort forklaring og visualiseringen.
5. **Les mer** – lenke til «Metoder og kilder».

Fremdrift lagres lokalt; ingen poeng eller karakter. **For undervisning:** en øvelse kan deles som lenke (som
delingslenkene i dag), så en lærer kan sende samme oppgave til en hel klasse.

## Plassering

- **I appen:** en egen inngang «Lær» (f.eks. fra Paletter-oversikten og Hjelp-menyen på Mac), og «Lær mer» ved et ⓘ i
  verktøyene som fører rett til riktig kapittel.
- **På kolorist.no:** kapitlene som egne sider (med lenke til øvelsen i appen) – nyttig i undervisning og for å bli
  funnet.

## Faglige forbehold

- Goethe og Itten er dels subjektive – presenteres som tradisjon.
- Fargesynssimulering er ikke diagnose.
- Albers' verk er vernet: øvelsene bygger på ideene, uten å gjengi bildene.
- Proprietære fargesystemer nevnes ikke i markedsføring.
- Spektre anslått fra fargeverdier har klare grenser (metameri); målte data der det finnes.

## Mulige trinn

1. **Først:** kromatisitetsdiagram med gamuter og lyskilder (Studio og Lys), forvekslingslinjer i Fargesyn, og en
   3D-visning av gamut og palett. Tre–fire øvelser knyttet til disse.
2. **Deretter:** læringsmodulen med kapittel 1–5 og øvelsesformatet.
3. **Senere:** relativitet (CAM16-bakgrunn), metameri med spektrale data, observatør etter alder, deling av øvelser for
   undervisning, og kapitlene på kolorist.no.

## Kilder (utvalg)

- Isaac Newton: *Opticks* (1704)
- J. W. von Goethe: *Zur Farbenlehre* (1810); P. O. Runge: *Die Farben-Kugel* (1810)
- M. E. Chevreul: *De la loi du contraste simultané des couleurs* (1839)
- J. C. Maxwell: fargematching og fargefotografi (1855–1861); John Dalton om eget fargesyn (1794)
- H. von Helmholtz; E. Hering: *Zur Lehre vom Lichtsinne* (1878)
- A. H. Munsell: *A Color Notation* (1905); W. Ostwald: *Die Farbenfibel* (1916)
- J. Itten: *Kunst der Farbe* (1961); J. Albers: *Interaction of Color* (1963)
- CIE 15:2018 *Colorimetry*; CIE 170-1:2006 *Fundamental chromaticity diagram with physiological axes*
- G. Wyszecki og W. S. Stiles: *Color Science* (1982); M. D. Fairchild: *Color Appearance Models* (3. utg. 2013)
- E. H. Land: retinex-teorien (1977); K. Fridell Anter: *What colour is the red house?* (2000)
- J.-P. Lenclos: fargenes geografi
