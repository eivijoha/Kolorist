# App Store Connect og App Review – Kolorist 1.2 (arbeidsutkast)

Utgangspunktet er tekstene for 1.1 (`Dokumentasjon/1.1/AppStore.md`). Endringer som skal med til 1.2:

- [x] Beskrivelsen (iOS, nb/en): «sammenlign gjengivelseshensiktene med ΔE2000» → «undersøk fargeforskjell med ΔE2000»
      / «compare rendering intents with ΔE2000» → «investigate colour difference with ΔE2000». (Nettsiden er allerede rettet.)
- [x] «Nytt i denne versjonen» for 1.2 – utkast under (iOS og Mac, nb/en).
- [ ] Beskrivelsen: legg inn et avsnitt om lys og fargemåling (utkast under).
- [x] Kameraforklaringen (systemspørsmålet) nevner nå lysmåling.
- [ ] Personvernetiketten er uendret («Data Not Collected»): lysmiljøer, referansekort og kameraprofiler ligger i
      brukerens egen iCloud (nøkkel–verdi), og stillbildet av kortet brukes bare på enheten.
- [x] Skjermbilder i `Dokumentasjon/1.2/Skjermbilder/` (iPhone 6,5″, iPad 13″, Mac; nb og en): Studio, Harmoni,
      Overgang, Kontrast, Fargesyn og «Se i lys». Tatt med `-skjermbilde YES` og samme argumenter som for 1.1;
      «Se i lys» med `-panelFørst lys`. Mac med `-testmaalinger YES -kunSRGB NO`.

### Utkast: Nytt i 1.2 – iPhone og iPad, norsk

```
Kolorist 1.2 tar lyset med i regnestykket.

• Se i lys: se farger og hele paletter slik de oppleves i lyset der de skal brukes – egne lysmiljøer eller standard betraktningsforhold for grafisk vurdering, arbeidsplasser, skoler og museer.
• Farger slik de egentlig er: kompenser farger du plukker for lyset de ble fotografert i – også i bilder.
• Gråkort og referansekort: få riktig farge og lyshet, og mål fargetemperatur og belysningsstyrke. Kalibrer kameraet én gang med et referansekort – deretter holder et gråkort, også i et annet lys.
• Vurdering i lys: farger som skifter karakter, og fargepar som blir vanskelige å skille i svakt lys eller under lysrør og LED.
• LRV og luminanskontrast i valgt lys, for bygg og interiør.
• Delingsmappe: palettene som filer i en mappe i skytjenesten du bruker – også for kolleger på Windows.
• Nye harmonier: analog med komplementær aksent, triade og kvadrat – og naturlig lyshetsrekkefølge, der gule farger blir lysere og blå mørkere, som i naturen.
• Munsell i trinnene fra Munsell-boka, og verdiene fra fargesirkelen for hver farge i harmonier.
```

### Utkast: Nytt i 1.2 – iPhone og iPad, engelsk

```
Kolorist 1.2 brings light into the equation.

• See in light: see colours and whole palettes as they appear in the light where they will be used – your own viewing conditions or standard viewing conditions for graphic arts, workplaces, schools and museums.
• Colours as they really are: compensate the colours you pick for the light they were photographed in – in photos too.
• Grey cards and reference cards: get the right colour and lightness, and measure colour temperature and illuminance. Calibrate the camera once with a reference card – after that a grey card is enough, even in different light.
• Critique in light: colours that change character, and colour pairs that become hard to tell apart in dim light or under fluorescent and LED lighting.
• LRV and luminance contrast in the chosen light, for buildings and interiors.
• Sharing folder: your palettes as files in a folder in the cloud service you use – for colleagues on Windows too.
• New harmonies: analogous with a complementary accent, triad and square – and natural lightness order, where yellows become lighter and blues darker, as in nature.
• Munsell in the steps of the Munsell book, and the colour-wheel values for each colour in harmonies.
```

### Utkast: Nytt i 1.2 – Mac

Mac-versjonen gikk rett til 1.1. For 1.2 gjelder samme punkter, men lysmåling skjer på iPhone/iPad. Bytt punkt 2–3 med:

```
• Se farger og paletter i lysmiljøene du har målt på iPhone – de synkroniseres via iCloud.
• Med iPhone som kamera (Continuity) kan fargene kompenseres med gråkort eller referansekort.
```
```
• See colours and palettes in the viewing conditions you measured on iPhone – they sync through iCloud.
• With iPhone as the camera (Continuity), colours can be compensated with a grey card or reference card.
```

### Utkast: avsnitt til beskrivelsen

```
LYS OG FARGEMÅLING
Se farger og paletter slik de oppleves i lyset der de skal brukes. Kompenser farger du plukker for lyset, og bruk et gråkort eller et referansekort for riktig farge og lyshet, fargetemperatur og belysningsstyrke.
```
```
LIGHT AND COLOUR MEASUREMENT
See colours and palettes as they appear in the light where they will be used. Compensate the colours you pick for the light, and use a grey card or reference card for the right colour and lightness, colour temperature and illuminance.
```

---

## 1. App-informasjon (gjelder alle versjoner)

