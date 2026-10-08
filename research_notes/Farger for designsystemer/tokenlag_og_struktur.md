# Fargesystemer for web- og app-designsystemer: tokenlag, toneskalaer, lys/mørk modus

Notater samlet 2026-10-08. Kilder er datert der datoen var tilgjengelig. Sitater står på originalspråket.

Kildeforbehold: Medium-artikler (uxdesign.cc, EightShapes) ble lest via nettleserpanelet eller speilet (readmedium.com); Polaris-dokumentasjonen og Material 2-siden om mørkt tema lot seg ikke hente (se «Gaps» under hvert spørsmål).

## Hvilke tokenlag finnes, og hva kaller de ledende kildene dem?

### Takeaway
Så godt som alle kildene opererer med tre lag: (1) rå palettverdier uten betydning («global», «primitive», «base», «reference», «definitions», «options», «palette»), (2) rollebaserte alias («semantic», «system», «alias», «functional», «theme», «usage», «decisions») som er det komponentene faktisk bruker og som bytter verdi mellom lys/mørk modus, og (3) et valgfritt komponentlag («component», «pattern», «decision tokens») for avvik som må kunne temas. DTCG-formatet definerer ingen lag selv, bare alias-mekanismen.

### Cited Findings
- Pavel Kiselev (uxdesign.cc, 8. des. 2022): «The colour system has three main components: Global colours are a common library of colour swatches that sets the tone for your visual language. System colours bring a structure to enable light and dark mode transition. Component colours represent individual UI elements.» Globale farger er «Never exposed directly, globals are the source of the colour system», og dette laget er «optional». Systemfarger «are the core values in our design language, represented by context-agnostic names … I found it more efficient to derive from global ones». Komponentfarger er «decision tokens that represent a context in which a referenced value is used» og «always derived from system colours». — [Kiselev, Designing a colour system](https://uxdesign.cc/designing-colour-system-d9d39f245e01)
- Nathan Curtis (EightShapes, «Tokens in Design Systems»): tokens kobler «options (like $color-neutral-20) to contexts (like a conventional dark background color)»; eksempler på kontekstnivå: `$background-color-disabled`, `$text-color-microcopy`, `$border-hairline`. Tommelfingerregel for når noe fortjener et token: etter omtrent tre bruk – «If it shows up that much, it's usually token-worthy». — [Curtis, Tokens in Design Systems](https://medium.com/eightshapes-llc/tokens-in-design-systems-25dd82d58421) (lest via readmedium-speil)
- Brad Frost (eddie.bradfrost.com): «Tier 1 — Definitions» (rå verdier som `--ed-color-blue-500`, aldri brukt direkte i komponenter), «Tier 2 — Usage/Semantic» (`--ed-theme-color-background-default`, `--ed-theme-color-content-default`, `--ed-theme-color-border-default`, `--ed-theme-color-content-accent-1`), «Tier 3 — Component» (`--ed-c-button-background`). Tier 1 «define all ingredients», Tier 2 «map Tier 1 tokens to specific roles», Tier 3 «reserved for component-specific and other special use cases». — [Frost, Design tokens](https://eddie.bradfrost.com/design-tokens/) (siden ga 404 ved direkte henting; innholdet er fra søkesammendrag av samme side – bør verifiseres)
- GitHub Primer: tre nivåer. «Base tokens» «map directly to raw values» og er «only to be used as a reference for functional and component/pattern tokens». «Functional tokens» representerer «global UI patterns such as text, borders, shadows, and backgrounds» og «respect color modes». «Component/pattern tokens» er «more specific or unique than functional tokens» og «respect color modes». — [Primer, Color overview](https://primer.style/foundations/color/overview)
- Fluent 2 (Microsoft): globale tokens som `grey[14]`, `brand[80]` pakkes i alias-tokens som `colorNeutralBackground1`; alias er gruppert i Neutral, Brand, Status (`colorStatusDangerBackground`, `colorStatusSuccessForeground`, `colorStatusWarningBorder`) og «generic status»/palette (`colorPaletteRedBackground`). — [Fluent 2 Color tokens](https://fluent2.microsoft.design/color-tokens)
- USWDS: «System tokens» (hele paletten på 24 fargefamilier), «Theme tokens» (et rollebasert utvalg per prosjekt), «State tokens» (error, warning, success, info, emergency). — [USWDS Color tokens](https://designsystem.digital.gov/design-tokens/color/overview/)
- Atlassian: tokennavnet beskriver bruk, ikke utseende: «A design token's name describes how it should be used, and each part communicates one piece of its usage.» Struktur Foundation.Property.Modifier, f.eks. `color.icon.success`. «Light mode, dark mode, and high-contrast mode are all examples of theming.» — [Atlassian Design tokens](https://atlassian.design/foundations/tokens/design-tokens/)
- DTCG Format Module (utkast datert 8. sept. 2026, «2025.10»): definerer ikke lag, men «a token can be an alias for another token. This spec considers the terms 'alias' and 'reference' to be synonyms»; alias «are useful for expressing design choices, eliminating repetition of values in token files, creating semantic relationships between tokens, and maintaining consistency». Grupper gir hierarki; eksemplene viser lagdeling i praksis (basisfarger → semantiske grupper → komponentspesifikke). Fargetypen henviser til egen Color-modul; eksempel `"colorSpace": "srgb"`, `"components": [0, 0.4, 0.8]`. — [DTCG Format](https://www.designtokens.org/tr/drafts/format/)
- Generell oppsummering fra flere systemdokumentasjoner (Backbase, Mediquo, Open Library): «Primitive tokens are raw palette values (e.g. blue-500) and are never used directly in components», «Semantic tokens … describe what something is for, not what it looks like», «A component tier exists only where a component must deviate from its role and that deviation must stay themeable», «Components read semantic tokens only». — [Backbase](https://designsystem.backbase.com/latest/design-tokens/introduction-5PSH8xS5); [Mediquo](https://wc-showcase.mediquo.com/design-system/foundations/color); [Open Library](https://docs.openlibrary.org/developers/frontend/design-tokens.html)

### Inferences
- Lagbetegnelsene varierer, men funksjonen er lik: lag 1 er modus-agnostisk (samme verdi i lys og mørk), lag 2 bærer modusbyttet, lag 3 er unntak. Det er altså i lag 2 kontrastgarantiene må bo.
- For et verktøy som Kolorist er det naturlig å eksportere lag 1 (skalaer) og tilby lag 2 (roller) som kartlegging på toppen, siden komponentlaget er produktspesifikt.

### Gaps
- DTCG har ingen normativ veiledning om nivåer; søk fant ingen «tiers»-anbefaling fra gruppen selv.
- Brad Frosts tier-side kunne ikke hentes direkte (404); innholdet er fra søkesammendrag.

## Hvordan bestemmes antall trinn og lyshet per trinn?

### Takeaway
Tre hovedstrategier finnes: (a) fast antall trinn med fast lyshetsmål per trinn i et perseptuelt rom (Material HCT-tone 0–100; Tailwind 50–950 i OKLCH; Fluent grey 2–98), (b) trinn definert ut fra bruksområde og kontrastgaranti (Radix 1–12; Primer 0–13; Carbon 10–100; USWDS 0–100 med luminansvinduer), og (c) rent lineære lyshetsserier (Kiselev: 48 gråtoner i 2 %-steg). Antall trinn i praksis: 9–12 for farger, flere for nøytrale.

### Cited Findings
- Kiselev: globale nøytrale går «Starting from 100% lightness down to 4%», «There are 48 steps, and each colour changes linearly from the lightest to the darkest shade using a 2% increment … I just need to pick a starting point, set a direction and decide on the distance between adjacent shades». Samme kulør (hue) for alle gråtoner. Aksentmodulen: «16 colours and 9 shades for each». Systempaletten: «99 colours in each palette». Aksentskalaens roller: «Shades 600 and 500 would work best for distinct borders; Shade 300 is a primary colour; Shade 400 gives slightly higher contrast and could be used for non-text elements like glyphs or data visualisation colours; Shades 200 and 100 are semi-transparent and made for tints and highlights». Tekst får egen underpalett: «tree shades for visual hierarchy and several colours for semantics … an independent sub-palette as it makes it easier to fit into WCAG accessibility requirements». — [Kiselev](https://uxdesign.cc/designing-colour-system-d9d39f245e01)
- Material 3: tonepaletter «are given a number from 0 to 100 in increments of 10, as well as 95, 98, and 99. Some palettes include more values.» «Tonal values range from 0 (black) to 100 (white).» HCT-tone = oppfattet lyshet: «colors with the same perceived brightness share the same tone value in HCT, but can have different HSL lightness values.» Chroma i HCT «top out at roughly 120», og «some hues cannot exist with certain chroma or tones … This is why the chroma value may increase or decrease for some tones in a tonal palette.» Fem nøkkelfarger per kildefarge: Primary, Secondary, Tertiary, Neutral, Neutral variant. — [M3 How the system works](https://m3.material.io/styles/color/system/how-the-system-works)
- Radix Colors: 12 trinn, definert etter bruk: 1–2 «designed for app backgrounds and subtle component backgrounds», 3–5 komponentbakgrunner (normal, hover, trykket/valgt), 6–8 kantlinjer (subtil, interaktiv, sterk/fokusring), 9–10 «designed for solid backgrounds» (høyest kroma ved trinn 9), 11–12 «designed for text» (lav- og høykontrast). — [Radix, Understanding the scale](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)
- Primer: nøytralskalaen har «shades of gray between 0 and 13, including white and black»; trinn 0–6 bakgrunner, 7–8 kantlinjer/skillelinjer, 9–10 tekst og ikoner. — [Primer](https://primer.style/foundations/color/overview)
- Carbon: «twelve color grades—Black, White and ten values for each hue», 10–100. — [Carbon Color overview](https://carbondesignsystem.com/elements/color/overview/)
- USWDS: grader 0 (hvitt) til 100 (svart); systemtokens bruker 5–90. «Magic numbers work because each grade conforms to a specific range of values for relative luminance», f.eks. grad 50: relativ luminans 0,175–0,183. — [USWDS](https://designsystem.digital.gov/design-tokens/color/overview/)
- Fluent 2: grå fra `grey[2]` til `grey[98]` (f.eks. 14, 26, 38), brand fra `brand[10]` til `brand[160]`, statusfarger som `cranberry[primary]`, `cranberry[shade10]`, `cranberry[tint40]`. — [Fluent 2](https://fluent2.microsoft.design/color-tokens)
- Tailwind v4 (analyse av Matteo Frana, dev.to, 20. feb. 2025): 11 trinn 50–950, paletten er bygd i OKLCH; «The Lightness follows a non-linear curve that remains fairly consistent across color palettes, though grays show a steeper decrease in the darker shades»; «The chroma (saturation) follows a Gaussian curve pattern, peaking between the '400' and '600' shades, with a sharper decrease in the lighter shades»; «none of these diagrams follows a linear pattern». — [Frana, The mystery of Tailwind colors v4](https://dev.to/matfrana/the-mystery-of-tailwind-colors-v4-hjh)
- Eksempel på Tailwind-verdier (fra søkesammendrag; aggregatorsider): blue-50 `oklch(97% 0.014 254.604)`, blue-500 `oklch(62.3% 0.214 259.815)`, blue-950 `oklch(28.2% 0.091 267.935)`. En «typisk» 11-trinns OKLCH-skala som flere veiledninger gjengir: 50 = 97 %, 100 = 93 %, 200 = 87 %, 300 = 78 %, 400 = 65 %, 500 = 55 %, 600 = 45 %, 700 = 37 %, 800 = 27 %, 900 = 20 %, 950 = 14 % L. — [kombai.com Tailwind colors](https://kombai.com/tailwind/colors/); [skillselion color-scale](https://skillselion.com/skills/dylantarre/design-system-skills/color-scale) (sekundærkilder; tallene stemmer ikke eksakt med Tailwinds blue-500 = 62,3 %, så tabellen er en forenkling)
- Evil Martians («OKLCH in CSS», oppgitt datert 17. sept. 2025): HSL-lyshet er ikke perseptuell – «Different hues represent different 'real' lightness values»; i OKLCH «the L component is accurate» på tvers av kulører. Anbefalt metode: hold L konstant, varier kroma trinnvis. Nettlesere bruker fortsatt «the fast, but inaccurate, clipping method» for farger utenfor gamut; spesifikasjonen anbefaler OKLCH-basert kartlegging. — [Evil Martians](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)
- Kevin Muldoon (uxdesign.cc, 23. aug. 2026): tittel og ingress hevder at OKLCH-lyshet «can't predict contrast — and there's a better number for your palette weights». Artikkelen er betalingsmur; bare innledningen (Oklab-historikk, «an OK Lab color space») var tilgjengelig. — [Muldoon](https://uxdesign.cc/stop-using-oklch-lightness-for-your-color-scale-02025deca49d)
- Chroma/Radiance (pushing-pixels.org, 9. juni 2025): tre tonepaletter fra samme kulør (300) med ulik kroma: 40 for «active», 18 for «muted», 8 for «neutral». — [Chroma part II](https://www.pushing-pixels.org/?p=19668)

### Inferences
- Systemene som gir kontrastgarantier (Radix, Primer, USWDS, Material) definerer trinnene via luminans/kontrast, ikke via jevne OKLCH-L-steg. Jevne L-steg (Tailwind, Evil Martians) gir visuell jevnhet men ingen garanti mot WCAG-terskler – det er Muldoons poeng.
- Kiselevs 2 %-lineære HSL-lignende serie er den minst perseptuelle av metodene; han bruker nummerering etter «intensitet» (grey-100 … grey-4) i stedet for lyshetsrom.

### Gaps
- Muldoons alternative «number for your palette weights» (sannsynligvis WCAG-luminans eller APCA) kunne ikke bekreftes bak betalingsmuren.
- Tailwinds egne designnotater om hvorfor kurven er ikke-lineær fant jeg ikke.

## Hvordan avledes mørk modus?

### Takeaway
Fire mønstre dokumenteres: (1) speilet/reversert skala (Atlassian 700→400, 100→1000; Primer inverterer nøytralskalaen så funksjonstokens deles), (2) separat mørk skala (Radix egne mørke skalaer; Atlassian DarkNeutral-rampe; Kiselev egne mørke aksenter med 20 % lavere metning), (3) tonebytte i samme palett (Material: primary tone 40 i lys, 80 i mørk; surface-containere som lysere toner oppover i hierarkiet), (4) overlegg/alfa (Kiselev «alt», «shade», «tint» med modusavhengig opasitet). Kiselev skiller mellom «dark elevated» (høyere flate = lysere) og «dark deep» (høyere flate = mørkere) og velger «dark elevated».

### Cited Findings
- Kiselev: «What would happen with white? It could either stay the lightest shade or become the darkest one.» «Dark elevated: This style uses the same gradient direction in both themes. From lightest to darkest.» «Dark deep: … In the dark mode, it goes from darkest to lightest.» Valg: «For the dark mode, I decided to go with the dark elevated theme … I took the last six shades at the end of the spectrum … The lightest shade is at 14% and it goes down to 4%.» Kantlinjer: «Stroke colours went in the opposite direction, increasing intensity makes the colour lighter.» Aksenter: «For the dark mode, I created another less saturated one … Dark mode accents 20% less saturated.» Mørk palett avviker bare for kontrastfarger: «the dark mode palette only has special values for the contrast fills, strokes and alt colours. They are a few % lighter than their 'base' peers.» Hjelpefarger: «Shades and tints are semi-transparent and the opacity level depends on the theme. In the light mode, tints are more pronounced and shades use lower opacity levels and vice-versa.» «White, black and transparent ones are theme agnostic.» Komponentlaget muliggjør ulik stil per modus: «I used component tokens to style buttons differently in two themes.» — [Kiselev](https://uxdesign.cc/designing-colour-system-d9d39f245e01)
- Atlassian: «If the swatches are divided in half, each half becomes a mirror … if a button color is 700 in light theme, it will be 400 in dark theme. If a section message background is 100 in light theme, it will be 1000 in dark theme. Design tokens will handle these conversions for you.» Nøytrale har egen mørk rampe: «Neutral100 in the light neutral ramp should equate to DarkNeutral100 in the dark neutral ramp.» Nøytraltrinn: 100, 200, 250, 300, 400, 500, 600, 700, 800, 850, 900, 1000, 1100, 1200; mettede familier 100–1000 pluss 250 og 850. — [Atlassian Color palette](https://atlassian.design/foundations/color/color-palette)
- Primer: «the light scale starting with white and the dark scale starting with black. By inverting the scales, light and dark themes are able to share many of the same functional color tokens without custom overrides.» — [Primer](https://primer.style/foundations/color/overview)
- Material 3: «the algorithm assigns the color tone primary40 to the primary role and the tone primary100 to the on primary role» (lyst tema). «Dark theme colors are also automatically assigned so that apps receive both light and dark themes through a single set of color roles.» Fem surface-container-roller (lowest, low, default, high, highest); «Surface dim» og «Surface bright» beholder relativ lyshet i begge modi, mens «the default surface color automatically inverts between light and dark themes». «Fixed» aksentroller «maintain the same tone in light and dark themes», med advarsel: «Fixed colors don't change based on light or dark theme, so they're likely to cause contrast issues.» — [M3 Color roles](https://m3.material.io/styles/color/roles); [M3 How the system works](https://m3.material.io/styles/color/system/how-the-system-works)
- Chroma/Radiance (M3-inspirert): «Surface tokens in light mode use lighter tones, while surface tokens in dark mode use darker tones»; active container ≈ tone 80 lys / 40 mørk, muted ≈ 85 / 32, neutral ≈ 95 / 26. — [Chroma part II](https://www.pushing-pixels.org/?p=19668)
- Carbon: fire temaer navngitt etter primær bakgrunnsfarge – White, Gray 10 (lyse), Gray 90, Gray 100 (mørke). Lagdeling: i lyse temaer «layers alternate between White and Gray 10»; i mørke «layers become one step lighter with each added layer». Lag: base layer, layer 01, 02, 03, med tokens som ender på -00/-01/-02/-03. — [Carbon overview](https://carbondesignsystem.com/elements/color/overview/); [Carbon usage](https://carbondesignsystem.com/elements/color/usage/)
- Radix: anbefaler «white for your app background in light mode, and Step 1 or 2 from a gray or coloured scale in dark mode», med «mutable aliases» som peker til ulike farger per modus. «Sky, Mint, Lime, Yellow, and Amber are designed for dark foreground text and steps 9 and 10», mens «Most step 9 colors are designed for white foreground text». — [Radix](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)
- Fluent 2: alias-tokens vises som parallelle kolonner per tema; `colorNeutralBackground1` = `white` (lys) og `grey[16]` (mørk). — [Fluent 2](https://fluent2.microsoft.design/color-tokens)

### Inferences
- Speiling (Atlassian/Primer) forutsetter en symmetrisk skala rundt midten; det fungerer for nøytrale men krever egne mørke ramper for mettede farger (Atlassian gjør begge deler).
- «Dark elevated» (Kiselev) og Materials surface-container-hierarki er samme idé: høyere flate = lysere nøytral; Carbon formaliserer det som «én trinn lysere per lag».
- Redusert metning i mørk modus (Kiselev 20 %, Material 2s desaturerte primærfarge) går igjen, men bare Kiselev gir et tall.

### Gaps
- Material 2-siden om mørkt tema (base #121212, overleggprosent per dp) lot seg ikke hente – cookie-banner blokkerte innholdet. Tallene er ikke bekreftet i denne runden.
- Fant ingen kilde som sammenligner «reversert skala» mot «egen mørk skala» kvantitativt.

## Hvilke kontrastforhold mellom trinn garanteres, og etter hvilken standard?

### Takeaway
Garantiene uttrykkes som «tekst på trinn N mot flate trinn M». WCAG 2-forhold dominerer (Material 3:1/4,5:1/7:1 etter tonedifferanse; Carbon 4,5:1/3:1; USWDS «magic number» 40/50/70; Primer trinn 9 mot 0–4, trinn 10 mot 5–6); Radix bruker APCA (Lc 60 og Lc 90 for trinn 11/12 på trinn 2).

### Cited Findings
- Material 3: «The color system is built on accessible color pairings. These color pairs provide an accessible minimum 3:1 contrast.» «Using tones 50 and 98 for a button and its label creates an accessible 3:1 contrast»; «Using colors of tones 30 and 98 for a button and its label create a 7:1 contrast». Tre kontrastnivåer: Standard, Medium («minimum contrast ratio of 3:1»), High («7:1 contrast ratio»). Outline: «Don't use the outline variant color to create visual hierarchy … Instead, use the outline color or another color providing 3:1 contrast with the surface color.» Outline variant kan brukes på kanter «provided that those targets contain elements inside them that provide visual contrast … the icons and text inside the targets meet 4.5:1 contrast». — [M3 How the system works](https://m3.material.io/styles/color/system/how-the-system-works); [M3 Color roles](https://m3.material.io/styles/color/roles)
- Sekundærkilder om Material: «colors that are at least 40 steps apart in tonal value achieve a contrast ratio of at least 3:1»; «Tone 40 on Tone 100 (white) guarantees 7:1+ contrast; Tone 80 on Tone 10 guarantees similar contrast in dark mode». — [Dubai Design System](https://designsystem.dubai.ae/foundations/colors); [MUI palette docs](https://v7.mui.com/material-ui/customization/palette/) (ikke bekreftet mot m3.material.io i denne runden)
- Radix (APCA): «Steps 11 and 12—which are designed for text—are guaranteed to Lc 60 and Lc 90 APCA contrast ratio on top of a step 2 background from the same scale.» — [Radix](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)
- Primer: «Step 9 is considered the minimum contrast value for text against steps 0 through 4, while 10 meets the minimum against 5 and 6.» Høykontrast-temaer: «the goal is to hit a minimum of 7:1 for most text and interactive elements.» — [Primer](https://primer.style/foundations/color/overview)
- Carbon: liten tekst (under 24 px) «requires a 4.5:1 contrast ratio»; stor tekst og grafiske elementer «require a 3:1 contrast ratio». Kontrasttabellen angir minste trinn, f.eks. 4,5:1 mot svart krever «50 through White (6 steps)». — [Carbon overview](https://carbondesignsystem.com/elements/color/overview/)
- USWDS «magic number» = graddifferanse: «40+: WCAG 2.0 AA Large Text contrast (example: gray-90 and indigo-warm-50v)», «50+: WCAG 2.0 AA contrast or AAA Large Text contrast (example: gray-90 and red-40)», «70+: WCAG 2.0 AAA contrast (example: gray-10 and red-80)». «Colors of grade 50 result in Section 508 AA contrast against both pure white (grade 0) and pure black (grade 100).» — [USWDS](https://designsystem.digital.gov/design-tokens/color/overview/)
- Kiselev: ingen tallfestede garantier, men prinsipper: «All accents are balanced to produce the same level of contrast which would define their usage»; «the strokes should be visible against the background colour of the same intensity»; kontrastvarianter «have 'contrast' in their name to indicate that they would create high contrast against their 'base' counterparts»; tekstpaletten er egen for å «fit into WCAG accessibility requirements». — [Kiselev](https://uxdesign.cc/designing-colour-system-d9d39f245e01)

### Inferences
- Både Material (tone) og USWDS (grade) bygger trinnet på WCAG-relativ luminans, slik at en fast tonedifferanse gir et fast minimumsforhold. OKLCH-L gir ikke denne egenskapen direkte, derfor Muldoons kritikk.
- Radix er det eneste av de store systemene som har gått over til APCA for garantiene sine; de andre holder seg til WCAG 2.

### Gaps
- Atlassians kontrastregler per token (hvilke `color.text.*` som består 4,5:1 på hvilke `elevation.surface.*`) fant jeg ikke; palettsiden sier bare at tokens «handle these conversions».
- Polaris' regler lot seg ikke hente (401/404/socket-feil på tre URL-er).

## Hva anbefaler uxdesign.cc-artikkelen konkret?

### Takeaway
Pavel Kiselevs «Designing a colour system» (8. des. 2022, 12 min) beskriver et tre-lags, multi-brand system for lys/mørk modus: globale swatcher → systemfarger navngitt etter bruk (fill/stroke/text/alt + intensitetstall) → komponenttokens. Nøytrale lages som 48 lineære gråtrinn (100 % → 4 % lyshet, 2 %-steg, samme kulør); lys modus starter fra rent hvitt, mørk modus («dark elevated») bruker de siste seks trinnene 14 % → 4 %. Aksenter: 16 kulører × 9 trinn globalt, egne mørke aksenter med 20 % lavere metning; systemaksentene har trinn 100–600 med faste roller. Semantikk: blå = primær, rød = fare, amber = advarsel, grønn = suksess (RAG). 99 farger per palett.

### Cited Findings
- Metadata: forfatter Pavel Kiselev, UX Collective, «Dec 8, 2022», «12 min read». Undertittel: «Building multi-brand colour systems that support light and dark modes with minimum effort. It is all about organizing, naming and choosing the right colour values for the system to work.» «So each colour name in the system is a design token, that simple.» — [Kiselev](https://uxdesign.cc/designing-colour-system-d9d39f245e01)
- Navnekonvensjon: kategorier etter bruk – fill, stroke, text, alt. «The type reflects the way colour is supposed to be used and the number is a colour intensity.» «I believe every designer understands terms like 'fill' and 'stroke' therefore I've decided to name the colours using these words.» Relasjoner: «Fills are the lightest shades in your arsenal, these to be your main background colours. Strokes are not supposed to fill large areas but outline or divide them … strokes should be visible against the background colour of the same intensity. Alt or alternative colours are semi-transparent ones and could be applied both as fills and strokes.» — samme kilde
- Nøytrale: «It could be fully desaturated, a bit colder or warmer or even tinted in a fancy way to support the brand.» Plug-and-play-moduler: «Warm greys, low saturation», «Cold greys, low saturation», «Bluish greys, 20% saturation» – bytte av modul gir «a different tone for the whole design». — samme kilde
- Lys modus: «I always start with pure white and build progression from there. For stroke colours, I shifted the starting point to the right. The further it starts the more prominent borders are going to be.» Alternativ med «A 4% step makes greys more intense providing greater contrast against the pure white». Mørk: 2 % gir «Low contrast, ideal for low light environments»; 4 % gir mer kontrast. — samme kilde
- Aksenter og semantikk: «we would need a primary accent for brand & CTA elements and RAG for semantics»; «blue becomes primary, red turns into a danger indicator, amber stands for warnings and green clears the way»; «Each theme uses slightly different shades for a better experience». «The primary accent could be derived from any global colour which makes it super easy to adapt the palette for specific brand needs» (eksempel: primær byttet til rosa). — samme kilde
- Kontrastvarianter: for mørke flater i lys modus (f.eks. mørk sidemeny) utvides paletten «with darker fills, strokes, text colours and alt colours. They have 'contrast' in their name». — samme kilde
- Hjelpefarger: «I use shades for shadows and to darken areas below them. Tint would always lighten a surface.» — samme kilde
- Komponenttokens, minimumssett («would make up 90% of your design»): Common UI element (visuelle tilstander for menypunkter, listepunkter, verktøylinjeknapper), Form controls, Button («Most important UI element of all»), Card, Overlay (dropdown, popover, modal). — samme kilde
- Verktøy nevnt: ColorBox.io, Eva Design System Color Generator, TailwindInk; Tokens Studio (Figma Tokens) for temaer. Omfang: «The system proved itself on the application family scale … 100+ apps with thousands of screens.» Innrømmelse: «Some devs have argued that the naming convention is 'weird', and for them, there are component colours to bridge the gap.» Henviser til Francis Wus Hazel-system som lignende konvensjon. — samme kilde
- Hazel (Francis Wu, del 1): organiserer i «Surfaces», «Content», «Borders»; «By using transparent colors, you're automatically ensuring a visual relationship between layers of UI elements»; første forsøk endte i «206 colors and growing» for 8 komponenter. — [Wu, Hazel part 1](https://medium.com/@thisisfranciswu/designing-hazels-accessible-color-system-part-1-8a73a2298c35) (via readmedium)

### Inferences
- Kiselevs tallsystem er omvendt av de fleste (grey-100 er lysest, grey-4 mørkest; aksent 100 er lysest/transparent, 600 mørkest), og nummeret er «intensitet», ikke lyshet i et fargerom. Metoden er HSL-lineær og ikke perseptuelt jevn – en svakhet sammenlignet med OKLCH/HCT-baserte skalaer.
- «Alt»-fargene (halvtransparente) tilsvarer Radix' alfa-skalaer og Hazels transparente lag.

### Gaps
- Artikkelens bilder (palettetabeller, opasitetsverdier for shade/tint per modus, de konkrete heksverdiene) var ikke tilgjengelige som tekst; eksakte opasitetstall mangler.

## Hvordan kartlegges merkevarefarger til systemet, og hva er success/warning/error/info-rollene?

### Takeaway
Merkefargen velges som «primær/brand»-aksent fra en av de globale kulørene (Kiselev; Material utleder fem nøkkelfarger fra én kildefarge; Fluent har egen `brand`-skala 10–160). Statusroller er nesten universelle: Carbon error = Red 60, success = Green 50, warning = Yellow 30, info = Blue 70; Material har bare «error» som standardrolle (statisk selv i dynamisk farge); Primer har accent, success, attention, danger pluss domenespesifikke open/closed/done/sponsors; Atlassian brand, danger, warning, success, discovery, information; USWDS error, warning, success, info, emergency.

### Cited Findings
- Carbon støttefarger: Error = Red 60, Success = Green 50, Warning = Yellow 30, Info = Blue 70. Token-kategorier: Background, Layer, Field, Border, Text, Link, Icon, Support, Focus, Skeleton. — [Carbon overview](https://carbondesignsystem.com/elements/color/overview/)
- Material 3: roller i seks grupper – primary, secondary, tertiary, error, surface, outline (26 standardroller). «Error is an example of a static color (it doesn't change even in dynamic color schemes) … They still adapt to light and dark theme.» Begreper: «Container – Roles used as a fill color for foreground elements like buttons», «On – … a color for text or icons on top of its paired parent color», «Variant – … a lower emphasis alternative». — [M3 Color roles](https://m3.material.io/styles/color/roles)
- Primer-roller: accent, success, attention, danger, open, closed, done, sponsors; «Background and border colors have both a `muted` and `emphasis` option.» — [Primer](https://primer.style/foundations/color/overview)
- Atlassian: rolleeksempler success, danger, discovery i tokennavn som `color.icon.success`; kategorier tekst, lenker, ikoner, bakgrunner, kantlinjer, diagrammer, skeleton; elevation-tokens for «surface level and shadow». — [Atlassian Design tokens](https://atlassian.design/foundations/tokens/design-tokens/)
- Fluent 2: Status = danger/success/warning; Brand = `colorBrandBackground`, `colorBrandForeground`, `colorBrandStroke`. — [Fluent 2](https://fluent2.microsoft.design/color-tokens)
- USWDS state tokens: error, warning, success, info, emergency; theme tokens som `primary` er familier på linje med `red`, `blue-warm`. — [USWDS](https://designsystem.digital.gov/design-tokens/color/overview/)
- Curtis: fargekonsepter («concept») som `feedback` (success, warning, error), `action` (primary, secondary), `visualization`, `commerce` (sale, clearance); eksempel `$color-feedback-success`. — [Curtis, Naming tokens](https://medium.com/eightshapes-llc/naming-tokens-in-design-systems-9e86c7444676)
- Kiselev: RAG (rød/amber/grønn) + blå primær; se forrige seksjon. — [Kiselev](https://uxdesign.cc/designing-colour-system-d9d39f245e01)

### Inferences
- «Info» er den minst stabile rollen (Material mangler den, Atlassian kaller den «information», Primer bruker «accent»); «warning» er i alle systemer gul/amber, «danger/error/critical» rød, «success» grønn.
- Carbon velger ulike trinn per status (60/50/30/70) fordi gul må være mørkere på hvit – samme luminansproblem som Radix løser med mørk tekst på Yellow/Amber trinn 9.

### Gaps
- Shopify Polaris' rollesett (critical, warning, success, info, caution, emphasis, magic) kunne ikke bekreftes – alle Polaris-URL-er feilet.

## Navnekonvensjoner

### Takeaway
Nathan Curtis' skjema er referansen: nivåene Namespace (system, theme, domain) · Object (component, element, group) · Base (category, concept, property) · Modifier (variant, state, scale, mode). Skalaer navngis enumerert (1,2,3), ordnet (50, 100 … 900), proporsjonalt eller i t-skjortestørrelser. Alle kilder advarer mot utseendenavn i rollelaget; Atlassian, Primer og Fluent bruker property-først (`color.text.danger`, `fgColor`, `colorNeutralForeground`), Kiselev bruker designerbegreper (fill/stroke).

### Cited Findings
- Curtis: nivåer «Base: category, concept, property; Modifiers: variant, state, scale, mode; Objects: component, nested element, component group; Namespaces: system, theme, domain». Eksempler: `$esds-color-neutral-42` (namespace, category, concept, scale), `$color-feedback-success`, `$color-text-on-dark`. Skala-modifikatorer: «Enumerated (1, 2, 3), ordered (50, 100...900), proportional (1-x, 2-x), t-shirt sizes (s, m, l, xl)». Modus: `on-light`, `on-dark`, `on-brand`; noen systemer antar lys som standard og legger bare til `on-dark`. «A theme may eventually require on-light, on-dark color applications» – tema og modus er ortogonale. Unngå homonymer (`type`, `text`). Generisk `$color-success` vs. spesifikk `$color-text-success`. Start lokalt i komponenter, løft til globalt ved gjenbruk i tre eller flere komponenter. «Effective token names improve and sustain a team's shared understanding of visual style through design, code, and other interdisciplinary handoffs.» — [Curtis, Naming tokens](https://medium.com/eightshapes-llc/naming-tokens-in-design-systems-9e86c7444676)
- Atlassian: Foundation.Property.Modifier – «Foundation: The type of visual design attribute … such as color, elevation, or space. Property: The UI element the token is being applied to, such as a border, background, shadow … Modifier: Additional details about the token's purpose, such as its color role, emphasis, or interaction state.» — [Atlassian](https://atlassian.design/foundations/tokens/design-tokens/)
- Brad Frost: prefiks for lag (`--ed-color-*` lag 1, `--ed-theme-color-*` lag 2, `--ed-c-*` komponent). — [Frost](https://eddie.bradfrost.com/design-tokens/)
- Kiselev: type + intensitet (fill/stroke/text/alt + tall); «contrast»-prefiks for mørke motstykker. — [Kiselev](https://uxdesign.cc/designing-colour-system-d9d39f245e01)

### Inferences
- Nummerretning er ikke standardisert: Tailwind/Carbon/USWDS/Atlassian/Primer teller mørkere oppover; Material-tone og Fluent grey teller lysere oppover; Kiselev teller mørkere nedover. Et verktøy bør gjøre retningen eksplisitt ved eksport.

### Gaps
- Ingen.

## Vanlige fallgruver kildene advarer mot

### Takeaway
Gjentatte advarsler: HSL-lyshet er ikke perseptuell (gul og blå ved samme L); LCH bøyer blått mot lilla; kroma kan ikke holdes konstant over hele skalaen (gamut); jevn OKLCH-L garanterer ikke WCAG-kontrast; «fixed» farger som ikke bytter med modus bryter kontrast; feil parring av roller (primary mot primary container) bryter tilgjengelighet; for mange tokens (Hazel: 206 for 8 komponenter); og navn etter utseende i stedet for formål.

### Cited Findings
- Evil Martians: HSL – «Different hues represent different 'real' lightness values»; LCH – «blue became purple» ved endring av bare lyshet (270°–330°); nettlesernes gamut-klipping er «fast, but inaccurate». — [Evil Martians](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)
- Flere sekundærkilder: «Yellow at L=50% looks far brighter than blue at L=50%» (HSL); «blues can sustain higher chroma at low lightness; yellows peak in chroma at high lightness». — [modern-css.com](https://modern-css.com/perceptually-uniform-colors-with-oklch); [pravinkumar.co](https://www.pravinkumar.co/blog/oklch-color-webflow-brand-system-2026)
- Tailwind v4-analyse: kulørdrift er bevisst – «yellows shift toward orange in darker shades, and blues shift toward violet in darker shades». — [Frana](https://dev.to/matfrana/the-mystery-of-tailwind-colors-v4-hjh)
- Material 3: «some hues cannot exist with certain chroma or tones … bright light blue or bright light red are not quite possible»; «Combining colors improperly may break contrast … particularly when colors are adjusted through dynamic color features such as user-controlled contrast»; «Fixed colors … are likely to cause contrast issues». «Don't conflate color spaces when inspecting or adjusting colors.» — [M3](https://m3.material.io/styles/color/system/how-the-system-works); [M3 roles](https://m3.material.io/styles/color/roles)
- Muldoon: OKLCH «can't predict contrast» (ingress). — [Muldoon](https://uxdesign.cc/stop-using-oklch-lightness-for-your-color-scale-02025deca49d)
- Curtis: risikoer – «Hardened scales that resist future modifications», beslutninger begravd i «single-purpose files», og overhead av konstant tokenvurdering. — [Curtis, Tokens](https://medium.com/eightshapes-llc/tokens-in-design-systems-25dd82d58421)
- Wu (Hazel): «206 colors and growing» for 8 komponenter som motivasjon for å restrukturere. — [Wu](https://medium.com/@thisisfranciswu/designing-hazels-accessible-color-system-part-1-8a73a2298c35)
- Radix: gule/lyse kulører krever mørk tekst på trinn 9–10, i motsetning til resten. — [Radix](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)

### Inferences
- Samlet anbefaling fra kildene: generer i et perseptuelt rom (OKLCH/HCT), men valider trinnene mot kontrastmål (WCAG-luminans eller APCA) og gamut-kartlegg i stedet for å klippe – akkurat det Kolorist allerede gjør med `gamutKartlagt(til:)`.

### Gaps
- Muldoons fullstendige argument og tall (betalingsmur).
- Material 2 mørkt tema (overleggprosenter) ikke hentet.
- Shopify Polaris og Atlassians nye «color-new»-sider (roller og surface-tokens) ikke hentet (404).
