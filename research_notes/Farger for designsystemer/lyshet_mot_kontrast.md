# Lyshet mot kontrast: hva bør forankre trinnene i en 50–950-skala?

*Notater for Kolorist, 2026-10-08. Kilder er hentet og lest 2026-10-08. Egne beregninger er merket «EGEN BEREGNING» og kan kjøres på nytt med skriptet i vedlegget (kun Python-standardbibliotek).*

**Kort svar.** WCAG 2-kontrast er en ren funksjon av relativ luminans Y, og CIE L* er en monoton funksjon av Y alene. Fast L* gir derfor *nøyaktig* fast WCAG-kontrast på tvers av alle kulører (spredning 0 etter definisjon). OKLCH L er ikke en funksjon av Y alene: for samme WCAG-kontrast varierer OKLCH L med ca. 3 poeng (på 0–100) over 12 kulører ved C ≤ 0,12, og 5–6 poeng ved maks kroma i sRGB. APCA er verken eksakt i L* eller OKLCH L (L*-spredning 0,4–0,7 poeng ved C ≤ 0,12, opptil ~3,3 ved maks kroma), og den er polaritetsavhengig; der må kontrasten sjekkes direkte.

---

## 1. Kevin Muldoon, «Stop using OKLCH lightness for your color scale» – hva er argumentet, og hvilket «bedre tall» foreslår han?

### Takeaway
Fulltekst er **ikke** hentet: artikkelen er «Member-only story» bak Medium-betalingsmur, og alle speil/arkiver ga 403/429/404 eller tomt resultat. Det som er bekreftet (RSS-metadata) og det som er gjengitt av et søkeverktøy tyder på at «det bedre tallet» er CIE L* (luminans omskrevet til en perseptuell skala), men dette er **ikke verifisert ordrett fra artikkelen**. Hovedpåstanden (OKLCH L predikerer ikke WCAG-kontrast, mens L*/Y gjør det) er bekreftet av egne beregninger nedenfor.