| Felt | Verdi |
|---|---|
| Navn (30) | **Kolorist** – er navnet opptatt: «Kolorist – fargepaletter» / «Kolorist: Colour Palettes» |
| Bundle-ID | `no.engenett.Kolorist` |
| SKU | `kolorist-2026` (bare til eget bruk) |
| Primærkategori | Grafikk og design (Graphics & Design) |
| Sekundærkategori | Produktivitet (Productivity) |
| Opphavsrett | `2026 Eivind Arnstein Johansen` |
| Innholdsrettigheter | Nei, appen inneholder ikke, viser ikke og gir ikke tilgang til innhold fra tredjeparter |
| Aldersgrense | Svar «Nei/Ingen» på alt i spørreskjemaet → 4+. Ingen nettleser, ingen brukerinnhold som deles, ingen kjøp i appen. |
| Pris | Velg selv (gratis eller betalt). Ingen kjøp i appen. |
| Lisensavtale | Apples standard EULA |

### URL-er

| Felt | Norsk | Engelsk |
|---|---|---|
| Support URL | `https://kolorist.no/support.html` | `https://kolorist.no/en/support.html` |
| Marketing URL | `https://kolorist.no/` | `https://kolorist.no/en/` |
| Privacy Policy URL | `https://kolorist.no/privacy.html` | `https://kolorist.no/en/privacy.html` |

Nettsiden må være publisert før innsending; App Review åpner support- og personvernsidene.

### App Privacy (personvernetiketten)

- «Do you or your third-party partners collect data from this app?» → **No, we do not collect data from this app.**
- Resultat: **Data Not Collected**.
- Begrunnelse: ingen egne servere, ingen analyse, ingen krasjrapportering fra tredjepart, ingen reklame.
  CloudKit-synk går til brukerens private database, og det regnes ikke som innsamling hos utvikleren.
  Apple Intelligence kjøres på enheten.

### Eksportregler (kryptering)

Appen bruker bare kryptering som er innebygd i Apples operativsystem (HTTPS/CloudKit). Svar
**«None of the algorithms mentioned above»** / ingen ikke-unntatt kryptering. Settes
`ITSAppUsesNonExemptEncryption = NO` i Info.plist, slipper du spørsmålet ved hver opplasting (ikke lagt inn ennå).

---

## 2. Versjonstekster – iPhone og iPad, norsk (bokmål)

**Undertittel (30)** – uendret

```
Fargepaletter for designere
```

**Reklametekst (170)** – kan endres uten ny versjon

```
Bygg paletter i OKLCH, CMYK med ICC-profiler og Munsell, kontroller kontrast og fargesyn-problematikk, og kopier fargene rett inn i annen design-programvare.
```

**Nytt i denne versjonen (4000)**

```
Kolorist 1.1 er laget for flere fagfelt – også arkitektur og interiør – og gjør det raskere å jobbe med paletter.

• Fargebiblioteker: importer egne fargekart i ASE, ACO eller ACB med navngitte toner. Farger, toner og harmonier låses til bibliotekets toner, og Studio viser tonenavnene.
• Munsell: ny fargemodell med kulør i steg på 2,5, valør og kroma – og Munsells og Herings fargesirkler for harmonier.
• Harmoni: se hele harmonier i valgt fargerom med verdier eller tonenavn, med grunnfarger tydelig merket.
• LRV: lysrefleksjonsverdi og flatekontrast etter BS 8300 og NS 11001 – for bygg og interiør.
• Rec. 2020 og ProPhoto RGB som innebygde fargerom.
• Egne ICC-profiler og fargebiblioteker samles på ett sted, importeres i én operasjon og kan slettes fra appen.
• Paletter for hånden på store iPader: flytt farger dit du trenger dem med dra og slipp.
• Farger du plukker fra kamera og bilder, tas vare på til du bestemmer deg for å lagre dem.
• Raskere arbeid med paletter: bruk en farge direkte, og vurder, kontroller kontrast og skriv ut hele paletter.
• Angre overalt, også med ⌘Z på tastatur.
• Paneler kan legges sammen og flyttes, og verdier kan skjules og sorteres – oppsettet synkroniseres.
• Bedre paletter fra verdiord: bygget etter harmoniprinsipper med lesbar kontrast.
• Vurderinger av paletter viser hva de bygger på.
• Gradienter i paletter, og «Kopier til» for gradienter: Figma, Sketch, Affinity, Illustrator, InDesign, Photoshop, Pages, Keynote, Numbers, CSS og SwiftUI.
• Skriv ut en palett på A4 – fargeflater i CIELab med navn og verdier – eller lagre den som PDF.
```

**Beskrivelse (4000)**

