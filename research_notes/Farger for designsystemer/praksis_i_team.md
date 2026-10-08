# Hvordan design- og frontend-team faktisk bygger og vedlikeholder fargesystemer (2023–2026)

Metodenotat: Datert 2026-10-08. Mange av kildene lot seg bare hente som maskinsammendrag via WebFetch (ikke full tekst), og søkemotoren ga lite fra Reddit, Hacker News, Medium (betalingsmur) og Figma Community (JS-rendret, ingen brukertall). Alt som står uten kilde under «Gaps» er IKKE funnet. Tall er gjengitt slik kilden oppgir dem; sitater er på originalspråk (engelsk). Kilder merket «(sammendrag)» er ikke lest i full tekst.

## 1. Hva rapporterer praktikere som riktig antall nyanser, trinn og tokens, og hvorfor?

### Takeaway
Det finnes ingen konsensus om ett tall, men de konkrete eksemplene klynger seg rundt: 6–10 kulørfamilier, 10–12 trinn per skala (50–900/950 eller 1–12), og omtrent 40–100 semantiske fargetokens. Flere praktikere sier at de stoppet på det semantiske laget; en annen (Steve Dennis) mener det motsatte og endte med flere, mer spesifikke komponenttokens for å gjøre valg enklere.

### Cited Findings
- Dashlane (mørk modus lansert januar 2025, prosjekt startet 2022): endte med 91 tokens på semantisk nivå og «stoppet» før komponentspesifikke tokens. Reglene «If you touch it, migrate it» og halvukentlige automatiske kodeskanninger ble brukt for adopsjon. Verktøy: Tokens Studio (fargeverdier) og Specify (nå nedlagt). «Contrast logic is basically inverted in dark mode.» Tilbakemelding fra brukere: «My retinas are burning» (om lys tema). (sammendrag) — [Dashlane](https://dashlane.com/blog/dark-theme-dashlane)
- Hightouch: 10 kulørfamilier × 10 nyanser (50–900), alt i OKLCH; basistrinnet er 600 (knapper, ikon, lenker); semantiske tokens peker på bestemte trinn «to keep components in sync». (sammendrag) — [Hightouch UI](https://ui.hightouch.com/foundation/colors)
- Close (CRM), juli 2024: 6 kulørfamilier («Gray, Gold, Blue, Red, and others») med 90+ trinn totalt, ca. 10–20 trinn per skala (colorGray01–colorGray90); skiftet fra HSL til LCH fordi «In HSL, colors with different hues and the same lightness value can be perceived as different levels of lightness». (sammendrag) — [Close: Light and dark, our color systems journey](https://making.close.com/posts/light-and-dark-our-color-systems-journey/)
- Linear (mars 2024): gikk fra 98 spesifikke variabler per tema til tre inngangsvariabler (base, aksent, kontrast) og LCH; kontrastvariabelen går fra 30 til 100 og gir automatisk høykontrasttema. Begrunnelse: «LCH has the benefit that it's perceptually uniform, meaning a red and a yellow color with lightness 50 will appear roughly equally light to the human eye.» (sammendrag) — [Linear: How we redesigned the Linear UI](https://linear.app/now/how-we-redesigned-the-linear-ui)
- Radix Colors: 12 trinn per skala med fast rolle per trinn (1–2 bakgrunner, 3–5 komponentbakgrunn normal/hover/aktiv, 6–8 kanter og fokusring, 9–10 solid fyll og dens hover, 11–12 tekst lav/høy kontrast). Lys og mørk er egne skalaer, P3-støtte fra v3. «you can guarantee that you won't have any contrast issues just by following the recommended applications.» (sekundærkilde, pakkedokumentasjon) — [Radix Colors via pub.dev](https://pub.dev/documentation/radix_colors/latest/)
- Et produksjonsklart tema trenger «roughly 40–60 color tokens» (bakgrunn, tekst, kanter, interaktive tilstander for lys og mørk) — påstand fra en enkelt blogg, ikke primærkilde — [Dolfy-blogg via søk](https://www.dolfy.ai/blog/dark-mode-design-tokens-real-theming-mobile-apps)
- Howard Shaw (dev.to, 15. des. 2025), solo-prosjekt: semantiske kategorier `bg.canvas/surface/elevated`, `text.primary/secondary/muted`, `border.subtle/strong`, `accent`, `success/warning/danger/info`. «Dark mode is not colors. It is a forcing function» som avslører inkonsekvent komponentstyling. (sammendrag) — [dev.to](https://dev.to/howard_shaw_3c36a3a6cb900/i-finally-added-dark-mode-and-it-forced-me-to-fix-more-than-colors-2n84)
- Steve Dennis (11. sep. 2022, utenfor tidsrommet men ofte sitert): «Don't overcomplicate decision points.» Hans løsning var enkle, statiske semantiske paletter med svært spesifikke komponenttokens-alias: flere tokens, men klarere valg. Står i direkte motsetning til Dashlane-valget. (sammendrag) — [My Five Biggest Design System Mistakes](https://clipcontent.substack.com/p/my-five-biggest-design-system-mistakes-4725859926c2)
- Primer (GitHub) har ni temaer (light, dark, dimmed, høykontrast, fargeblind/tritanopi-varianter) fra samme funksjonelle token-lag. — [primer/primitives](https://github.com/primer/primitives)
- GitHub (2022): HSLuv-baserte skalaer, «Primer Prism» laget fordi «disjointed color tools» ga et prosess av «trial and error, copy and paste»; Figma-filen for mørk modus hadde 370 000+ lag. Åtte eksisterende verktøy inspirerte Prism, bl.a. ColorBox, Leonardo og Huetone. (sammendrag) — [GitHub Blog](https://github.blog/2022-06-14-accelerating-github-theme-creation-with-color-tooling/)
- Stripe (15. okt. 2019, klassiker): bytte til CIELAB; garanti om at to farger har tilstrekkelig kontrast for liten tekst hvis de er minst fem nivåer fra hverandre. Original palett: «none of the default text colors we were using for small text (except for black) met the contrast threshold.» (sammendrag) — [Stripe](https://stripe.com/blog/accessible-color-systems)

### Inferences
- Skalaen 50–900(950) (10–11 trinn) er de facto-standarden i dokumentasjon fra Hightouch, Tailwind-lignende verktøy og generatorer; Radix' 12 trinn er det eneste utbredte alternativet der hvert trinn har en fast rolle. Dette passer for et verktøy som lar brukeren velge «rollebaserte» trinn.
- Semantisk lag på 40–100 tokens ser ut til å være det praktiske omfanget (Dashlane 91). Debatten er ikke om tokenantallet, men om komponenttokens-laget skal finnes (Dashlane nei, Dennis ja).
- Linear viser at man kan redusere hele temaet til få inngangsparametre (base, aksent, kontrast) hvis fargerommet er perseptuelt jevnt.

### Gaps
- Ingen undersøkelse (zeroheight, Sparkbox, Figma) som oppgir median antall kulørfamilier, trinn eller fargetokens. Zeroheight-rapporten 2025-PDF var for stor for WebFetch (>10 MB), og kun overskriftstall er hentet.
- Sparkbox Design Systems Survey: kun 2022 (200+ svar) dukket opp; ingen 2023–2025-utgave funnet. Ikke brukt her.
- Figmas egen «State of design systems»: ikke funnet.
- Hightouch-kilden sier «brighter» om hover (600→700) på en skala der høyere tall normalt er mørkere; sammendraget kan være misvisende, sjekk originalen.

## 2. Hvilke navneskjema anbefales av flere uavhengige praktikere?

### Takeaway
To lag er de facto-standard: (1) primitiver med kulørnavn + tall (blue-500), og (2) semantiske tokens etter rolle (`bg`/`surface`, `text`/`fg`, `border`, `icon`, status) pluss valgfri tilstand (`-hover`, `-active`, `-disabled`). Alle fem kildene under bruker rolle foran kulørnavn i det semantiske laget.

### Cited Findings
- Close: basistokens `--color[Hue][Lightness]` (f.eks. `--colorGray10`), semantiske `--color[Element][Component][Variant][State]` (f.eks. `--colorBgTableCellHighlighted`). Lys/mørk byttes ved at semantiske tokens peker på samme basenavn med ulik verdi per tema. (sammendrag) — [Close](https://making.close.com/posts/light-and-dark-our-color-systems-journey/)
- Hightouch: `text.primary`, `text.danger`, ikon-tokens speiler tekst-tokens én-til-én; interaktive grupper har `background`, `backgroundHover`, `border`, `base`, `hover`, `pressed`, `text`. Merk bevisst forskjell: `text.danger` (600) vs. `danger.text` (700). (sammendrag) — [Hightouch](https://ui.hightouch.com/foundation/colors)
- Howard Shaw: `bg.canvas/surface/elevated`, `text.*`, `border.subtle/strong`. (sammendrag) — [dev.to](https://dev.to/howard_shaw_3c36a3a6cb900/i-finally-added-dark-mode-and-it-forced-me-to-fix-more-than-colors-2n84)
- Samlet søkeresultat over flere designsystemdokumenter (VTEX Shoreline, Deliveroo, Volvo, Shopify Polaris m.fl.): mønsteret `--color-{name}-{part}[-{state}]` med faste «parts» `surface`, `fg`, `bg`, `border`, `text`; «Every `{name}-surface` that hosts text has a matching `{name}-fg`». Dette er et maskinsammendrag fra flere sider (inkl. én «DESIGN_SYSTEM.md» fra en liten pakke), ikke et uavhengig intervju. — [dxos DESIGN_SYSTEM.md](https://cdn.jsdelivr.net/npm/@dxos/ui-theme@0.9.0/src/css/DESIGN_SYSTEM.md), [Deliveroo](https://design.deliveroo.net/foundations/color/color-tokens-docs), [Polaris](https://polaris-react.shopify.com/design/colors/color-tokens)
- Primitiver: «hue + numeric scale (red.50 … red.950)… The numeric scale represents lightness, not importance»; brukt av Tailwind, Radix, Stripe og Primer (påstand fra samme sammendrag). — [dxos](https://cdn.jsdelivr.net/npm/@dxos/ui-theme@0.9.0/src/css/DESIGN_SYSTEM.md)
- Figmas designsystems.com (fargeguide): «add another modifying word to a color's name to describe its intended use»; viser til Lyft og Nathan Curtis (EightShapes, 16 læringspunkter). (sammendrag) — [designsystems.com](https://www.designsystems.com/color-guides/)
- Primer: «functional colors» abstraherer lys/mørk/høykontrast (f.eks. `textPrimary`, `iconTertiary`). — [Primer](https://primer.style/foundations/color/overview)

### Inferences
- «bg/fg/border/text/icon + state-suffiks» er det mest gjentatte uavhengig av organisasjon. «surface/on-surface» (Material) ble ikke funnet i praktikerkilder i denne runden, bare `surface` + `fg`.
- Ingen kilde rapporterte eksplisitt at «designere vs utviklere» valgte ulike navn, men Close og GitHub nevner at fellesspråk var et mål (Linear: «unified language between designers and engineers» i sammendraget).

### Gaps
- Ingen førstehåndsberetning om «designere og utviklere kranglet om navn» funnet. Design Tokens-community-/Slack-/Discord-oppsummeringer ikke funnet.
- Nathan Curtis' 16 takeaways og Medium/UX Collective-artikler ikke lest (betalingsmur / ikke hentet).

## 3. Hvilke generatorverktøy brukes mest 2025–2026, hvilket fargerom, og tar de kontrast som input?

### Takeaway
Utviklingen går fra HSL (Tints.dev, enkle tint/shade-plugins) mot OKLCH/LCH/HCT, og de mest ambisiøse verktøyene (Leonardo, Atmos, Huetone, Color Scales I/O) tar kontrastmål som input eller viser det live. Rangering etter faktisk bruk lot seg ikke fastslå: ingen Figma-brukertall funnet.

### Cited Findings
- Leonardo (Adobe, Nate Baldwin): genererer farger fra målkontrastforhold (standard 3 og 4,5) mot en felles bakgrunn; støtter RGB, HSV, HSL, HSLuv, Lab, LCH og CIECAM02; JS-modul + webgrensesnitt; temaer deles med utviklere. — [InfoQ](https://www.infoq.com/news/2020/03/adobe-leonardo-accessible-colors), [GitHub](https://github.com/adobe/leonardo)
- ColorBox (Lyft, 27. sep. 2018, Apache 2.0): inndata steg, hue, metning, luminans med kurvepresets; skala 0–100 der 0–50 gir 4,5:1 mot svart og 60–100 gir 4,5:1 mot hvit. Siter Kevyn Arnott: «We wanted to remove the need to manually check color contrast using third-party tools.» Den nåværende colorbox.io markedsføres som OKLCH-interpolasjon med WCAG-sjekk og eksport til CSS, Tailwind, Figma tokens, JSON (merk: kan være et nyere produkt enn Lyfts originalalgoritme; uavklart). — [WP Tavern](https://wptavern.com/lyft-open-sources-colorbox-algorithm-for-building-accessible-color-systems), [colorbox.io](https://colorbox.io/accessible-color-palette)
- Huetone (Ardov): LCH/OKLCH, WCAG og APCA, eksport, Figma-plugin (jf. egen side). Gratis og åpen kildekode. — [Huetone](https://huetone.ardov.me), [Atmos sin sammenligning](https://atmos.style/alternatives/huetone)
- Atmos: OKLCH-skalaer med easing-kurver og hue-overganger, WCAG 2 + APCA live, fargesynssimulator, versjonshistorikk, delte paletter, Figma-plugin, eksport til CSS/Tailwind/Style Dictionary/JS/SVG; 14 dagers prøve, betalt. Kilden er Atmos' egen markedsføring (partisk). — [Atmos](https://atmos.style/alternatives/huetone)
- Color Scales I/O (Figma-plugin, forumpost juni 2026): 12+ fargerom (OKLCH, LCH, HCT, HSLuv, Display P3), WCAG 2.1 og APCA, eksport til Figma-variabler, W3C design tokens, Leonardo-tema-URL, Dev Mode-snutter. Forfatterens kritikk av eksisterende: «beautiful ramps in Figma, then hours checking pairs, fixing dark mode, re-exporting variables»; Leonardo er «not built for day-to-day Figma work». — [Figma Forum](https://forum.figma.com/showcase-your-work-14/color-scales-i-o-create-edit-and-export-accessible-palettes-for-design-systems-54816)
- Tint & Shades Generator (dev.to, 30. des. 2025): HSL, trinn 50–900, eksport JSON og CSS-variabler, helt klient-side; valgt HSL fordi «smoother, more predictable ramps». Et eksempel på at HSL fortsatt velges av enkeltutviklere. (sammendrag) — [dev.to](https://dev.to/danishmk1286/i-built-a-tint-shades-generator-for-design-tokens-and-figma-bc2)
- Tints.dev: HEX/HSL-basert palettgenerator for Tailwind (fra en dev.to-liste fra nov. 2024; ikke verifisert mot verktøyets egen side — /about ga 404). — [dev.to](https://dev.to/hosseinyazdi/9-lesser-known-but-powerful-color-tools-youll-regret-missing-1bk6)
- Stripe brukte et internt CIELAB-verktøy (2019); Linear LCH (2024); GitHub HSLuv (Prism, 2022); Close LCH + Ardovs picker (lab.ardov.me); Hightouch OKLCH. — kilder over.
- Matthew Ström-artikkel (omtrent 2024, uten datert byline i sammendraget): avviser RGB, HSL, Lab og LCH til fordel for OKHsl; formler: lyshet `L(n)=1-n`, metning `S(n)=-4n²+4n`, hue-skift `H(n)=H_base+5(1-n)` mot Bezold–Brücke-effekten, kontrast `r(x)=e^(3.04x)`; basehues 250°/145°/20°/70° (blå/grønn/rød/gul); biblioteker culori/colorjs.io. ADVARSEL: artikkelen ble hentet via redirect fra matthewstrom.com til et annet domene (mattstromawn.com); forfatterskap og eventuell kopi er ikke verifisert. — [mattstromawn.com](https://mattstromawn.com/writing/generating-color-palettes/)

### Inferences
- Verktøy som tar kontrastmål som input (Leonardo, ColorBox, Color Scales I/O, Atmos) beskrives som de «seriøse»; de enkle tint/shade-pluginene (HSL) dekker hovedsakelig Tailwind-lignende 50–900.
- Det er et tydelig hull mellom «web-first generator» og «lever Figma-variabler + Dev Mode»; ingen av de funne verktøyene er native Mac/iPad.

### Gaps
- Ingen brukertall (installasjoner) for Figma-pluginene Foundation Color Generator, Supa Palette, Color Shades, Uicolors, Accessible Palette (Wildbit), Palettte eller Tints.dev: Figma Community-sider rendres med JS og ga ingen tall.
- Wildbit Accessible Palette-innlegget og Uicolors' fargerom ikke lest.
- Ingen uavhengig rangering av «mest brukt 2025–2026» funnet.

## 4. Hvilke konkrete tall brukes for hover/pressed/disabled?

### Takeaway
Det er to tilnærminger: «rungs» (trinn opp/ned i skalaen, f.eks. Hightouch 600→700→800 og Radix 9→10) og «delta/overlay» (lysthet- eller alfaprosent). Konkrete tall fra førstehåndskilder var få; søkeoppsummeringer gir typiske verdier som er uverifiserte.

### Cited Findings
- Hightouch: hover = ett trinn (600→700), pressed = to trinn (600→800), disabled = avmettet grå; sammendraget kaller det «brighter», men på en 50–900-skala betyr det sannsynligvis mørkere (uklart). Dark mode ved hvit/svart-alfa-overlays (`blackAlpha.*`/`whiteAlpha.*`), ikke egen mørk palett. (sammendrag) — [Hightouch](https://ui.hightouch.com/foundation/colors)
- Radix: komponentbakgrunn 3 (normal) → 4 (hover) → 5 (aktiv/valgt); solid 9 → hover 10; kant 7 → hover 8. — [Radix via pub.dev](https://pub.dev/documentation/radix_colors/latest/)
- Søkeoppsummering (uten navngitt primærkilde, uverifisert): OKLCH-delta hover ±5–10 % lyshet (+ for lys modus, − for mørk) og chroma +0,02–0,03; pressed ca. −5 % fra hover; disabled-opacity 0,4 eller 0,5; hover-overlay 0,04. Trolig hentet fra Material-lignende rammeverk og generiske blogger; bruk med forbehold. — [søkeresultat](https://uxdesign.cc/handling-hover-and-pressed-states-in-design-systems-9d1c2a29213d) (artikkel bak betalingsmur, ikke lest)
- Howard Shaw: skjelettlastere som bruker faste grå mislyktes i mørk modus; løsning er opasitetsbaserte tokens; hardkodede badge-bakgrunner og fokusringer ble usynlige. (sammendrag) — [dev.to](https://dev.to/howard_shaw_3c36a3a6cb900/i-finally-added-dark-mode-and-it-forced-me-to-fix-more-than-colors-2n84)
- zeroheight sine interaksjonsråd (fra UX Collective-treff): «no state should rely solely on color change» — formulert i et søkesammendrag; uverifisert.

### Inferences
- «Trinn i skalaen» krever at skalaen er perseptuelt jevn; ellers får noen kulører et synlig for stort hopp (hue drift/uteblitt hopp ved gul). Jevn skala er derfor en forutsetning for rungs-metoden.
- Alpha-overlays (Hightouch) forklarer hvordan man kan holde antallet tokens nede, men koster kontrastforutsigbarhet.

### Gaps
- Ingen tabell fra et enkelt team med eksakte prosenter for hover/pressed/disabled i egne systemer funnet. Material 3 state layers (8/12/12 %, 38 % disabled) hører til «de store» og ble ikke hentet her.

## 5. Hva er de hyppigste feilene, med eksempler?

### Takeaway
Gjentakende: (1) mørk modus behandlet som invertering, (2) for mange eller feil nivå av tokens, (3) HSL-skalaer med ujevn opplevd lyshet, (4) avhengighet av tredjepartsplugin, (5) flaskehals/enkeltperson, (6) manuell kontrastkontroll sent i prosessen, (7) migrering av gamle farger.

### Cited Findings
- Mørk modus ≠ invertering: «The mistake almost every team makes is treating dark mode as an inversion exercise» og «good theming was never about inverting colors — it's about designing a system of relationships between colors that can be swapped as a set» (formulering fra søkesammendrag av Dolfy-blogg, ikke primær verifisert). Dashlane bekrefter at kontrastlogikk er omvendt i mørk. — [Dolfy](https://www.dolfy.ai/blog/dark-mode-design-tokens-real-theming-mobile-apps), [Dashlane](https://dashlane.com/blog/dark-theme-dashlane)
- Visuelt hierarki kollapser i mørk: «if a component needs a border to be visible, the surface» layers are too similar; diagramaksetekst og rutenett blir lavkontrast; varmekart blir for harde; fokusringer usynlige; PNG-ikoner feiler. — [Shaw, dev.to](https://dev.to/howard_shaw_3c36a3a6cb900/i-finally-added-dark-mode-and-it-forced-me-to-fix-more-than-colors-2n84)
- HSL-lyshet: «the way HSL calculates lightness is flawed» (Stripe); gul ved samme L ser lysere ut enn blå. Stripe fant at mørkning for å nå 4,5:1 ga «muddy» farger. — [Stripe](https://stripe.com/blog/accessible-color-systems)
- Hue drift: Ström mener Bezold–Brücke-effekten (farger virker mer lilla i skygge, gulere i lys) krever hue-skift langs skalaen; gul har ulik topp-chroma og må kalibreres separat; avrundingsfeil i hex krever ekstra kontrastbuffer (3,04 i stedet for 3,008). Usikker kilde (se domenevarsel). — [mattstromawn.com](https://mattstromawn.com/writing/generating-color-palettes/)
- Tredjepartsplugin: Dennis bygde på Themer-pluginen; «performance degraded» og variantkompatibilitet brøt da Figma utviklet seg; «Be very, very careful about relying on third-party plugins.» Dashlane brukte Specify, som nå er nedlagt. — [Dennis](https://clipcontent.substack.com/p/my-five-biggest-design-system-mistakes-4725859926c2), [Dashlane](https://dashlane.com/blog/dark-theme-dashlane)
- Enkeltpunktsfeil: Dennis var eneste som kunne gjøre komplekse tokenendringer: «bottleneck blocked contributions and progress stalled for months». — samme kilde
- Overgang: Close måtte vurdere «page by page» og fant gamle fargevariabler; Dashlane innrømmer at noen tokens fortsatt må justeres etter lansering og brukte «color-value updates» der full komponentombygging var uoverkommelig. — [Close](https://making.close.com/posts/light-and-dark-our-color-systems-journey/), [Dashlane](https://dashlane.com/blog/dark-theme-dashlane)
- Atlassian mørkt tema: ~700 tilbakemeldinger/uke i alfa som falt til 17/uke; 5 176 tilbakemeldinger over 5 måneder; 90 % av hex→token-konvertering automatisert; 1 200+ bilder i 60+ team trengte alternative versjoner; ca. 350 000 brukere i beta (april 2023). (sammendrag) — [Atlassian](https://www.atlassian.com/blog/announcements/the-story-of-dark-theme)
- Zeroheight 2025: 84 % av teamene har design tokens (56 % i 2024); typiske utfordringer: arkitekturkompleksitet når systemet modnes, begrenset verktøy for sentral tokenstyring, synkronisering bare design→kode, ønske om diff mellom Figma-variabler og kodetokens og synlighet på tokenbruk. «Tokens seem to be the one area where we've all seen the value realized relatively early on.» — [zeroheight](https://zeroheight.com/how-we-document), [WebDesignerDepot](https://webdesignerdepot.com/?p=63603)
- Primer/GitHub: uten verktøy var mørkmodus-arbeidet «trial and error, copy and paste, back and forth». — [GitHub Blog](https://github.blog/2022-06-14-accelerating-github-theme-creation-with-color-tooling/)

### Inferences
- «Merkevarefarge som ikke kan nå 4,5:1» og «gul/varselfarge» er velkjente problemer, men ikke dokumentert med sitat i kildene jeg fikk tak i; Stripes «muddy»-funn og Ströms gul-kalibrering er nærmeste belegg.
- «Dark mode saturation» (avmetting av aksenter i mørk) er ikke direkte belagt; Shaw («harsh») og Hightouchs overlay-tilnærming peker på det.
- Rekkefølge-mønster: team som begynner i et perseptuelt rom og lar kontrast styre trinnvalg (Stripe, Lyft, Leonardo, Linear) rapporterer færre manuelle rettelser enn de som starter med HSL og justerer for hånd.

### Gaps
- Ingen konkret case på «merkevarefarge må endres for 4,5:1» funnet. Ingen Reddit/HN-tråder hentet (søkene ga ingen treff på relevante tråder).
- Kontrasttest-verktøy (Stark, Able, Figmas innebygde, axe) ikke undersøkt i denne runden; kun automatisert WCAG-sjekk i Dashlane/Close og live-kontrast i Atmos/Huetone/Leonardo er belagt.

## 6. Er det etterspørsel etter et native (ikke-nettleser) fargesystemverktøy på Mac/iPad, og hva mangler i dagens verktøy?

### Takeaway
Ingen kilde etterspør eksplisitt et native Mac/iPad-verktøy; alle funnet verktøy er web eller Figma-plugin. Det praktikerne sier mangler, er: dagligarbeid i Figma uten å hoppe ut, kontroll av farge-par og mørk modus i samme verktøy, toveis synk design↔kode, og token-diff/governance.

### Cited Findings
- «beautiful ramps in Figma, then hours checking pairs, fixing dark mode, re-exporting variables»; Leonardo er «powerful but not built for day-to-day Figma work» (forfatterens tolkning). — [Color Scales I/O](https://forum.figma.com/showcase-your-work-14/color-scales-i-o-create-edit-and-export-accessible-palettes-for-design-systems-54816)
- Zeroheight 2025: synk går bare design→kode; teamene ønsker diffing av Figma-variabler mot kodetokens, synlighet over tokenbruk, automatisk dokumentasjon og sentral tokenstyring med governance. — [zeroheight](https://zeroheight.com/how-we-document)
- GitHub: åtte eksisterende verktøy var uten helhet; derfor bygde de Prism («disjointed color tools»). — [GitHub Blog](https://github.blog/2022-06-14-accelerating-github-theme-creation-with-color-tooling/)
- Stripe og Lyft bygde egne interne/åpne verktøy fordi eksisterende ikke ga kontrastfeedback i perseptuelt rom. — [Stripe](https://stripe.com/blog/accessible-color-systems), [WP Tavern](https://wptavern.com/lyft-open-sources-colorbox-algorithm-for-building-accessible-color-systems)
- Atmos: lukket betalingsmodell med versjonshistorikk og samarbeid, dvs. betalingsvilje finnes for team-funksjoner (kilden er egen markedsføring). — [Atmos](https://atmos.style/alternatives/huetone)
- Dukket opp ved søk: MCP-baserte token-generatorer (f.eks. «Tokven MCP», generering fra én hex til OKLCH-lys/mørk-tokens, typografi, spacing, WCAG-validering) og skill-pakker — et tegn på at LLM-agenter nå også er en kanal for tokengenerering. — [Tokven MCP](https://mcp.so/ja/servers/tokven)

### Inferences
- Hullet jeg ser: kontrastdrevet generering (Leonardo-stil) + lys/mørk-parvisning + eksport til Figma-variabler/DTCG/Swift, i en native app som også kan lese farger fra skjerm/kamera/pipette. Dette er min vurdering, ikke belagt av praktikere.
- Det finnes ingen funnet kilde på Apple-plattform-bruk (asset catalogs med lys/mørk, SwiftUI-eksport) i fargesystemer fra team; dette kan være et nisjehull, men også bevis på lav etterspørsel.

### Gaps
- Ingen Reddit r/web_design / r/UXDesign, Hacker News, Config/Clarity-foredrag eller Design Tokens Slack/Discord funnet som sier noe om native Mac/iPad-verktøy. Direkte svar på etterspørsel: ukjent.
- Ingen tall på hvor mange som jobber med farger på iPad/Mac vs. nettleser.
