# App Store Connect – Kolorist 1.3

Tekstene står per plattform og språk, i den rekkefølgen de legges inn i App Store Connect:

1. [iPhone og iPad – norsk](#1-iphone-og-ipad--norsk-bokmål)
2. [iPhone og iPad – engelsk](#2-iphone-og-ipad--engelsk)
3. [Mac – norsk](#3-mac--norsk-bokmål)
4. [Mac – engelsk](#4-mac--engelsk)
5. [Felles for alle plattformer](#5-felles-for-alle-plattformer): App Review, skjermbilder og sjekkliste

App-informasjon, URL-er, personvernetiketten og eksportregler er uendret fra 1.2 (`Dokumentasjon/1.2/AppStore.md`).

Nøkkelord: fargefunksjoner designere og arkitekter søker etter. Ord som står i navnet eller undertittelen
(«Kolorist», «Fargepaletter for designere», «Colour palettes for designers»), indekseres allerede og gjentas ikke;
ordene kombineres med dem («color» + «picker», «farge» + «palett»). Samme sett for iOS og Mac.

Skrivemåte: tekstene beskriver hva man oppnår, ikke hvor menyene er; ubestemt flertall («farger», «paletter»); annen
programvare og rettighetsbelagte fargesystemer nevnes ikke ved navn. Standarder (WCAG, APCA, LRV, TEK17) kan nevnes.

---

## 1. iPhone og iPad – norsk (bokmål)

**Undertittel (30)** – felles, uendret

```
Fargepaletter for designere
```

**Reklametekst (170)**

```
Fra palett til designsystem: toneskalaer med lik kontrast, farger for lys og mørk modus og kontroll etter WCAG, APCA og LRV – rett inn i verktøyene du bruker.
```

**Nytt i denne versjonen (4000)**

```
Kolorist 1.3 tar paletten helt fram til designsystemet.

• Designsystem fra en palett: roller for aksent, nøytral og status gir farger for lys og mørk modus, med og uten økt kontrast. Se dem på knapper, felt, brytere og varsler, med kontrasten for hvert fargepar og kravet i WCAG. Legg til egne roller, for eksempel info.
• Eksporter designsystemet som fargesett for apputvikling, design tokens med alias og én fil per modus, og CSS med lys og mørk modus og Display P3 – med en README som forklarer systemet. Eller del det som lenke: mottakere ser komponentene og fargene i nettleseren.
• Toneskala i Studio, ved siden av Farge og Harmoni: trinn 50–950 med lik kontrast for alle kulører – trinn 400 holder minst 3:1 og trinn 600 minst 4,5:1 mot hvitt.
• Skriftfarger i paletten om du vil: én nær hvit og én nær sort, med palettens kulørpreg.
• Ny kontrastsjekk: velg WCAG 2.2, APCA eller LRV. Øverst står tallet og det strengeste kravet fargen ikke klarer.
• Kontrast mellom flater med valgfri metode: LRV-forskjell, Weber (TEK17, NS 11001) eller Michelson.
• Forskjellen mellom to farger med ΔE2000, ΔL*, ΔC* og Δh – kopier én verdi eller alle som tabell.
• Kopier farger som RGB-verdier til CAD, BIM og video, og som lineære verdier til 3D-programmer.
• Plukk farge med kamera eller fra bilde rett fra fargefeltene – eller endre fargen i Studio og ta den med tilbake.
• Nye harmonier: monokromatisk og tonebane, der kuløren går i bue gjennom lyshet og metning – og Goethes fargesirkel.
• Palettgrupper: samle paletter i grupper, og skriv ut, lagre og kopier hele grupper. Importer ASE-filer som paletter.
• Endre rekkefølgen på farger ved å dra dem, og vis en farge fra hvor som helst.
• Kildefargerom for CMYK og RGB, papirhvitt og valgfritt betraktningsforhold for visningen.
```

**Beskrivelse (4000)**

```
Kolorist er et fargeverktøy for designere og arkitekter på iPhone, iPad og Mac. Bygg paletter på tvers av fargerom, gjør dem om til designsystemer, kontroller kontrast og fargesyn, se fargene i lyset der de skal brukes – og få dem inn i verktøyene du allerede bruker.

FRA PALETT TIL DESIGNSYSTEM
• Roller for aksent, nøytral og status gir farger for lys og mørk modus, med og uten økt kontrast – merkefargen beholdes der den holder kravene
• Se fargene på knapper, felt, brytere, varsler og faner, med kontrasten for hvert fargepar og kravet i WCAG
• Egne roller, for eksempel info, kategorier eller tilbud
• Toneskalaer med lik kontrast for alle kulører, rett i Studio
• Eksporter som fargesett for apputvikling, design tokens og CSS med lys og mørk modus – eller del designsystemet som lenke

ALLE FARGEROM
• Rediger i OKLCH, OKLab, CIE LCH, CIELab, Munsell, HSB, HSL, RGB og CMYK
• Display P3 side om side med sRGB, Adobe RGB, CMYK eller en hvilken som helst ICC-profil – kartlagt, aldri klippet
• Angi CMYK eller RGB i profilen de skal brukes i, og få rene CMYK-verdier
• Skriv hex, CSS-farger eller Munsell-notasjon

FARGEBIBLIOTEKER, ICC-PROFILER OG FILAMENT
• Importer egne fargekart i ASE, ACO eller ACB med navngitte toner
• Filamentfarger for 3D-print: over 2 200 farger fra 150 produsenter, de fleste målt – finn nærmeste filament
• Egne ICC-profiler, synkronisert via iCloud Drive

OVERGANGER, TONER OG HARMONIER
• Overganger i like perseptuelle steg i OKLab, med lysere og mørkere rader og CSS-gradienter
• Harmonier fra monokromatisk og tonebane til triade og kvadrat, på fargesirkler i OKLCH, CIE LCH, Munsell, Hering, Goethe, HSL eller RYB

KONTRAST OG FARGESYN
• Kontrastsjekk etter WCAG 2.2, APCA eller LRV, med «Rett opp» som justerer fargen til den består
• Skriftkontrast og skriftfarger for hele paletter
• Kontrast mellom flater for bygg og interiør: LRV-forskjell, Weber eller Michelson – også i valgt lys
• Se paletter med protan-, deutan- og tritanavvik og akromatopsi – og hvilke farger som blir vanskelige å skille
• Forskjellen mellom to farger med ΔE2000, ΔL*, ΔC* og Δh

LYS OG FARGEMÅLING
• Se farger og hele paletter under egne og standardiserte betraktningsforhold
• Mål lyset med kameraet, og kompenser farger du plukker med gråkort eller referansekort (beta)

PLUKK FARGER
• Kamera og bilder, rett fra fargefeltene der du trenger fargen
• Farger du plukker, tas vare på til du lagrer dem

APPLE INTELLIGENCE PÅ ENHETEN
• Fra verdiord til palett, forankret i en kunnskapsbase med over hundre fargebegreper
• Navngi farger og få vurdering av paletter
Alt kjøres på enheten. Uten Apple Intelligence lages paletter direkte fra kunnskapsbasen.

DEL, LAGRE OG EKSPORTER
• Del farger, paletter, gradienter og harmonier som lenke – mottakere uten appen ser dem i nettleseren
• Lagre som ASE, ACO, design tokens, CSS, SwiftUI, GPL, SVG, hex og PDF
• Kopier farger og gradienter rett inn i design-, layout- og presentasjonsprogrammer – eller som RGB-verdier til CAD, BIM og video og lineære verdier til 3D-programmer
• Skriv ut paletter og palettgrupper på A4 i CIELab

PALETTER OG ICLOUD
Samle farger og gradienter i paletter og palettgrupper, og synkroniser via din egen, private iCloud.

ÅPENT OM METODENE
Appen viser metodene den bygger på – OKLab, CIEDE2000, CAM16, WCAG, APCA, LRV, Munsell, ICC og designtokens – med kilde og forklaring.

PERSONVERN
Ingen konto, ingen analyse, ingen reklame og ingen sporing. Utvikleren samler ikke inn data.

Krever iOS 26, iPadOS 26 eller macOS 26. Apple Intelligence krever en støttet enhet.
```

**Nøkkelord (100)**

```
farge,fargevelger,kontrast,universell utforming,LRV,WCAG,arkitekt,interiør,designsystem,CMYK,Munsell
```

**Skjermbilder:** `Dokumentasjon/1.3/Skjermbilder/nb/` (iPhone 6,5″) og `ipad-nb/` (iPad 13″) – alle tatt med 1.3.
Foreslått rekkefølge (høyst ti): designsystem, toneskala, kontrast, flatekontrast, studio, harmoni, lys, fargesyn,
overgang, fargefelt.

---

## 2. iPhone og iPad – engelsk

**Subtitle (30)** – unchanged

```
Colour palettes for designers
```

**Promotional text (170)**

```
From palette to design system: tone scales with consistent contrast, colours for light and dark mode, and checks by WCAG, APCA and LRV – straight into your tools.
```

**What’s New in This Version (4000)**

```
Kolorist 1.3 takes your palette all the way to a design system.

• Design system from a palette: roles for accent, neutral and status give colours for light and dark mode, with and without increased contrast. See them on buttons, fields, switches and alerts, with the contrast for each colour pair and the WCAG requirement. Add your own roles, such as info.
• Export the design system as colour sets for app development, design tokens with aliases and one file per mode, and CSS with light and dark mode and Display P3 – with a README that explains the system. Or share it as a link: recipients see the components and colours in their browser.
• Tone scale in Studio, next to Colour and Harmony: steps 50–950 with the same contrast for every hue – step 400 holds at least 3:1 and step 600 at least 4.5:1 against white.
• Text colours in the palette if you want them: one near white and one near black, tinted with the palette’s hue.
• New contrast check: choose WCAG 2.2, APCA or LRV. The figure and the strictest requirement the colour does not meet are shown at the top.
• Contrast between surfaces with a choice of method: LRV difference, Weber or Michelson.
• The difference between two colours with ΔE2000, ΔL*, ΔC* and Δh – copy one value or all of them as a table.
• Copy colours as RGB values for CAD, BIM and video, and as linear values for 3D apps.
• Pick a colour with the camera or from a photo right from the colour fields – or edit it in Studio and bring it back.
• New harmonies: monochromatic and tone path, where the hue arcs through lightness and saturation – and Goethe’s colour wheel.
• Palette groups: gather palettes in groups, and print, save and copy whole groups. Import ASE files as palettes.
• Reorder colours by dragging them, and show a colour from anywhere.
• Source colour space for CMYK and RGB, paper white and a choice of viewing condition for the display.
```

**Description (4000)**

```
Kolorist is a colour tool for designers and architects on iPhone, iPad and Mac. Build palettes across colour spaces, turn them into design systems, check contrast and colour vision, see colours in the light where they will be used – and get them into the tools you already use.

FROM PALETTE TO DESIGN SYSTEM
• Roles for accent, neutral and status give colours for light and dark mode, with and without increased contrast – your brand colour is kept wherever it meets the requirements
• See the colours on buttons, fields, switches, alerts and tabs, with the contrast for each colour pair and the WCAG requirement
• Your own roles, such as info, categories or offers
• Tone scales with the same contrast for every hue, right in Studio
• Export as colour sets for app development, design tokens and CSS with light and dark mode – or share the design system as a link

EVERY COLOUR SPACE
• Edit in OKLCH, OKLab, CIE LCH, CIELab, Munsell, HSB, HSL, RGB and CMYK
• Display P3 side by side with sRGB, Adobe RGB, CMYK or any ICC profile – mapped, never clipped
• Enter CMYK or RGB in the profile they will be used in, and get clean CMYK values
• Type hex, CSS colours or Munsell notation

COLOUR LIBRARIES, ICC PROFILES AND FILAMENT
• Import your own colour charts in ASE, ACO or ACB with named tones
• Filament colours for 3D printing: more than 2,200 colours from 150 manufacturers, most of them measured – find the nearest filament
• Your own ICC profiles, synced through iCloud Drive

GRADIENTS, TONES AND HARMONIES
• Gradients in equal perceptual steps in OKLab, with lighter and darker rows and CSS gradients
• Harmonies from monochromatic and tone path to triad and square, on OKLCH, CIE LCH, Munsell, Hering, Goethe, HSL or RYB colour wheels

CONTRAST AND COLOUR VISION
• Contrast check by WCAG 2.2, APCA or LRV, with auto-fix that adjusts the colour until it passes
• Text contrast and text colours for whole palettes
• Contrast between surfaces for buildings and interiors: LRV difference, Weber or Michelson – in the chosen light too
• See palettes with protan, deutan and tritan deficiencies and achromatopsia – and which colours become hard to tell apart
• The difference between two colours with ΔE2000, ΔL*, ΔC* and Δh

LIGHT AND COLOUR MEASUREMENT
• See colours and whole palettes in your own and standard viewing conditions
• Measure the light with the camera, and compensate the colours you pick with a grey card or reference card (beta)

PICK COLOURS
• Camera and photos, right from the colour fields where you need the colour
• Colours you pick are kept until you save them

APPLE INTELLIGENCE ON DEVICE
• From value words to a palette, grounded in a knowledge base of more than a hundred colour concepts
• Name colours and get a critique of your palette
Everything runs on device. Without Apple Intelligence, palettes are built straight from the knowledge base.

SHARE, SAVE AND EXPORT
• Share colours, palettes, gradients and harmonies as links – recipients without the app see them in their browser
• Save as ASE, ACO, design tokens, CSS, SwiftUI, GPL, SVG, hex and PDF
• Copy colours and gradients straight into design, layout and presentation apps – or as RGB values for CAD, BIM and video and linear values for 3D apps
• Print palettes and palette groups on A4 in CIELab

PALETTES AND ICLOUD
Collect colours and gradients in palettes and palette groups, and sync through your own private iCloud.

OPEN ABOUT METHODS
The app shows the methods it builds on – OKLab, CIEDE2000, CAM16, WCAG, APCA, LRV, Munsell, ICC and design tokens – with source and explanation.

PRIVACY
No account, no analytics, no ads and no tracking. The developer collects no data.

Requires iOS 26, iPadOS 26 or macOS 26. Apple Intelligence requires a supported device.
```

**Keywords (100)**

```
color,picker,contrast,accessibility,WCAG,LRV,architect,interior,design system,harmony,CMYK,Munsell
```

**Screenshots:** `Dokumentasjon/1.3/Skjermbilder/en/` (iPhone 6.5″) and `ipad-en/` (iPad 13″), all taken with 1.3, in the
same order as the Norwegian ones.

---

## 3. Mac – norsk (bokmål)

> **Merk:** Mac går rett fra 1.1 til 1.3 (Eivind 2026-10-08), så teksten under tar med nyhetene fra både 1.2 og 1.3.

**Reklametekst (170)**

```
Fra palett til designsystem: toneskalaer med lik kontrast, farger for lys og mørk modus, kontroll etter WCAG, APCA og LRV – plukk fra hele skjermen og dra fargene videre.
```

**Nytt i denne versjonen (4000)** – Mac hopper fra 1.1, så nyhetene fra 1.2 er med

```
Kolorist 1.3 for Mac tar paletten helt fram til designsystemet – og tar lyset med i regnestykket.

FRA PALETT TIL DESIGNSYSTEM
• Designsystem fra en palett: roller for aksent, nøytral og status gir farger for lys og mørk modus, med og uten økt kontrast. Se dem på knapper, felt, brytere og varsler, med kontrasten for hvert fargepar og kravet i WCAG. Legg til egne roller, for eksempel info.
• Eksporter designsystemet som fargesett for apputvikling, design tokens med alias og én fil per modus, og CSS med lys og mørk modus og Display P3 – med en README som forklarer systemet.
• Toneskala i Studio med lik kontrast for alle kulører, og skriftfarger i paletten om du vil.
• Del designsystemet som lenke: mottakere ser komponentene og fargene i nettleseren.

KONTRAST
• Ny kontrastsjekk: velg WCAG 2.2, APCA eller LRV. Øverst står tallet og det strengeste kravet fargen ikke klarer.
• Skriftkontrast rett i palettene: hver farge som tekst på de andre.
• Kontrast mellom flater med valgfri metode: LRV-forskjell, Weber (TEK17, NS 11001) eller Michelson – også i valgt lys.
• Forskjellen mellom to farger med ΔE2000, ΔL*, ΔC* og Δh – kopier én verdi eller alle som tabell.

LYS
• Se farger og hele paletter slik de oppleves under andre betraktningsforhold – egne eller standardiserte for grafisk vurdering, arbeidsplasser, skoler og museer.
• Paletter i lys: hver farge på skjermen og i lyset side om side, og hvilke fargepar som blir vanskelige å skille i svakt lys eller under lysrør og LED.
• Betraktningsforhold du har målt med iPhone og iPad, følger med til Macen via iCloud.
• Med iPhone som kamera kan farger kompenseres for lyset med gråkort eller referansekort (beta).

FARGER OG HARMONIER
• Nye harmonier: monokromatisk, tonebane, triade, kvadrat og analog med komplementær aksent – på fargesirkler med Goethe og Munsell, og med naturlig lyshetsrekkefølge.
• Filamentfarger for 3D-print: over 2 200 farger fra 150 produsenter, de fleste målt – finn nærmeste filament.
• Munsell i trinnene fra Munsell-boka.
• Kildefargerom for CMYK og RGB, papirhvitt og valgfritt betraktningsforhold for visningen.

PALETTER, DELING OG EKSPORT
• Palettgrupper: samle paletter i grupper, og skriv ut, lagre og kopier hele grupper. Importer ASE-filer som paletter.
• Del farger, paletter, gradienter og harmonier som lenke – mottakere uten appen ser fargene i nettleseren.
• Lagre som: velg formater etter hvor filene skal brukes, og lagre dem i en mappe eller del dem.
• Kopier gradienter som redigerbare gradienter til design-, layout- og presentasjonsprogrammer, og farger som RGB-verdier til CAD, BIM og video og lineære verdier til 3D-programmer.
• Kopierte gradienter har færre stopp, så de er enkle å redigere videre.
• Endre rekkefølgen på farger ved å dra dem, legg til farger rett i lista, og plukk farge rett fra fargefeltene – eller endre den i Studio og ta den med tilbake.

PÅ MACEN
• Kopier paletter rett inn i fargevelgeren på Macen, som fargeliste i alle programmer.
• Designsystemer får egen plass i sidepanelet når vinduet er bredt.
• Palettene i spalten til høyre har tydeligere valg, med tekst på visningene, og seksjoner du ikke bruker, kan legges sammen.
• Skjermpipette også med ⌘I, og hurtigtaster: ⌘N ny palett, ⇧⌘S lagre som, ⌘1–5 for fanene.
```

**Beskrivelse (4000)**

```
Kolorist er et fargeverktøy for designere og arkitekter på Mac – og på iPhone og iPad med samme kjøp. Bygg paletter på tvers av fargerom, gjør dem om til designsystemer, kontroller kontrast og fargesyn, se fargene i lyset der de skal brukes – og få dem inn i verktøyene du allerede bruker.

FRA PALETT TIL DESIGNSYSTEM
• Roller for aksent, nøytral og status gir farger for lys og mørk modus, med og uten økt kontrast – merkefargen beholdes der den holder kravene
• Se fargene på knapper, felt, brytere, varsler og faner, med kontrasten for hvert fargepar og kravet i WCAG
• Egne roller, for eksempel info, kategorier eller tilbud
• Toneskalaer med lik kontrast for alle kulører, rett i Studio
• Eksporter som fargesett for apputvikling, design tokens og CSS med lys og mørk modus – eller del designsystemet som lenke

ALLE FARGEROM
• Rediger i OKLCH, OKLab, CIE LCH, CIELab, Munsell, HSB, HSL, RGB og CMYK
• Display P3 side om side med sRGB, Adobe RGB, CMYK eller en hvilken som helst ICC-profil – kartlagt, aldri klippet
• Angi CMYK eller RGB i profilen de skal brukes i, og få rene CMYK-verdier
• Skriv hex, CSS-farger eller Munsell-notasjon

FARGEBIBLIOTEKER, ICC-PROFILER OG FILAMENT
• Importer egne fargekart i ASE, ACO eller ACB med navngitte toner
• Filamentfarger for 3D-print: over 2 200 farger fra 150 produsenter, de fleste målt – finn nærmeste filament
• Egne ICC-profiler, synkronisert via iCloud Drive

OVERGANGER, TONER OG HARMONIER
• Overganger i like perseptuelle steg i OKLab, med lysere og mørkere rader og CSS-gradienter
• Harmonier fra monokromatisk og tonebane til triade og kvadrat, på fargesirkler i OKLCH, CIE LCH, Munsell, Hering, Goethe, HSL eller RYB

KONTRAST OG FARGESYN
• Kontrastsjekk etter WCAG 2.2, APCA eller LRV, med «Rett opp» som justerer fargen til den består
• Skriftkontrast og skriftfarger for hele paletter
• Kontrast mellom flater for bygg og interiør: LRV-forskjell, Weber eller Michelson – også i valgt lys
• Se paletter med protan-, deutan- og tritanavvik og akromatopsi – og hvilke farger som blir vanskelige å skille
• Forskjellen mellom to farger med ΔE2000, ΔL*, ΔC* og Δh

LYS OG FARGEMÅLING
• Se farger og hele paletter under egne og standardiserte betraktningsforhold
• Mål lyset med iPhone eller iPad – betraktningsforholdene følger med til Macen via iCloud
• Kompenser farger for lyset med gråkort eller referansekort, med iPhone som kamera (beta)

PLUKK OG DRA
• Skjermpipette som plukker farger fra hvor som helst på skjermen
• Dra fargeprøver inn i andre programmer og fargebrønner – og dra farger inn fra dem
• Legg paletter i fargevelgeren på Macen, som fargeliste i alle programmer
• Kamera, også iPhone som kamera, og bilder

APPLE INTELLIGENCE PÅ ENHETEN
• Fra verdiord til palett, forankret i en kunnskapsbase med over hundre fargebegreper
• Navngi farger og få vurdering av paletter
Alt kjøres på enheten. Uten Apple Intelligence lages paletter direkte fra kunnskapsbasen.

DEL, LAGRE OG EKSPORTER
• Del farger, paletter, gradienter og harmonier som lenke – mottakere uten appen ser dem i nettleseren
• Lagre som ASE, ACO, design tokens, CSS, SwiftUI, GPL, SVG, hex, PDF og fargeliste for macOS
• Kopier farger og gradienter rett inn i design-, layout- og presentasjonsprogrammer – eller som RGB-verdier til CAD, BIM og video og lineære verdier til 3D-programmer
• Skriv ut paletter og palettgrupper på A4 i CIELab

PALETTER OG ICLOUD
Samle farger og gradienter i paletter og palettgrupper, og synkroniser via din egen, private iCloud.

ÅPENT OM METODENE
Appen viser metodene den bygger på – OKLab, CIEDE2000, CAM16, WCAG, APCA, LRV, Munsell, ICC og designtokens – med kilde og forklaring.

PERSONVERN
Ingen konto, ingen analyse, ingen reklame og ingen sporing. Utvikleren samler ikke inn data.

Krever macOS 26. Apple Intelligence krever en Mac med Apple-chip.
```

**Nøkkelord (100)**

```
farge,fargevelger,kontrast,universell utforming,LRV,WCAG,arkitekt,interiør,designsystem,CMYK,Munsell
```

**Skjermbilder:** `Dokumentasjon/1.3/Skjermbilder/mac-nb/` (2880 × 1800) – alle tatt med 1.3. Foreslått rekkefølge:
designsystem, toneskala, kontrast, flatekontrast, studio, harmoni, lys, fargesyn, overgang. Engelsk i `mac-en/`.

---

## 4. Mac – engelsk

**Promotional text (170)**

```
From palette to design system: tone scales with consistent contrast, light and dark mode, checks by WCAG, APCA and LRV – pick from anywhere on screen and drag colours on.
```

**What’s New (4000)** – the Mac skips 1.2, so the 1.2 news is included

```
Kolorist 1.3 for Mac takes your palette all the way to a design system – and brings light into the equation.

FROM PALETTE TO DESIGN SYSTEM
• Design system from a palette: roles for accent, neutral and status give colours for light and dark mode, with and without increased contrast. See them on buttons, fields, switches and alerts, with the contrast for each colour pair and the WCAG requirement. Add your own roles, such as info.
• Export the design system as colour sets for app development, design tokens with aliases and one file per mode, and CSS with light and dark mode and Display P3 – with a README that explains the system.
• Tone scale in Studio with the same contrast for every hue, and text colours in the palette if you want them.
• Share the design system as a link: recipients see the components and colours in their browser.

CONTRAST
• New contrast check: choose WCAG 2.2, APCA or LRV. The figure and the strictest requirement the colour does not meet are shown at the top.
• Text contrast right in your palettes: each colour as text on the others.
• Contrast between surfaces with a choice of method: LRV difference, Weber or Michelson – in the chosen light too.
• The difference between two colours with ΔE2000, ΔL*, ΔC* and Δh – copy one value or all of them as a table.

LIGHT
• See colours and whole palettes as they appear in other viewing conditions – your own or standard ones for graphic arts, workplaces, schools and museums.
• Palettes in light: each colour on screen and in the light side by side, and which colour pairs become hard to tell apart in dim light or under fluorescent and LED lighting.
• Viewing conditions you measured with iPhone and iPad follow you to the Mac through iCloud.
• With iPhone as the camera, colours can be compensated for the light with a grey card or reference card (beta).

COLOURS AND HARMONIES
• New harmonies: monochromatic, tone path, triad, square and analogous with a complementary accent – on colour wheels including Goethe and Munsell, with natural lightness order.
• Filament colours for 3D printing: more than 2,200 colours from 150 manufacturers, most of them measured – find the nearest filament.
• Munsell in the steps of the Munsell book.
• Source colour space for CMYK and RGB, paper white and a choice of viewing condition for the display.

PALETTES, SHARING AND EXPORT
• Palette groups: gather palettes in groups, and print, save and copy whole groups. Import ASE files as palettes.
• Share colours, palettes, gradients and harmonies as a link – recipients without the app see the colours in their browser.
• Save as: choose formats by where the files will be used, and save them to a folder or share them.
• Copy gradients as editable gradients to design, layout and presentation apps, and colours as RGB values for CAD, BIM and video and linear values for 3D apps.
• Copied gradients have fewer stops, so they are easy to edit further.
• Reorder colours by dragging them, add colours right in the list, and pick a colour right from the colour fields – or edit it in Studio and bring it back.

ON THE MAC
• Copy palettes straight into the Mac colour picker, as a colour list in every app.
• Design systems get their own place in the sidebar when the window is wide.
• Palettes in the right-hand column have clearer controls, with labelled views, and sections you don’t use can be collapsed.
• Screen eyedropper with ⌘I too, and keyboard shortcuts: ⌘N new palette, ⇧⌘S Save as, ⌘1–5 for the tabs.
```

**Description (4000)**

```
Kolorist is a colour tool for designers and architects on Mac – and on iPhone and iPad with the same purchase. Build palettes across colour spaces, turn them into design systems, check contrast and colour vision, see colours in the light where they will be used – and get them into the tools you already use.

FROM PALETTE TO DESIGN SYSTEM
• Roles for accent, neutral and status give colours for light and dark mode, with and without increased contrast – your brand colour is kept wherever it meets the requirements
• See the colours on buttons, fields, switches, alerts and tabs, with the contrast for each colour pair and the WCAG requirement
• Your own roles, such as info, categories or offers
• Tone scales with the same contrast for every hue, right in Studio
• Export as colour sets for app development, design tokens and CSS with light and dark mode – or share the design system as a link

EVERY COLOUR SPACE
• Edit in OKLCH, OKLab, CIE LCH, CIELab, Munsell, HSB, HSL, RGB and CMYK
• Display P3 side by side with sRGB, Adobe RGB, CMYK or any ICC profile – mapped, never clipped
• Enter CMYK or RGB in the profile they will be used in, and get clean CMYK values
• Type hex, CSS colours or Munsell notation

COLOUR LIBRARIES, ICC PROFILES AND FILAMENT
• Import your own colour charts in ASE, ACO or ACB with named tones
• Filament colours for 3D printing: more than 2,200 colours from 150 manufacturers, most of them measured – find the nearest filament
• Your own ICC profiles, synced through iCloud Drive

GRADIENTS, TONES AND HARMONIES
• Gradients in equal perceptual steps in OKLab, with lighter and darker rows and CSS gradients
• Harmonies from monochromatic and tone path to triad and square, on OKLCH, CIE LCH, Munsell, Hering, Goethe, HSL or RYB colour wheels

CONTRAST AND COLOUR VISION
• Contrast check by WCAG 2.2, APCA or LRV, with auto-fix that adjusts the colour until it passes
• Text contrast and text colours for whole palettes
• Contrast between surfaces for buildings and interiors: LRV difference, Weber or Michelson – in the chosen light too
• See palettes with protan, deutan and tritan deficiencies and achromatopsia – and which colours become hard to tell apart
• The difference between two colours with ΔE2000, ΔL*, ΔC* and Δh

LIGHT AND COLOUR MEASUREMENT
• See colours and whole palettes in your own and standard viewing conditions
• Measure the light with iPhone or iPad – it syncs to the Mac through iCloud
• Compensate colours for the light with a grey card or reference card, with iPhone as the camera (beta)

PICK AND DRAG
• Screen eyedropper that picks colours from anywhere on screen
• Drag swatches into other apps and colour wells, and back
• Add palettes to the Mac colour picker, as a colour list in every app
• Camera, including iPhone as a camera, and photos

APPLE INTELLIGENCE ON DEVICE
• From value words to a palette, grounded in a knowledge base of more than a hundred colour concepts
• Name colours and get a critique of your palette
Everything runs on device. Without Apple Intelligence, palettes are built straight from the knowledge base.

SHARE, SAVE AND EXPORT
• Share colours, palettes, gradients and harmonies as links – recipients without the app see them in their browser
• Save as ASE, ACO, design tokens, CSS, SwiftUI, GPL, SVG, hex, PDF and a macOS colour list
• Copy colours and gradients straight into design, layout and presentation apps – or as RGB values for CAD, BIM and video and linear values for 3D apps
• Print palettes and palette groups on A4 in CIELab

PALETTES AND ICLOUD
Collect colours and gradients in palettes and palette groups, and sync through your own private iCloud.

OPEN ABOUT METHODS
The app shows the methods it builds on – OKLab, CIEDE2000, CAM16, WCAG, APCA, LRV, Munsell, ICC and design tokens – with source and explanation.

PRIVACY
No account, no analytics, no ads and no tracking. The developer collects no data.

Requires macOS 26. Apple Intelligence requires a Mac with Apple silicon.
```

**Keywords (100)**

```
color,picker,contrast,accessibility,WCAG,LRV,architect,interior,design system,harmony,CMYK,Munsell
```

---

## 5. Felles for alle plattformer

### App Review – Notes (4000)

```
Thank you for reviewing Kolorist 1.3, a colour palette tool for designers and architects on iPhone, iPad and Mac (one universal purchase).

NO ACCOUNT NEEDED
No account, no server of our own, no analytics, ads or in-app purchases. Data syncs through the user's private iCloud when signed in; otherwise everything stays on device.

NEW IN 1.3 – HOW TO TEST
• Design system: open a palette › ⋯ › Make design system. A preview opens with Components, Roles and Scales; Save keeps it. Export (share button) writes colour sets, design tokens, CSS and a README to a folder.
• Tone scale: Studio › Tone scale (also from a colour in a palette › Create tone scale). "Contrast (L*)" gives the same contrast for every hue.
• Copy to: touch and hold (right-click on Mac) a colour › Copy to. New targets: RGB 0–255, RGB 0–1, linear values for 3D apps, and on Mac the system colour picker (writes a colour list to ~/Library/Colors).
• Share a design system: open it › ⋯ › Share as link; the link opens a preview in the browser or in the app.
• Text colours: open a palette › A (text contrast) › Define text colours.
• Contrast: Assess › Contrast. Choose WCAG 2.2, APCA or LRV below the colour field; tap Text or Background in the field to pick a colour (also with camera or photo).
• ΔE: Assess › ΔE. Touch and hold a value to copy it, or use Copy all as a table.
• Harmonies: Studio › Harmony › Monochromatic or Tone path.
• Palette groups: Palettes › + › New palette group, then drag palettes into it.

CAMERA
Used live, on device only, to pick colours, measure light and show the colour vision filter. Nothing is stored or sent.

APPLE INTELLIGENCE
On-device Foundation Models with a built-in knowledge base as fallback. No text leaves the device.

BUNDLED DATA
Filament colours from FilamentColors.xyz under CC BY 4.0, credited in the app and at kolorist.no.

Methods and sources: in the app (Palettes › Methods and sources) and at https://kolorist.no/en/methods.html
Contact: eivind.johansen@ntnu.no
```

### TestFlight – What to Test (4000)

Mac (fra 1.1 til 1.3):

```
Takk for at du tester Kolorist 1.3 for Mac! Versjonen hopper over 1.2, så mye er nytt. Prøv gjerne dette:

• Designsystem: åpne en palett › ⋯ › Lag designsystem. Se på komponentene i lys og mørk modus, bytt farger mellom rollene, lagre og eksporter. Del det gjerne som lenke.
• Kontrast: Vurdering › Kontrast med WCAG, APCA eller LRV. Velg farger rett i flaten, og prøv «Endre i Studio …» i menyen på fargene.
• Lys: se farger og paletter under ulike betraktningsforhold (Vurdering › Lys og palettvisningen «Se i lys»).
• Toneskala i Studio, nye harmonier (monokromatisk og tonebane) og filamentfarger.
• Palettgrupper: lag en gruppe og dra paletter inn i den.
• Kopier til: høyreklikk på en farge › Kopier til – også «Macens fargevelger».
• Synk: har du iPhone eller iPad med 1.3, sjekk at paletter, grupper og designsystemer kommer over.

Gi tilbakemelding med skjermbilde (⌘⇧3) via TestFlight, eller til eivind.johansen@ntnu.no.
```

iPhone og iPad (fra 1.2 til 1.3):

```
Takk for at du tester Kolorist 1.3! Prøv gjerne dette:

• Designsystem: åpne en palett › ⋯ › Lag designsystem. Se på komponentene i lys og mørk modus, bytt farger mellom rollene, lagre og eksporter. Del det gjerne som lenke.
• Kontrast: Vurdering › Kontrast med WCAG, APCA eller LRV. Trykk på fargene i flaten for å velge, og prøv «Endre i Studio …».
• Toneskala: Studio › Toneskala.
• Nye harmonier: monokromatisk og tonebane.
• Palettgrupper: lag en gruppe og dra paletter inn i den.
• Kopier til: trykk og hold på en farge › Kopier til.
• ΔE: kopier verdiene, én eller alle som tabell.
• Synk: sjekk at paletter, grupper og designsystemer kommer over til dine andre enheter med 1.3.

Gi tilbakemelding med skjermbilde via TestFlight, eller til eivind.johansen@ntnu.no.
```

### Skjermbilder – slik er de tatt

| Mappe | Plattform | Størrelse | Bilder |
|---|---|---|---|
| `nb/`, `en/` | iPhone 6,5″ | 1284 × 2778 | studio, harmoni, toneskala, overgang, fargesyn, lys, kontrast, flatekontrast, designsystem, fargefelt |
| `ipad-nb/`, `ipad-en/` | iPad 13″ | 2064 × 2752 | de samme |
| `mac-nb/`, `mac-en/` | Mac | 2880 × 1800 | de samme uten fargefelt |

Tatt 2026-10-09 i simulatorene «Skjermbilder 6,5» og «Skjermbilder iPad 13», Debug-bygg med `-skjermbilde YES`, klokka
satt til 9:41. Felles: `-visOgsåProfil kCGColorSpaceGenericCMYK -harmoni jevn -harmoniAntall 5`. Studio med
`-startfane studio -studioModus farge|harmoni|toneskala`; Overgang med `-overgangFra "#1B3A6B" -overgangTil "#F2B84B"
-overgangAntall 7`; Fargesyn med `-startfane vurdering -vurderingDel fargesyn`; Lys med `-vurderingDel lys -lys.valgtMiljø
6C1E0000-0000-4000-8000-000000002700 -seILys.somFoto NO`; Kontrast med `-vurderingDel kontrast -kontrastType wcag`;
flatekontrast med `-kontrastType lrv -startfarge "#B4674D" -flatekontrastmetode weber`; designsystemet med
`-eksempeldesignsystem YES -visDesignsystem YES -startfane paletter` (Mac: `-startfane designsystemer`). Fargefeltet er
menyen på Tekst i kontrastsjekken.
Mac: usignert Debug-bygg med de samme argumentene og `-ApplePersistenceIgnoreState YES -kunSRGB NO -testmaalinger YES
-skjermbildevindu YES` (vinduet 1440 × 900 pt midt på den innebygde Retina-skjermen), fanget med `screencapture -l <vindu> -o`.

### Før du sender inn

- [x] CloudKit-skjemaet publisert til produksjon 2026-10-09 (CloudKit Console › iCloud.no.engenett.Kolorist › Deploy Schema
      Changes). Nytt i 1.3: feltene `CD_gruppeID`, `CD_sortering` og `CD_tekstfargeData` i `CD_PalettDokument`, og
      posttypene `CD_PalettGruppe` og `CD_DesignsystemDokument`. Utviklingsskjemaet ble gjort komplett 2026-10-09 med
      Debug-argumentet `-initialiserCloudKitSkjema YES` (Mac). Uten dette synkroniseres ikke palettgrupper,
      rekkefølge, skriftfarger og designsystemer i App Store-bygget.
- [ ] Ny versjon 1.3 opprettet for iOS og macOS, med tekstene over.
- [ ] Skjermbilder lastet opp (iPhone, iPad og Mac, norsk og engelsk).
- [x] 1.3-nettsiden publisert på kolorist.no 2026-10-09; 1.2 ligger i `historisk/1.2/`.
- [ ] Notes for App Review byttet til teksten over.
- [ ] `CURRENT_PROJECT_VERSION` økt for opplastingen.