```
Kolorist er et fargeverktøy for designere og arkitekter på iPhone, iPad og Mac. Bygg paletter på tvers av fargerom, med perseptuelt jevne overganger, kontrastsjekk, simulering av fargesyn, ICC-profiler og egne fargebiblioteker – og få fargene inn i verktøyene du allerede bruker.

ALLE FARGEROM
• Rediger i OKLCH, OKLab, CIE LCH, CIELab, Munsell, HSB, HSL, RGB og CMYK
• Display P3 side om side med sRGB, Adobe RGB, Rec. 2020, ProPhoto RGB, CMYK eller en hvilken som helst ICC-profil
• Varsel når fargen er utenfor fargeområdet – farger kartlegges inn i fargerommet uten å klippes
• Angi CMYK eller RGB direkte i en valgt ICC-profil
• Rene CMYK-verdier: grått innslag flyttes til sort (UCR/GCR)
• Feltet for fargeverdi forstår hex, CSS-farger, Munsell-notasjon og vanlige beskrivelser som «dyp havblå»

FARGEBIBLIOTEKER OG ICC-PROFILER
• Importer egne fargekart i ASE, ACO eller ACB (Adobe Color Book) med navngitte toner
• Farger, toner og harmonier låses til bibliotekets toner, og Studio viser tonenavnene
• Importer egne .icc- og .icm-profiler
• Alt samles på ett sted og følger med til de andre enhetene dine via iCloud Drive
• Konverter mellom profiler, og undersøk fargeforskjell med ΔE2000

OVERGANGER, TONER OG HARMONIER
• Overganger i like perseptuelle steg i OKLab, med lysere og mørkere rader
• CSS-gradient i oklab med sRGB-reserve – lineær, radiell eller konisk
• Toneskalaer fra 50 til 950
• Komplementær, split-komplementær, analog med eller uten aksent, triade, kvadrat og jevn fordeling på fargesirkel i OKLCH, CIE LCH, Munsell, Hering, HSL eller RYB – med naturlig lyshetsrekkefølge om du vil

TILGJENGELIGHET OG FARGESYN
• WCAG 2.2-kontrast: AA og AAA, stor tekst og grafikk, og «Rett opp» som justerer fargen til den består
• Flatekontrast med LRV (lysrefleksjonsverdi) etter BS 8300 og NS 11001 – for dører, vegger, gulv og skilt
• Kontrastmatrise og vurdering av hele paletter
• Se paletter med protan-, deutan- og tritanavvik og akromatopsi – og hvilke farger som blir vanskelige å skille
• Kamera med fargesynsfilter: se omgivelsene slik de kan oppleves med hvert avvik

PLUKK FARGER
• Kamera med zoom, makrofokus og lykt
• Bilder, med dominerende farger
• Farger du plukker, tas vare på til du lagrer dem
• Skjermpipette på Mac

APPLE INTELLIGENCE PÅ ENHETEN
• Fra verdiord til palett – «trygg, varm, nordisk» – forankret i en kunnskapsbase med over hundre fargebegreper
• Paletter bygges etter harmoniprinsipper – lik valør eller metning, aksentfarge, lys eller mørk bakgrunn – med lesbar kontrast
• Beskriv en farge og se den i Studio
• Juster med fritekst, navngi farger og få vurdering av paletter
Alt kjøres på enheten. Uten Apple Intelligence lages paletter direkte fra kunnskapsbasen.

KOPIER TIL OG EKSPORT
• «Kopier til» designverktøy, layout-, bilde- og presentasjonsprogrammer – i formatet hvert program tar imot
• Dra fargeprøver rett inn i andre programmer på Mac
• Eksport til ASE- og ACO-fargeprøver, Design Tokens (DTCG), SVG, CSS, GPL, SwiftUI og hex
• Farger eksporteres i formatet de er lagret i – for eksempel som CMYK
• Skriv ut paletter på A4: fargeflater i CIELab med navn og verdier

PALETTER OG ICLOUD
Samle farger og gradienter i paletter, lagre enkeltfarger og hele gradienter, og synkroniser via din egen, private iCloud. På store iPader har du paletter for hånden mens du jobber, og flytter farger dit du trenger dem. Angre det du gjør, også med ⌘Z.

SIRI OG SNARVEIER
Lag palett fra verdiord, beskriv en farge, lag overgang, konverter farge og sjekk kontrast.

ÅPENT OM METODENE
Hver del av appen viser hvilke metoder den bygger på – OKLab, CSS Color 4, CIEDE2000, WCAG, LRV, Munsell, simulering av fargesyn og ICC – med kilde og forklaring.

PERSONVERN
Ingen konto, ingen analyse, ingen reklame og ingen sporing. Utvikleren samler ikke inn data.

Krever iOS 26, iPadOS 26 eller macOS 26. Apple Intelligence krever en støttet enhet.
```

**Nøkkelord (100, kommaseparert uten mellomrom)**

```
farge,palett,fargekart,OKLCH,CMYK,ICC,Munsell,LRV,kontrast,WCAG,overgang,pipette,harmoni,fargeblind
```

---

## 3. Versjonstekster – iPhone og iPad, engelsk

**Subtitle (30)** – unchanged

```
Colour palettes for designers
```

**Promotional text (170)**

```
Build palettes in OKLCH, CMYK with ICC profiles and Munsell, check for contrast and colour vision challenges, and copy colours straight into other design software.
```

**What’s New in This Version (4000)**

```
Kolorist 1.1 reaches more disciplines – including architecture and interiors – and makes working with palettes faster.

• Colour libraries: import your own colour charts in ASE, ACO or ACB with named tones. Colours, tones and harmonies are locked to the library’s tones, and Studio shows the tone names.
• Munsell: a new colour model with hue in steps of 2.5, value and chroma – and the Munsell and Hering colour wheels for harmonies.
• Harmony: see the whole harmony in the chosen colour space with values or tone names, with the base colour clearly marked.
• LRV: light reflectance value and surface contrast to BS 8300 and NS 11001 – for buildings and interiors.
• Rec. 2020 and ProPhoto RGB as built-in colour spaces.
• Your own ICC profiles and colour libraries are gathered in one place, imported in one step and can be deleted in the app.
• Palettes at hand on large iPads: move colours where you need them with drag and drop.
• Colours you pick from the camera and photos are kept until you decide to save them.
• Faster work with palettes: use a colour directly, and critique, check contrast and print whole palettes.
• Undo everywhere, including ⌘Z on a keyboard.
• Panels can be collapsed and reordered, and values hidden and sorted – the layout syncs.
• Better palettes from value words: built on harmony principles with legible contrast.
• A palette critique now shows what it is based on.
• Gradients in palettes, and “Copy to” for gradients: Figma, Sketch, Affinity, Illustrator, InDesign, Photoshop, Pages, Keynote, Numbers, CSS and SwiftUI.
• Print a palette on A4 – CIELab swatches with names and values – or save it as a PDF.
```

