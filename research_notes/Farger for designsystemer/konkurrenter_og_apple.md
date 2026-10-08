# Konkurrenter for fargeverktøy til designsystemer, og Apples offisielle systemfarger (stand 2026-10-08)

Merking: **[primær]** = Apples egne sider/App Store-oppføring/utviklerens egen side lest direkte denne dagen. **[sekundær]** = tredjepart. **[selvrapportert]** = produsentens egen markedsføring (ikke uavhengig verifisert). **[uverifisert]** = ikke bekreftet. **[egen beregning]** / **[egen måling]** = utledet av notatets forfatter. Alle App Store-data (pris, oppdateringsdato, versjon, vurdering) er hentet fra iTunes Search/Lookup-API-et (country=us) 2026-10-08, som speiler App Store-oppføringen.

---

## Del A1. Native Mac/iPad/iPhone-apper for palett, skalaer, kontrast og tokens

### Takeaway
Den viktigste funnet er at gapet er smalere enn antatt: **PaletteWright** (Mac + iPad, utgitt juni 2026) og **Pinwheel** (Bjango, Mac, sept. 2026 i Mac App Store) dekker allerede store deler av «native app + OKLCH-ramper + DTCG/Figma-eksport + kontrast». Resten av de native appene (Pastel, ColorSlurp, Sip, ColorCopy, Spectra m.fl.) er plukkere/palettbibliotek uten toneskalaer for designsystem. Ingen av de native appene som er funnet viser Apple-stil (iOS/Liquid Glass) komponentforhåndsvisning eller Xcode asset catalog-eksport med lys/mørk/økt kontrast som førsteklasses mål.

### Cited Findings

**Direkte konkurrenter (designsystem-orientert)**