### Cited Findings
- Tittel, forfatter, datoer og undertittel (bekreftet fra Mediums egen RSS, ordrett): forfatter Kevin Muldoon, publisert «Sun, 23 Aug 2026 20:37:16 GMT», oppdatert 2026-09-25T13:22:08Z, tagger token-design, design, design-systems, color-theory, accessibility. Ingress/snippet: «It’s brilliant at generating color, but it can’t predict contrast — and there’s a better number for your palette weights.» — [UX Collective-tagfeed color-theory (RSS)](https://uxdesign.cc/feed/tagged/color-theory), hentet 2026-10-08. Artikkel-URL: [uxdesign.cc/stop-using-oklch-lightness-for-your-color-scale-02025deca49d](https://uxdesign.cc/stop-using-oklch-lightness-for-your-color-scale-02025deca49d) (Medium-ID 02025deca49d; forfatterens Medium-profil er @kmuldoon, feeden `medium.com/feed/@kmuldoon` er tom).
- Artikkelen er «Member-only story» (sidetittel i søkeresultat). — [uxdesign.cc-artikkelen](https://uxdesign.cc/stop-using-oklch-lightness-for-your-color-scale-02025deca49d); direkte henting ga HTTP 403.
- **Andrehånds gjengivelse (søkeverktøyets oppsummering av forhåndsvisningen, ikke ordrett sitat, brukes med forbehold):** (a) resonnementet er at når man kjenner luminansen til to farger, kjenner man kontrasten, fordi kulør ikke inngår i formelen; (b) «Test it»: sett flere kulører til samme OKLCH-lyshet, f.eks. 56, og se at de ikke består/feiler kontrastsjekk samlet; (c) «whatever Oklab’s lightness measures, it is not the thing WCAG contrast measures»; (d) «WCAG and APCA both run on luminance, and CIE L* is that luminance re-expressed on a scale tuned to the eye»; (e) «Oklab was never built for that» (kontrast hører under WCAG/APCA). — [uxdesign.cc-artikkelen via WebSearch](https://uxdesign.cc/stop-using-oklch-lightness-for-your-color-scale-02025deca49d?gi=af4514ac9677), 2026-10-08.
- Forsøk som mislyktes (for å spare tid neste gang): WebFetch/curl mot uxdesign.cc (403, Cloudflare), web.archive.org (429 / 404 ingen snapshot), archive.ph/.is/.today (429), freedium.cfd (DNS finnes ikke), readmedium.com (side uten innhold), r.jina.ai (403), scribe.rip (404), Google-cache (404), Medium-RSS for forfatter (tom) og uxdesign.cc/feed + tag-feeder (kun ingress, ikke `content:encoded` – Medium trunkerer medlemshistorier).

### Inferences
- Eksempelet «OKLCH L = 56» stemmer med egen beregning (§5): ved OKLCH L = 0,56 og C = min(0,12; maks) varierer WCAG-kontrast mot hvit fra 4,41 til 4,97 over 12 kulører, altså rett over og rett under AA-grensen 4,5. Med maks kroma: 4,34–5,48. Dette er en bekreftelse av *påstanden*, ikke av hans tall.
- Det sannsynlige «bedre tallet» er CIE L* (evt. Y). Må bekreftes mot fulltekst før det siteres som hans anbefaling.

### Gaps
- Hans konkrete tall, tabeller, anbefalte L*-verdier per vekt (50–950) og eventuelle unntak/forbehold: ikke tilgjengelig. Fulltekst må leses via Medium-konto eller limes inn manuelt; ingen proxy/arkiv virket.

---

## 2. Material Design 3: «40 toner = 3:1, 50 toner = 4,5:1»

### Takeaway
Material definerer *tone* (HCT) som identisk med CIE L*, og dokumenterer at toneforskjell 40 gir kontrast ≥ 3:1 og 50 gir ≥ 4,5:1. Regelen er en god tommelfingerregel, men **ikke strengt sann**: egen beregning gir 4,484:1 for tone 100 mot tone 50 (eksakt krever 4,5:1 ΔL* = 50,10 mot hvit; 3:1 krever ΔL* = 38,35). Den offisielle m3.material.io-teksten lot seg ikke hente (JavaScript-side); ordlyden er hentet fra Materials åpne kildekode, et W3C-sitat av Material-bloggen og et designsystem som siterer M3.

### Cited Findings
- Kildekommentar i `hct.ts`, ordrett: «Using L* creates a link between the color system, contrast, and thus accessibility. Contrast ratio depends on relative luminance, or Y in the XYZ color space. L*, or perceptual luminance can be calculated from Y. Unlike Y, L* is linear to human perception, allowing trivial creation of accurate color tones. Unlike contrast ratio, measuring contrast in L* is linear, and simple to calculate. A difference of 40 in HCT tone guarantees a contrast ratio >= 3.0, and a difference of 50 guarantees a contrast ratio >= 4.5.» — [material-foundation/material-color-utilities, typescript/hct/hct.ts (main)](https://raw.githubusercontent.com/material-foundation/material-color-utilities/main/typescript/hct/hct.ts), hentet 2026-10-08.
- Kildekommentar i `contrast.ts`, ordrett: «Contrast ratio is calculated using XYZ's Y. When linearized to match human perception, Y becomes HCT's tone and L*a*b*'s' L*. Informally, this is the lightness of a color. … Tone is equivalent to L* in the L*a*b* color space, or L in the LCH color space.» Kontrast regnes som `(lighter + 5.0) / (darker + 5.0)` med Y på 0–100. — [typescript/contrast/contrast.ts](https://raw.githubusercontent.com/material-foundation/material-color-utilities/main/typescript/contrast/contrast.ts), hentet 2026-10-08.
- Blogginnlegget «The science of color & design» (James O’Leary, material.io; i dag omdirigert til m3.material.io/blog/science-of-color-design/, kun JS-gjengitt), sitert ordrett av Chris Lilley 2022-06-14: «The HCT color system makes meeting accessibility standards much easier. Instead of using the unintuitive measure of a contrast ratio, the system converts those same requirements to a simple difference in tone, HCT’s measure of lightness. Contrast is guaranteed simply by picking colors whose tone values are far enough apart—no complex calculations required.» og «For example, to meet WCAG contrast requirements, smaller elements (less than ¼” or 40 dp) require a tone difference of 50 with their background, larger elements require a tone difference of 40. This principle works consistently for any pair of colors.» — [W3C public-css-archive, Chris Lilley 2022-06-14](https://lists.w3.org/Archives/Public/public-css-archive/2022Jun/0306.html), hentet 2026-10-08.
- Lilley i samme innlegg: «Note that the minimum contrasts for small and large text (50 and 40) are different from the thresholds for WCAG 2.1 and for APCA; thresholds are algorithm-specific.» — samme kilde.
- M3-sidens formulering, sitert via Dubai Design System (sekundærkilde, «Accessibility > Contrast in Material»): «Material’s tonal system corresponds to Web color contrast standards as follows: Colors that are at least 40 steps apart in tonal value achieve a contrast ratio of at least 3:1 … at least 50 steps apart … at least 4.5:1». — [designsystem.dubai.ae/foundations/colors](https://designsystem.dubai.ae/foundations/colors), hentet 2026-10-08 (fra en WebFetch-oppsummering; ikke verifisert mot m3.material.io).
- **EGEN BEREGNING (kjør skriptet i vedlegget):** nøyaktig test av regelen med Y fra L*:

### Material-regelen «40 tonar = 3:1, 50 tonar = 4,5:1» (eksakt, Y fra L*)

- Kontrast 3.0:1 krever høyst ΔL* = 38.35 (verst ved lys tone 100.00)
- Kontrast 4.5:1 krever høyst ΔL* = 50.10 (verst ved lys tone 100.00)
- Kontrast 7.0:1 krever høyst ΔL* = 62.16 (verst ved lys tone 100.00)
- Tone 100 mot tone 60: 3.170:1;  tone 40 mot tone 0: 3.250:1
- Tone 100 mot tone 50: 4.484:1;  tone 50 mot tone 0: 4.684:1
- Minste kontrast for ΔL*=40 over hele skalaen: 3.170:1 ved lav tone 60.00
- Minste kontrast for ΔL*=50 over hele skalaen: 4.484:1 ved lav tone 50.00


### Inferences
- Materials regel er en direkte konsekvens av at tone = L* = en monoton funksjon av Y; derfor gjelder den «for ethvert fargepar» uavhengig av kulør, som O’Leary skriver. Det er nettopp denne egenskapen OKLCH L mangler.
- Grensetilfellet er mot hvit (tone 100): 4,5:1 mot hvit krever L* ≤ 49,90 (ikke 50,00); 3:1 krever L* ≤ 61,65 (ikke 60). Dvs. regelen er konservativ for 3:1 (3,17:1 ved tone 60) og marginalt for optimistisk for 4,5:1 (4,484:1 ved tone 50). Et skala-design bør bruke eksakte L*-grenser, ikke avrundede 40/50.

### Gaps
- Offisiell ordlyd på m3.material.io (accessibility/color-contrast eller «how the system works»): ikke hentet fordi sidene krever JavaScript (WebFetch fikk kun sidetittel). Dubai-sitatet bør sjekkes mot originalen.

---

## 3. USWDS «magic number» (grader 0–100 bundet til luminansvinduer)

### Takeaway
USWDS forankrer fargetoken på en 0–100-«grade» der 0 er hvit og 100 er svart, og hver grade er bundet til et *luminansvindu*; forskjellen mellom to grader («magic number») garanterer kontrastnivå (40+ = AA stor tekst, 50+ = AA, 70+ = AAA). Dette er i praksis en L*-lignende forankring i luminans (ikke OKLCH).

### Cited Findings
- «We call the difference in grade between any two colors the magic number.» «A magic number of 40+ results in WCAG 2.0 AA Large Text contrast (example: gray-90 and indigo-warm-50v).» «A magic number of 50+ results in WCAG 2.0 AA contrast or AAA Large Text contrast (example: gray-90 and red-40).» «A magic number of 70+ results in WCAG 2.0 AAA contrast (example: gray-10 and red-80).» «Colors of grade 50 result in Section 508 AA contrast against both pure white (grade 0) and pure black (grade 100).» — [USWDS Color overview](https://designsystem.digital.gov/design-tokens/color/overview/), hentet 2026-10-08.
- «USWDS uses a 100-point scale to communicate a color token's grade, where 0 is pure white and 100 is pure black.» «Each color family has 10 grades, which fall between 5 and 90.» — samme kilde.
- Luminansvinduer per grade (min–maks relativ luminans), slik tabellen står på siden (siden nevner at minste luminans for grade 40 ble endret i 2022, uswds-site#1631): 0: 1,000; 5: 0,850–0,930; 10: 0,750–0,820; 20: 0,500–0,650; 30: 0,350–0,450; 40: 0,225–0,300; 50: 0,175–0,183; 60: 0,100–0,125; 70: 0,050–0,070; 80: 0,020–0,040; 90: 0,005–0,015; 100: 0,000. — samme kilde. (Tabellen ble hentet via WebFetch-oppsummering; grade 50-vinduet er verifisert konsistent: Y = 0,1833 gir nøyaktig 4,5:1 mot hvit og Y = 0,175 gir 4,5:1 mot svart.)

### Inferences — EGEN BEREGNING
### USWDS: luminansvinduer omregnet til CIE L*

| Grad | Y min–maks | L* min–maks | 100−grad | Kontrast mot hvit (min–maks) |
|---:|:--|:--|---:|:--|
| 5 | 0.85–0.93 | 93.9–97.2 | 95 | 1.07–1.17 |
| 10 | 0.75–0.82 | 89.4–92.6 | 90 | 1.21–1.31 |
| 20 | 0.5–0.65 | 76.1–84.5 | 80 | 1.50–1.91 |
| 30 | 0.35–0.45 | 65.7–72.9 | 70 | 2.10–2.63 |
| 40 | 0.225–0.3 | 54.6–61.7 | 60 | 3.00–3.82 |
| 50 | 0.175–0.183 | 48.9–49.9 | 50 | 4.51–4.67 |
| 60 | 0.1–0.125 | 37.8–42.0 | 40 | 6.00–7.00 |
| 70 | 0.05–0.07 | 26.7–31.8 | 30 | 8.75–10.50 |
| 80 | 0.02–0.04 | 15.5–23.7 | 20 | 11.67–15.00 |
| 90 | 0.005–0.015 | 4.5–12.6 | 10 | 16.15–19.09 |

Worst-case kontrast for «magisk tall» (gradpar, vinduer: lys grad g1 med min-Y, mørk grad g2 med maks-Y):

- Magisk tall 40: laveste mulige kontrast 3.00:1 (grad 60 mot 100)
- Magisk tall 50: laveste mulige kontrast 4.23:1 (grad 40 mot 90)
- Magisk tall 70: laveste mulige kontrast 8.00:1 (grad 30 mot 100)


- Grade ≈ 100 − L* innenfor hvert vindu (vinduene dekker omtrent L* = 100 − grade ± 5). USWDS' vinduer er altså *luminansbaserte* og uavhengige av kulørfamilie, som er nøyaktig det en L*/Y-forankring gir.
- Merk: ved å lese vinduene som yttergrenser blir verste mulige kontrast for «50+» 4,23:1 (grade 40 øvre kant mot grade 90), dvs. under 4,5. De faktiske tokenene ligger sannsynligvis innenfor snevrere områder enn vinduene; dette er ikke undersøkt. For 40+ (3,00:1) og 70+ (8,00:1) holder garantien akkurat/romslig.

### Gaps
- Faktiske hex-/luminansverdier for USWDS-tokenene (kun vinduene er hentet), og om «50+ = 4,5:1» holder for alle faktiske par.

---

## 4. Andre publiserte analyser av OKLCH L mot WCAG-kontrast

### Takeaway
Ingen av kildene jeg fant gir en tabell som kvantifiserer avviket; kildene splitter seg i «OKLCH L er monoton i Y og dermed godt nok for å søke» (Verou) og «OKLCH alene er ikke nok, bruk APCA/kontrastberegning» (Evil Martians, Muldoon). Ottosson har aldri hevdet at Oklab L er luminans.

### Cited Findings
- Lea Verou, issue «[css-color-5] color-contrast() with automatic continuous lightness adjustment» (csswg-drafts #5153, 2020-06-02), ordrett: «And before you point out that contrast is relative luminance (Y) based and not lightness based: Yes, I’m aware, but: Two colors with the same RL also have the same L; Y and L increase/decrease together, albeit at different rates. I.e. For any colors C1, C2, if Y1 > Y2 then L1 > L2 and vice versa. So, if there is a lighter/darker color that will pass a given contrast ratio, increasing/decreasing LCH lightness will find it.» (Her L er CIE LCH L*, ikke OKLCH L.) — [W3C public-css-archive 2020-Jun/0085](https://lists.w3.org/Archives/Public/public-css-archive/2020Jun/0085.html), hentet 2026-10-08.
- Andrey Sitnik og Travis Turner, «OKLCH in CSS: why we moved from RGB and HSL» (Evil Martians, 2025-09-17): «“Perceived” means that it has consistent lightness for our eyes, unlike `L` in `hsl()`.» Kodekommentar: «We do not need to detect text color with color-contrast()» fordi «All backgrounds with L≥87% have good contrast with black text.» Changelog 2023-02-05: «“Contrast” was replaced with “lightness”.» og at man bør bruke APCA til å detektere kontrast: «Just OKLCH is not enough.» — [Evil Martians](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl), hentet 2026-10-08 (sitatene via WebFetch-oppsummering).
- Björn Ottosson, «A perceptual color space for image processing» (2020-12-23): mål er at modellen «should predict lightness, chroma and hue well»; L er «perceived lightness»; modellen er tilpasset CAM16-UCS-data («predictions for chroma and lightness are close to those of CAM16-UCS»), ikke utledet fra luminans eller WCAG. — [bottosson.github.io/posts/oklab](https://bottosson.github.io/posts/oklab/), hentet 2026-10-08.
- Chris Lilley (W3C): kontrastterskler er algoritmespesifikke (se §2). Kilde: [W3C 2022-06-14](https://lists.w3.org/Archives/Public/public-css-archive/2022Jun/0306.html).
- APCA-konstanter «0.0.98G-4g» (brukt i beregningene): mainTRC 2.4; sRco/sGco/sBco 0,2126729/0,7151522/0,0721750; normBG 0,56, normTXT 0,57, revTXT 0,62, revBG 0,65; blkThrs 0,022, blkClmp 1,414; scaleBoW = scaleWoB = 1,14; loBoWoffset = loWoBoffset = 0,027; deltaYmin 0,0005; loClip 0,1 — [Myndex/apca-w3, src/apca-w3.js](https://raw.githubusercontent.com/Myndex/apca-w3/master/src/apca-w3.js), hentet 2026-10-08. Selvtest i skriptet gir svart på hvit Lc 106,04 og hvit på svart −107,88.
- Radix Colors: dokumentasjonen sier trinn 11 er «low-contrast text» og trinn 12 «high-contrast text»; jeg fant **ikke** dokumentasjon på hvilke APCA-mål (Lc 60/90) som brukes, og dette bør ikke påstås. — [Radix: composing a palette](https://www.radix-ui.com/colors/docs/palette-composition/composing-a-palette) (kun via søkesammendrag).

### Inferences
- Verous argument gjelder *søk* (monotoni gir at man alltid kan finne en farge som består ved å bevege L). Det stemmer også for OKLCH L, siden Y(L) er monoton ved fast kulør og kroma (sjekket: bisection konvergerer for alle 12 kulører). Men en *fast skala* (samme L-verdi per trinn for alle kulører) gir ikke fast kontrast: det er forskjellen mellom «kan finne» og «er garantert».
- Evil Martians’ kodekommentar «L≥87 % har god kontrast mot svart tekst» holder i praksis (egen beregning): ved OKLCH L = 0,87 er laveste WCAG-kontrast mot svart 13,55:1 over de 12 kulørene (C ≤ 0,12 og maks kroma). Ved lyse nivåer og mørk tekst spiller spredningen liten rolle fordi marginen er stor; problemet ligger i nærheten av 3:1/4,5:1-grensene.

### Gaps
- Chris Lilleys eller Evil Martians’ eventuelle kvantifisering av OKLCH L mot kontrast; Lea Verous nyere skriving om temaet; eksplisitt «APCA vs WCAG»-sammenligning av peer review-kvalitet; Radix’ metode. Søk ga ikke primærkilder.

---

## 5. EGEN BEREGNING: hvilket lyshetsmål har minst spredning over kulører ved fast kontrast?

### Takeaway
**Y og CIE L* er nøyaktige for WCAG 2 per definisjon** (kontrast er en funksjon av Y alene; L* er en monoton funksjon av Y; spredningen over kulører er 0 – tabellene viser 0,00 fordi bisection løser mot Y). OKLCH L avviker: ca. **3 poeng** (0–100-skala) spredning ved C ≤ 0,12, og **5,3–6,0 poeng** ved maks sRGB-kroma. Verst er kulørene rundt magenta/rosa (h 330–0, høyest L) mot grønn/cyan (h 150–180, lavest L). APCA er ikke eksakt for noe av målene; L* har likevel 4–8 ganger mindre spredning enn OKLCH L ved lav kroma, mens ved maks kroma og Lc 90 er OKLCH L litt jevnere (drevet av en metta mørk blå).

### Metode
- sRGB ↔ lineær (stykkevis IEC), OKLab/OKLCH med Ottosson-matrisene (original 2020; CSS Color 4 har marginalt avrundede varianter, uten betydning her), CIE L* (D65, κ/ε-form), WCAG 2: `(Y1+0,05)/(Y2+0,05)` med Y = 0,2126 R + 0,7152 G + 0,0722 B (lineær), APCA 0.0.98G-4g (ren 2,4-gamma, ikke stykkevis).
- 12 kulører h = 0, 30, …, 330 (OKLCH-grader). C = min(0,12; maks C i sRGB-gamut ved gitt L,h) eller C = maks i gamut. Bisection (60 iterasjoner) på OKLCH L for eksakt mål. Gamut = sRGB; Display P3 ville gitt større spredning ved maks kroma. Verdiene er ikke 8-bit-kvantisert.
- Konvensjon i Kolorist (kanonisk lineær utvidet sRGB, gamut-kartlegging i stedet for klipping) er ikke brukt her; her er alle farger i gamut.

### Cited Findings
- (Ingen eksterne kilder i denne delen; alle tall er egne. Se vedlegg for kode.)

### Inferences (resultater)

**Oppsummering av spredning (maks − min over 12 kulører):**

### Oppsummering: spredning over 12 kulører (OKLCH L ×100 vs CIE L*)

| Kromatilstand | Mål | Spredning OKLCH L (×100) | Spredning CIE L* |
|:--|:--|---:|---:|
| C = min(0,12; maks) | WCAG 3:1 mot hvit | 3.0 | 0.00 |
| C = min(0,12; maks) | WCAG 4,5:1 mot hvit | 2.9 | 0.00 |
| C = min(0,12; maks) | WCAG 4,5:1 mot svart | 2.9 | 0.00 |
| C = min(0,12; maks) | APCA tekst på hvit Lc 60 | 3.2 | 0.43 |
| C = min(0,12; maks) | APCA hvit på farge abs(Lc) 60 | 3.3 | 0.44 |
| C = min(0,12; maks) | APCA tekst på hvit Lc 75 | 2.9 | 0.40 |
| C = min(0,12; maks) | APCA hvit på farge abs(Lc) 75 | 3.0 | 0.41 |
| C = min(0,12; maks) | APCA tekst på hvit Lc 90 | 2.8 | 0.73 |
| C = min(0,12; maks) | APCA hvit på farge abs(Lc) 90 | 3.0 | 0.50 |
| C = maks i sRGB-gamut | WCAG 3:1 mot hvit | 6.0 | 0.00 |
| C = maks i sRGB-gamut | WCAG 4,5:1 mot hvit | 5.4 | 0.00 |
| C = maks i sRGB-gamut | WCAG 4,5:1 mot svart | 5.3 | 0.00 |
| C = maks i sRGB-gamut | APCA tekst på hvit Lc 60 | 4.6 | 2.03 |
| C = maks i sRGB-gamut | APCA hvit på farge abs(Lc) 60 | 5.2 | 1.23 |
| C = maks i sRGB-gamut | APCA tekst på hvit Lc 75 | 4.4 | 2.22 |
| C = maks i sRGB-gamut | APCA hvit på farge abs(Lc) 75 | 4.5 | 2.18 |
| C = maks i sRGB-gamut | APCA tekst på hvit Lc 90 | 2.5 | 3.29 |
| C = maks i sRGB-gamut | APCA hvit på farge abs(Lc) 90 | 3.1 | 3.20 |


**Tolkning:**
- WCAG: L* eksakt (0,00). OKLCH L: 2,9–3,0 poeng (C ≤ 0,12) og 5,3–6,0 (maks kroma). Det er ca. **0,03–0,06 i OKLCH L**; til sammenligning er et typisk trinn i en 11-trinns skala ca. 0,08–0,09 i L, så avviket tilsvarer en tredel til to tredeler av et trinn.
- Retning: ved samme kontrast har varme/rosa/magenta kulører *høyere* OKLCH L (h 330/0: 0,6849–0,7097 for 3:1) enn grønn/cyan (h 150–180: 0,6501–0,6545). Dvs. ved *lik* OKLCH L har magenta/rosa lavere Y enn grønn/cyan og dermed *høyere* kontrast mot hvit (ved L = 0,56, C ≤ 0,12: 4,41:1 for h 150 grønn mot 4,97:1 for h 0 rosa; maks kroma: 4,34:1 h 150 mot 5,48:1 h 300). En OKLCH-L-forankret skala ville gitt lilla/rosa-trinn som består AA mot hvit på et trinn der grønt feiler. (Mot svart tekst er retningen motsatt.)
- Fast OKLCH L → kontrastspenn mot hvit (12 kulører):

##### Fast OKLCH L → kontrast mot hvit på tvers av 12 kulører (C = min(0,12; maks))

| OKLCH L | min kontrast | maks kontrast | CIE L* min–maks |
|---:|---:|---:|:--|
| 0.45 | 7.04 | 7.96 | 34.4–37.7 |
| 0.50 | 5.67 | 6.42 | 40.2–43.5 |
| 0.56 | 4.41 | 4.97 | 47.2–50.5 |
| 0.60 | 3.74 | 4.21 | 51.8–55.2 |
| 0.65 | 3.05 | 3.44 | 57.6–61.1 |
| 0.70 | 2.53 | 2.83 | 63.4–66.9 |

##### Samme, men C = maks i gamut

| OKLCH L | min kontrast | maks kontrast | CIE L* min–maks |
|---:|---:|---:|:--|
| 0.45 | 7.02 | 8.67 | 32.1–37.7 |
| 0.50 | 5.63 | 7.02 | 37.8–43.7 |
| 0.56 | 4.34 | 5.48 | 44.5–50.9 |
| 0.60 | 3.67 | 4.60 | 49.3–55.7 |
| 0.65 | 3.00 | 3.79 | 54.7–61.6 |
| 0.70 | 2.47 | 3.14 | 60.3–67.6 |


- Nøytrale grånivåer: for C = 0 er OKLCH L = ∛Y nøyaktig (M₁-radene summerer til 1), mens L* = 116∛Y − 16 (for Y > 0,008856). Derfor har grå samme rangordning og monoton kobling, men ulik skala: L* 50 ↔ OKLCH L 0,569; L* 60 ↔ 0,655. Mellomgrå med lik kontrast mot hvit og svart er L* ≈ 49,4 (Y = 0,1791, ≈ 4,58:1 begge veier).

| CIE L* | OKLCH L (nøytral) | kontrast mot hvit | kontrast mot svart |
|---:|---:|---:|---:|
| 98 | 0.983 | 1.05 | 19.98 |
| 95 | 0.957 | 1.13 | 18.52 |
| 90 | 0.914 | 1.29 | 16.26 |
| 80 | 0.828 | 1.70 | 12.34 |
| 70 | 0.741 | 2.30 | 9.15 |
| 60 | 0.655 | 3.17 | 6.62 |
| 50 | 0.569 | 4.48 | 4.68 |
| 40 | 0.483 | 6.46 | 3.25 |
| 30 | 0.397 | 9.35 | 2.25 |
| 20 | 0.310 | 13.14 | 1.60 |
| 10 | 0.224 | 17.14 | 1.23 |
| 5 | 0.177 | 18.91 | 1.11 |

- **APCA (min–maks OKLCH L og CIE L* som gir akkurat |Lc| 60/75/90, farget tekst på hvit og hvit tekst på farge):**

| Kromatilstand | Mål | OKLCH L min–maks | CIE L* min–maks |
|:--|:--|:--|:--|
| C = min(0,12; maks) | APCA: farget tekst på hvit, Lc 60 | 0.6288–0.6609 | 58.60–59.03 |
| C = min(0,12; maks) | APCA: hvit tekst på fargen, abs(Lc) 60 | 0.6631–0.6960 | 62.65–63.09 |
| C = min(0,12; maks) | APCA: farget tekst på hvit, Lc 75 | 0.5233–0.5525 | 46.08–46.48 |
| C = min(0,12; maks) | APCA: hvit tekst på fargen, abs(Lc) 75 | 0.5637–0.5940 | 50.87–51.28 |
| C = min(0,12; maks) | APCA: farget tekst på hvit, Lc 90 | 0.3948–0.4227 | 30.88–31.61 |
| C = min(0,12; maks) | APCA: hvit tekst på fargen, abs(Lc) 90 | 0.4385–0.4684 | 36.29–36.79 |
| C = maks i gamut | APCA: farget tekst på hvit, Lc 60 | 0.6240–0.6699 | 56.91–58.93 |
| C = maks i gamut | APCA: hvit tekst på fargen, abs(Lc) 60 | 0.6580–0.7104 | 61.76–62.99 |
| C = maks i gamut | APCA: farget tekst på hvit, Lc 75 | 0.5192–0.5629 | 44.21–46.43 |
| C = maks i gamut | APCA: hvit tekst på fargen, abs(Lc) 75 | 0.5593–0.6047 | 49.03–51.21 |
| C = maks i gamut | APCA: farget tekst på hvit, Lc 90 | 0.3948–0.4200 | 28.31–31.61 |
| C = maks i gamut | APCA: hvit tekst på fargen, abs(Lc) 90 | 0.4383–0.4689 | 33.59–36.79 |

  - APCA er polaritetsavhengig: |Lc| 60 krever L* ≈ 58,6–59,0 for farget tekst på hvit, men L* ≈ 62,7–63,1 for hvit tekst på fargen (ca. 4 L*-poeng forskjell). En enkelt lyshetsverdi per trinn kan derfor ikke gi samme Lc i begge retninger; WCAG 2 er symmetrisk.
  - Ved C ≤ 0,12 er L*-spredningen 0,40–0,73 poeng mot 2,8–3,3 for OKLCH L (4–8 ganger mindre). Ved maks kroma er L*-spredningen 1,2–3,3 mot OKLCH L 2,5–5,2; ved Lc 90 er OKLCH L marginalt jevnere (2,5/3,1 mot 3,3/3,2) fordi APCAs 2,4-gamma og mørk-klamping gjør de mest mettede mørke fargene (sterk blå, h 270, #2800DB) til utliggere i L*. Dette siste er min tolkning, ikke testet separat.
  - Lc 75 for farget tekst på hvit gir L* ≈ 46 (strengere enn WCAG 4,5:1 som gir L* ≈ 49,9); Lc 60 gir L* ≈ 59 (strengere enn 3:1 ved L* 61,65).

**Fullstendige tabeller, WCAG 2, C = min(0,12; maks i gamut):**

##### 3:1 mot hvit (C = min(0,12; maks i gamut))

| Kulør h | C brukt | OKLCH L | CIE L* | Y | sRGB hex |
|---:|---:|---:|---:|---:|:--|
| 0 | 0.120 | 0.6849 | 61.65 | 0.3000 | #D57997 |
| 30 | 0.120 | 0.6827 | 61.65 | 0.3000 | #D97B6C |
| 60 | 0.120 | 0.6776 | 61.65 | 0.3000 | #CD8444 |
| 90 | 0.120 | 0.6702 | 61.65 | 0.3000 | #B2912E |
| 120 | 0.120 | 0.6622 | 61.65 | 0.3000 | #8A9D42 |
| 150 | 0.120 | 0.6562 | 61.65 | 0.3000 | #55A569 |
| 180 | 0.119 | 0.6545 | 61.65 | 0.3000 | #00A893 |
| 210 | 0.114 | 0.6584 | 61.65 | 0.3000 | #00A4B8 |
| 240 | 0.120 | 0.6652 | 61.65 | 0.3000 | #439DD6 |
| 270 | 0.120 | 0.6737 | 61.65 | 0.3000 | #7A92E0 |
| 300 | 0.120 | 0.6804 | 61.65 | 0.3000 | #A487D7 |
| 330 | 0.120 | 0.6842 | 61.65 | 0.3000 | #C37DBD |
| **min–maks** | | 0.6545–0.6849 | 61.65–61.65 | 0.3000–0.3000 | |
| **spredning (maks−min)** | | **0.0304** (=3.0 på 0–100-skala) | **0.00** | 0.0000 | |

##### 4,5:1 mot hvit (C = min(0,12; maks i gamut))

| Kulør h | C brukt | OKLCH L | CIE L* | Y | sRGB hex |
|---:|---:|---:|---:|---:|:--|
| 0 | 0.120 | 0.5836 | 49.90 | 0.1833 | #B35A78 |
| 30 | 0.120 | 0.5815 | 49.90 | 0.1833 | #B75C4F |
| 60 | 0.120 | 0.5766 | 49.90 | 0.1833 | #AC6621 |
| 90 | 0.116 | 0.5691 | 49.90 | 0.1833 | #927300 |
| 120 | 0.120 | 0.5612 | 49.90 | 0.1833 | #6C7E1E |
| 150 | 0.120 | 0.5549 | 49.90 | 0.1833 | #34864C |
| 180 | 0.101 | 0.5555 | 49.90 | 0.1833 | #008675 |
| 210 | 0.097 | 0.5587 | 49.90 | 0.1833 | #008393 |
| 240 | 0.120 | 0.5643 | 49.90 | 0.1833 | #1B7DB5 |
| 270 | 0.120 | 0.5729 | 49.90 | 0.1833 | #5D73BF |
| 300 | 0.120 | 0.5795 | 49.90 | 0.1833 | #8568B6 |
| 330 | 0.120 | 0.5830 | 49.90 | 0.1833 | #A25F9D |
| **min–maks** | | 0.5549–0.5836 | 49.90–49.90 | 0.1833–0.1833 | |
| **spredning (maks−min)** | | **0.0287** (=2.9 på 0–100-skala) | **0.00** | 0.0000 | |

##### 4,5:1 mot svart (C = min(0,12; maks i gamut))

| Kulør h | C brukt | OKLCH L | CIE L* | Y | sRGB hex |
|---:|---:|---:|---:|---:|:--|
| 0 | 0.120 | 0.5749 | 48.88 | 0.1750 | #B05876 |
| 30 | 0.120 | 0.5728 | 48.88 | 0.1750 | #B45A4C |
| 60 | 0.120 | 0.5679 | 48.88 | 0.1750 | #A9631E |
| 90 | 0.115 | 0.5604 | 48.88 | 0.1750 | #8F7000 |
| 120 | 0.120 | 0.5525 | 48.88 | 0.1750 | #6A7C1B |
| 150 | 0.120 | 0.5462 | 48.88 | 0.1750 | #328349 |
| 180 | 0.099 | 0.5469 | 48.88 | 0.1750 | #008373 |
| 210 | 0.095 | 0.5501 | 48.88 | 0.1750 | #008090 |
| 240 | 0.120 | 0.5556 | 48.88 | 0.1750 | #177BB2 |
| 270 | 0.120 | 0.5642 | 48.88 | 0.1750 | #5A70BC |
| 300 | 0.120 | 0.5708 | 48.88 | 0.1750 | #8366B3 |
| 330 | 0.120 | 0.5743 | 48.88 | 0.1750 | #A05C9A |
| **min–maks** | | 0.5462–0.5749 | 48.88–48.88 | 0.1750–0.1750 | |
| **spredning (maks−min)** | | **0.0287** (=2.9 på 0–100-skala) | **0.00** | 0.0000 | |


**Fullstendige tabeller, WCAG 2, C = maks i sRGB-gamut:**

##### 3:1 mot hvit (C = maks i sRGB-gamut)

| Kulør h | C brukt | OKLCH L | CIE L* | Y | sRGB hex |
|---:|---:|---:|---:|---:|:--|
| 0 | 0.212 | 0.6972 | 61.65 | 0.3000 | #FF5598 |
| 30 | 0.198 | 0.6923 | 61.65 | 0.3000 | #FF5F4B |
| 60 | 0.160 | 0.6811 | 61.65 | 0.3000 | #DE7C00 |
| 90 | 0.137 | 0.6707 | 61.65 | 0.3000 | #B69000 |
| 120 | 0.157 | 0.6607 | 61.65 | 0.3000 | #879F00 |
| 150 | 0.179 | 0.6501 | 61.65 | 0.3000 | #00AC4F |
| 180 | 0.119 | 0.6545 | 61.65 | 0.3000 | #00A893 |
| 210 | 0.114 | 0.6584 | 61.65 | 0.3000 | #00A4B8 |
| 240 | 0.152 | 0.6649 | 61.65 | 0.3000 | #009DE7 |
| 270 | 0.170 | 0.6772 | 61.65 | 0.3000 | #708EFF |
| 300 | 0.193 | 0.6894 | 61.65 | 0.3000 | #AF79FF |
| 330 | 0.300 | 0.7097 | 61.65 | 0.3000 | #FF2FF7 |
| **min–maks** | | 0.6501–0.7097 | 61.65–61.65 | 0.3000–0.3000 | |
| **spredning (maks−min)** | | **0.0595** (=6.0 på 0–100-skala) | **0.00** | 0.0000 | |

##### 4,5:1 mot hvit (C = maks i sRGB-gamut)

| Kulør h | C brukt | OKLCH L | CIE L* | Y | sRGB hex |
|---:|---:|---:|---:|---:|:--|
| 0 | 0.243 | 0.6002 | 49.90 | 0.1833 | #E7007A |
| 30 | 0.239 | 0.5968 | 49.90 | 0.1833 | #EC1300 |
| 60 | 0.136 | 0.5780 | 49.90 | 0.1833 | #B26300 |
| 90 | 0.116 | 0.5691 | 49.90 | 0.1833 | #927300 |
| 120 | 0.133 | 0.5606 | 49.90 | 0.1833 | #6B7F00 |
| 150 | 0.152 | 0.5517 | 49.90 | 0.1833 | #00893E |
| 180 | 0.101 | 0.5555 | 49.90 | 0.1833 | #008675 |
| 210 | 0.097 | 0.5587 | 49.90 | 0.1833 | #008393 |
| 240 | 0.129 | 0.5642 | 49.90 | 0.1833 | #007EB9 |
| 270 | 0.227 | 0.5835 | 49.90 | 0.1833 | #4B67FF |
| 300 | 0.259 | 0.5997 | 49.90 | 0.1833 | #9C43FF |
| 330 | 0.276 | 0.6055 | 49.90 | 0.1833 | #D300CD |
| **min–maks** | | 0.5517–0.6055 | 49.90–49.90 | 0.1833–0.1833 | |
| **spredning (maks−min)** | | **0.0538** (=5.4 på 0–100-skala) | **0.00** | 0.0000 | |

##### 4,5:1 mot svart (C = maks i sRGB-gamut)

| Kulør h | C brukt | OKLCH L | CIE L* | Y | sRGB hex |
|---:|---:|---:|---:|---:|:--|
| 0 | 0.240 | 0.5910 | 48.88 | 0.1750 | #E20078 |
| 30 | 0.236 | 0.5876 | 48.88 | 0.1750 | #E71200 |
| 60 | 0.133 | 0.5691 | 48.88 | 0.1750 | #AE6000 |
| 90 | 0.115 | 0.5604 | 48.88 | 0.1750 | #8F7000 |
| 120 | 0.131 | 0.5520 | 48.88 | 0.1750 | #697C00 |
| 150 | 0.150 | 0.5432 | 48.88 | 0.1750 | #00863C |
| 180 | 0.099 | 0.5469 | 48.88 | 0.1750 | #008373 |
| 210 | 0.095 | 0.5501 | 48.88 | 0.1750 | #008090 |
| 240 | 0.127 | 0.5556 | 48.88 | 0.1750 | #007BB5 |
| 270 | 0.232 | 0.5756 | 48.88 | 0.1750 | #4963FF |
| 300 | 0.264 | 0.5922 | 48.88 | 0.1750 | #9A3DFF |
| 330 | 0.272 | 0.5962 | 48.88 | 0.1750 | #CF00C9 |
| **min–maks** | | 0.5432–0.5962 | 48.88–48.88 | 0.1750–0.1750 | |
| **spredning (maks−min)** | | **0.0529** (=5.3 på 0–100-skala) | **0.00** | 0.0000 | |


(APCA-tabellene per kulør er utelatt for kompakthet; kjør skriptet for alle 24 tabeller.)

### Gaps
- Display P3/Rec.2020-gamut ikke testet. Kroma-hastighet (hvor raskt C øker mot gamutgrensen i en ekte skala) er ikke modellert; reelle skalaer ligger mellom de to tilstandene (C ≤ 0,12 og maks).
- APCA «font-size/weight»-oppslagstabellen (Bronze) er ikke brukt; kun Lc-verdier.

---

## 6. Konklusjon: hva bør en 50–950-skala forankres på?

### Takeaway
Forankre kontrastbærende steg på **CIE L* (tone) eller relativ luminans Y**, ikke på OKLCH L. L* er nøyaktig for WCAG 2, kommer med en kjent og dokumentert praksis (Material HCT: tone = L*, USWDS: luminansvinduer), og er lineær nok til jevne trinn. Bruk OKLCH/OKLab til kulør, kroma og interpolasjon, og løs per kulør OKLCH L slik at målt L* treffer trinnets mål (gamut-bevisst). For APCA og for kritiske par: kontroller kontrasten direkte, siden ingen lyshetsmåling er eksakt og APCA er polaritetsavhengig.

### Cited Findings
- Se §2 (Material: tone = L*, regel 40/50), §3 (USWDS: grader bundet til luminansvinduer) og §4 (Verou, Evil Martians, Ottosson).

### Inferences
- **Rangering for fast kontrast over kulører** (egen beregning): (1) Y og L* – eksakt for WCAG 2; (2) OKLCH L – ca. 3 poeng avvik ved moderat kroma, 5–6 ved høy; (3) APCA direkte – alltid riktig for APCA, men krever polaritet og par.
- **Anbefalte eksakte L*-grenser (WCAG, Y-koeffisienter 0,2126/0,7152/0,0722):** 3:1 mot hvit ⇒ L* ≤ 61,65; 4,5:1 mot hvit ⇒ L* ≤ 49,90; 4,5:1 mot svart ⇒ L* ≥ 48,88; mellom 49,90 og 48,88 passerer både hvit og svart tekst 4,5:1 bare i et smalt belte (≈ 1 L*-poeng) – i praksis kan ikke ett trinn tåle både hvit og svart 4,5:1 med noen margin. Trinn 500 på L* = 50 feiler akkurat 4,5:1 mot hvit (4,484:1); legg trinn rundt 49 eller lavere hvis hvit tekst på trinnet skal bestå.
- **Kontrast direkte som anker** (WCAG-forhold eller Lc) er overlegent for *par* (tekst/bakgrunn) men dårlig som skalaens koordinat: forholdet er ulineært, avhenger av motparten og (APCA) av polaritet. Bruk det som valideringssteg og som kilde til L*-mål (L* = f(ønsket forhold) ved kjent motpart), ikke som lagringsformat.
- Hvis OKLCH L beholdes som synlig kontroll (kjent for brukere), vis L* som «kontrastlyshet» ved siden av, eller kall den «tone» (Material-begrepet), og la skalaens trinn defineres i tone. Gråtoner: L* → OKLCH L er ∛-sammenhengen over, så de to kan konverteres enkelt.
- Usikkerhet: dette er min tolkning av egne tall og de siterte kildene; Muldoons fulltekst er ikke lest.

### Gaps
- Muldoons faktiske anbefaling (L* vs Y vs noe annet) og hans trinn-til-verdi-tabell.
- Perseptuell jevnhet av L*-trinn over kulører (L* har kjente svakheter, særlig for blå og i mørke områder); kontrasten er eksakt, men «likt lys» i visuell forstand er ikke vist her.

---

## Vedlegg: reproduserbart skript (Python 3, kun standardbibliotek)

Lagres som `lyshet.py` og kjøres med `python3 -I lyshet.py > ut.md`. Kjøretid < 1 s. Skriver alle tabellene over (inkludert 24 kulørtabeller) og selvtester (APCA 106,04 / −107,88).

```python
#!/usr/bin/env python3
"""Lyshet mot kontrast. Kun standardbiblioteket. Kjør: python3 lyshet.py"""
import math

# ---------- sRGB / lineær ----------
def srgb_to_lin(c):
    return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4
def lin_to_srgb(c):
    return 12.92*c if c <= 0.0031308 else 1.055*c**(1/2.4)-0.055

# ---------- OKLab (Ottosson 2020) ----------
def lin_to_oklab(r, g, b):
    l = 0.4122214708*r + 0.5363325363*g + 0.0514459929*b
    m = 0.2119034982*r + 0.6806995451*g + 0.1073969566*b
    s = 0.0883024619*r + 0.2817188376*g + 0.6299787005*b
    l, m, s = (math.copysign(abs(x)**(1/3), x) for x in (l, m, s))
    return (0.2104542553*l + 0.7936177850*m - 0.0040720468*s,
            1.9779984951*l - 2.4285922050*m + 0.4505937099*s,
            0.0259040371*l + 0.7827717662*m - 0.8086757660*s)
def oklab_to_lin(L, a, b):
    l = (L + 0.3963377774*a + 0.2158037573*b)**3
    m = (L - 0.1055613458*a - 0.0638541728*b)**3
    s = (L - 0.0894841775*a - 1.2914855480*b)**3
    return (4.0767416621*l - 3.3077115913*m + 0.2309699292*s,
            -1.2684380046*l + 2.6097574011*m - 0.3413193965*s,
            -0.0041960863*l - 0.7034186147*m + 1.7076147010*s)
def oklch_to_lin(L, C, h):
    hr = math.radians(h)
    return oklab_to_lin(L, C*math.cos(hr), C*math.sin(hr))
EPS = 1e-7
def in_gamut(rgb):
    return all(-EPS <= c <= 1+EPS for c in rgb)
def max_chroma(L, h):
    """Største C som er innenfor sRGB ved gitt L og h (bisection)."""
    if L <= 0 or L >= 1: return 0.0
    lo, hi = 0.0, 0.5
    for _ in range(50):
        mid = (lo+hi)/2
        if in_gamut(oklch_to_lin(L, mid, h)): lo = mid
        else: hi = mid
    return lo
def clamp01(x): return min(1.0, max(0.0, x))

# ---------- Y, CIE L*, WCAG 2 ----------
def Y_of_lin(rgb):
    r, g, b = (clamp01(c) for c in rgb)
    return 0.2126*r + 0.7152*g + 0.0722*b      # WCAG 2.x-koeffisienter
def Y_exact(rgb):                               # CSS Color 4 / sRGB-matrisen
    r, g, b = (clamp01(c) for c in rgb)
    return 0.2126729*r + 0.7151522*g + 0.0721750*b
def Lstar(Y):
    return 116*Y**(1/3)-16 if Y > 216/24389 else Y*24389/27
def Y_of_Lstar(Ls):
    return ((Ls+16)/116)**3 if Ls > 8 else Ls*27/24389
def wcag(Y1, Y2):
    a, b = max(Y1, Y2), min(Y1, Y2)
    return (a+0.05)/(b+0.05)

# ---------- APCA 0.0.98G-4g ----------
def apca_Y(rgb_lin_unused=None, srgb=None):
    r, g, b = (clamp01(c) for c in srgb)
    return 0.2126729*r**2.4 + 0.7151522*g**2.4 + 0.0721750*b**2.4   # ren gamma 2.4, ikke stykkevis
def apca_Lc(Ytxt, Ybg):
    blkThrs, blkClmp = 0.022, 1.414
    normBG, normTXT, revTXT, revBG = 0.56, 0.57, 0.62, 0.65
    scaleBoW = scaleWoB = 1.14
    loBoWoffset = loWoBoffset = 0.027
    deltaYmin, loClip = 0.0005, 0.1
    if Ytxt < blkThrs: Ytxt += (blkThrs-Ytxt)**blkClmp
    if Ybg < blkThrs: Ybg += (blkThrs-Ybg)**blkClmp
    if abs(Ybg-Ytxt) < deltaYmin: return 0.0
    if Ybg > Ytxt:
        s = (Ybg**normBG - Ytxt**normTXT)*scaleBoW
        return 0.0 if s < loClip else (s-loBoWoffset)*100
    s = (Ybg**revBG - Ytxt**revTXT)*scaleWoB
    return 0.0 if s > -loClip else (s+loWoBoffset)*100

# ---------- farge fra (L, C-modus, h) ----------
def color_at(L, h, cap):
    C = max_chroma(L, h) if cap is None else min(cap, max_chroma(L, h))
    lin = oklch_to_lin(L, C, h)
    lin = tuple(clamp01(c) for c in lin)
    srgb = tuple(lin_to_srgb(c) for c in lin)
    return C, lin, srgb

def solve_L(h, cap, f, target, increasing_in_L):
    """Finn OKLCH L slik at f(L)=target (f monoton i L)."""
    lo, hi = 0.001, 0.999
    for _ in range(60):
        mid = (lo+hi)/2
        v = f(mid)
        if (v < target) == increasing_in_L: lo = mid
        else: hi = mid
    return (lo+hi)/2

HUES = list(range(0, 360, 30))

def wcag_vs_white(L, h, cap):  # kontrast mot hvit (synkende i L)
    C, lin, _ = color_at(L, h, cap)
    return wcag(1.0, Y_of_lin(lin))
def wcag_vs_black(L, h, cap):  # kontrast mot svart (stigende i L)
    C, lin, _ = color_at(L, h, cap)
    return wcag(Y_of_lin(lin), 0.0)
def apca_text_on_white(L, h, cap):  # Lc, fargen er tekst på hvit, positiv, synkende i L
    C, lin, srgb = color_at(L, h, cap)
    return apca_Lc(apca_Y(srgb=srgb), 1.0)
def apca_white_on_color(L, h, cap):  # |Lc|, hvit tekst på fargen, synkende i L
    C, lin, srgb = color_at(L, h, cap)
    return abs(apca_Lc(1.0, apca_Y(srgb=srgb)))
def apca_black_on_color(L, h, cap):  # Lc, svart tekst på fargen, stigende i L
    C, lin, srgb = color_at(L, h, cap)
    return apca_Lc(0.0, apca_Y(srgb=srgb))

def stats(xs):
    return min(xs), max(xs), max(xs)-min(xs), (sum(xs)/len(xs))

def table(title, fn, target, increasing, cap, kind="wcag"):
    print(f"\n#### {title}\n")
    print("| Kulør h | C brukt | OKLCH L | CIE L* | Y | sRGB hex |")
    print("|---:|---:|---:|---:|---:|:--|")
    Ls, Lss, Ys = [], [], []
    for h in HUES:
        L = solve_L(h, cap, lambda x: fn(x, h, cap), target, increasing)
        C, lin, srgb = color_at(L, h, cap)
        Y = Y_of_lin(lin) if kind == "wcag" else Y_exact(lin)
        ls = Lstar(Y)
        hexs = "#"+"".join(f"{round(clamp01(c)*255):02X}" for c in srgb)
        Ls.append(L); Lss.append(ls); Ys.append(Y)
        print(f"| {h} | {C:.3f} | {L:.4f} | {ls:.2f} | {Y:.4f} | {hexs} |")
    a = stats(Ls); b = stats(Lss); c = stats(Ys)
    print(f"| **min–maks** | | {a[0]:.4f}–{a[1]:.4f} | {b[0]:.2f}–{b[1]:.2f} | {c[0]:.4f}–{c[1]:.4f} | |")
    print(f"| **spredning (maks−min)** | | **{a[2]:.4f}** (={a[2]*100:.1f} på 0–100-skala) | **{b[2]:.2f}** | {c[2]:.4f} | |")
    return a[2]*100, b[2]

def main():
    # Selvtest
    assert abs(apca_Lc(0.0, 1.0)-106.04) < 0.1, apca_Lc(0.0, 1.0)
    assert abs(apca_Lc(1.0, 0.0)+107.88) < 0.1, apca_Lc(1.0, 0.0)
    print(f"Selvtest APCA: svart på hvit {apca_Lc(0,1):.2f}, hvit på svart {apca_Lc(1,0):.2f}")
    print(f"Selvtest: L*(Y=1)={Lstar(1):.2f}, wcag(1,0)={wcag(1,0):.1f}")
    summary = []
    for capname, cap in (("C = min(0,12, maks i gamut)", 0.12), ("C = maks i sRGB-gamut", None)):
        print(f"\n### WCAG 2 – {capname}")
        for title, fn, tgt, inc in (
            ("3:1 mot hvit", wcag_vs_white, 3.0, False),
            ("4,5:1 mot hvit", wcag_vs_white, 4.5, False),
            ("4,5:1 mot svart", wcag_vs_black, 4.5, True)):
            s = table(f"{title} ({capname})", lambda L, h, c, fn=fn: fn(L, h, c), tgt, inc, cap)
            summary.append((capname, "WCAG "+title, s))
        print(f"\n### APCA 0.0.98G-4g – {capname}")
        for lc in (60, 75, 90):
            s = table(f"APCA: farget tekst på hvit, Lc {lc} ({capname})", apca_text_on_white, lc, False, cap, kind="apca")
            summary.append((capname, f"APCA tekst på hvit Lc {lc}", s))
            s = table(f"APCA: hvit tekst på fargen, |Lc| {lc} ({capname})", apca_white_on_color, lc, False, cap, kind="apca")
            summary.append((capname, f"APCA hvit på farge |Lc| {lc}", s))
    print("\n### Oppsummering: spredning over 12 kulører (OKLCH L ×100 vs CIE L*)\n")
    print("| Kromatilstand | Mål | Spredning OKLCH L (×100) | Spredning CIE L* |\n|:--|:--|---:|---:|")
    for cn, name, (so, sl) in summary:
        print(f"| {cn} | {name} | {so:.1f} | {sl:.2f} |")

    # Fast OKLCH L: hvilken kontrast får du?
    print("\n### Fast OKLCH L → kontrast mot hvit på tvers av 12 kulører (C = min(0,12, maks))\n")
    print("| OKLCH L | min kontrast | maks kontrast | CIE L* min–maks |\n|---:|---:|---:|:--|")
    for L in (0.45, 0.50, 0.56, 0.60, 0.65, 0.70):
        cs, ls = [], []
        for h in HUES:
            C, lin, _ = color_at(L, h, 0.12)
            Y = Y_of_lin(lin); cs.append(wcag(1.0, Y)); ls.append(Lstar(Y))
        print(f"| {L:.2f} | {min(cs):.2f} | {max(cs):.2f} | {min(ls):.1f}–{max(ls):.1f} |")
    print("\n### Samme, men C = maks i gamut\n")
    print("| OKLCH L | min kontrast | maks kontrast | CIE L* min–maks |\n|---:|---:|---:|:--|")
    for L in (0.45, 0.50, 0.56, 0.60, 0.65, 0.70):
        cs, ls = [], []
        for h in HUES:
            C, lin, _ = color_at(L, h, None)
            Y = Y_of_lin(lin); cs.append(wcag(1.0, Y)); ls.append(Lstar(Y))
        print(f"| {L:.2f} | {min(cs):.2f} | {max(cs):.2f} | {min(ls):.1f}–{max(ls):.1f} |")

    # Grå (C=0): OKLCH L mot L*
    print("\n### Nøytrale (C=0): OKLCH L ved gitt CIE L*\n")
    print("| CIE L* | OKLCH L (×100) |\n|---:|---:|")
    for ls in (95, 90, 80, 70, 60, 50, 40, 30, 20, 10):
        Y = Y_of_Lstar(ls); L = Y**(1/3)
        print(f"| {ls} | {L*100:.1f} |")

    # Material-regelen: eksakt minste toneforskjell
    print("\n### Material-regelen «40 tonar = 3:1, 50 tonar = 4,5:1» (eksakt, Y fra L*)\n")
    for ratio in (3.0, 4.5, 7.0):
        worst = 0
        worst_at = None
        t = 0.0
        # for hvert par (tA,tB) finn minste forskjell d slik at kontrast >= ratio; ta maks over posisjon
        for i in range(0, 10001):
            tA = i/100  # lys tone fra 0..100
            YA = Y_of_Lstar(tA)
            # mørk tone tB som gir akkurat ratio: (YA+.05)/(YB+.05)=ratio
            YB = (YA+0.05)/ratio-0.05
            if YB < 0: continue
            d = tA-Lstar(YB)
            if d > worst: worst, worst_at = d, tA
        print(f"- Kontrast {ratio}:1 krever høyst ΔL* = {worst:.2f} (verst ved lys tone {worst_at:.2f})")
    for d in (40, 50):
        print(f"- Tone 100 mot tone {100-d}: {wcag(1.0, Y_of_Lstar(100-d)):.3f}:1;  tone {d} mot tone 0: {wcag(Y_of_Lstar(d), 0):.3f}:1")
    # Verste tilfelle for ΔL*=40 og 50 over hele skalaen
    for d in (40, 50):
        mn = min((wcag(Y_of_Lstar(t+d), Y_of_Lstar(t)), t) for t in [i/100 for i in range(0, 100*(100-d)+1)])
        print(f"- Minste kontrast for ΔL*={d} over hele skalaen: {mn[0]:.3f}:1 ved lav tone {mn[1]:.2f}")

    # USWDS-vinduer
    print("\n### USWDS: luminansvinduer omregnet til CIE L*\n")
    win = {5:(0.850,0.930),10:(0.750,0.820),20:(0.500,0.650),30:(0.350,0.450),40:(0.225,0.300),50:(0.175,0.183),
           60:(0.100,0.125),70:(0.050,0.070),80:(0.020,0.040),90:(0.005,0.015)}
    print("| Grad | Y min–maks | L* min–maks | 100−grad | Kontrast mot hvit (min–maks) |\n|---:|:--|:--|---:|:--|")
    for g, (a, b) in win.items():
        print(f"| {g} | {a}–{b} | {Lstar(a):.1f}–{Lstar(b):.1f} | {100-g} | {wcag(1,b):.2f}–{wcag(1,a):.2f} |")
    print("\nWorst-case kontrast for «magisk tall» (gradpar, vinduer: lys grad g1 med min-Y, mørk grad g2 med maks-Y):\n")
    allw = dict(win); allw[0] = (1.0, 1.0); allw[100] = (0.0, 0.0)
    for mag in (40, 50, 70):
        worst = 9e9; wp = None
        for g1 in allw:
            g2 = g1+mag
            if g2 in allw:
                r = wcag(allw[g1][0], allw[g2][1])
                if r < worst: worst, wp = r, (g1, g2)
        print(f"- Magisk tall {mag}: laveste mulige kontrast {worst:.2f}:1 (grad {wp[0]} mot {wp[1]})")
if __name__ == "__main__":
    main()

```