**Description (4000)**

```
Kolorist is a colour tool for designers and architects on iPhone, iPad and Mac. Build palettes across colour spaces, with perceptually even gradients, contrast checks, colour vision simulation, ICC profiles and your own colour libraries – and get your colours into the tools you already use.

EVERY COLOUR SPACE
• Edit in OKLCH, OKLab, CIE LCH, CIELab, Munsell, HSB, HSL, RGB and CMYK
• Display P3 side by side with sRGB, Adobe RGB, Rec. 2020, ProPhoto RGB, CMYK or any ICC profile
• Out-of-gamut warnings – colours are gamut-mapped, never clipped
• Enter CMYK or RGB directly in a chosen ICC profile
• Clean CMYK values: grey components move to black (UCR/GCR)
• The colour field understands hex, CSS colours, Munsell notation and plain descriptions like “deep ocean blue”

COLOUR LIBRARIES AND ICC PROFILES
• Import your own colour charts in ASE, ACO or ACB (Adobe Color Book) with named tones
• Colours, tones and harmonies are locked to the library’s tones, and Studio shows the tone names
• Import your own .icc and .icm profiles
• Everything is gathered in one place and follows you to your other devices through iCloud Drive
• Convert between profiles, and investigate colour difference with ΔE2000

GRADIENTS, TONES AND HARMONIES
• Gradients in equal perceptual steps in OKLab, with lighter and darker rows
• CSS gradients in oklab with an sRGB fallback – linear, radial or conic
• Tone scales from 50 to 950
• Complementary, split complementary, analogous with or without an accent, triad, square and even distributions on an OKLCH, CIE LCH, Munsell, Hering, HSL or RYB colour wheel – with natural lightness order if you like

ACCESSIBILITY AND COLOUR VISION
• WCAG 2.2 contrast: AA and AAA, large text and graphics, and auto-fix that adjusts the colour until it passes
• Surface contrast with LRV (light reflectance value) to BS 8300 and NS 11001 – for doors, walls, floors and signage
• Contrast matrix and critique of the whole palette
• See the palette with protan, deutan and tritan deficiencies and achromatopsia – and which colours become hard to tell apart
• Camera with a colour vision filter: see your surroundings as they may appear with each deficiency

PICK COLOURS
• Camera with zoom, macro focus and torch
• Photos, with dominant colours
• Colours you pick are kept until you save them
• Screen eyedropper on Mac

APPLE INTELLIGENCE ON DEVICE
• From value words to a palette – “calm, warm, Nordic” – grounded in a knowledge base of more than a hundred colour concepts
• Palettes are built on harmony principles – equal value or saturation, an accent colour, a light or dark background – with legible contrast
• Describe a colour and see it in Studio
• Adjust with free text, name colours and get a critique of your palette
Everything runs on device. Without Apple Intelligence, palettes are built straight from the knowledge base.

COPY TO AND EXPORT
• “Copy to” design tools, layout, photo and presentation apps – in the format each app accepts
• Drag swatches straight into other apps on Mac
• Export to ASE and ACO swatches, Design Tokens (DTCG), SVG, CSS, GPL, SwiftUI and hex
• Colours are exported in the format they were saved in – for example as CMYK
• Print the palette on A4: CIELab swatches with names and values

PALETTES AND ICLOUD
Collect colours and gradients in palettes, save single colours and whole gradients, and sync through your own private iCloud. On large iPads your palettes are at hand while you work, and you move colours where you need them. Undo what you do, including with ⌘Z.

SIRI AND SHORTCUTS
Create a palette from value words, describe a colour, create a gradient, convert a colour and check contrast.

OPEN ABOUT METHODS
Every part of the app shows the methods it builds on – OKLab, CSS Color 4, CIEDE2000, WCAG, LRV, Munsell, colour vision simulation and ICC – with source and explanation.

PRIVACY
No account, no analytics, no ads and no tracking. The developer collects no data.

Requires iOS 26, iPadOS 26 or macOS 26. Apple Intelligence requires a supported device.
```

**Keywords (100)**

```
colour,color,palette,picker,OKLCH,CMYK,ICC,Munsell,LRV,contrast,WCAG,gradient,eyedropper,colorblind
```

---

## 3b. Mac-versjonen (macOS) – norsk (bokmål)

**Mac-versjonen slippes rett som 1.1** (1.0 for Mac ble trukket før publisering). Den er dermed første versjon på Mac,
og App Store Connect viser ikke feltet «Nytt i denne versjonen» – bruk bare reklametekst, beskrivelse og nøkkelord under.
Alt som er nytt i 1.1, står derfor også i Mac-beskrivelsen under. «Nytt i denne versjonen» for Mac står igjen til en
senere versjon.