- **PaletteWright** (Mandelbrot Metal / Michael Stebel Consulting). Mac + iPad, minOS 26.0, v2.3, utgitt 2026-06-23, oppdatert 2026-08-27, gratis med Pro. Ingen App Store-vurderinger ennå (0). Beskrives som «turns captured and imported colors into accessible, versioned design systems for Mac and iPad.» — [App Store-oppføring via iTunes Lookup](https://itunes.apple.com/lookup?id=6771067568&country=us&entity=macSoftware) [primær], [palettewright.com](https://palettewright.com) [primær/selvrapportert]
  - Ramper: «perceptual OKLCH tools», «Edit and lock exact stops», OKLCH Harmony Wheel («Choose an anchor, tune OKLCH hue/chroma/lightness, select a harmony, preview, and apply to unlocked stops»). Ikke beskrevet som kontrastforankrede skalaer; antall steg og metode er ikke oppgitt. — [features.html](https://palettewright.com/features.html) [selvrapportert]
  - Kontrast: «WCAG 2.2 + supplemental APCA»; resultat Pass / Fail / Needs Review; erklærte forgrunn/bakgrunn-par per bruk (normal tekst, stor tekst, ikke-tekst-UI, grafikk, dekor), modus og tilstand. «Validate tests the relationships declared for Light, Dark, and Increased Contrast—not every possible palette pairing.» — [how-to-validate-palettes.html](https://palettewright.com/how-to-validate-palettes.html) [selvrapportert]
  - Komponentforhåndsvisning: «Component Preview Lab» i Validate: «scan account cards, buttons, inputs, badges, navigation, progress, charts, modals, status lists, and code surfaces.» Sjekker «text readability, focus colors, button hierarchy, disabled states, and status colors». Tilstander default, hover, pressed, focus nevnes i valideringsteksten, men siden beskriver ikke separat forhåndsvisning per tilstand. — [samme side](https://palettewright.com/how-to-validate-palettes.html) [selvrapportert]
  - Eksport: «Figma Variables, DTCG and Style Dictionary tokens, adaptive CSS, Tailwind, shadcn/ui, SwiftUI, XML, Jetpack Compose, Flutter, React Native, Adobe ASE». Apple Color List/ASE nevnt. **Xcode asset catalog er ikke nevnt**, heller ikke Liquid Glass/Apple-stilpresets. — [App Store-beskrivelse](https://itunes.apple.com/lookup?id=6771067568&country=us&entity=macSoftware) [primær], [features.html](https://palettewright.com/features.html) [selvrapportert]
  - Øvrig: CLI/CI med SARIF-rapporter, fargesynssimulering (Machado-matriser), «constrained repair» (forslag som når AA/AAA mens låste roller bevares), releases/changelog, Mac-skjermfangst, iPad-kamera/Pencil, WebKit-sjekk av renderte sider. 16 språk inkl. norsk (NL, SV er i listen; «NO/NB» ikke i listen jeg leste). — App Store-beskrivelsen [primær]
  - Pris (USD): Free $0 (10 paletter i ett prosjekt, grunneksport PNG/CSS/core JSON); Pro månedlig $3,99, årlig $24,99, livstid $49,99. — [palettewright.com](https://palettewright.com) [selvrapportert]
  - Egen «competitive analysis» (rechecked 2026-08-26) nevner ColorCopy, Sip, ColorSlurp, Pikka, ColorSnapper, Coolors, Adobe Color, Atmos, Leonardo, Palettt, Figma Variables, Penpot, Tokens Studio, Style Dictionary, Polypane, Stark. Ikke Pinwheel, Kolorist eller Realtime Colors. Strukturert som «Other tools solve a color task. PaletteWright preserves the color system.» — [competitive-analysis.html](https://palettewright.com/competitive-analysis.html) [selvrapportert]

- **Pinwheel – Design Systems** (Bjango). Mac, macOS 15+, v1.12.0, i Mac App Store fra 2026-09-15 til $8,99. Bjangos egen side: $9 USD + tax, 30 dagers prøve, «All 1.x updates are included». Tidligere pris ca. $25 og ingen Mac App Store-versjon ifølge [sekundær] omtale fra nov. 2024 (mjtsai.com, via søk; ikke selv lest), så prisen er trolig senket. — [App Store via iTunes Lookup](https://itunes.apple.com/lookup?id=6809695736&country=us&entity=macSoftware) [primær], [bjango.com/mac/pinwheel](https://bjango.com/mac/pinwheel/) [primær]
  - Funksjoner: «Color sets» (trinnvise gradienter, «perfect as design system primitives», OKLAB/OKLCH-blanding), «Color aliases» for semantiske farger, navnerom/grupper, skygger/tall/strenger/boolske verdier. — App Store-beskrivelsen [primær]
  - Kontrast: «on-the-fly color accessibility testing that shows WCAG 2 and APCA contrast next to the picker»; rapporter som HTML/PDF; CLI. — App Store-beskrivelsen [primær]
  - Import/eksport: Design Tokens JSON, Figma-, Sketch-dokumenter, CSS, asset catalogs (import); eksport SCSS, Design Tokens JSON, SwiftUI color enums, egendefinerte maler, Figma-plugin. Åpent dokumentformat (Git-vennlig). — App Store-beskrivelsen [primær], [bjango.com](https://bjango.com/mac/pinwheel/) [primær]
  - **Ikke funnet:** komponent-/UI-forhåndsvisning, eksplisitt lys/mørk/økt kontrast-modus, Xcode asset catalog som eksportmål (kun import). — [bjango.com/help/pinwheel/welcome](https://bjango.com/help/pinwheel/welcome/) [primær; hjelpesiden er overfladisk]

**Plukkere og palettbiblioteker (ikke designsystem)**

- **Pastel** (Steven Troughton-Smith). iPhone/iPad/Mac, v2.6.2, oppdatert 2026-10-02, gratis (opptil 8 paletter) + engangs IAP. 4,7 av 5 fra 1 441 vurderinger. Hjul/RGB/crayons, fotoanalyse, iCloud, kopi av RGB/hex/Objective-C/Swift/SwiftUI, Procreate-eksport, bakgrunnsbilder. Ingen toneskalaer, kontrast eller tokens nevnt. — [App Store via iTunes Lookup](https://itunes.apple.com/lookup?id=413897608&country=us) [primær]
- **ColorSlurp** (IdeaPunch). iPhone/iPad/Mac, v1.5.3, **sist oppdatert 2023-07-14**, 4,5 av 5 (94). Eksport til PDF, ASE, CSS, Sass, Swift, CLR, HTML, JSON; harmonier; Pro-kjøp for palett-eksport. Ingen skalaer/kontrast nevnt i beskrivelsen. — [App Store via iTunes Lookup](https://itunes.apple.com/lookup?id=1287239339&country=us) [primær]
- **Coolors** (iOS-app). Sist oppdatert 2022-09-02 (v4.6.9), 4,8 av 5 (10 605). Generator, bildeuttrekk, eksport som bilde/PDF/lenke. Ingen tokens/kontrast i appbeskrivelsen. — [App Store via iTunes Lookup](https://itunes.apple.com/lookup?id=956480678&country=us) [primær]
- **ColorCopy** (Mac, menylinje). Innlegg 2026-05-18, godkjent i Mac App Store; august 2026-tillegg: nå selvdistribuert på ColorCopy.app, ikke lenger i Mac App Store. macOS 14+. Gratis med 50 kopier/mnd; Pro $7,99 engangs. 21 formater, 24 forhåndsinnstilte paletter (Tailwind, Material 3, Radix, IBM Carbon, **Apple System Colors**), «named scales», kontrastsjekker med WCAG 2 (AA/AAA) og APCA + «fix»-knapp, import .ase/.clr/JSON, eksport i åtte formater inkl. CSS custom properties. Ingen DTCG/Figma/asset catalog nevnt, ingen komponentforhåndsvisning. — [abeautifulsite.net](https://www.abeautifulsite.net/posts/introducing-colorcopy/) [primær]
- **Sip** (Mac, menylinje). Kontrastsjekk finnes, paletter, Apple-fargetyper (NSColor/UIColor/CGColor). Pris, versjon og eksportformater varierer mellom kildene ($10 i 2019, Setapp, 4.1.1 vs 5.0.1); ikke verifisert mot sipapp.io. — [TidBITS 2019](https://tidbits.com/2019/08/06/sip-smart-color-management-for-your-mac/) [sekundær], [appgefahren.de](https://www.appgefahren.de/sip-fuer-mac-farben-und-paletten-immer-griffbereit-258694.html) [sekundær]. Nåværende status: **[uverifisert]**.
- **Spectra: Color Picker** (Gabriel John Fordan). iPhone/iPad/Mac, minOS 26.0, utgitt 2026-07-14. Pro: WCAG 2.1 + APCA med «one-tap fix», harmonier, **eksport som SwiftUI Color Set og Xcode Asset Catalog**, Tailwind-token, JSON, iCloud-synk. Ingen toneskalaer/komponentforhåndsvisning. Ingen vurderinger ennå. — [App Store via iTunes Lookup](https://itunes.apple.com/lookup?id=6788351107&country=us&entity=macSoftware) [primær]
- **UI Color Palette Designer** (Itch Studio). iPhone/iPad (ikke Mac), v1.1.0, utgitt 2025-10-13, oppdatert 2026-08-04, gratis, 0 vurderinger. To glidere (kulør og chroma) genererer hele UI-paletten i OKLCH (bakgrunner, tekst, kanter, handlinger, varsler); «A sample screen (nav bar, hero card, buttons, a search field and status badges)»; WCAG 2.1-gradering per par (AAA/AA/AA Large/Fail); fargesynssimulering; eksport: CSS custom properties (OKLCH/HSL), CSS-tema med lys + mørk, SwiftUI Color extension, Android XML; lys/mørk-bryter; iCloud-forhåndsinnstillinger. Ingen DTCG/Figma/asset catalog, ingen tilstander nevnt. Nærmeste iOS-konkurrent i *ånd*. — [App Store via iTunes Lookup](https://itunes.apple.com/lookup?id=6753760392&country=us) [primær]
- **Contrasts – WCAG Accessibility** (Christoph Wendt), Mac, macOS 26+, v2.0.0, 2026-03-27, gratis: kun kontrastsjekk med forhåndsvisningsmodus. — [App Store](https://itunes.apple.com/lookup?id=6467809245&country=us&entity=macSoftware) [primær]
- **ContrastRadar** (Mac, 2026-08-14, v1.0): bilde-/skjermdump-basert WCAG 2.2 + APCA; ikke palettverktøy. — [App Store](https://itunes.apple.com/lookup?id=6798684772&country=us&entity=macSoftware) [primær]
- **Color Wheel** (Roman Sevastyanov), iOS, $3,99, v12.5, 2026-09-29: fargehjul for malere, har kontrastforhold-verktøy; ikke designsystem. — [App Store](https://itunes.apple.com/lookup?id=1449736609&country=us) [primær]
- **Pocket Palette** (Penpyre), iOS, gratis, 2026-05-05: enkel palett med hex/RGB/HSB/CMYK-kopi og CloudKit. — [App Store](https://itunes.apple.com/lookup?id=1342063329&country=us) [primær]
- **Pastel Palette Lab** (Sergey Fonov, iOS, 2026-09-05): ser ut som en nær kopi av Pastels funksjonsliste. — [App Store](https://itunes.apple.com/lookup?id=6771744010&country=us) [primær]
- **Pantone Connect** (X-Rite), v. 2020-12-30, 3,1 av 5 (214): Reference-kategori, ikke relevant for tokens. — iTunes Search [primær]
- **Fant ikke** (i iTunes-søk, Mac eller iOS, 2026-10-08): «Colorsnapper» (utenfor Mac App Store), «Contrast» (UsabilityHub/Stark), «Hues», Spectrum (Mac-fargeverktøy), «Color UI» eller Adobe Color som egen app (Adobe Capture finnes, v. 2023-11-28). Status **[uverifisert]**; de bør ikke omtales som tilgjengelige i App Store uten ny sjekk.

### Inferences
- Konkurransebildet 2026: det finnes minst to native Mac-apper med ekte designsystemambisjon (PaletteWright, Pinwheel). Kolorist kan ikke posisjonere seg som «den første native appen» for palett → designsystem uten å bli korrigert. Posisjonen må baseres på noe annet (se A3).
- PaletteWrights *komponentforhåndsvisning* er et generisk web-/app-UI-sett (kort, knapper, inputs, badges, charts, modaler) – ingen Apple-stil. Pinwheel har ingen forhåndsvisning. UI Color Palette Designer har én eksempelskjerm, uten tilstander.
- Utover PaletteWright er Xcode asset catalog som *eksport* bare funnet hos Spectra (Pro) – og der som plukker-eksport per farge, ikke som lys/mørk/økt-kontrast-variantsett fra et system. Pinwheel importerer asset catalogs, men eksporterer ikke (ut fra tilgjengelig tekst).
- Gamle apper (Coolors iOS 2022, ColorSlurp 2023) er stillestående – iOS/iPad-segmentet for generatorer er i praksis tomt for aktivt vedlikeholdte, designsystem-rettede apper med unntak av UI Color Palette Designer.

### Gaps
- PaletteWrights faktiske skjermbilder/UX og kvalitet er ikke testet; ingen uavhengige anmeldelser funnet (0 App Store-vurderinger; kun egen markedsføring og én pressemelding på einpresswire.com). Antall ramp-steg, om skalaer ankres til kontrastmål, og om norsk språk støttes, er ikke avklart.
- Pinwheels tilstands-/modusstøtte (lys/mørk/økt kontrast) er ikke bekreftet; kun en brukeranbefaling på produktsiden antyder det. Hjelpesidene om «Testing» og «Design Tokens JSON» ble ikke lest.
- Sip, ColorSnapper, Contrast (Stark/UsabilityHub), Hues, Spectrum (Mac), Adobe Color-app: ikke bekreftet nåværende pris/oppdatering/funksjoner i denne runden.
- App Store-anmeldelser (tekst) er ikke hentet; kun snittvurdering og antall via API. Ingen sitater fra anmeldelser funnet.
- Pris-/oppdateringsdata er for US-storefront.

---

## Del A2. Web-/Figma-verktøy med komponentforhåndsvisning

### Takeaway
Web-verktøyene viser typisk et ferdig eksempel-UI (landingsside, shadcn-blokker, Material-komponenter) i lys/mørk, men ingen av dem som er undersøkt viser eksplisitte hover/pressed/focus/disabled-tilstander side om side med kontrast pass/fail per par. Unntaket er Radix (skalaen er konstruert for tilstandene, ikke vist i en forhåndsvisning). Figmas innebygde kontrastsjekk støtter fortsatt ikke koblede variabler (brukerforespørsel januar 2026).

### Cited Findings
- **Realtime Colors** (realtimecolors.com): Forhåndsvisning er en hel landingsside: hero, funksjonsblokker, statistikkstripe, «How does it work»-steg, prisingkort (Basic, Pro «Most Popular», Enterprise), testimonials, FAQ, artikkelliste, bunntekst. Hover/focus/disabled ikke beskrevet. Kontrastindikator per fargeinput (Text, Background, Primary, Secondary, Accent): rødt kryss (ingen AA/AAA), gult (kanskje AA), grønt (AA+AAA). Lys/mørk-bryter (Alt+T). Eksport: CSS, Tailwind CSS, SCSS, Custom Code (DaisyUI, shadcn, NextUI, Flutter, Bootstrap, Material UI, Chakra, Vuetify m.fl.), Shades, Gradients, QR; verdiformat HEX/RGB/HSL/OKLAB/OKLCH. Ingen changelog på siden. — [realtimecolors.com](https://www.realtimecolors.com) [primær; WebFetch-sammendrag av siden]
- **Material Theme Builder** (material-foundation.github.io/material-theme-builder): Forhåndsvisning observert i nettleser 2026-10-08: tekstfelt (to varianter), chips (Assist, Filter, Suggestion), knapper (filled, tonal, outlined), FAB-er (liten/stor/utvidet), segmentknapper («Android / Windows / Web / Linux»), fremdriftsindikatorer, og «Light Scheme»-fargerollekort (Primary, Secondary, Tertiary, Error med On-/Container-roller). Kildeinndata: bilde/wallpaper (dynamisk farge) eller kilde-farge; kjernefarger og utvidede farger. Mørk modus-ikon i topplinjen. Verktøyet er et to-stegs flyt («Add Theme Colors», «Pick your fonts»). Eksportformater ble ikke verifisert i økta. GitHub-repoet er arkivert/skrivebeskyttet. — [live-verktøyet](https://material-foundation.github.io/material-theme-builder/) [primær, observert], [GitHub README](https://github.com/material-foundation/material-theme-builder) [primær]. Offisielt lanseringsinnlegg (2021): eksporterer «design tokens as a Design Systems Package» og tema-kode for Android Views og Jetpack Compose — [m3.material.io/blog](https://m3.material.io/blog/material-theme-builder) [primær, via søk, ikke selv åpnet]. Kontrastnivåer (medium/høy) i nettverktøyet: **[uverifisert]**.
- **tweakcn** (tweakcn.com/editor/theme): Observert 2026-10-08. Redigerbare tokens: Primary, Secondary, Accent, Base, Card, Popover, Muted, Destructive (hver Background/Foreground), Border/Input/Ring, Chart 1–5, Sidebar; Typography og «Other» (radius, skygge). Forhåndsvisningsfaner: Custom, Cards, Dashboard, Application, Marketing (shadcn-blokker: kalender, skjemaer, tabeller, dialoger, chat, chart m.m.). Knapper: «Export to Figma», «Import», «Share», «Save», «Code». AI-«Generate». Visuelle verdier i OKLCH. Kontrast per par er ikke observert. — [tweakcn.com](https://tweakcn.com/editor/theme) [primær, observert]. Gratis/åpen kildekode, Tailwind v3/v4 — [designrevision.com](https://designrevision.com/alternatives/tweakcn) [sekundær].
- **shadcn/ui** («Create» på ui.shadcn.com/create erstatter /themes?): Siden ble ikke lest (SPA); søk indikerer at april 2026-CLI kan bytte preset i eksisterende prosjekt og at Create er stedet for å prøve presets. — [releases.sh via søk](https://releases.sh/release/rel_i8uhrWFO70gBTq5Gt6BSH) [sekundær]. Forhåndsvisningsinnhold og tilstander: **[uverifisert]**.
- **uicolors.app**: Merke- og sekundærskala + status- og nøytralskala (gated bak Pro); forhåndsvisning i kategoriene Cards, Websites, Dashboards, Components, Shadcn/ui, Charts, Logos; skrifter; tilfeldige farger; lagrede paletter. Kontrastsjekk ikke innebygd (lenke til eget nettsted-kontrastverktøy). Eksportformater og lys/mørk ikke funnet på siden. — [uicolors.app](https://uicolors.app) [primær]
- **Atmos** (atmos.style): Fargegenerator og hjul (analogous/complementary/triadic/tetradic), semantisk statusgenerator (success/warning/danger/info fra primærfarge), skyggegenerator med easing-kurver, LCH/OKLCH, gamut sRGB/Display P3, kontrastsjekk WCAG 2 + APCA, fargesynssimulator, delte paletter, versjonshistorikk, Figma-plugin, import/eksport; «Get started – it's free». Forhåndsvisningskomponenter, tilstander og lys/mørk ikke beskrevet. — [atmos.style](https://atmos.style) [primær]
- **Radix Colors / custom palette** (radix-ui.com/colors/custom): Velger Accent, Gray, Background + Light/Dark-bryter; 12-trinnsskalaer; eksempel-UI (kontaktkort, påmeldingsskjema, oppgaveliste, sitat). Siden viser «Please upgrade to the new version»-melding. Trinnenes tiltenkte bruk er knyttet til tilstander: «3: UI element background (normal state)», «4: Hovered UI element background», «5: Active / Selected», «7: UI element border and focus rings», «8: Hovered UI element border», «9: Solid backgrounds», «10: Hovered solid backgrounds», «11: Low-contrast text», «12: High-contrast text»; steg 11 og 12 er «guaranteed to Lc 60 and Lc 90 APCA contrast ratio on top of a step 2 background from the same scale». — [custom palette](https://www.radix-ui.com/colors/custom) [primær], [understanding the scale](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale) [primær]
- **Coolors Visualizer**: Malltyper: Mobile/Web UI, Branding, Typography, Pattern, Illustration («More templates to come!»). Tilstander, kontrast og eksport fra visualiseringen er ikke nevnt; egen Contrast Checker finnes. Figma-plugin finnes. — [coolors.co/visualizer](https://coolors.co/visualizer) [primær]
- **Happy Hues**: Kuraterte paletter (1–17) vist på en eksempelside (bakgrunn, overskrift, underoverskrift, knapp, knappetekst, illustrasjon, kort, tagger, nyhetsbrev); klikk for å kopiere hex. Ingen tilstander, kontrast eller eksport. — [happyhues.co](https://www.happyhues.co) [primær]
- **Huemint**: «AI color palette generator»; forhåndsvisning for merke/nettsted/grafikk er ikke detaljert på startsiden. Detaljer **[uverifisert]**. — [huemint.com](https://www.huemint.com)
- **Color Scales I/O** (Figma-plugin, Tasos Dervenagas, innlegg 2026-06-13): Import fra Figma-utvalg, token-JSON, Leonardo-tema-URL, bildeuttrekk; «add or remove stops» for APCA og WCAG 2.1; «integrates Adobe Leonardo contrast colour engine under the hood»; 12+ fargerom; adaptive temaer (lys, mørk, høy kontrast, egne); eksport: Figma-variabler og stiler, W3C DTCG (JSON/YAML), Leonardo-URL (Pro), Dev Mode CSS/JS (Pro). Gratis kjerne; eksport til variabler/tokens begrenset til 3 per 30 dager; Pro $49 engangs. Ingen komponentforhåndsvisning eller tilstander nevnt (kun «preview changes live on your canvas»). 0 svar og 104 visninger ved lesing. — [Figma Forum](https://forum.figma.com/showcase-your-work-14/color-scales-i-o-create-edit-and-export-accessible-palettes-for-design-systems-54816) [primær, selvrapportert]
- **Supa Palette** (Figma): Eldre sekundærkilde: v4.0, 30K+ ferdige paletter, 11 fargesystemer (Tailwind, Material UI, Radix), kurveeditor, lys/mørk-moduser, engangskjøp $36–$168. Eksportformater ikke bekreftet. — [AlternativeTo](https://alternativeto.net/software/supa-palette/about) [sekundær]
- **Foundation: Color Generator** (Figma): kun sekundærkilder; genererer palett og fargestiler (gratis, ifølge én indonesisk blogg); eksportformater **[uverifisert]**. «Foundation Studio» er et annet plugin som skal eksportere til CSS/SCSS/JSON. — [buildwithangga.com](https://buildwithangga.com/tips/12-plugin-figma-paling-membantu-untuk-uiux-designer) [sekundær]
- **Tokens Studio**: Fargeramper via «color modifiers» krever Pro-medlemskap (artikkel jan. 2024); ingen innebygd kontrastsjekk funnet; DTCG-status ikke bekreftet i 2026. — [uxdesign.cc](https://uxdesign.cc/create-a-color-ramp-using-color-modifiers-in-tokens-studio-8222cf735242) [sekundær]
- **Figma innebygd**: Kontrastsjekker nås via fargevelgerens Custom-fane; fungerer ikke direkte på koblede variabler. Figma Forum-forespørsel 2025-09-12: «Currently it is only possible to check accessabilty (color contrast) with detached variables.»; svar 2025-11-05 («how is this not a thing?»), 2025-12-09 og 2026-01-15 («Please!»); 3 svar, 128 visninger, ingen Figma-statusmerking. APCA ikke bekreftet innebygd (kun via plugins som Stark). — [Figma Forum](https://forum.figma.com/suggest-a-feature-11/ability-to-check-the-color-contrast-of-color-variables-45165) [primær]. Også: Figma støtter ifølge brukertråd fortsatt ikke OKLCH/OKLab (innlegg t.o.m. desember 2025) — [Figma Forum](https://forum.figma.com/suggest-a-feature-11/support-oklab-and-oklch-8257/index4.html) [sekundær via søk]. Fant ikke noe offisielt Figma-release notes om kontrast 2025–2026 **[uverifisert]**.

### Inferences
- Tilstandene hover/pressed/focus/disabled er nesten alltid *implisitt* (Radix' skala er designet for dem; PaletteWright validerer dem) – få verktøy *viser* dem som en matrise med tilhørende kontrasttall. Dette er et mulig differensieringspunkt for Kolorist.
- Kontrast per par vises i Realtime Colors (3-nivå-indikator per inputfarge), UI Color Palette Designer (graderte par) og PaletteWright (deklarerte par), men sjelden knyttet til en Apple-stil komponentflate.
- Eksport til Figma-variabler/DTCG er i ferd med å bli standard (Color Scales I/O, PaletteWright, Pinwheel via plugin, tweakcn «Export to Figma»).

### Gaps
- Material Theme Builders eksportformater og kontrastnivåer, shadcn/ui Create, Huemint, Coolors Visualizer-detaljer, Supa Palette og Foundation-plugin: ikke verifisert direkte (SPA-sider som ikke lot seg lese, eller bare sekundærkilder).
- Stark, Leonardo (Adobe), Polypane og Penpot er ikke undersøkt direkte (kun nevnt i PaletteWrights egen analyse).
- Figmas offisielle 2025–2026-endringer for tilgjengelighet er ikke lest fra Figmas egne endringslogger.

---

## Del A3. Gapet og brukerklager

### Takeaway
Kombinasjonen «native Apple-app + OKLCH-/kontrastankrede skalaer + komponenttilstander (hover/pressed/focus/disabled) vist side om side + DTCG/Figma/Xcode-eksport + lys/mørk/økt kontrast + Apple-stil (iOS/Liquid Glass) forhåndsvisning» tilbys ikke i sin helhet av noen funnet. PaletteWright kommer nærmest, men har generisk (ikke Apple-stil) forhåndsvisning og ikke dokumentert Xcode asset catalog-eksport.

### Cited Findings
- Apples egen HIG krever varianter for lys, mørk og økt kontrast for egendefinerte farger («If you define a custom color, make sure to supply light and dark variants, and an increased contrast option for each variant that provides a significantly higher amount of visual differentiation.» — [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color) [primær]). Ingen av de gjennomgåtte verktøyene annonserer produksjon av Xcode color sets med alle tre variantene fra ett fargesystem; PaletteWright annonserer «Light, Dark, and Increased Contrast» i validering og «SwiftUI»-eksport, men ikke asset catalog. — [App Store-beskrivelse](https://itunes.apple.com/lookup?id=6771067568&country=us&entity=macSoftware) [primær]
- Brukerforespørsler funnet:
  - Figma Forum (2025-09 → 2026-01): kontrastsjekk for koblede variabler, sitater i A2. — [Figma Forum](https://forum.figma.com/suggest-a-feature-11/ability-to-check-the-color-contrast-of-color-variables-45165) [primær]
  - Tokens Studio feature request «Theme Switcher for non-DS designers» (Chris Kerr, 2024-04-11, 76 stemmer): «Our design team really need to be able to apply themes (light/dark mode, density, etc, etc). using tokens.»; «we are having to compromise the architecture of our tokens to support Figna's approach to them.»; «a lot more tokens to manage.»; «forcing us to make all the colours we need explicit in the primitive layer.»; «A specific example not being able to abstract common colour modifications for states.» — [Tokens Studio Featurebase](https://tokensstudio.featurebase.app/p/theme-switcher-for-non-ds-designers) [primær]
  - Figma Forum: «how long until OKLCH» (se A2) [sekundær].
- Fant **ikke** konkrete sitater fra r/FigmaDesign, r/UXDesign, Product Hunt eller App Store-anmeldelser som ber om denne kombinasjonen (Reddit-søk ga ingen treff; én speilet r/FigmaDesign-tråd «The contrast checker» ble bare sett i søkeresultat og ikke lest). — søk 2026-10-08.

### Inferences
- Gapet som synes å stå åpent (det må valideres ved at noen laster ned og tester PaletteWright og Pinwheel): (1) **Apple-stil forhåndsvisning** med ekte iOS/macOS-komponenter og Liquid Glass-oppførsel, ikke generisk web-UI; (2) **tilstandsmatrise** (normal/hover-pressed/focus/disabled) med kontrasttall per par, i lys/mørk/økt kontrast; (3) **Xcode asset catalog / Color Set** som førsteklasses eksport med alle tre variantene, sammen med DTCG og Figma; (4) skalaer *forankret i kontrastmål* (Radix: steg 11/12 garantert Lc 60/90; Color Scales I/O og Leonardo gjør kontrastbasert) kombinert med OKLab/OKLCH-konsistens; (5) norsk/nordisk lokalisering (PaletteWright har NL og SV, men NB/NO ikke bekreftet).
- Posisjonering må konkurrere mot PaletteWright (bredde, CI, validering) og Pinwheel (profesjonelt token-format, Bjango-omdømme) – og trolig vinne på *Apple-fidelity og enkelhet* heller enn bredde.
- Risiko: PaletteWright er ung (juni 2026) og utvikles raskt (2.0 → 2.3 på 2 måneder); gapet kan lukkes.

### Gaps
- Ingen uavhengige brukeranmeldelser eller forum-sitater om PaletteWright/Pinwheel funnet.
- Reddit, Product Hunt og App Store-anmeldelser er ikke søkt systematisk (søkemotoren returnerte ikke Reddit-innhold; ingen direkte tilgang).
- Ingen kvantitative markedsdata.

---

## Del B1. Apples offisielle systemfargeverdier

### Takeaway
Apples HIG Color-side (sist oppdatert 16. desember 2025; verdiene «Updated system color values» 9. juni 2025) publiserer **én felles tabell** (SwiftUI-navn) med RGB for 12 systemfarger i fire varianter, pluss seks iOS/iPadOS-gråtoner. HIG oppgir **ikke** tallverdier for bakgrunns- eller etikettfarger; de kommer her fra sekundærkilde (iOS 13, 2019) og en egen måling på macOS 27.

### Cited Findings

**Apples forbehold (primær):** «Avoid hard-coding system color values in your app. Documented color values are for your reference during the app design process. The actual color values may fluctuate from release to release, based on a variety of environmental variables. Use APIs like Color to apply system colors.» — [HIG Color JSON](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/color.json) (hentet 2026-10-08) [primær]. Endringslogg: «June 9, 2025: Updated system color values, and added guidance for Liquid Glass.», «December 16, 2025: Updated guidance for Liquid Glass.», «December 19, 2022: Corrected RGB values for system mint color (Dark Mode)». Tabellen er felles for iOS/iPadOS/macOS/(visionOS bruker mørk standard): «visionOS system colors use the default dark color values.»

**Systemfarger (RGB oppgitt av Apple som alt-tekst «R-…,G-…,B-…» på fargeprøvebildene; hex er egen konvertering).** Kolonner som i HIG: Default (light), Default (dark), Increased contrast (light), Increased contrast (dark):

| Farge (SwiftUI) | Lys | Mørk | Lys + økt kontrast | Mørk + økt kontrast |
|---|---|---|---|---|
| red | 255,56,60 (#FF383C) | 255,66,69 (#FF4245) | 233,21,45 (#E9152D) | 255,97,101 (#FF6165) |
| orange | 255,141,40 (#FF8D28) | 255,146,48 (#FF9230) | 197,83,0 (#C55300) | 255,160,86 (#FFA056) |
| yellow | 255,204,0 (#FFCC00) | 255,214,0 (#FFD600) | 161,106,0 (#A16A00) | 254,223,67 (#FEDF43) |
| green | 52,199,89 (#34C759) | 48,209,88 (#30D158) | 0,137,50 (#008932) | 74,217,104 (#4AD968) |
| mint | 0,200,179 (#00C8B3) | 0,218,195 (#00DAC3) | 0,133,117 (#008575) | 84,223,203 (#54DFCB) |
| teal | 0,195,208 (#00C3D0) | 0,210,224 (#00D2E0) | 0,129,152 (#008198) | 59,221,236 (#3BDDEC) |
| cyan | 0,192,232 (#00C0E8) | 60,211,254 (#3CD3FE) | 0,126,174 (#007EAE) | 109,217,255 (#6DD9FF) |
| blue | 0,136,255 (#0088FF) | 0,145,255 (#0091FF) | 30,110,244 (#1E6EF4) | 92,184,255 (#5CB8FF) |
| indigo | 97,85,245 (#6155F5) | 109,124,255 (#6D7CFF) | 86,74,222 (#564ADE) | 167,170,255 (#A7AAFF) |
| purple | 203,48,224 (#CB30E0) | 219,52,242 (#DB34F2) | 176,47,194 (#B02FC2) | 234,141,255 (#EA8DFF) |
| pink | 255,45,85 (#FF2D55) | 255,55,95 (#FF375F) | 231,18,77 (#E7124D) | 255,138,196 (#FF8AC4) |
| brown | 172,127,94 (#AC7F5E) | 183,138,102 (#B78A66) | 149,109,81 (#956D51) | 219,166,121 (#DBA679) |

**iOS/iPadOS system gray (UIKit-navn):**

| Navn | Lys | Mørk | Lys + økt kontrast | Mørk + økt kontrast |
|---|---|---|---|---|
| systemGray | 142,142,147 (#8E8E93) | 142,142,147 (#8E8E93) | 108,108,112 (#6C6C70) | 174,174,178 (#AEAEB2) |
| systemGray2 | 174,174,178 (#AEAEB2) | 99,99,102 (#636366) | 142,142,147 (#8E8E93) | 124,124,128 (#7C7C80) |
| systemGray3 | 199,199,204 (#C7C7CC) | 72,72,74 (#48484A) | 174,174,178 (#AEAEB2) | 84,84,86 (#545456) |
| systemGray4 | 209,209,214 (#D1D1D6) | 58,58,60 (#3A3A3C) | 188,188,192 (#BCBCC0) | 68,68,70 (#444446) |
| systemGray5 | 229,229,234 (#E5E5EA) | 44,44,46 (#2C2C2E) | 216,216,220 (#D8D8DC) | 54,54,56 (#363638) |
| systemGray6 | 242,242,247 (#F2F2F7) | 28,28,30 (#1C1C1E) | 235,235,240 (#EBEBF0) | 36,36,38 (#242426) |

(Merknad fra HIG: «In SwiftUI, the equivalent of systemGray is gray.» Endringslogg 2024-02-02: «Distinguished UIKit and SwiftUI gray colors in iOS and iPadOS».)

Kilde for begge tabeller: [HIG Color JSON](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/color.json) [primær], tall hentet fra `references[*].alt` på bildene `colors-unified-*` og `ios-default-/ios-accessible-systemgray*`.

**Egen kontrastberegning (WCAG 2.x relativ luminans) [egen beregning] av Apples tall:**

| Farge | lys på #FFFFFF | mørk på #000000 | lys+økt kontrast på #FFFFFF | mørk+økt kontrast på #000000 |
|---|---|---|---|---|
| red | 3,57 | 6,12 | 4,56 | 7,15 |
| orange | 2,31 | 9,41 | 4,55 | 10,41 |
| yellow | 1,51 | 14,87 | 4,59 | 15,85 |
| green | 2,22 | 10,39 | 4,54 | 11,42 |
| mint | 2,12 | 11,82 | 4,55 | 12,79 |
| teal | 2,16 | 11,30 | 4,57 | 12,74 |
| cyan | 2,16 | 11,94 | 4,57 | 13,02 |
| blue | 3,52 | 6,49 | 4,57 | 9,76 |
| indigo | 5,09 | 5,98 | 6,12 | 9,84 |
| purple | 4,17 | 5,79 | 5,21 | 9,75 |
| pink | 3,65 | 5,96 | 4,57 | 9,68 |
| brown | 3,53 | 6,84 | 4,58 | 9,74 |

Hvit tekst på default lys-blå (#0088FF): 3,52:1; på økt kontrast-blå (#1E6EF4): 4,57:1. Mørk-blå (#0091FF) på #1C1C1E: 5,26:1.

**Bakgrunnsfarger (iOS/iPadOS).** HIG beskriver kun *rollene* (primær/sekundær/tertiær; «system» vs «grouped»: «Primary for the overall view / Secondary for grouping content or elements within the overall view / Tertiary for grouping content or elements within secondary elements») og at mørk modus har «base» og «elevated» bakgrunner; ingen tallverdier. — [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color), [HIG Dark Mode](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/dark-mode.json) [primær]

Tallverdier **[sekundær: Noah Gilmore, «Dark mode UIColor compatibility», datert 2019-06-08, iOS 13; sannsynligvis utdatert i detaljene for iOS 26, jf. Apples forbehold]**:

| Navn | Lys | Mørk |
|---|---|---|
| systemBackground | #FFFFFF | #000000 |
| secondarySystemBackground | #F2F2F7 | #1C1C1E |
| tertiarySystemBackground | #FFFFFF | #2C2C2E |
| systemGroupedBackground | #F2F2F7 | #000000 |
| secondarySystemGroupedBackground | #FFFFFF | #1C1C1E |
| tertiarySystemGroupedBackground | #F2F2F7 | #2C2C2E |

— [noahgilmore.com](https://noahgilmore.com/blog/dark-mode-uicolor-compatibility/) [sekundær]. Merk samsvar: lysegrå F2F2F7 og mørk 1C1C1E/2C2C2E er identiske med Apples publiserte systemGray6 (lys 242,242,247; mørk 28,28,30) og systemGray5 mørk (44,44,46) ovenfor [primær], noe som styrker at verdiene fortsatt stemmer. Økt kontrast-verdier for bakgrunnene: **ikke funnet**.

**Etikettfarger (iOS/iPadOS)** [sekundær, samme kilde, iOS 13]:

| Navn | Lys | Mørk |
|---|---|---|
| label | #000000 (100 %) | #FFFFFF (100 %) |
| secondaryLabel | #3C3C43 @ 60 % | #EBEBF5 @ 60 % |
| tertiaryLabel | #3C3C43 @ 30 % | #EBEBF5 @ 30 % |
| quaternaryLabel | #3C3C43 @ 18 % | #EBEBF5 @ 18 % |

(Kilden oppgir mørk quaternary som 0,18; andre kilder har gitt 0,16 — uverifisert.) HIG lister kun roller: Label, Secondary label, Tertiary label, Quaternary label, Placeholder text, Separator, Opaque separator, Link. — [HIG Color JSON](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/color.json) [primær]

**macOS (HIG):** HIG lister AppKit-roller (labelColor, secondaryLabelColor, tertiaryLabelColor, quaternaryLabelColor, windowBackgroundColor, controlBackgroundColor, underPageBackgroundColor, textBackgroundColor, separatorColor, controlAccentColor, linkColor, keyboardFocusIndicatorColor, selectedContentBackgroundColor, m.fl.) uten tallverdier. — [HIG Color JSON](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/color.json) [primær]. Appens aksentfarge: «Beginning in macOS 11, you can specify an accent color to customize the appearance of your app's buttons, selection highlighting, and sidebar icons. The system applies your accent color when the current value in General > Accent color settings is multicolor.»

**macOS-verdier målt 2026-10-08 [egen måling; macOS 27 / Darwin 27.0.0; Swift-skript med `NSAppearance.performAsCurrentDrawingAppearance`, sRGB, kommandolinjeprosess, ikke et ekte vindu]:**

| NSColor | Aqua (lys) | Dark Aqua |
|---|---|---|
| windowBackgroundColor | #FFFFFF | #1E1E1E |
| controlBackgroundColor | #FFFFFF | #1E1E1E |
| textBackgroundColor | #FFFFFF | #1E1E1E |
| underPageBackgroundColor | #F6F6F6 | #282828 |
| labelColor | svart, α 0,847 | hvit, α 0,847 |
| secondaryLabelColor | svart, α 0,498 | hvit, α 0,549 |
| tertiaryLabelColor | svart, α 0,259 | hvit, α 0,247 |
| quaternaryLabelColor | svart, α 0,098 | hvit, α 0,098 |
| separatorColor | svart, α 0,098 | hvit, α 0,098 |
| controlAccentColor | #007AFF | #007AFF |
| linkColor | #0068DA | #419CFF |
| systemBlue | #0088FF | #0091FF |
| systemRed | #FF383C | #FF4245 |
| systemGreen | #34C759 | #30D158 |
| systemGray | #8E8E93 | #98989D |
| selectedContentBackgroundColor | #0064E1 | #0059D1 |
| keyboardFocusIndicatorColor | #0067F4 α 0,498 | #1AA9FF α 0,498 |
| disabledControlTextColor | svart α 0,247 | hvit α 0,247 |

NSColor.systemBlue/Red/Green (lys og mørk) samsvarer eksakt med HIG-tabellen ovenfor, noe som bekrefter at macOS 27 bruker de samme «unified» verdiene. Avviket: `systemGray` mørk er #98989D på macOS mot #8E8E93 i HIG (iOS UIKit). Økt kontrast-utseendene (`accessibilityHighContrastAqua`/`DarkAqua`) ga identiske verdier som standard i denne målemetoden, så økt kontrast-verdier for macOS-roller er **ikke** målt (sannsynlig begrensning ved kjøring utenfor en ekte app/systeminnstilling).

### Inferences
- Apples «økt kontrast»-lysvarianter er konstruert slik at *alle* ender på ca. 4,5:1 mot hvit (4,54–4,59 for de fleste; indigo/purple har mer) – mens standard lysvarianter feiler 4,5:1 (gult 1,51:1). Dette tyder på at Apples system er *kontrastforankret for økt kontrast* og farge-/kulørbalansert i standard. Brukbar designregel for Kolorists «Apple-stil»: standardvariant tuner for kulør/«glød», økt kontrast tuner for ≥ 4,5:1 mot bakgrunn.
- Mørke varianter er lysere/mer mettede og alle ≥ 5,6:1 mot sort; ingen av de mørke standardfargene trenger økt kontrast for 4,5:1 mot #000000, men mot elevated-bakgrunner (#1C1C1E) er marginen mindre.
- Tallverdier for bakgrunn/etikett bør, om de brukes i appen, hentes dynamisk via API (`Color(.systemBackground)` osv.) i stedet for å kopieres; i en *forhåndsvisning* av Apple-stil kan sekundærkildens iOS 13-verdier brukes som tilnærming med forbehold, og kan kontrolleres mot HIG-grått (F2F2F7, 1C1C1E, 2C2C2E).

### Gaps
- Ingen tallverdier fra Apple for iOS-bakgrunns- og etikettfarger i denne HIG-versjonen (kun roller). Verdiene her kommer fra iOS 13 (2019) [sekundær]; verifisering mot iOS 26 krever måling i simulator/enhet (ikke gjort; kunne ikke kjøre kode i iOS-simulator i denne runden).
- Bakgrunns-/etikett-verdier for økt kontrast og «elevated» mørke bakgrunner er ikke dokumentert i primærkilder jeg fant. Dark mode «elevated» er kun beskrevet kvalitativt.
- macOS-måling er fra kommandolinje, ikke ekte vindu; økt kontrast-verdier uten forskjell.
- sarunw.com og andre sekundærkilder ble ikke brukt.

---

## Del B2. Apples kontrastveiledning (Accessibility-siden)

### Takeaway
Apple viser WCAG AA-terskler i tabellform og nevner APCA ved navn, men gir ikke APCA-terskler. Mørk modus-siden setter lavest 4,5:1 og anbefaler 7:1 for liten tekst.

### Cited Findings
- Sitat (Accessibility › Vision): «Strive to meet color contrast minimum standards. To ensure all information in your app is legible, it's important that there's enough contrast between foreground text and icons and background colors. Two popular standards of measure for color contrast are the [WCAG] and the Accessible Perceptual Contrast Algorithm (APCA). Use standard contrast calculators to ensure your UI meets acceptable levels. Accessibility Inspector uses the following values from WCAG Level AA as guidance in determining whether your app's colors have an acceptable contrast.» — [HIG Accessibility JSON](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/accessibility.json), hentet 2026-10-08 [primær]
- Tabell (eksakt):

  | Text size | Text weight | Minimum contrast ratio |
  |---|---|---|
  | Up to 17 pts | All | 4.5:1 |
  | 18 pts | All | 3:1 |
  | All | Bold | 3:1 |

  — samme kilde [primær]. (Merk: tabellen hopper over området mellom 17 og 18 pt; slik står den.)
- Oppfølging: «If your app doesn't provide this minimum contrast by default, ensure it at least provides a higher contrast color scheme when the system setting Increase Contrast is turned on. If your app supports Dark Mode, make sure to check the minimum contrast in both light and dark appearances.» — samme kilde [primær]
- «Prefer system-defined colors. These colors have their own accessible variants that automatically adapt when people adjust their color preferences, such as enabling Increase Contrast or toggling between the light and dark appearances.» — samme kilde [primær]
- Standard- og minstestørrelser for egendefinert tekst: iOS/iPadOS 17 pt / 11 pt; macOS 13 pt / 10 pt; tvOS 29/23; visionOS 17/12; watchOS 16/12. — samme kilde [primær]
- Dark Mode-siden: «Aim for sufficient color contrast in all appearances. […] At a minimum, make sure the contrast ratio between colors is no lower than 4.5:1. For custom foreground and background colors, strive for a contrast ratio of 7:1, especially in small text.» — [HIG Dark Mode JSON](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/dark-mode.json) [primær]. Samme side: «in Dark Mode with Increase Contrast and Reduce Transparency turned on (both separately and together), you may find places where dark text is less legible when it's on a dark background. You might also find that turning on Increase Contrast in Dark Mode can result in reduced visual contrast between dark text and a dark background.»
- Mørk modus (iOS/iPadOS): «two sets of background colors — called base and elevated»; «Prefer the system background colors. […] the background color automatically changes from base to elevated when an interface is in the foreground, such as a popover or modal sheet.» — samme kilde [primær]

### Inferences
- Apple tilbyr to «gulv»: 4,5:1 (alltid) og 7:1 (anbefalt for liten tekst på egendefinerte farger). Kolorist kan bruke disse som to kontrastmål («AA, AAA-aktig»).
- Terskelen for ikke-tekst-UI (3:1) står ikke i denne tabellen (kun tekst vekt/størrelse) – WCAG 1.4.11 må hentes fra W3C ved behov.

### Gaps
- Ingen APCA-terskler fra Apple. Ingen krav til ikke-tekst-kontrast (knappekant, fokusring) i HIG-sidene som ble lest.

---

## Del B3. Liquid Glass (iOS 26/macOS 26): tint, merkefarge, kontrast og glassProminent

### Takeaway
Apple sier at glass «has no inherent color» og tar farge fra innholdet bak; farge skal brukes sparsomt, på *bakgrunnen* til primærhandlinger (ikke symboler/tekst), og aksentfargen brukes automatisk på prominente knapper. Kontrasten over glass håndteres av systemmaterialet, scroll edge effect og en anbefalt 35 % mørk dimming-lag for clear glass over lyst innhold.

### Cited Findings
- «By default, Liquid Glass has no inherent color, and instead takes on colors from the content directly behind it. You can apply color to some Liquid Glass elements, giving them the appearance of colored or stained glass. This is useful for drawing emphasis to a specific control, like a primary call to action, and is the approach the system uses for prominent button styling.» — [HIG Color › Liquid Glass color](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/color.json) [primær]
- «Apply color sparingly to the Liquid Glass material, and to symbols or text on the material. If you apply color, reserve it for elements that truly benefit from emphasis, such as status indicators or primary actions. To emphasize primary actions, apply color to the background rather than to symbols or text. For example, the system applies the app accent color to the background in prominent buttons — such as the Done button — to draw attention and elevate their visual prominence. Refrain from adding color to the background of multiple controls.» — samme kilde [primær]
- Merkefarge: «By contrast, in apps with primarily monochromatic content or backgrounds, choosing your brand color as the app accent color can be an effective way to tailor your app experience and reflect your company's identity.» Motsatt: «Avoid using similar colors in control labels if your app has a colorful background. […] too much color can be overwhelming and make control labels more difficult to read. If your app features colorful backgrounds or visually rich content, prefer a monochromatic appearance for toolbars and tab bars, or choose an accent color with sufficient visual differentiation.» — samme kilde [primær]
- Standardutseende: «By default, symbols and text on these elements follow a monochromatic color scheme, becoming darker when the underlying content is light, and lighter when it's dark. Liquid Glass appears more opaque in larger elements like sidebars to preserve legibility over complex backgrounds and accommodate richer content on the material's surface.» — samme kilde [primær]
- «Be aware of the placement of color in the content layer. Make sure your interface maintains sufficient contrast by avoiding overlap of similar colors in the content layer and controls when possible. Although colorful content might intermittently scroll underneath controls, make sure its default or resting state — like the top of a screen of scrollable content — maintains clear legibility.» — samme kilde [primær]
- Egendefinerte farger: «Make sure all your app's colors work well in light, dark, and increased contrast contexts. […] If you define a custom color, make sure to supply light and dark variants, and an increased contrast option for each variant […]. Even if your app ships in a single appearance mode, provide both light and dark colors to support Liquid Glass adaptivity in these contexts.» — samme kilde [primær]
- Adopting Liquid Glass: «Review your use of color in controls. Be judicious with your use of color in controls and navigation so they stay legible. If you do apply color to these elements, leverage system colors, or define a custom color with light and dark variants, and an increased contrast option for each variant.» Også «Reduce your use of custom backgrounds in controls and navigation elements» og «Test your app's custom elements, colors, and animations with different configurations of these settings» (Reduce Transparency/Motion). — [Adopting Liquid Glass JSON](https://developer.apple.com/tutorials/data/documentation/technologyoverviews/adopting-liquid-glass.json) [primær]
- Materials-siden: Liquid Glass har to varianter, regular og clear. «Use the regular variant when background content might create legibility issues, or when components have a significant amount of text.» Clear: «If the underlying content is bright, consider adding a dark dimming layer of 35% opacity.» «Help ensure legibility by using vibrant colors on top of materials.» — [HIG Materials JSON](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/materials.json) [primær]
- Scroll edge effect: «Scroll views offer a scrollEdgeEffectStyle(_:for:) that helps maintain sufficient legibility and contrast for controls by obscuring content that scrolls beneath them.» — Adopting Liquid Glass [primær]
- `glassProminent`-stilen: «A button style that applies a prominent Liquid Glass effect based on the button's context. […] This style is similar to the borderedProminent style.» — [SwiftUI PrimitiveButtonStyle.glassProminent](https://developer.apple.com/tutorials/data/documentation/swiftui/primitivebuttonstyle/glassprominent.json) [primær]. `Glass.tint(_:)`: «Returns a copy of the structure with a configured tint color.»; eksempeltekst: «Assign a tint color to suggest prominence.» — [SwiftUI Glass.tint](https://developer.apple.com/tutorials/data/documentation/swiftui/glass/tint(_:).json) [primær]
- Praktisk mønster (WWDC25-referat): `.glass` for sekundære handlinger uten tint, `.glassProminent` + `.tint` for primærhandling; å tinte alle knapper gjør at ingenting skiller seg ut. — [DEV Community](https://dev.to/diskcleankit/liquid-glass-in-swift-official-best-practices-for-ios-26-macos-tahoe-1coo) [sekundær]. Betarapport om at tint på `glassProminent` ikke virket i lys modus — [Natasha The Robot](https://www.natashatherobot.com/p/liquidglass-button-ios-26) [sekundær; beta-tid, uverifisert nå].
- Appikoner (iOS/iPadOS/macOS 26): «default (light), dark, clear, and tinted appearance variants». — Adopting Liquid Glass [primær]

### Inferences
- For en Apple-stil forhåndsvisning betyr dette: merkefargen vises som (a) appens aksentfarge (bakgrunn på `glassProminent`-knapper, valgte elementer, lenker), ikke som farge på glassflater generelt; (b) ett prominent element per visning; (c) toolbar/tab bar monokrome som standard; (d) glass uten egen farge.
- Kontrast over glass kan ikke beregnes fra paletten alene (avhenger av bakgrunnsinnholdet og systemets dimming/luminans-justering). En forhåndsvisning bør derfor vise kontrast for *palett→flate*-par (aksentbakgrunn + etikett, tekst på systembakgrunn), og merke glass som «systemhåndtert»/ikke målbart.
- Aksentfargen må ha lys-/mørk-/økt kontrast-varianter og gi lesbar hvit (eller svart) etikett på `glassProminent`; Apples eget blå gir 3,52:1 med hvit tekst i standard (se B1), så Apples egen standard oppfyller ikke 4,5:1 uten økt kontrast; dette er en relevant «design-realitet» å vise.

### Gaps
- Ikke lest: HIG Buttons-siden og «Applying Liquid Glass to custom views» i sin helhet (kun søkt etter tint/prominent: ingen treff utover `tint`-eksempelet). Eksakt tint-algoritme/opasitet for `glassProminent` er ikke dokumentert i det jeg leste.
- Ingen tallverdier for Liquid Glass-dimming utenom 35 % for clear glass.
- Nyere endringer etter 2025-12-16 (HIG Color) er ikke undersøkt.

---

## Kildeoversikt (hentet 2026-10-08)
- Apple HIG JSON: color.json, dark-mode.json, accessibility.json, materials.json (developer.apple.com/tutorials/data/design/human-interface-guidelines/…)
- Apple Developer Documentation JSON: adopting-liquid-glass, primitivebuttonstyle/glassprominent, glass/tint(_:)
- iTunes Search/Lookup API (App Store-data, US)
- Egne målinger: AppKit-fargeverdier (Swift-skript på macOS 27), kontrastberegninger (Python)
- palettewright.com (hovedside, features, competitive-analysis, how-to-validate-palettes, release-notes), bjango.com/mac/pinwheel, abeautifulsite.net (ColorCopy), realtimecolors.com, tweakcn.com (observert), material-foundation.github.io/material-theme-builder (observert), radix-ui.com/colors, atmos.style, uicolors.app, coolors.co/visualizer, happyhues.co, huemint.com, Figma Forum (to tråder), Tokens Studio Featurebase, noahgilmore.com
