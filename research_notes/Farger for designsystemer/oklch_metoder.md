# OKLCH/OKLab-baserte metoder for UI-fargeskalaer og paletter (Ottosson, Evil Martians, Tailwind, Open Props, shadcn, Leonardo, Huetone m.fl.)

Utført 2026-10-08. Språk: norsk bokmål; tall, sitater og kode i original. «Egen beregning» = jeg har regnet selv (python, standard Oklab-matriser) og det er ikke publisert av kilden. Mange sider er hentet via WebFetch (en liten modell sammenfatter siden), så sitater fra artikler er mindre sikre enn tall hentet rått fra GitHub (curl); rå filer er markert «rå fil».

Viktige avvik fra oppdragsteksten (funnet under research):
- **tints.dev bruker IKKE OKLCH** til å lage skalaen. Koden bruker HSLuv («perceived») eller HSL («linear»); OKLCH er bare ett av flere *utdataformater*. Se spørsmål 1.
- Matthew Ströms «How to pick the least wrong colors» (2022) handler om **datavisualiseringspaletter** (CIEDE2000 + simulert annealing), ikke 50–950-UI-skalaer og ikke OKLCH. Ingen «Pencil/Stripe-avledet» skalametode funnet.
- Josh W. Comeaus «Shadow Palette Generator» lager **skygger**, ikke fargeskalaer. Ingen OKLCH-skalageneratorer fra Comeau funnet.
- Evil Martians' eget Harmony-nettsted/README oppgir ingen tall, men `source.json` i repoet gir alle tallene (rå fil), og Harmonizer-README beskriver metoden.

---

## 1. Hvilken eksakt OKLCH-lyshet (og kroma) per trinn bruker/anbefaler metodene for 50–950?

### Takeaway
Fire publiserte tallsett i OKLCH finnes: Tailwind v4 (L varierer per kulør, ca. 0.97 → 0.26 for kromatiske), Evil Martians' Harmony (L løst fra APCA-mål, nesten lik på tvers av kulører, kroma identisk per trinn), Open Props (16 trinn, ett L/C-sett for alle kulører, bare hue varierer) og shadcn (nøytrale/tonede baser). Leonardo, Huetone, Harmonizer, accessible-palette og Stripe tar kontrast, ikke lyshet, som input. Ottosson gir ingen skala, men «toe»-formelen som gjør OKLab-L mer CIELab-lik.

### Cited Findings

**Harmony (Evil Martians) – faktiske verdier** (rå fil `source.json`, v1.4.0; npm `@evilmartians/harmony`; oppdatert i repoet, Tailwind v4-støtte 2024-11-25). Lyshet (OKLCH L), kroma (C) og APCA-kontrast (Lc) pr. trinn. Feltet `$contrast` i source.json er APCA-Lc målt mot `$contrastBg` (black for 50–500, med negativt fortegn; white for 600–950, positivt). Eksempel Red / Blue / Yellow / Gray:

| Trinn | L Red | L Blue | L Yellow | L Gray | C (alle kromatiske kulører) | C Gray | |Lc| mot bakgrunn |
|---|---|---|---|---|---|---|---|
| 50 | 0.9883 | 0.9883 | 0.9883 | 0.9883 | 0.0047 | 0.0047 | 105 (mot svart) |
| 100 | 0.9668 | 0.9648 | 0.9648 | 0.9648 | 0.0172 | 0.016 | 100 |
| 200 | 0.9219 | 0.9160 | 0.9180 | 0.9180 | 0.0422 | 0.016 | 90 |
| 300 | 0.8613 | 0.8496 | 0.8535 | 0.8535 | 0.0781 | 0.016 | 77 |
| 400 | 0.8008 | 0.7832 | 0.7891 | 0.7891 | 0.1141 | 0.016 | 65 |
| 500 | 0.7422 | 0.7188 | 0.7266 | 0.7266 | 0.1516 | 0.016 | 54 (mot svart) |
| 600 | 0.6270 | 0.6055 | 0.6113 | 0.6133 | 0.1359 | 0.016 | 65 (mot hvit) |
| 700 | 0.5352 | 0.5176 | 0.5234 | 0.5234 | 0.1156 | 0.016 | 77 |
| 800 | 0.4199 | 0.4062 | 0.4102 | 0.4121 | 0.0906 | 0.016 | 90 |
| 900 | 0.3066 | 0.2969 | 0.3008 | 0.3027 | 0.0656 | 0.016 | 100 |
| 950 | 0.1934 | 0.1875 | 0.1914 | 0.1934 | 0.0406 | 0.016 | 105 |

  Kilde: [source.json](https://raw.githubusercontent.com/evilmartians/harmony/main/source.json), [repo](https://github.com/evilmartians/harmony). Kolonnen «C» er identisk for alle 22 kromatiske kulører (min = maks, egen utlesning av filen); L varierer bare ca. ±0.02 mellom kulører per trinn (størst spenn: 500, Cyan 0.705 vs Rose 0.744). Hue-vinkler i Harmony er jevnt fordelt per kulørnavn (Red 20, Orange 43.33, Amber 66.67, Yellow 90, Lime 106.67, Green 123.33, Emerald 140, Teal 160, Cyan 180, Sky 210, Blue 240 …; egen utlesning). Noen farger ved 100–400 er markert `$isP3: true` (utenfor sRGB, f.eks. Red 100–400), så kroma er ikke gamut-avkortet – P3-flagg brukes i stedet.
- Harmonizer (generatoren) standard: nivåer 100–900 med **APCA-mål 100, 90, 77, 65, 51, 65, 77, 90, 100** (speilet rundt 500), `chroma: 0` per nivå som utgangspunkt, `chromaMode: "even"`, `colorSpace: "p3"`, `contrastModel: "apca"`, bakgrunn `#fff`/`#000`. — [defaultConfig.ts (rå fil)](https://raw.githubusercontent.com/evilmartians/harmonizer/main/packages/core/src/defaultConfig.ts), [Harmonizer README](https://github.com/evilmartians/harmonizer)
- Harmony-README: «Equal contrast within lightness groups, Mirrored contrast pairs, Contrast levels for readability, Tailwind compatibility, P3 gamut». Harmonizer README: «Define levels (e.g., 100–900) as lightness steps. Adjust contrast per level (calculated against your background).» — [Harmony README](https://raw.githubusercontent.com/evilmartians/harmony/main/README.md), [Harmonizer README](https://raw.githubusercontent.com/evilmartians/harmonizer/main/README.md)

**Tailwind v4 (`theme.css`, rå fil, siste endring av filen 2026-07-14)** – L i % (OKLCH), runde tall fra filen. Tabellen er utregnet fra filen (egen tabulering):

| Kulør | 50 | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 950 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| red L | 97.1 | 93.6 | 88.5 | 80.8 | 70.4 | 63.7 | 57.7 | 50.5 | 44.4 | 39.6 | 25.8 |
| red C | .013 | .032 | .062 | .114 | .191 | .237 | .245 | .213 | .177 | .141 | .092 |
| yellow L | 98.7 | 97.3 | 94.5 | 90.5 | 85.2 | 79.5 | 68.1 | 55.4 | 47.6 | 42.1 | 28.6 |
| yellow C | .026 | .071 | .129 | .182 | .199 | .184 | .162 | .135 | .114 | .095 | .066 |
| green L | 98.2 | 96.2 | 92.5 | 87.1 | 79.2 | 72.3 | 62.7 | 52.7 | 44.8 | 39.3 | 26.6 |
| green C | .018 | .044 | .084 | .150 | .209 | .219 | .194 | .154 | .119 | .095 | .065 |
| blue L | 97.0 | 93.2 | 88.2 | 80.9 | 70.7 | 62.3 | 54.6 | 48.8 | 42.4 | 37.9 | 28.2 |
| blue C | .014 | .032 | .059 | .105 | .165 | .214 | .245 | .243 | .199 | .146 | .091 |
| blue H | 254.6 | 255.6 | 254.1 | 251.8 | 254.6 | 259.8 | 262.9 | 264.4 | 265.6 | 265.5 | 267.9 |
| violet L | 96.9 | 94.3 | 89.4 | 81.1 | 70.2 | 60.6 | 54.1 | 49.1 | 43.2 | 38.0 | 28.3 |
| violet C | .016 | .029 | .057 | .111 | .183 | .250 | .281 | .270 | .232 | .189 | .141 |
| slate L | 98.4 | 96.8 | 92.9 | 86.9 | 70.4 | 55.4 | 44.6 | 37.2 | 27.9 | 20.8 | 12.9 |
| slate C | .003 | .007 | .013 | .022 | .040 | .046 | .043 | .044 | .041 | .042 | .042 |
| gray L | 98.5 | 96.7 | 92.8 | 87.2 | 70.7 | 55.1 | 44.6 | 37.3 | 27.8 | 21.0 | 13.0 |
| gray C | .002 | .003 | .006 | .010 | .022 | .027 | .030 | .034 | .033 | .034 | .028 |
| zinc L | 98.5 | 96.7 | 92.0 | 87.1 | 70.5 | 55.2 | 44.2 | 37.0 | 27.4 | 21.0 | 14.1 |
| zinc C | 0 | .001 | .004 | .006 | .015 | .016 | .017 | .013 | .006 | .006 | .005 |

  Øvrige tonede nøytrale i samme fil: mauve (C 0.003–0.034, H ≈ 320–326), olive (C 0.003–0.031, H ≈ 106–107), mist (C 0.002–0.021, H 197–229), taupe (C 0.002–0.021, H 17–68, varierer), stone (C 0.001–0.013, H varierer 34–106). — [theme.css](https://raw.githubusercontent.com/tailwindlabs/tailwindcss/main/packages/tailwindcss/theme.css) (ekstrahert med regex; zinc/mauve-rader har `none` som hue ved 50 og er justert i tabellen).
  Tailwind-skalaen er **ikke** konstruert med lik L eller lik kontrast per trinn på tvers av kulører: 500-trinn spenner fra L 55–79.5 (yellow 79.5, indigo 58.5); 50-trinn 96.2–98.8. Gule/limegrønne har høyere L i de midtre trinnene.

**Open Props OKLCH (16 trinn, ett sett for alle kulører)** – rå fil `props.colors-oklch.css`:

| Trinn | L | C |
|---|---|---|
| 0 | 99% | .03 |
| 1 | 95% | .06 |
| 2 | 88% | .12 |
| 3 | 80% | .14 |
| 4 | 74% | .16 |
| 5 | 68% | .19 |
| 6 | 63% | .20 |
| 7 | 58% | .21 |
| 8 | 53% | .20 |
| 9 | 49% | .19 |
| 10 | 42% | .17 |
| 11 | 35% | .15 |
| 12 | 27% | .12 |
| 13 | 20% | .09 |
| 14 | 14% | .07 |
| 15 | 11% | .05 |

  Kode: `--color-N: oklch(L% C var(--color-hue, 0));` og `--color-bright: oklch(65% .3 var(--color-hue, 0))`. Hue-variabler: red 25, pink 350, purple 310, violet 290, indigo 270, blue 240, cyan 210, teal 185, green 145, lime 125, yellow 100, orange 75. — [props.colors-oklch.css](https://raw.githubusercontent.com/argyleink/open-props/main/src/props.colors-oklch.css), [props.colors-oklch-hues.css](https://raw.githubusercontent.com/argyleink/open-props/main/src/props.colors-oklch-hues.css). Merk: Open Props' ordinære fargepalett (hex) bygger på `colar`/`open-color` ([props.colors.src.js](https://raw.githubusercontent.com/argyleink/open-props/main/src/props.colors.src.js)); OKLCH-settet er en egen, kulørnøytral kurve. Ingen gamut-avkorting i kilden (kroma opp til .21 ved alle hues – utenfor sRGB for f.eks. gul/cyan; egen vurdering ut fra beregning under).

**shadcn/ui** (rå fil `registry/themes.ts`): grunnfarger i OKLCH som semantiske tokens, ikke 50–950-skalaer. Neutral (kroma 0): background `oklch(1 0 0)`, foreground `oklch(0.145 0 0)`, primary `oklch(0.205 0 0)`, muted-foreground `oklch(0.556 0 0)`, border `oklch(0.922 0 0)`, ring `oklch(0.708 0 0)`, destructive (lys) `oklch(0.577 0.245 27.325)`, destructive (mørk) `oklch(0.704 0.191 22.216)`, mørk border `oklch(1 0 0 / 10%)`, mørk input `oklch(1 0 0 / 15%)`. Tonede baser (lys modus), foreground / muted-foreground / border: stone `0.147 0.004 49.25` / `0.553 0.013 58.071` / `0.923 0.003 48.717`; zinc `0.141 0.005 285.823` / `0.552 0.016 285.938` / `0.92 0.004 286.32`; mauve `0.145 0.008 326` / `0.542 0.034 322.5` / `0.922 0.005 325.62`; olive `0.153 0.006 107.1` / `0.58 0.031 107.3` / `0.93 0.007 106.5`. Aksentfarger (primary): blue `oklch(0.488 0.243 264.376)`, green `0.527 0.154 150.069`, orange `0.553 0.195 38.402`, red `0.505 0.213 27.518`, violet `0.491 0.27 292.581` (alle Tailwind-600-ish verdier). — [themes.ts](https://raw.githubusercontent.com/shadcn-ui/ui/main/apps/v4/registry/themes.ts). shadcn bruker Tailwind v4-fargene som fargeside (`/colors`), ikke egen generator; «themes generator» ikke undersøkt nærmere (gap).

**Radix** (kun eksakte lysmål): trinn 11 «guaranteed to Lc 60» og trinn 12 «guaranteed to Lc 90» APCA mot trinn 2-bakgrunn; trinn 9 har høyest kroma; trinn-bruk 1 app-bakgrunn … 12 høykontrasttekst. Radix sier «Radix Colors are not intended to be customised» (dokumentasjonen om egne paletter gir ingen algoritme). — [Understanding the scale](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale), [Composing a palette](https://www.radix-ui.com/colors/docs/palette-composition/composing-a-palette)

**Ottosson – lyshet** (sentrale tall):
- Oklab publisert 2020-12-23; RMS-feil lyshet 0.20 (CIELab 1.70), kroma 0.81 (CIELab 1.84), hue 0.49 (JzAzBz 0.43). Ottosson innrømmer «all these existing models have drawbacks». — [Oklab](https://bottosson.github.io/posts/oklab/)
- Okhsl/Okhsv 2021-09-08, «toe»-funksjon for L_r (referansehvitt Y=1): k₁ = 0.206, k₂ = 0.03, k₃ = (1+k₁)/(1+k₂); `toe(x) = 0.5*(k3*x − k1 + sqrt((k3*x − k1)² + 4*k2*k3*x))`; `toe_inv(x) = (x*x + k1*x)/(k3*(x + k2))`. L_r «closely matches the lightness estimate of CIELab overall and is nearly equal at 50% lightness»; og: «it is not possible to have a lightness scale that is perfectly uniform independent of viewing conditions». Okhsl bruker C₀(l) (hue-uavhengig), C_mid(h,l), C_max(h,l) med interpolasjon: s=0 → dC/ds=C₀, s=0.8 → C_mid, s=1.0 → C_max (sRGB-gamut-cusp). Begrensning: «larger variation in perceived chroma» ved maks metning pga. sRGB-formen. — [Okhsv/Okhsl](https://bottosson.github.io/posts/colorpicker/)
- sRGB gamut clipping 2021-01-25: anbefalt «Adaptive L₀ with α = 0.05» (projiser mot grå, L₀ hue-avhengig = L_cusp eller 0.5). — [Gamut clipping](https://bottosson.github.io/posts/gamutclipping/)
- Ottosson sin blogg har bare fire innlegg (2020-12-03 «How software gets color wrong», 2020-12-23 Oklab, 2021-01-25 gamut clipping, 2021-09-08 Okhsv/Okhsl); ingen senere notater om gamut/lyshet funnet. — [bottosson.github.io](https://bottosson.github.io/)

**Verktøy som tar kontrast som input (ikke L)** – se spørsmål 4. Eksplisitte tall oppgitt:
- Accessible Palette (Wildbit/Postmark, Eugene Fedorenko, 2021-09-16): CIELAB-lyshet 88.6, 75.2, 50.6 for nivå 200, 400, 600 (Postmark-eksempel). — [wildbit.com](https://wildbit.com/blog/accessible-palette-stop-using-hsl-for-color-systems)
- Stripe (2019-10-15): to farger må ligge ≥5 nivåer fra hverandre for liten tekst (4.5:1), ≥4 for ikoner/stor tekst (3:1); ingen L*-tall per trinn i artikkelen. — [Stripe](https://stripe.com/blog/accessible-color-systems)

**tints.dev (Simeon Griggs)** – algoritme fra rå fil `createSwatches.ts`: stopp `[0,50,100,…,900,950,1000]`; tre ankre: stopp 0 → `lMax` (default 100), valgt stopp (default 500) → basefargens lyshet (HSLuv-L i modus «perceived», HSL-L i modus «linear»), stopp 1000 → `lMin` (default 0); øvrige stopp **lineært interpolert** i L mellom ankrene og avrundet til heltall (L 0–100). Dvs. lyshet *avledes fra inndatafargen*, ingen faste mål. Standard: `colorMode: "perceived"`, `h:0, s:0, lMin:0, lMax:100`, utdata `MODES = oklch | hex | p-3 | hsl` (OKLCH er kun visning). Tittel i koden: «A fast and flexible, HSL-tweakable palette generator». — [createSwatches.ts](https://raw.githubusercontent.com/simeongriggs/tints.dev/main/app/lib/createSwatches.ts), [constants.ts](https://raw.githubusercontent.com/simeongriggs/tints.dev/main/app/lib/constants.ts), [README](https://raw.githubusercontent.com/simeongriggs/tints.dev/main/README.md), [launch-post](https://www.simeongriggs.dev/using-the-tailwind-css-palette-generator-and-api). «Luminance» i grensesnittet = den lineære HSL-modusen (`colorMode: "linear"`), «Lightness» = HSLuv-modusen (README: «Switch between Lightness and Luminance to produce a different spread of colours at the extremes»; kobling til kodens `colorMode` er min tolkning).

### Inferences
- For en app som allerede jobber i OKLCH er det enkleste rå-gjenbruket: (a) Harmony-tabellen (L-sett og C-sett som tall, hue fritt; kontrast-garantert) eller (b) Open Props' 16-trinns kurve (ingen kontrastgaranti). Tailwind-tabellen viser hva mange i praksis kopierer, men har ikke jevn L/kontrast på tvers av kulører.
- Harmony viser at «lik L per trinn» ikke er det de faktisk bruker – de løser L fra APCA-mål; den lille L-spredningen (~±0.02) er verdien av at mål-kontrast gir *litt ulik* L per kulør.
- Ottosson sin toe-funksjon er nyttig hvis man vil at L-skalaen skal kunne sammenlignes med CIELab-lyshet (Stripe/Accessible Palette-tradisjonen).

### Gaps
- Radix-genereringsalgoritmen (L-mål per trinn i OKLCH) ikke verifisert i denne runden; kun APCA-målene for trinn 11–12 funnet.
- tints.dev sin interne bruk av «lightness»-tall per trinn: ingen faste tall (avledes fra base).
- Atmos' eksakte lysheter/easing-kurver ikke publisert i frie docs jeg kunne hente (se spørsmål 2).
- uicolors.app: algoritmen er ikke dokumentert; en sekundærkilde hevder HSL-interpolasjon mot nær-hvit/svart, men det er ikke verifisert ([saasykit-/aggregator-søk](https://webdesignerdepot.com/uicolors-uses-css-to-generate-custom-color-scales-for-designers/)); behandles som uverifisert.
- Huetone: ingen genereringsalgoritme (det er et manuelt redigerings-/analyseverktøy); se spørsmål 4.
- accessible-palette.com var ikke tilgjengelig (DNS-feil fra dette miljøet); bruker Wildbit-bloggen.

---

## 2. Hvordan håndteres kroma over skalaen og hueforskyvning?

### Takeaway
Tre mønstre: (1) kroma som topp i midten, lik for alle kulører (Harmony: C-kurve 0.0047 → 0.1516 → 0.0406; Open Props: .03 → .21 → .05), (2) kroma som varierer per kulør, tett opp mot gamut (Tailwind v4, hvor blå/fiolett topper på 0.25–0.29 ved trinn 600 og gul på 0.20 ved 400), (3) kroma bevart fra inndatafargen (Accessible Palette, tints.dev). Hueforskyvning: Harmony og Open Props har *ingen* (konstant hue); Tailwind har tydelig hue-drift (gul 102 → 54, orange 74 → 36, pink 343 → 4); Accessible Palette og tints.dev har manuelle hue-kompensasjonskontroller.

### Cited Findings
- Harmony: C per trinn er identisk for alle kromatiske kulører (50: 0.0047 … 500: 0.1516 … 950: 0.0406; tabell i spørsmål 1); hue er konstant gjennom hele skalaen per kulør (f.eks. Red 20 på alle trinn; Blue 240). Forholdet C(trinn)/C(500): 0.031, 0.113, 0.278, 0.515, 0.753, 1.0, 0.896, 0.762, 0.598, 0.433, 0.268 (egen regning). P3-flagg i stedet for gamut-klipping: Red 100–400 `$isP3: true` men Red 500–950 og 50 `false`. — [source.json](https://raw.githubusercontent.com/evilmartians/harmony/main/source.json); Harmonizer-README: «Perceptualy consistent chroma with OKLCH»; `chromaMode: "even"` — [defaultConfig.ts](https://raw.githubusercontent.com/evilmartians/harmonizer/main/packages/core/src/defaultConfig.ts)
- Tailwind v4: kroma-topp ved trinn 500–600 for blå/fiolett/lilla/fuchsia/rosa/rød (C 0.21–0.29), ved 300–500 for gul/amber/lime (0.18–0.24); hue for blå øker jevnt 254.6 → 267.9 fra 50 → 950; gul 102.2 → 53.8; orange 73.7 → 36.3; pink 343 → 354 (500) → 0.6–4 (600–950); rose 12 → 17 → 12. — [theme.css](https://raw.githubusercontent.com/tailwindlabs/tailwindcss/main/packages/tailwindcss/theme.css) (egen tabulering). Mørkeste trinn (950) beholder 0.05–0.15 kroma.
- Open Props OKLCH: C-kurve topp .21 ved trinn 7 (L 58%), konstant hue (variabel `--color-hue`). — [props.colors-oklch.css](https://raw.githubusercontent.com/argyleink/open-props/main/src/props.colors-oklch.css)
- tints.dev: kroma/«saturation» styres av `s`-parameter som øker mot ytterkantene: `tweak = round((diff+1) * s * (1 + diff/10))`, maks 100 (diff = antall stopp-indekser fra valgt stopp), hue-skift: `diff * h` (grader per stopp-avstand), begge i HSLuv/HSL. Dvs. lineær hue-drift bort fra base, symmetrisk i begge retninger (absolutt avstand). — [createSwatches.ts](https://raw.githubusercontent.com/simeongriggs/tints.dev/main/app/lib/createSwatches.ts)
- Accessible Palette: «Chroma is preserved from starting colors»; hue kan justeres per nivå («To shift them a little closer to orange, I use a negative Hue compensation») for gule som mørkner mot grønnaktig. — [Wildbit](https://wildbit.com/blog/accessible-palette-stop-using-hsl-for-color-systems)
- apcach (Evil Martians/Anton Lovchikov) kan finne «most saturated color possible within a given contrast requirement» med `maxChroma()`: `apcach(crToFg("white", 60), maxChroma(), 145) // oklch(65.01% 0.28 145)`; `maxChroma(0.25)` på hue 200 → `oklch(66.14% 0.15 200)` (gamut-begrenset). Advarsel: «apcach always returns a result even if the color doesn't exist in any color spaces». — [apcach README](https://raw.githubusercontent.com/antiflasher/apcach/main/README.md)
- Maks sRGB-kroma er sterkt hue- og L-avhengig (egen beregning med standard Oklab-matriser, sRGB): ved L 0.56: gul h110 → 0.122, rød h29 → 0.230, grønn h142 → 0.189, cyan h195 → 0.096, blå h264 → 0.242, lilla h305 → 0.291; ved L 0.85: rød 0.082, gul 0.186, grønn 0.286, blå 0.074. Eksempel: Open Props sin C=.21 ved L 58% er utenfor sRGB for gul (maks ca. 0.12) og cyan.
- Evil Martians: kroma er «below 0.37» i praksis både for sRGB og P3; hver hue har egen maks; ikke alle L/C/H-kombinasjoner vises på alle skjermer; nettleseres gamut-mapping er ufullkomment, `@media (color-gamut: p3)` anbefales. Blå ≈ hue 220–240 i deres picker-skala. — [OKLCH in CSS: why we moved from RGB and HSL](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl) (2025-09-17, Sitnik & Turner)
- Atmos: skalaer genereres i OKLCH «with easing curves» (markedsføring; ingen tall publisert); OKLCH-kroma ca. 0–0.45, LCH 0–130. — [Atmos color-space](https://atmos.style/docs/project/color-space)
- Lea Verou 2020-04-04: ved L=50, H=180 er maks sRGB-kroma bare 35 (LCH), ved H=0 77 – «Chroma is theoretically unbounded (varies by hue and lightness)». — [LCH colors in CSS](https://lea.verou.me/blog/2020/04/lch-colors-in-css-what-why-and-how/)

### Inferences
- «Maks kroma ved gitt L» (gamut-begrenset) er den praktiske teknikken for kulører med smal gamut (gul/cyan): Harmony velger i stedet *lik C* og lar P3 dekke resten, Tailwind lar C følge kulørens egen kurve.
- Hue-drift Tailwind-stil er innebygget i håndtunede verdier, mens de programmatiske (Harmony, Open Props) holder hue konstant. Konstant hue i OKLCH gir i praksis mindre visuell drift enn i LCH (blått mot lilla), jf. Atmos.

### Gaps
- Atmos sin faktiske easing/kromafordeling: ikke funnet (docs viste ingen tall).
- Joshua Comeau: ingen OKLCH-skala/kroma-råd funnet (se spørsmål 6).

---

## 3. Hvordan defineres nøytrale (tonede grå): kromaverdi og hue-kilde?

### Takeaway
Nøytrale er en egen skala med lav fast kroma (ca. 0.004–0.046) og én fast hue hentet fra en nabokulør/«temperatur». Harmony bruker 0.016 for «Gray» (hue 275) og 0.008 for flere andre; Tailwind v4 bruker kroma som følger L-kurven (høyest ved 400–600).

### Cited Findings
- Harmony (rå fil, egen utlesning): Gray: C 0.0047 ved 50, 0.016 (konstant) 100–950, hue 275; Slate: 0.0047 → 0.024, hue 275; Zinc 0.0049 → 0.008, hue 275; Stone 0.008, hue 75; Sand 0.0104 → 0.012, hue 75; Olive 0.008, hue 120; Mauve 0.008, hue 325; Neutral: C 0, hue 0. L-mønsteret for nøytrale følger Gray (0.9883, 0.9648, 0.918, 0.8535, 0.7891, 0.7266, 0.6133, 0.5234, 0.4121, 0.3027, 0.1934 – egen utlesning). — [source.json](https://raw.githubusercontent.com/evilmartians/harmony/main/source.json)
- Tailwind v4 (egen tabulering fra filen): slate C 0.003 → 0.046 (topp ved 500), hue ≈ 248–266; gray C 0.002 → 0.034, hue ≈ 248–265; zinc C 0.001 → 0.017, hue ≈ 286; stone C 0.001 → 0.013, hue varierer (34–106) fordi kroma er så lav at hue blir støy; olive C 0.003 → 0.031, hue ≈ 106–107; mauve C 0.003 → 0.034, hue ≈ 320–326; mist C 0.002–0.021, hue 197–229; taupe C 0.002–0.021, hue 17–68. — [theme.css](https://raw.githubusercontent.com/tailwindlabs/tailwindcss/main/packages/tailwindcss/theme.css)
- shadcn: Neutral har C 0; «zinc» foreground `oklch(0.141 0.005 285.823)`, «mauve» muted-foreground `oklch(0.542 0.034 322.5)`, «olive» `oklch(0.58 0.031 107.3)`; border-nivået har C 0.003–0.007 på alle tonede baser. — [themes.ts](https://raw.githubusercontent.com/shadcn-ui/ui/main/apps/v4/registry/themes.ts)
- Radix: tonede grå (mauve, slate, sage, olive, sand) «based on various hues»; hver anbefales parvist med en aksentfarge. — [Composing a palette](https://www.radix-ui.com/colors/docs/palette-composition/composing-a-palette)
- Open Props: ingen separat nøytralskala i OKLCH-filen (samme kurve med hue-variabel; kroma ned til .03–.05 ved ytterkantene). — [props.colors-oklch.css](https://raw.githubusercontent.com/argyleink/open-props/main/src/props.colors-oklch.css)

### Inferences
- Rimelig regel utledet fra tabellene: nøytral C ≈ 0.004–0.03 (under ca. 0.01 er hue knapt synlig og numerisk ustabil – Tailwind stone viser hue-støy); hue hentes fra merkevarefargen eller fra en fast «temperaturhue» (275 kjølig, 75–120 varm).

### Gaps
- Ingen kilde forklarer *hvorfor* akkurat 0.016 (Harmony Gray); Evil Martians' valg er ikke begrunnet i det jeg fant.

---

## 4. Hvilke metoder tar kontrast (WCAG/APCA) som input, og hvordan løses lyshet?

### Takeaway
Harmonizer/Harmony (APCA, OKLCH, apcach), Leonardo (WCAG2/APCA, mange romvalg inkl. OKLCH, binærsøk), Huetone (manuell redigering med kontrastvisning, CIELCH/OKLCH), Accessible Palette (CIELAB L* + WCAG/APCA-visning), Stripe (CIELAB, nivåavstand ↔ kontrast) og Radix (APCA Lc 60/90 for trinn 11/12) styrer etter kontrast. Løsning: invers søk (binærsøk eller analytisk) på L langs en kurve gitt hue og kroma.

### Cited Findings
- Harmonizer: «Define levels … as lightness steps. Adjust contrast per level (calculated against your background)», APCA standard eller WCAG, retning fg→bg eller bg→fg, egen bakgrunn; kalkulatoren er `apcach` som «blends» APCA og OKLCH. Trinn-APCA-mål (standard): 100, 90, 77, 65, 51, 65, 77, 90, 100. — [Harmonizer README](https://raw.githubusercontent.com/evilmartians/harmonizer/main/README.md), [defaultConfig.ts](https://raw.githubusercontent.com/evilmartians/harmonizer/main/packages/core/src/defaultConfig.ts)
- apcach API: `apcach(contrast, chroma, hue)`; eksempler (fargen med APCA 60 på hvit, kroma 0.2, hue 145 → `oklch(62.5% 0.2 145)`; mot svart `oklch(73.8% 0.2 145)`; mot `#E8E8E8` `oklch(52.71% 0.2 145)`; `crToFg("white", 60)` → `oklch(66.02% 0.2 145)`). APCA er polaritetsavhengig (tekst vs. bakgrunn), derfor `crToBg()`/`crToFg()`. — [apcach README](https://raw.githubusercontent.com/antiflasher/apcach/main/README.md); Evil Martians: [Exploring the OKLCH ecosystem](https://evilmartians.com/chronicles/exploring-the-oklch-ecosystem-and-its-tools) (2025-05-28; apcach, Harmonizer, Polychrom, Huetone nevnt).
- Leonardo (Adobe, Nate Baldwin m.fl.) – kode (rå fil `utils.js`): `createScale` lager en 3000-punkts interpolert skala gjennom fargenøklene (`colorKeys`) i valgt rom (`CAM02:'jab'`, `HSLuv`, `LAB`, `LCH`, `OKLAB`, `OKLCH`, plus HSL/HSV/RGB osv.), og `searchColors` kjører **binærsøk** (halverer steg fra colorLen/2, toleranse ε = 0.01, maks 100 iterasjoner) på posisjonen der kontrasten mot bakgrunnen er lik ønsket ratio; retning (`dir`) fra kontrast ved første vs. siste punkt. Kontrast: WCAG2 `(L1+0.05)/(L2+0.05)` (negativ for lysere-enn-bakgrunn) eller APCA; ratioer er negative/positive mot bakgrunn. Standard-ratioer i demo: «3, 4.5, 7». Mørk modus: temaet justeres med lightness-/contrast-/saturation-glidere; hele temaet kan skiftes mørkere med bakgrunnslyshet. Grensesnittet tilbyr valg av interpolasjonsrom CAM02, Lab, LCh, OKLab, OKLCh, HSL, HSV, HSLuv. — [utils.js (rå fil)](https://raw.githubusercontent.com/adobe/leonardo/main/packages/contrast-colors/lib/utils.js), [leonardocolor.io](https://leonardocolor.io/), [Theme-siden](https://leonardocolor.io/theme.html)
- Huetone (Alexey Ardov): modeller `cielch` (L 0–100, C 0–134) og `oklch` (L 0–100 vist, C 0–0.33) i koden; kontrast: WCAG-ratio og APCA; palett redigeres per rute i L/C/H, med «equalize»-ikoner; bygger «à la Stripe»: «Stripe team for publishing that article back in 2019 which inspired me to make this app». Siste push til repoet 2023-11-19. Ingen automatisk skalagenerering utover presets (Tailwind, Radix, Stripe, GitHub, Ant, Chakra, IBM, USWDS m.fl.). — [ardov/huetone README](https://raw.githubusercontent.com/ardov/huetone/master/README.md), [colorModels.ts](https://raw.githubusercontent.com/ardov/huetone/master/src/shared/colorFuncs/colorModels.ts), [repo](https://github.com/ardov/huetone)
- Stripe (2019-10-15): CIELAB for å forstå «how each color appears to our eyes»; krav 4.5:1 for liten tekst, 3:1 for stor tekst; to farger ≥5 nivåer fra hverandre for liten tekst, ≥4 for ikoner/stor tekst; farger skal passere over hvitt og «atop the lightest color value in any hue». Ingen numeriske L*-verdier i artikkelen. Dark mode/neutrale ikke omtalt. — [Stripe: accessible color systems](https://stripe.com/blog/accessible-color-systems)
- Accessible Palette (Wildbit, 2021-09-16): CIELAB; «uses color's Chroma and Hue to calculate a scale with multiple lightness levels»; lyshet fritt justerbar per nivå; to kontrastmetrikker: WCAG 2.1 og APCA, der «score 60» regnes som minimum for lesbar tekst ~ 4.5:1; eksempel L* 88.6, 75.2, 50.6 for nivå 200/400/600. — [Wildbit](https://wildbit.com/blog/accessible-palette-stop-using-hsl-for-color-systems)
- Radix: Lc 60 (trinn 11) og Lc 90 (trinn 12) mot trinn 2. — [Understanding the scale](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)
- Color.js (Verou/Lilley) støtter seks kontrastalgoritmer: Weber, Michelson, WCAG 2.1, APCA (versjon 0.0.98G-4g), Lstar, Delta Phi Star; notat om WCAG 2.1: «been criticized for numerous false positive and false negative results, particularly in dark mode»; Lstar: «a lightness difference of 30 units in CIE L* was sufficient for legible contrast». — [colorjs.io/docs/contrast](https://colorjs.io/docs/contrast)
- Atmos: innebygd kontrastsjekker med WCAG 2 og APCA; skalageneratoren oppgis å lage «perceptually uniform with predictable contrast using LCH or OKLCH» (markedsføring). — [atmos.style](https://atmos.style/docs/guides)

### Inferences
- Algoritme som kan implementeres direkte i en OKLCH-app: for hver (hue, kroma, mål-Lc) → binærsøk på L ∈ [0,1], konvertér til sRGB/P3 (gamut-kartlagt), beregn APCA/WCAG mot bakgrunn, iterer til |kontrast − mål| < ε (Leonardo ε=0.01; apcach tilsvarende). Fordi kontrast er monotont i L, konvergerer binærsøk.
- Harmony-mønsteret «speilede mål» (100/90/77/65/51 | 51/65/77/90/100) gir automatisk samsvar mellom lys og mørk modus.

### Gaps
- Nøyaktig beregning i apcach (om den løser analytisk eller ved binærsøk): ikke lest i kildekoden.
- Nate Baldwins artikler («Leonardo»-serien på Medium, «Color tooling»-foredrag): ikke hentet (Medium ga 403/ingen treff); detaljer her er fra Leonardos kode og nettsted, ikke fra artiklene.
- Huetone har ingen dokumentert automatisk skalametode (appen er manuell).

---

## 5. Hva sies om mørk modus-skalaer?

### Takeaway
Tre tilnærminger: speilet/omvendt skala med samme kontrastmål (Harmony: «Mirrored contrast pairs»), egen skala justert med lyshet/kontrast/metning (Leonardo), og separate semantiske tokens med redusert/endret kroma (shadcn).

### Cited Findings
- Harmony/Harmonizer: «Themes don't mirror: Light/dark modes require custom mappings» er problemet de løser; Harmony-features: «Mirrored contrast pairs», og Harmonizer-standard har både `bgColorLight: "#fff"` og `bgColorDark: "#000"`, `bgLightStart: 5`; i `source.json` er trinn 50–500 målt mot svart (negativ Lc, −105 … −54) og 600–950 mot hvit (65 … 105) – dvs. samme absolutte Lc-nivåer speilet rundt midten. — [Harmonizer README](https://raw.githubusercontent.com/evilmartians/harmonizer/main/README.md), [defaultConfig.ts](https://raw.githubusercontent.com/evilmartians/harmonizer/main/packages/core/src/defaultConfig.ts), [source.json](https://raw.githubusercontent.com/evilmartians/harmony/main/source.json)
- Leonardo: mørk modus fra samme skala ved å senke bakgrunnslyshet (lightness-glider), justere kontrast og metning. — [leonardocolor.io/theme.html](https://leonardocolor.io/theme.html)
- shadcn (rå fil): mørk modus er *egne verdier*, ikke speilet skala. Eksempel Neutral: background `0.145` (lys-foreground), card `0.205`, primary `0.922`, secondary/muted/accent `0.269`, muted-foreground `0.708` (lys: 0.556); destructive mørk `oklch(0.704 0.191 22.216)` mot lys `oklch(0.577 0.245 27.325)` → høyere L og lavere kroma (0.245 → 0.191) i mørk modus; border/input med alfa: `oklch(1 0 0 / 10%)` / `/ 15%`. — [themes.ts](https://raw.githubusercontent.com/shadcn-ui/ui/main/apps/v4/registry/themes.ts)
- Radix: egne mørke skalaer (steg 1–12 med samme bruksområder; mørk 1–2 = bakgrunn); trinn 11/12 har samme Lc-garanti. — [Understanding the scale](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale)
- Tailwind v4 har ingen dedikert mørk skala; samme 50–950 brukes invertert av brukeren (fra filen; ingen mørk-spesifikke tall).
- Color.js: WCAG 2.1 gir mange feil i mørk modus (se over); APCA er polaritetsfølsom og skiller lys-på-mørk fra mørk-på-lys. — [colorjs.io](https://colorjs.io/docs/contrast)
- Atmos: feature-liste nevner dark mode-støtte; ingen metodedetaljer funnet. (se spørsmål 4)

### Inferences
- shadcn-eksempelet (mørk destructive: L opp ~0.13, C ned ~0.054) er en praktisk regel: i mørk modus løft L og reduser kroma for å unngå «glødende» overflater. Det er en observasjon av verdiene, ikke en publisert regel.
- Harmony-modellen krever at kontrastmålene er definert som absolutte Lc-nivåer (polaritet-bevisst), slik at «lys 300» og «mørk 700» får lik kontrast mot sin respektive bakgrunn.

### Gaps
- Ingen kilde som gir en eksplisitt formel for kromareduksjon i mørk modus.
- Radix' mørke trinn-L-tall ikke hentet.
- Stripe-artikkelen omtaler ikke mørk modus.

---

## 6. Publiserte kritikker av OKLCH for UI-skalaer (lyshet vs. kontrast, blå kroma, gamut-kanter)

### Takeaway
Hovedkritikken: OKLCH-L er ikke luminans, så like L ≠ lik WCAG/APCA-kontrast (Helmholtz–Kohlrausch-effekten, hue-avhengig). Praktisk implikasjon: bruk kontrast som input og la L være utgangen (Harmony, Leonardo). I tillegg: gamut-avgrenset kroma varierer sterkt per hue (gul/cyan smal, blå/lilla bred), og nettleseres gamut-mapping er ufullkommen.

### Cited Findings
- uxdesign.cc, «Stop using OKLCH lightness for your color scale» (forfatter/dato ikke bekreftet; Medium-medlemsartikkel, 403 ved henting): treff-snutt: «OKLCH is brilliant at generating color, but it can't predict contrast»; kilden hevder at fargetoner ved samme OKLCH-L ikke passerer/stryker kontrasttester likt. Kun snutter fra søk; selve artikkelen er ikke lest. — [uxdesign.cc](https://uxdesign.cc/stop-using-oklch-lightness-for-your-color-scale-02025deca49d) (UVERIFISERT innhold)
- Egen beregning (standard Oklab→sRGB, WCAG 2.1 kontrast mot hvit, kroma C=0.12 eller gamut-maks der den er lavere): ved OKLCH L=0.56 varierer WCAG-kontrasten mellom kulører fra 4.43 (grønn h142) til 4.93 (rød h29), 4.90 (lilla), 4.72 (blå), 4.57 (gul), 4.44 (cyan) – dvs. noen passerer 4.5:1, andre ikke. Ved L=0.70: 2.54 (cyan) … 2.81 (rød); ved L=0.85: 1.51 (cyan) … 1.63 (rød/lilla). Spredningen er altså ca. ±5–10 % i kontrastforhold ved samme L. (Illustrasjon av punktet; ikke publisert av noen kilde.)
- Harmony løser det slik: L varierer ca. ±0.02 mellom kulører ved samme APCA-mål (500: Cyan 0.705 – Rose 0.744), bekrefter at samme APCA-kontrast krever ulik OKLCH-L. — [source.json](https://raw.githubusercontent.com/evilmartians/harmony/main/source.json)
- Ottosson selv: «it is not possible to have a lightness scale that is perfectly uniform independent of viewing conditions» og Okhsl: «larger variation in perceived chroma» pga. sRGB-gamutformen; Oklab hue-feil 0.49 RMS (JzAzBz bedre, 0.43). — [Okhsv/Okhsl](https://bottosson.github.io/posts/colorpicker/), [Oklab](https://bottosson.github.io/posts/oklab/)
- LCH (ikke OKLCH) har «hue shift from blue to purple when changing just the lightness value»; OKLCH retter dette; Atmos: «There's really no reason to use LCH over OKLCH. Since OKLCH doesn't have any major drawbacks». Et ekte, men moderat avvik: «LCH lightness of 5 approximately equals OKLCH lightness of 18; OKLCH shades below lightness 15 appear very dark». — [Atmos: LCH vs OKLCH, 2023-05-07](https://atmos.style/blog/lch-vs-oklch), [Atmos color-space](https://atmos.style/docs/project/color-space), Comeau (OKLCH «fixes a bug related to how blue hues shift», anbefaler Evil Martians-artikkelen) — [Comeau: color formats](https://www.joshwcomeau.com/css/color-formats/)
- Evil Martians (2025-09-17) trekker fram gamut og økosystem som utfordringer: «not all combinations of L, C, and H will result in colors that are supported by every monitor»; kroma praktisk «below 0.37»; P3 ≈ 30 % flere farger. Ingen kritikk av OKLCH-lyshet i selve artikkelen. — [OKLCH in CSS](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)
- Karl Koch «On OKLCH» (2026-04-06) er ren pro-OKLCH, ingen kritikk. — [karlkoch.me](https://karlkoch.me/writing/on-oklch/)
- Lea Verou 2020-04-04: LCH-lyshet er «meaningful» men gamut-avhengig kroma (L=50: H=180 maks 35, H=0 maks 77). — [lea.verou.me](https://lea.verou.me/blog/2020/04/lch-colors-in-css-what-why-and-how/). Verou-poster 2024–2025 om kontrast/OKLCH: ikke funnet.
- WCAG 2.1-kritikk (i Color.js-dokumentasjonen): «numerous false positive and false negative results, particularly in dark mode»; Color.js: «luminance contrast is the primary factor affecting reading speed». — [colorjs.io/docs/contrast](https://colorjs.io/docs/contrast)
- Kritikk av HSL (motivasjon for alle): Accessible Palette: blå mye mørkere enn gul ved like HSL-parametre. — [Wildbit](https://wildbit.com/blog/accessible-palette-stop-using-hsl-for-color-systems)

### Inferences
- Konsensus blant praktikerne som har bygd verktøy: bruk OKLCH som *fargerom for kroma/hue* og for interpolasjon, men *kontrast som lysheten-driver* (Harmony, Leonardo). Rent L-baserte skalaer (Open Props, Tailwind-tilnærming) gir ikke garantert kontrast.
- Blå har både bredest gamut (høy maks-C ved lav L) og er der LCH sin hue-feil var mest synlig; i OKLCH er det altså gul/cyan som er gamut-problemet (smal kroma), ikke blå (egen beregning over).

### Gaps
- Selve «Stop using OKLCH lightness»-artikkelen er ikke lest (betalingsmur / 403); innholdet er bare kjent fra søkesnutt.
- Verou 2024–2025 poster (kontrastalgoritmer, «LCH colors in CSS»-oppdateringer): ikke funnet.
- Matthew Ström: ingen «Pencil/Stripe-avledet» metode funnet; hans «least wrong colors» (CIEDE2000-optimalisering for datavis, med fargesynssimulering Brettel mfl., 38 % tap-forbedring fra tilfeldig baseline, 217.8 → 136.3) er en annen type oppgave. — [Ström-Awn: How to pick the least wrong colors](https://mattstromawn.com/writing/how-to-pick-the-least-wrong-colors/) (domene omdirigert fra matthewstrom.com, hentet 2026-10-08; dato ikke oppgitt i artikkelen)
- Josh Comeau: «The Joy of Color»/palettgenerator for OKLCH-skalaer ikke funnet; «Shadow Palette Generator» (introdusert nov. 2021, sist oppdatert aug. 2025) lager skygger. — [Comeau: shadow palette](https://www.joshwcomeau.com/css/introducing-shadow-palette-generator/) (fra søkesammendrag, ikke åpnet).
- Evil Martians oklch.com-pickerens interne regler (gamut-visning, «chroma capped») og blogginnlegg 2024–2025 utover de to fetched: ikke gjennomgått.