macOS har egen versjonsside i App Store Connect, med egen reklametekst, beskrivelse, nøkkelord, «Nytt i denne versjonen»
og skjermbilder. Navn og undertittel er felles (App-informasjon), og iPad deler tekst med iPhone. Support- og
markedsførings-URL er de samme som for iOS.

**Reklametekst (170)**

```
Bygg paletter i OKLCH, CMYK med ICC-profiler og Munsell, kontroller kontrast og fargesyn, plukk farger fra hele skjermen og dra dem rett inn i annen design-programvare.
```

**Nytt i denne versjonen (4000)**

```
Kolorist 1.1 er laget for flere fagfelt – også arkitektur og interiør – og utnytter Mac-vinduet bedre.

• Paletter for hånden: i et bredt vindu har du paletter ved siden av verktøyene hele tiden.
• Dra og slipp: flytt farger fra paletter dit du jobber – og hent farger inn fra systemets fargepanel og andre programmer.
• Fargebiblioteker: importer egne fargekart i ASE, ACO eller ACB med navngitte toner. Farger, toner og harmonier låses til bibliotekets toner, og Studio viser tonenavnene.
• Munsell: ny fargemodell med kulør i steg på 2,5, valør og kroma – og Munsells og Herings fargesirkler for harmonier.
• Harmoni: se hele harmonier i valgt fargerom med verdier eller tonenavn, med grunnfarger tydelig merket.
• LRV: lysrefleksjonsverdi og flatekontrast etter BS 8300 og NS 11001 – for bygg og interiør.
• Rec. 2020 og ProPhoto RGB som innebygde fargerom.
• Egne ICC-profiler og fargebiblioteker samles på ett sted, importeres i én operasjon og kan slettes fra appen.
• Farger du plukker fra kamera, bilder og skjermen, tas vare på til du bestemmer deg for å lagre dem.
• Kamera: målepunktet følger pekeren, og et klikk fanger fargen der.
• Angre (⌘Z) overalt.
• Gradienter i paletter, og «Kopier til» for gradienter: Figma, Sketch, Affinity, Illustrator, InDesign, Photoshop, Pages, Keynote, Numbers, CSS og SwiftUI.
• Skriv ut en palett (⌘P) på A4 – fargeflater i CIELab med navn og verdier – eller arkiver den som PDF.
• Raskere arbeid med paletter: bruk en farge direkte, og vurder, kontroller kontrast og skriv ut hele paletter.
• Paneler kan legges sammen og flyttes, og verdier kan skjules og sorteres – oppsettet synkroniseres.
• Bedre paletter fra verdiord: bygget etter harmoniprinsipper med lesbar kontrast.
```

**Beskrivelse (4000)**

```
Kolorist er et fargeverktøy for designere og arkitekter på Mac – og på iPhone og iPad med samme kjøp. Bygg paletter på tvers av fargerom, med perseptuelt jevne overganger, kontrastsjekk, simulering av fargesyn, ICC-profiler og egne fargebiblioteker – og få fargene inn i programmene du allerede bruker.

PLUKK OG DRA
• Skjermpipette som plukker farger fra hvor som helst på skjermen
• Dra fargeprøver inn i andre programmer og fargebrønner – og dra farger inn fra dem
• Paletter for hånden i et bredt vindu
• Bilder, med dominerende farger
• Kamera, også iPhone som kamera, med lysfelt på skjermen – målepunktet følger pekeren
• Farger du plukker, tas vare på til du lagrer dem
• Kopier aktiv farge som OKLCH med ⌥⌘C, lim inn en farge med ⌥⌘V, og angre med ⌘Z

ALLE FARGEROM
• Rediger i OKLCH, OKLab, CIE LCH, CIELab, Munsell, HSB, HSL, RGB og CMYK
• Display P3 side om side med sRGB, Adobe RGB, Rec. 2020, ProPhoto RGB, CMYK eller en hvilken som helst ICC-profil
• Varsel utenfor fargeområdet – farger kartlegges, aldri klippes
• Angi CMYK eller RGB direkte i en valgt ICC-profil
• Rene CMYK-verdier: grått innslag flyttes til sort (UCR/GCR)
• Feltet for fargeverdi forstår hex, CSS-farger, Munsell-notasjon og vanlige beskrivelser som «dyp havblå»

FARGEBIBLIOTEKER OG ICC-PROFILER
• Importer egne fargekart i ASE, ACO eller ACB (Adobe Color Book) med navngitte toner
• Farger, toner og harmonier låses til bibliotekets toner, og Studio viser tonenavnene
• Bruk profiler som er installert på Macen, etter mappe
• Importer egne .icc- og .icm-profiler
• Alt samles på ett sted og følger med til iPhone og iPad via iCloud Drive
• Konverter mellom profiler med valgfri gjengivelseshensikt

OVERGANGER, TONER OG HARMONIER
• Overganger i like perseptuelle steg i OKLab, med lysere og mørkere rader
• CSS-gradient i oklab med sRGB-reserve – lineær, radiell eller konisk
• Toneskalaer fra 50 til 950
• Komplementær, split-komplementær, analog med eller uten aksent, triade, kvadrat og jevn fordeling på fargesirkel i OKLCH, CIE LCH, Munsell, Hering, HSL eller RYB – med naturlig lyshetsrekkefølge om du vil
• Se hele harmonier i valgt fargerom eller fargebibliotek, med grunnfargen merket

TILGJENGELIGHET OG FARGESYN
• WCAG 2.2-kontrast (AA og AAA), med «Rett opp» til fargen består
• Flatekontrast med LRV (lysrefleksjonsverdi) etter BS 8300 og NS 11001 – for bygg og interiør
• Kontrastmatrise og vurdering av hele paletter
• Se paletter med protan-, deutan- og tritanavvik og akromatopsi – og hvilke farger som blir vanskelige å skille
• Kamera med fargesynsfilter

APPLE INTELLIGENCE PÅ MACEN
• Fra verdiord til palett – «trygg, varm, nordisk» – forankret i en kunnskapsbase med over hundre fargebegreper
• Paletter bygges etter harmoniprinsipper med lesbar kontrast
• Beskriv en farge og se den i Studio
• Juster med fritekst, navngi farger og få vurdering av paletter
Alt kjøres lokalt. Uten Apple Intelligence lages paletter direkte fra kunnskapsbasen.

KOPIER TIL OG EKSPORT
• «Kopier til» designverktøy, layout-, bilde- og presentasjonsprogrammer – i formatet hvert program tar imot, også gradienter
• Eksport til ASE- og ACO-fargeprøver, Design Tokens (DTCG), SVG, CSS, GPL, SwiftUI og hex
• Farger eksporteres i formatet de er lagret i – for eksempel som CMYK
• Skriv ut paletter (⌘P) på A4 – fargeflater i CIELab med navn og verdier – eller arkiver som PDF

PALETTER OG ICLOUD
Samle farger og gradienter i paletter, lagre enkeltfarger og hele gradienter, og synkroniser med iPhone og iPad via din egen, private iCloud. Tilpass visningen til arbeidet ditt.

SIRI OG SNARVEIER
Lag palett fra verdiord, beskriv en farge, lag overgang, konverter farge og sjekk kontrast.

ÅPENT OM METODENE
Hver del av appen viser metodene den bygger på, med kilde og forklaring.

PERSONVERN
Ingen konto, ingen analyse, ingen reklame og ingen sporing. Utvikleren samler ikke inn data.

Krever macOS 26. Apple Intelligence krever en Mac med Apple-chip.
```

**Nøkkelord (100)**

```
farge,palett,fargekart,pipette,OKLCH,CMYK,ICC,Munsell,LRV,kontrast,WCAG,overgang,harmoni,fargeblind
```

---

## 3c. Mac-versjonen (macOS) – engelsk

**Promotional text (170)**

```
Build palettes in OKLCH, CMYK with ICC profiles and Munsell, check contrast and colour vision, pick colours anywhere on screen and drag them into other design apps.
```

**What’s New in This Version (4000)**

```
Kolorist 1.1 reaches more disciplines – including architecture and interiors – and makes better use of the Mac window.

• Palettes at hand: in a wide window your palettes stay beside the tools all the time.
• Drag and drop: move colours from your palettes to where you work – and bring colours in from the system colour panel and other apps.
• Colour libraries: import your own colour charts in ASE, ACO or ACB with named tones. Colours, tones and harmonies are locked to the library’s tones, and Studio shows the tone names.
• Munsell: a new colour model with hue in steps of 2.5, value and chroma – and the Munsell and Hering colour wheels for harmonies.
• Harmony: see the whole harmony in the chosen colour space with values or tone names, with the base colour clearly marked.
• LRV: light reflectance value and surface contrast to BS 8300 and NS 11001 – for buildings and interiors.
• Rec. 2020 and ProPhoto RGB as built-in colour spaces.
• Your own ICC profiles and colour libraries are gathered in one place, imported in one step and can be deleted in the app.
• Colours you pick from the camera, photos and the screen are kept until you decide to save them.
• Camera: the sampling point follows the pointer, and a click captures the colour there.
• Undo (⌘Z) everywhere.
• Gradients in palettes, and “Copy to” for gradients: Figma, Sketch, Affinity, Illustrator, InDesign, Photoshop, Pages, Keynote, Numbers, CSS and SwiftUI.
• Print a palette (⌘P) on A4 – CIELab swatches with names and values – or save it as a PDF.
• Faster work with palettes: use a colour directly, and critique, check contrast and print whole palettes.
• Panels can be collapsed and reordered, and values hidden and sorted – the layout syncs.
• Better palettes from value words: built on harmony principles with legible contrast.
```

**Description (4000)**

```
Kolorist is a colour tool for designers and architects on Mac – and on iPhone and iPad with the same purchase. Build palettes across colour spaces, with perceptually even gradients, contrast checks, colour vision simulation, ICC profiles and your own colour libraries – and get your colours into the apps you already use.

PICK AND DRAG
• Screen eyedropper that picks colours from anywhere on screen
• Drag swatches into other apps and colour wells – and drag colours in from them
• Your palettes at hand in a wide window
• Photos, with dominant colours
• Camera, including iPhone as a camera, with an on-screen light panel – the sampling point follows the pointer
• Colours you pick are kept until you save them
• OKLCH with ⌥⌘C, paste with ⌥⌘V, undo with ⌘Z

EVERY COLOUR SPACE
• Edit in OKLCH, OKLab, CIE LCH, CIELab, Munsell, HSB, HSL, RGB and CMYK
• Display P3 side by side with sRGB, Adobe RGB, Rec. 2020, ProPhoto RGB, CMYK or any ICC profile
• Out-of-gamut warnings – mapped, never clipped
• Enter CMYK or RGB directly in a chosen ICC profile
• Clean CMYK values: grey components move to black (UCR/GCR)
• The colour field understands hex, CSS colours, Munsell notation and plain descriptions like “deep ocean blue”

COLOUR LIBRARIES AND ICC PROFILES
• Import your own colour charts in ASE, ACO or ACB (Adobe Color Book) with named tones
• Colours are locked to the library’s tones, and Studio shows the tone names
• Use the profiles installed on your Mac, by folder
• Import your own .icc and .icm profiles
• All gathered in one place, synced to iPhone and iPad through iCloud Drive
• Convert between profiles with a chosen rendering intent

GRADIENTS, TONES AND HARMONIES
• Gradients in equal perceptual steps in OKLab, with lighter and darker rows
• CSS gradients in oklab with an sRGB fallback – linear, radial or conic
• Tone scales from 50 to 950
• Complementary, split complementary, analogous with or without an accent, triad, square and even distributions on an OKLCH, CIE LCH, Munsell, Hering, HSL or RYB colour wheel – with natural lightness order if you like
• See the whole harmony in the chosen colour space or colour library, with the base colour marked

ACCESSIBILITY AND COLOUR VISION
• WCAG 2.2 contrast (AA and AAA), with auto-fix until the colour passes
• Surface contrast with LRV (light reflectance value) to BS 8300 and NS 11001 – for buildings and interiors
• Contrast matrix and critique of whole palettes
• See palettes with protan, deutan and tritan deficiencies and achromatopsia – and which colours become hard to tell apart
• Camera with a colour vision filter

APPLE INTELLIGENCE ON YOUR MAC
• From value words to a palette – “calm, warm, Nordic” – grounded in a knowledge base of more than a hundred colour concepts
• Palettes are built on harmony principles with legible contrast
• Describe a colour and see it in Studio
• Adjust with free text, name colours and get a critique of your palette
Everything runs locally. Without Apple Intelligence, palettes are built straight from the knowledge base.

COPY TO AND EXPORT
• “Copy to” design tools, layout, photo and presentation apps – in the format each app accepts, gradients too
• Export to ASE, ACO, Design Tokens (DTCG), SVG, CSS, GPL, SwiftUI and hex
• Colours are exported in the format they were saved in – for example as CMYK
• Print palettes (⌘P) on A4 – CIELab swatches with names and values – or save as PDF

PALETTES AND ICLOUD
Collect colours and gradients in palettes, save single colours and whole gradients, and sync with iPhone and iPad through your own private iCloud. Tailor the view to your work.

SIRI AND SHORTCUTS
Create a palette from value words, describe a colour, create a gradient, convert a colour and check contrast.

OPEN ABOUT METHODS
Every part of the app shows the methods it builds on, with source and explanation.

PRIVACY
No account, no analytics, no ads and no tracking. The developer collects no data.

Requires macOS 26. Apple Intelligence requires a Mac with Apple silicon.
```

**Keywords (100)**

```
colour,color,palette,picker,eyedropper,OKLCH,CMYK,ICC,Munsell,LRV,contrast,WCAG,gradient,colorblind
```

---

## 3d. Skjermbilder

Alle i `Dokumentasjon/1.1/Skjermbilder/`, fem per plattform og språk: Studio (Farge), Harmoni, Overgang,
Kontrast (WCAG og LRV), Fargesyn. Bildene for 1.0 ligger i `Dokumentasjon/1.0/Skjermbilder/`.

| Mappe | Plattform | Størrelse |
|---|---|---|
| `nb/`, `en/` | iPhone 6,5" | 1284 × 2778 |
| `ipad-nb/`, `ipad-en/` | iPad 13" | 2064 × 2752 |
| `mac-nb/`, `mac-en/` | Mac | 2880 × 1800 |

iPhone og iPad er tatt i simulatorene «Skjermbilder 6,5» (iPhone 14 Plus) og «Skjermbilder iPad 13» (iPad Pro 13"),
begge iOS 26.5. Mac-bildene er vinduet alene (1440 × 900 pt på Retina-skjermen) og viser palettkolonnen med
plukkede farger. Alle er tatt fra et Debug-bygg med `-skjermbilde YES` (se `Kolorist/App/Skjermbildemodus.swift`):
eget lager i minnet med eksempelpaletter på appens språk og standardoppsett for paneler, så egne paletter og
innstillinger ikke kommer med. Overgang er tatt med `-overgangFra "#1B3A6B" -overgangTil "#F2B84B" -overgangAntall 7`,
Mac-bildene i tillegg med `-testmaalinger YES`.
Studio- og Harmoni-bildene er tatt på nytt for build 5 («Vis som», harmonien i fargeflaten, større fargesirkel
på iPad og Mac). Mac-bildene er tatt med `-kunSRGB NO`, så grunnfargen er den samme som på iPhone og iPad.

## 4. App Review Information

| Felt | Verdi |
|---|---|
| Sign-in required | **Nei** – ikke kryss av; ingen demokonto trengs |
| Contact – first/last name | Eivind Arnstein Johansen |
| Contact – e-post | eivind.johansen@ntnu.no |
| Contact – telefon | *(fyll inn, med landskode +47)* |
| Vedlegg | Valgfritt: en kort skjermopptaksvideo av fargebibliotek-import og dra og slipp på Mac |

**Notes (4000)** – på engelsk, som App Review leser raskest:

```
Thank you for reviewing Kolorist 1.1, a colour palette tool for designers and architects on iPhone, iPad and Mac (one universal purchase).

NO ACCOUNT NEEDED
All features work without signing in. There is no account, no server of our own, no analytics, no ads and no in-app purchases. Palettes sync through the user's private iCloud database (CloudKit) when the device is signed in to iCloud; without iCloud everything is stored on device.

WHERE TO FIND THE MAIN FEATURES
• Studio (first tab): edit the active colour in OKLCH, Lab, Munsell, RGB, CMYK etc. "Show as" picks a second colour space, an ICC profile or a colour library shown side by side. Colour | Tones | Harmony switches between editing, tone scales and harmonies.
• Palettes: tap + to create a palette, either empty or "New palette from value words (AI)". Tap a colour to select it; tap a palette's title to open it. Touch and hold (right-click on Mac) a palette for "Critique the palette" and "Contrast matrix", or a colour for "Copy to" (Figma, Adobe apps, Pages/Keynote/Numbers, CSS, SwiftUI) and other actions.
• Gradient: perceptual gradients between two colours, with lighter/darker rows and CSS export.
• Pick: camera, photos and (on Mac) a screen eyedropper. Picked colours appear at the top of Palettes, marked "Not saved".
• Assess: Contrast (WCAG text contrast and LRV surface contrast), Difference (ΔE2000) and Colour vision (simulation of colour vision deficiencies). The camera button next to each deficiency opens the camera with that filter.

NEW IN 1.1 – HOW TO TEST
• Colour libraries: export any palette as ASE (open a palette › Export › ASE), then import that file under Studio › Show as › My colour spaces … › Import. Choose the library under "Show as" to see the nearest named tone.
• Munsell: Studio › Colour model › Munsell.
• LRV: Assess › Contrast › Surfaces (LRV).
• Palette column: on a 13-inch iPad in landscape, or on a Mac with a window at least 1300 points wide. Drag a colour from the column onto From or To in Gradient.
• Undo: ⌘Z (Edit › Undo) after changing a colour or editing a palette.
• Gradients: in Gradient, use More › Add gradient to palette, or Copy gradient to … (Figma, Adobe apps, iWork, CSS, SwiftUI).
• Print: open a palette › Print … (or ⌘P on Mac), or Export › PDF with swatches (A4).

CAMERA
The camera is used live, on device only, to pick colours and to show the colour vision filter. No photos or video are stored or sent. If no camera is available (for example on a Mac without one), picking from photos and the screen eyedropper still work.

APPLE INTELLIGENCE
Value-word palettes, "Describe a colour", free-text adjustments, colour naming and palette critique use the on-device Foundation Models framework. On devices without Apple Intelligence, or when it is turned off, palettes are generated from a built-in knowledge base instead, and the app explains what is unavailable. No text leaves the device.

ICC PROFILES AND COLOUR LIBRARIES
No ICC profiles or colour libraries are bundled. The app uses the system's built-in colour spaces (sRGB, Display P3, Adobe RGB, Rec. 2020, ProPhoto RGB, Generic CMYK) and profiles and libraries the user imports under "My colour spaces". Imported files are stored in the app's iCloud Drive folder and can be deleted in the app. The Munsell conversion uses the published Munsell renotation data.

SIRI AND SHORTCUTS
App Shortcuts: "Describe a colour in Kolorist", "Create a palette in Kolorist", plus actions to create a gradient, convert a colour and check contrast.

MAC
The screen eyedropper uses the system colour sampler (NSColorSampler) and does not require screen recording permission. Swatches can be dragged into other apps, and colours can be dropped in from the system colour panel and other apps.

Methods and sources used by the app are listed in the app (bottom of Palettes › Methods and sources) and at https://kolorist.no/en/methods.html.

Contact: eivind.johansen@ntnu.no
```

---

## 5. Før du sender inn

- [ ] Nettsiden for 1.1 (`web/1.1/`) er publisert på kolorist.no.
- [x] `MARKETING_VERSION` er `1.1`. `CURRENT_PROJECT_VERSION` (nå `5`) økes for hver opplasting.
- [ ] Ny versjon opprettet i App Store Connect for både iOS og macOS (1.1), med «Nytt i denne versjonen» fra over.
- [ ] Nøkkelord og beskrivelse oppdatert (nye: Munsell, LRV, fargebiblioteker).
- [x] Skjermbilder for iPhone, iPad og Mac på norsk og engelsk (se 3d).
- [x] CloudKit-skjemaet er rullet ut til produksjon (3.10.2026): nytt felt `CD_gradientData` på paletter, og Core Datas `…_ckAsset`- og `CD_moveReceipt`-felt (lagt inn med `initializeCloudKitSchema`, som også dekker store paletter som synkroniseres som asset). Eldre versjoner (1.0) ignorerer feltene.
- [ ] Notes for App Review byttet til teksten over.
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) med begrunnelse `CA92.1` for `UserDefaults` – finnes fortsatt ikke i prosjektet.
- [ ] `ITSAppUsesNonExemptEncryption = NO` – står fortsatt ikke i Info.plist eller byggeinnstillingene.
- [x] Lagringsformatet er bakoverkompatibelt: paletter med Munsell-farger og farger fra fargebiblioteker kan
      leses av 1.0 på enheter som ikke er oppdatert ennå (se `PalettFarge` i `Palett.swift` og `LagringsformatTests`).
