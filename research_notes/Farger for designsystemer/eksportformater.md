# Eksportformater for fargetokens: DTCG, Figma, Tokens Studio, Style Dictionary og plattformene (status 2026-10)

Notater samlet 2026-10-08. Kilder er primærdokumentasjon der den fantes; sitater og JSON gjengis i original.

## 1. Hvordan ser et DTCG 2025.10-fargetoken ut, og hvordan uttrykkes lys/mørk modus?

### Takeaway
DTCG 2025.10 (Final Community Group Report, 28. oktober 2025) er den første stabile versjonen. Et fargetoken er `{"$type":"color","$value":{"colorSpace":…,"components":[…],"alpha":…,"hex":"#rrggbb"}}`; `colorSpace` og `components` er påkrevd, `alpha` (standard 1) og `hex` (6-sifret sRGB-fallback) er valgfrie. Lys/mørk uttrykkes ikke i selve tokenfila, men i en egen Resolver-modul (også stabil 2025.10) med `sets`, `modifiers` → `contexts` (`light`/`dark`) og `resolutionOrder`.

### Cited Findings

**Status og versjon**
- Design Tokens Format Module 2025.10 er «Final Community Group Report» publisert 28. oktober 2025 — [designtokens.org/TR/2025.10/format](https://www.designtokens.org/TR/2025.10/format/)
- Kunngjøringen 28. oktober 2025 kaller 2025.10 «first stable version», med referanseimplementasjoner i Style Dictionary, Tokens Studio og Terrazzo, og >10 verktøy som støtter eller implementerer (Penpot, Figma, Sketch, Framer, Knapsack, Supernova, zeroheight). Innholdet omfatter tematisering/multi-brand, Display P3 og Oklch, alias/arv, og kodegenerering for iOS, Android, web og Flutter — [W3C CG-kunngjøring](https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/)
- MIME-type `application/design-tokens+json` (eller `application/json`), filendelse `.tokens` eller `.tokens.json`, UTF-8 — [designtokens.org](https://designtokens.org/) (via søkesammendrag)
- Etter 2025.10 finnes utkast («Draft Community Group Report», datert 8. september 2026) for Format og Resolver, begge merket «Do not attempt to implement this version. Do not reference this version as authoritative in any way.» Utkastet til Format inneholder ingen endringslogg mot 2025.10, og adresserer ikke moduser/temaer — [Format-utkast](https://www.designtokens.org/TR/drafts/format/); [Resolver-utkast](https://www.designtokens.org/TR/drafts/resolver/)
- Gamle `tr.designtokens.org/format/` og `/resolver/` videresender (301) til `www.designtokens.org/TR/drafts/…` — observert ved henting.

**Fargetypen (Color Module 2025.10, Final CG Report 28. oktober 2025)**
- `$value`-objekt: `colorSpace` (string, påkrevd), `components` (array, påkrevd; hvert element tall eller `"none"`), `alpha` (tall 0–1, valgfri, standard 1), `hex` (string, valgfri, 6-sifret CSS-hex). «the fallback color _MUST_ be formatted in 6 digit CSS hex color notation format to avoid conflicts with the provided alpha value.» Spesifikasjonen sier ikke eksplisitt hvordan hex skal gamut-kartlegges — [Color Module 2025.10](https://www.designtokens.org/TR/2025.10/color/)
- 14 fargerom og komponentområder (samme kilde):

  | `colorSpace` | components | områder |
  |---|---|---|
  | `srgb`, `srgb-linear`, `display-p3`, `a98-rgb`, `prophoto-rgb`, `rec2020` | [R, G, B] | 0–1 hver |
  | `hsl` | [H, S, L] | [0–360), 0–100, 0–100 |
  | `hwb` | [H, W, B] | [0–360), 0–100, 0–100 |
  | `lab` | [L, a, b] | 0–100, ubegrenset (typisk −160…160) |
  | `lch` | [L, C, H] | 0–100, 0–∞ (typisk ≤230), [0–360) |
  | `oklab` | [L, a, b] | 0–1, ubegrenset (typisk −0,5…0,5) |
  | `oklch` | [L, C, H] | 0–1, 0–∞ (typisk ≤0,5), [0–360) |
  | `xyz-d65`, `xyz-d50` | [X, Y, Z] | 0–1 |

- `"none"`: «When specifying a color in some color spaces, a value of `0` could be ambiguous.» Nøkkelordet markerer manglende komponent, viktig for kulør-baserte rom ved interpolasjon — [Color Module 2025.10](https://www.designtokens.org/TR/2025.10/color/)
- Eksempler verbatim fra Color Module 2025.10:

```json
{
  "Hot pink": {
    "$type": "color",
    "$value": {
      "colorSpace": "oklch",
      "components": [0.7016, 0.3225, 328.363],
      "alpha": 1,
      "hex": "#ff00ff"
    }
  }
}
```

```json
{
  "Hot pink": {
    "$type": "color",
    "$value": {
      "colorSpace": "display-p3",
      "components": [1, 0, 1],
      "alpha": 1,
      "hex": "#ff00ff"
    }
  }
}
```

```json
{
  "Translucent shadow": {
    "$type": "color",
    "$value": { "colorSpace": "srgb", "components": [0, 0, 0], "alpha": 0.5, "hex": "#000000" }
  }
}
```

```json
{
  "White": {
    "$type": "color",
    "$value": { "colorSpace": "hsl", "components": ["none", 0, 100], "alpha": 1, "hex": "#ffffff" }
  }
}
```

**Alias, grupper, typearv, $extensions, $deprecated, navn (Format Module 2025.10)** — [designtokens.org/TR/2025.10/format](https://www.designtokens.org/TR/2025.10/format/)
- Alias med krøllparentes: `"$value": "{colors.blue}"`. I tillegg JSON Pointer på egenskapsnivå: `"primary": { "$ref": "#/colors/blue/$value" }`.
- Grupper er objekter uten `$value`; `$type` på gruppe arves. Prioritet: tokenets eget `$type` → nærmeste gruppes `$type` → foreldregruppers `$type` → ellers ugyldig token.
- Reservert `$root` lar en gruppe også være et token:

```json
{
  "color": {
    "accent": {
      "$root": { "$type": "color", "$value": { "colorSpace": "srgb", "components": [0.867, 0, 0], "hex": "#dd0000" } },
      "light": { "$value": { "colorSpace": "srgb", "components": [1, 0.133, 0.133] } }
    }
  }
}
```

- `$extensions`: «The optional `$extensions` property is an object where tools _MAY_ add proprietary, user-, team- or vendor-specific data». Nøkler i omvendt domenenotasjon (`"org.example.tool-a": 42`); verktøy må bevare ukjente utvidelser.
- `$deprecated`: `true`, `false` eller streng med begrunnelse («Please use the border style for active buttons instead.»).
- `$description`: fritekst.
- Navneregler: `{`, `}` og `.` er forbudt i token- og gruppenavn; navn kan ikke starte med `$`; navn er case-sensitive.

**Lys/mørk: Resolver Module 2025.10 (stabil)** — [designtokens.org/TR/2025.10/resolver](https://www.designtokens.org/TR/2025.10/resolver/)
- Status: Final Community Group Report, 28. oktober 2025. `$schema`: `https://www.designtokens.org/schemas/2025.10/resolver.json`.
- «A set is a collection of design tokens in DTCG format. A set _MUST_ contain a `sources` array with tokens declared directly, or a reference object pointing to a JSON file containing design tokens, or any combination of the two.» (Inline-tokens er altså tillatt.)
- «A modifier _MUST_ declare a `contexts` map of a `string` value to an array of token sources.» Modifiers «_MAY_ declare a `default` value that _MUST_ match one of the keys in `contexts`.»
- «The `resolutionOrder` key is an array of sets and modifiers ordered to produce the final result of tokens. The order is significant, with tokens later in the array overriding any tokens that came before them, in case of conflict.»
- Eksempel (fra utkastet, samme struktur som 2025.10):

```json
{
  "$schema": "https://www.designtokens.org/schemas/2025.10/resolver.json",
  "sets": {
    "color": { "sources": [ { "$ref": "base/foundation.json" } ] }
  },
  "modifiers": {
    "theme": {
      "contexts": {
        "light": [ { "$ref": "theme/light.json" } ],
        "dark":  [ { "$ref": "theme/dark.json" } ]
      },
      "default": "light"
    }
  },
  "resolutionOrder": [
    { "$ref": "#/sets/color" },
    { "$ref": "#/modifiers/theme" }
  ]
}
```
  Input `{ "theme": "dark" }` legger `theme/dark.json` sist og overstyrer grunnfargene ved konflikt — [Resolver-utkast](https://www.designtokens.org/TR/drafts/resolver/)

### Inferences
- Minimal, maksimalt kompatibel tokenfil for en fargeapp: én `.tokens.json` med `$type: "color"` på gruppenivå, hvert token med `colorSpace` + `components` + `alpha` + `hex`. `hex` er det eneste feltet eldre verktøy (og Figma-import, se spm. 2–3) garantert forstår, så det bør alltid skrives ut (gamut-kartlagt til sRGB, ikke klippet).
- Lys/mørk: én tokenfil per modus (`light.tokens.json`, `dark.tokens.json`) med identiske tokennavn, pluss en `resolver.json` som binder dem. Dette er også eksakt det Figma-import forventer («A new mode is created per file», spm. 3), så én-fil-per-modus er den konvensjonen som dekker både spec og Figma.
- Siden Format-utkastet (sept. 2026) ikke har endringslogg og eksplisitt ikke skal implementeres, bør eksport målrettes 2025.10, ikke utkastene.

### Gaps
- Hva Format- og Resolver-utkastene (8. sept. 2026) faktisk endrer mot 2025.10 fant jeg ikke (ingen endringslogg i dokumentet). Et eget «theming/modes»-forslag utover Resolver-modulen fant jeg ingen spor av; alt tyder på at Resolver *er* tematiseringsmekanismen.
- Spesifikasjonen sier ikke om `hex` skal være gamut-kartlagt eller klippet; valget ligger hos eksportøren.

## 2. Hvilke fargerom må et verktøy sende ut for maksimal kompatibilitet, og hva godtar Figma og Tokens Studio?

### Takeaway
Figma-import godtar kun `srgb` og `hsl` som `colorSpace`, og Tokens Studio lagrer alt som hex (konverterer andre rom til hex). Style Dictionary ≥5.3 og Terrazzo forstår alle 14 DTCG-rom. Praktisk minimum: `srgb`-komponenter + `hex`; valgfritt tilleggsfil/tilleggstoken i `oklch`/`display-p3` for CSS-pipelines.

### Cited Findings
- Figma-import: «Color (supports HSL and sRGB color spaces)»; dimension må være px, duration i sekunder, font family som enkel streng, number (eller boolean via `com.figma.type`), string (ikke-standard DTCG men godtatt) — [Figma Help: Modes for variables](https://help.figma.com/hc/en-us/articles/15343816063383-Modes-for-variables)
- Figmas importeksempler bruker hex-feltet (`"hex": "#E32828"`) — samme kilde.
- Figma internt: filer har fargeprofil sRGB eller Display P3; «all colors are specified in the same color space which will be the color profile of the document»; hex-modellen er standard, 8-sifret `#RRGGBBAA` — [Figma Help: Color models](https://help.figma.com/hc/en-us/articles/360043042113); [Figma Help: Color management](https://help.figma.com/hc/en-us/articles/360039825114)
- Figma REST API lagrer farge som `{ "r": 0.5, "g": 0.5, "b": 0.5, "a": 1 }` (flyttall 0–1) — [Figma REST API: Variables types](https://developers.figma.com/docs/rest-api/variables-types/)
- OKLCH/OKLAB i Figmas fargevelger er fortsatt et ønske i forum (tråd «support oklab and oklch») — [forum.figma.com](https://forum.figma.com/suggest-a-feature-11/support-oklab-and-oklch-8257)
- Tokens Studio: fargeverdier er hex `#ff0000`, `rgb(255, 0, 0)`, `rgba(255, 0, 0, 1)`, ARGB-hex8 `#80FFFF00`, `hsla(120, 50%, 50%, 1)`; «When you create a Color Token using a color space that is `not Hex`, the plugin will resolve the color to the equivalent Hex value». LCH, sRGB, P3 og HSL nevnes bare som rom for *modifikatorer* (Pro) — [docs.tokens.studio: Color](https://docs.tokens.studio/manage-tokens/token-types/color)
- Tokens Studio-referanser i verdier: `rgba({colors.grey.900}, 0.06)` — samme kilde.
- Penpot eksporterer «Tokens Studio format, not DTCG 2025.10» (brukerrapport) — [community.penpot.app](https://community.penpot.app/t/token-export-is-tokens-studio-format-not-dtcg-2025-10/10544)
- Style Dictionary v5.3.0 (9. februar 2025): «All color transformers now support both legacy string format and DTCG object format with `colorSpace`, `components`, `alpha`, and optional `hex` fallback properties»; alle 14 rom støttes; nye transformer `color/oklch`, `color/oklab`, `color/p3`, `color/lch`; «When a DTCG color object includes a `hex` property, it will be used as a fallback when the color is out-of-gamut for sRGB, allowing designers to provide pre-computed sRGB approximations.» — [style-dictionary v5.3.0 release](https://github.com/style-dictionary/style-dictionary/releases/tag/v5.3.0); [CHANGELOG](https://github.com/style-dictionary/style-dictionary/blob/main/CHANGELOG.md)
- Terrazzo (referanseimplementasjon) viser farge som `"$value": { "colorSpace": "srgb", "components": [0.4, 0.2, 0.6] }` og lenker til 2025.10 — [terrazzo.app DTCG](https://terrazzo.app/docs/guides/dtcg/)
- TokensBruecke (Figma-plugin + CLI) eksporterer DTCG 2025.10 og støtter «HEX, RGBA CSS, RGBA Object, DTCG color objects (srgb-dtcg, hsl-dtcg, oklch-dtcg)»; OKLCH importeres til Figma via hex-fallback — [TokensBruecke README](https://cdn.jsdelivr.net/npm/tokens-bruecke@3.15.1/README.md)
- Leonardo (Adobe) sine output-formater: HEX (standard), RGB, HSL, HSV, LAB, LCH, CAM02, CAM02p; interpolasjonsrom LCH, LAB, CAM02, HSL, HSLuv, HSV, RGB. OKLab/OKLCH og P3 er ikke nevnt i README — [adobe/leonardo contrast-colors README](https://github.com/adobe/leonardo/blob/main/packages/contrast-colors/README.md)

### Inferences
- Eneste fargerom som fungerer *overalt* (Figma-import, Tokens Studio, SD v4, Leonardo-stil verktøy) er `srgb` + `hex`. Eksporter derfor primært `colorSpace: "srgb"` med `hex`, og tilby OKLCH/P3 som alternativ eksportvariant (eller samme token i `oklch` for pipelines som vil bevare vid gamut via SD ≥5.3 / Terrazzo).
- Figma-filer i Display P3-profil tolker hex som P3-komponenter; når en fargeapp vet at brukerens Figma-fil er P3, kan den altså eksportere `display-p3`-komponentene som hex, men DTCG-import godtar ikke `colorSpace: "display-p3"` — så P3 til Figma går i praksis bare via REST/plugin-API med `{r,g,b,a}` i dokumentets profil.
- Alfa bør ligge i `alpha`-feltet; Tokens Studio foretrekker `rgba()`-strenger i eget format, men konverterer.

### Gaps
- Om Figma-import leser `components` når `hex` mangler, eller alltid krever `hex`, er ikke dokumentert i det jeg fant.
- Om Tokens Studios DTCG-modus (2026) skriver `$value` som objekt (`colorSpace`/`components`) eller fortsatt som hex-streng, er ikke dokumentert på fargesiden; dokumentasjonen anbefaler fortsatt SD-Transforms for å «align Tokens Studio-specific types with DTCG format types».

## 3. Hvordan fungerer Figmas variabelimport i 2025–2026?

### Takeaway
Figma har nå innebygd DTCG-JSON-import/eksport i Variables-panelet (dra-og-slipp fil → ny samling med én modus per fil; høyreklikk modus → «Import mode»/«Export mode»; samling → «Export modes»), kunngjort på Schema 2025 og utrullet gradvis desember 2025. REST-API-et (Enterprise, `file_variables:read/write`) bruker eget JSON-format med `valuesByMode` og `{r,g,b,a}`. Plugins (Tokens Studio, TokensBruecke, Variables Import m.fl.) dekker eldre planer og rikere format.

### Cited Findings
- «Design tokens must be in a JSON file and follow the Design Tokens Community Group (DTCG) format.» Ny samling: dra-og-slipp filer inn i Variables-visningen; «A new mode is created per file, and variables are only imported if they're present in all files with matching types.» Eksisterende modus: høyreklikk modus → «Import mode» (oppdaterer variabler med samme tokennavn og type). Eksport: høyreklikk modus → «Export mode»; høyreklikk samling → «Export modes» — [Figma Help: Modes for variables](https://help.figma.com/hc/en-us/articles/15343816063383-Modes-for-variables)
- Navnenormalisering: nøstede grupper blir skråstrek-stier, `color.accent.light` → `color/accent/light`; duplikater etter normalisering → bare første importeres — samme kilde.
- Kryss-samling-alias via utvidelsen `com.figma.aliasData` med `targetVariableID` og `targetVariableName` — samme kilde.
- Kunngjort på Figma Schema 2025 («extended variable collections and native variable export/import conforming with the DTCG token specification»); utrulling forsinket, fortsatt ufullstendig tidlig desember 2025; Figma Community Support: «keep refreshing your tabs» — [forum.figma.com: native variable export](https://forum.figma.com/ask-the-community-7/native-variable-export-feature-47831)
- Brukerrapport: eksporten inkluderer ikke `$description` selv om feltet finnes i Figmas Details-panel — [forum.figma.com](https://forum.figma.com/ask-the-community-7/native-variable-export-feature-47831) (via søkesammendrag; ikke bekreftet av Figma)
- REST API: GET local variables, GET published variables, POST variables; krever Enterprise-organisasjon (gjester utestengt), full seat/admin for skriving; scopes `file_variables:read` / `file_variables:write`; variabler må publiseres etter oppdatering før bruk i andre filer — [Figma REST API: Variables](https://developers.figma.com/docs/rest-api/variables/)
- Typer (verbatim-struktur):

```json
{ "type": "VARIABLE_ALIAS", "id": "variableId" }
```
```json
{
  "id": "string", "name": "string", "key": "string",
  "variableCollectionId": "string",
  "resolvedType": "COLOR|FLOAT|STRING|BOOLEAN",
  "valuesByMode": { "modeId": "value" },
  "description": "string",
  "scopes": ["ALL_SCOPES"],
  "codeSyntax": { "WEB": "varName", "ANDROID": "varName", "iOS": "varName" }
}
```
  Samling: `modes` (`modeId` → navn), `defaultModeId`, `variableIds`, pluss felt for utvidede samlinger (`isExtension`, `parentVariableCollectionId`, `inheritedVariableIds`) — [Figma REST API: Variables types](https://developers.figma.com/docs/rest-api/variables-types/)
- POST-body: fire arrays `variableCollections`, `variableModes`, `variables`, `variableModeValues` med `action: CREATE|UPDATE|DELETE`, midlertidige id-er for kryssreferanser i samme kall, fargeverdi `{ "r": 1, "g": 0, "b": 0, "a": 1 }`; maks 4 MB; Tier 3-ratebegrensning — [Figma REST API: Variables endpoints](https://developers.figma.com/docs/rest-api/variables-endpoints/)
- Plugins: «Figma Variables Import» (davo) importerer DTCG → variabler — [github.com/davo/figma-variables-import](https://github.com/davo/figma-variables-import); «figma-variable-import» (firefoxux) — [github.com/firefoxux/figma-variable-import](https://github.com/firefoxux/figma-variable-import); TokensBruecke eksporterer/importerer DTCG 2025.10 — [TokensBruecke](https://cdn.jsdelivr.net/npm/tokens-bruecke@3.15.1/README.md); Terrazzo har egen guide for import fra Figma — [terrazzo.app](https://terrazzo.app/docs/guides/import-from-figma)
- Tokens Studio: temagrupper blir Figma-samlinger, temavalg blir moduser — [documentation.tokens.studio: Themes](https://documentation.tokens.studio/platform/themes)

### Inferences
- For en fargeapp er «én DTCG-fil per modus med samme tokennavn» den enkleste veien inn i Figma uten API-nøkler eller Enterprise. Sluttbrukeren drar filene inn; Figma lager samlingen med lys/mørk-moduser.
- Tokennavn med `.` i Figma-import er umulig (DTCG forbyr), og `/` i navn blir gruppeseparator i Figma; apper bør unngå `/` i egne navn.
- REST-API-eksport er lite aktuelt for en forbrukerapp (Enterprise-krav); plugin- eller filbasert flyt er realistisk.

### Gaps
- Fant ikke Figmas offisielle, fullstendige JSON-eksempel for eksport (hvilke `$extensions` som skrives, f.eks. scopes/codeSyntax). Hjelpesiden for «Import and export variables» ble ikke funnet som egen URL; innholdet ligger i «Modes for variables»-artikkelen.
- Plankrav for innebygd DTCG-import (alle planer, eller bare Professional+?) er ikke dokumentert i det jeg fant.

## 4. Hva trenger Style Dictionary i JSON for CSS, Swift og Android, og hvordan håndteres moduser?

### Takeaway
Style Dictionary (v4 siden 2024, v5.x; siste 5.6.0) leser DTCG `$value`/`$type` direkte, og fra 5.3.0 fargeobjekter i alle 14 rom. Formatene `css/variables`, `ios-swift/class.swift`/`enum.swift`, `android/colors`, `compose/object` krever bare `$type: "color"` og en transform-gruppe. Moduser finnes ikke i SD-kjernen; de løses ved å bygge flere plattformer/kilde-sett (f.eks. Tokens Studios `permutateThemes`).

### Cited Findings
- DTCG-støtte «as of version 4»; «the latest format 2025.10 does not have full support yet in Style Dictionary» — «a work in progress in v5». Konverteringsverktøy flytter `value/type/description` → `$value/$type/$description` og gruppe-`$type` ned på tokens, men endrer ikke typeverdier (`size` → `dimension`) — [styledictionary.com/info/dtcg](https://styledictionary.com/info/dtcg/)
- Endringslogg: 5.3.0 fargeobjekter (14 rom, hex-fallback ved sRGB-utenfor-gamut, nye `color/oklch|oklab|p3|lch`); 5.4.0 DTCG 2025.10 dimension-objekt; siste versjon 5.6.0. Endringsloggen nevner ikke `$ref`/JSON Pointer, Resolver-modulen, `$deprecated` eller moduser — [CHANGELOG.md](https://github.com/style-dictionary/style-dictionary/blob/main/CHANGELOG.md); [v5.3.0](https://github.com/style-dictionary/style-dictionary/releases/tag/v5.3.0)
- Fargetransformer (alle matcher `token.type === 'color'`): `color/hex` (`#009688`), `color/hex8android` (`#ff009688`, alfa først), `color/rgb`, `color/hsl`, `color/hsl-4`, `color/css` (hex eller rgba avhengig av alfa), `color/UIColorSwift` (`UIColor(red: 0.667, …)`), `color/ColorSwiftUI` (`Color(red: 0.667, …)`), `color/composeColor` (`Color(0xFF009688)`), `color/hex8flutter` — [Predefined transforms](https://styledictionary.com/reference/hooks/transforms/predefined/)
- Formater med eksempelutdata — [Predefined formats](https://styledictionary.com/reference/hooks/formats/predefined/):

```css
:root {
  --color-background-base: #f0f0f0;
  --color-background-alt: #eeeeee;
}
```
  (`css/variables`, opsjoner `outputReferences`, `selector`, `sort`)

```swift
public enum StyleDictionary {
  public static let colorBackgroundDanger =
    UIColor(red: 1.000, green: 0.918, blue: 0.914, alpha: 1)
}
```
  (`ios-swift/enum.swift`; `class.swift` tilsvarende, standard `public` og `import UIKit`)

```xml
<resources>
  <color name="color_base_red_5">#fffaf3f2</color>
</resources>
```
  (`android/colors`, `android/resources`)

```kotlin
import androidx.compose.ui.graphics.Color
object StyleDictionary {
  val colorBaseRed5 = Color(0xFFFAF3F2)
}
```
  (`compose/object`)

- Tokens Studio SD-Transforms (krever SD ≥4.0.0, ESM-only): `register(StyleDictionary)` gir transform-gruppe og preprocessor `'tokens-studio'`; preprocessoren mapper Tokens Studio-typer til DTCG-typer og bevarer original i `$extensions['studio.tokens'].originalType`; `permutateThemes(themeData, { separator: '_' })` lager alle kombinasjoner fra `$themes.json` (`light_casual`, `dark_business` …); `ts/color/modifiers` med `format: 'hex' | 'hsl' | 'lch' | 'p3' | 'srgb'` — [sd-transforms README](https://github.com/tokens-studio/sd-transforms); [raw README](https://raw.githubusercontent.com/tokens-studio/sd-transforms/main/README.md)

```js
const sd = new StyleDictionary({
  source: ['tokens/**/*.json'],
  preprocessors: ['tokens-studio'],
  platforms: {
    css: {
      transformGroup: 'tokens-studio',
      transforms: ['name/kebab'],
      buildPath: 'build/css/',
      files: [{ destination: 'variables.css', format: 'css/variables' }],
    },
  },
});
```

- Tokens Studio `$themes.json` (verbatim fra sd-transforms README):

```json
[
  { "name": "light", "group": "mode",
    "selectedTokenSets": { "core": "source", "light": "enabled", "theme": "enabled" } },
  { "name": "dark", "group": "mode",
    "selectedTokenSets": { "core": "source", "dark": "enabled", "theme": "enabled" } },
  { "name": "casual", "group": "brand",
    "selectedTokenSets": { "core": "source", "casual": "enabled" } }
]
```
  og `$metadata.json` med `tokenSetOrder: ["primitives/Value", "semantic/light", "semantic/dark"]` — [documentation.tokens.studio](https://documentation.tokens.studio/platform/themes) (via søkesammendrag); temagrupper → Figma-samlinger, temavalg → moduser — [samme](https://documentation.tokens.studio/platform/themes)
- Tokens Studio-format vs DTCG: Tokens Studio bruker «multi-set envelope» der hver toppnøkkel er et sett-navn, pluss `$themes` og `$metadata`; DTCG definerer én flat tokenfil. Legacy-format uten `$`; DTCG-modus med `$value/$type/$description`; `{ } $` forbudt i navn i DTCG-modus; formatbytte konverterer filene (ny gren ved Git-synk) — [docs.tokens.studio: Token format](https://docs.tokens.studio/manage-settings/token-format)

### Inferences
- Minimum for SD: én DTCG-fil med `$type: "color"` på gruppa og `$value` enten som hex-streng (v4+) eller fargeobjekt (≥5.3). Med `hex` i objektet får eldre pipelines riktig sRGB.
- Moduser i SD: enten (a) to kjøringer med `source: ['core.json','light.json']` og `['core.json','dark.json']`, eller (b) Tokens Studio-sett + `$themes.json` + `permutateThemes`. Eksporterer appen én fil per modus, dekkes (a) direkte, og Tokens Studio-brukere kan selv skrive `$themes.json`.
- SD-utdata for Swift er UIKit/SwiftUI-literaler, ikke asset catalog; lys/mørk i Swift må dermed løses med egne `light`/`dark`-konstanter eller ved å generere `.colorset` selv (se spm. 6).

### Gaps
- SD har ingen innebygd støtte for Resolver-modulen eller `$ref`; status for «full 2025.10-støtte» i v5 er uklar utover endringsloggen.
- Om SD ≥5.3 gamut-kartlegger eller klipper OKLCH→hex når `hex` mangler, står ikke i notatene jeg fant.

## 5. Hva eksporterer etablerte fargesystemverktøy (Material Theme Builder, Leonardo, Radix)?

### Takeaway
De-facto «bunten» brukere forventer: CSS custom properties (lys + mørk), JS/TS-objekt, Android Compose (`Color.kt`/`Theme.kt`) eller XML, og et tokens-JSON (Material: eget Material Theme JSON pluss DTCG; Leonardo: W3C-tokens). P3-varianter leveres bare av Radix (CSS `color(display-p3 …)`-filer).

### Cited Findings
- Material Theme Builder: eksportformater «Material Theme JSON, DTCG tokens, Figma plugin, Android Compose Color.kt/Theme.kt, Android XML, CSS, Flutter» — [material-theme-builder README](https://raw.githubusercontent.com/material-foundation/material-theme-builder/main/README.md); «Select the Material Theme (JSON) option»; eksporterer «theming code for Material 3 libraries on Android Views and Jetpack Compose»; i Figma genereres tokens som Figma-stiler; skriftendringer påvirker ikke JSON-eksport — [m3.material.io blog](https://m3.material.io/blog/material-theme-builder) (via søkesammendrag). `m3.material.io/theme-builder` videresender nå (301) til `material-foundation.github.io/material-theme-builder/`.
- Android-dokumentasjonen viser Material Theme Builder-eksporten `Color.kt`:

```kotlin
val md_theme_light_primary = Color(0xFF476810)
val md_theme_light_onPrimary = Color(0xFFFFFFFF)
val md_theme_dark_primary = Color(0xFFACD370)
```
  og `lightColorScheme(primary = md_theme_light_primary, …)` / `darkColorScheme(...)` — [developer.android.com: Material 3 in Compose](https://developer.android.com/develop/ui/compose/designsystems/material3)
- Leonardo: «CSS Custom Properties», «JavaScript/NPM Module» (`@adobe/leonardo-contrast-colors`), «Design Tokens (JSON)» etter «w3c working spec», SVG — [leonardocolor.io](https://leonardocolor.io/); `contrastColors`-utdata: `{name: 'colorName', values: [{name: 'colorName100', contrast: ratio, value: '#hexcode'}]}` pluss `{background: '#hexcode'}` — [leonardo README](https://github.com/adobe/leonardo/blob/main/packages/contrast-colors/README.md)
- Radix Colors 3.0.0: `npm install @radix-ui/colors`; separate CSS-filer per skala og modus (`blue.css`, `blue-dark.css`, alpha- og P3-varianter) — [Installation](https://www.radix-ui.com/colors/docs/overview/installation); variabelnavn `--blue-1` … `--blue-12`, alfa `--blue-a1` …; lyse skalaer på `:root`, `.light`, `.light-theme`, mørke på `.dark`, `.dark-theme`; JS-objekter `blue.blue1`, `blueDark`, `blueA` — [Usage](https://www.radix-ui.com/colors/docs/overview/usage)

### Inferences
- En «komplett» eksport for en palettapp som skal konkurrere med dette: `tokens.json` (DTCG 2025.10), `tokens.css` (`:root` + `@media (prefers-color-scheme: dark)` eller `light-dark()`), `Colors.swift` (eller `.xcassets`-mappe), `Color.kt`, evt. `colors.xml`, ASE for Adobe. Kolorist har allerede ASE, CSS, DTCG, GPL, SwiftUI i FargeKjerne (prosjektets CLAUDE.md) — mangler er Android/Compose, asset catalog og modus-bevisst CSS.
- Radix' 12-trinns skala + alfa + P3 er den mest avanserte CSS-leveransen; P3 via `@supports (color: color(display-p3 1 1 1))` og `color(display-p3 r g b)` er mønsteret å følge for vid-gamut-eksport.

### Gaps
- Material Theme Builders DTCG-eksport: jeg fant ikke eksempel på filinnhold (om den bruker 2025.10-fargeobjekter eller hex). README nevner bare formatnavnet.
- Radix' P3-CSS-snutter ble ikke hentet verbatim (usage-siden ga ikke P3-eksempel i sammendraget).

## 6. Hvordan konsumerer CSS, SwiftUI/asset catalog og Compose tokens?

### Takeaway
CSS: `oklch()`/`color()` i custom properties, `color-mix(in oklab …)` (Baseline mai 2023) og `light-dark(a, b)` med `color-scheme: light dark` (Baseline mai 2024). SwiftUI: `.colorset` i asset catalog med `appearances` (`luminosity: dark`, `contrast: high`), `color-space` `srgb`/`display-p3`/`extended-srgb`, og Xcode 15+ genererer `Color(.navn)`. Compose: `Color(0xAARRGGBB)` i `lightColorScheme`/`darkColorScheme`, valgt med `isSystemInDarkTheme()`.

### Cited Findings
- `light-dark()`: «Two `<color>` values: First for light scheme, second for dark scheme»; krever `color-scheme` («Typically set on `:root`»); Baseline 2024, nyt tilgjengelig siden mai 2024 — [MDN light-dark()](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/light-dark)

```css
:root {
  color-scheme: light dark;
  --light-bg: ghostwhite;
  --dark-bg: darkslategray;
}
* { background-color: light-dark(var(--light-bg), var(--dark-bg)); }
```

- `color-mix(in <color-space>, <color> [<percentage>]?, <color> [<percentage>]?)`; standard interpolasjonsrom `oklab`; rektangulære rom `srgb, srgb-linear, display-p3, a98-rgb, prophoto-rgb, rec2020, lab, oklab, xyz, xyz-d50, xyz-d65`, polare `hsl, hwb, lch, oklch`; kulørmetoder `shorter|longer|increasing|decreasing hue`; Baseline «Widely available» siden mai 2023. Eksempel: `background-color: color-mix(in srgb, var(--base) 25%, transparent);` — [MDN color-mix()](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/color-mix)
- OKLCH i CSS: nativt siden 2023, tilgjengelig i alle moderne nettlesere — [MDN oklch()](https://developer.mozilla.org/docs/Web/CSS/color_value/oklch) (via søkesammendrag)
- Asset catalog `.colorset/Contents.json` (Apples arkiverte referanse): `colors`-array der hvert element er én variant med `idiom`, `display-gamut` (`sRGB`/`display-P3`) og `color` med `color-space` (`srgb | display-p3 | extended-srgb | extended-linear-srgb | gray-gamma-22`) og `components` (`red`, `green`, `blue`, `alpha`); `info` med `author` og `version: 1` — [Asset Catalog Format: Named Color](https://developer.apple.com/library/content/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/Named_Color.html). Den arkiverte referansen mangler `appearances`; Xcode-generert fil i dette prosjektet viser dagens form (komponenter som strenger, hex `"0xA8"` eller desimal `"1.000"`):

```json
{
  "colors": [
    { "color": { "color-space": "srgb",
        "components": { "red": "0xA8", "green": "0x4F", "blue": "0x00", "alpha": "1.000" } },
      "idiom": "universal" },
    { "appearances": [ { "appearance": "luminosity", "value": "dark" } ],
      "color": { "color-space": "srgb",
        "components": { "red": "0xFF", "green": "0xA2", "blue": "0x3A", "alpha": "1.000" } },
      "idiom": "universal" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```
  — [Kolorist/Assets.xcassets/Advarsel.colorset/Contents.json](/Users/eivind_ntnu/App-utvikling/Kolorist/Kolorist/Assets.xcassets/Advarsel.colorset/Contents.json) (lokal, Xcode-generert)
- Xcode 15: «Xcode automatically generates static properties corresponding to our assets on new `ColorResource` and `ImageResource` types»; bruk `Color(.myGreen)`; byggsetting `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` gir også `Color.myGreen`; virker med eldre deployment targets — [nilcoalescing.com: Xcode 15 assets](https://nilcoalescing.com/blog/Xcode15Assets); generert kode i `GeneratedAssetSymbols.swift` — [sarunw.com](https://sarunw.com/posts/swift-symbols-for-asset-catalog/)
- Compose: `lightColorScheme(...)`/`darkColorScheme(...)`, `isSystemInDarkTheme()`, dynamisk farge på Android 12+ med `dynamicLightColorScheme(LocalContext.current)` — [developer.android.com: Material 3](https://developer.android.com/develop/ui/compose/designsystems/material3)

```kotlin
@Composable
fun ReplyTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val colorScheme = if (!darkTheme) LightColorScheme else DarkColorScheme
    MaterialTheme(colorScheme = colorScheme, content = content)
}
```

### Inferences
- For SwiftUI er en eksportert `.xcassets`-mappe (én `.colorset` per token, med `display-p3`-komponenter når fargen er utenfor sRGB, og `luminosity: dark`-variant) den mest «native» leveransen; den gir `Color(.navn)` gratis i Xcode 15+. Et SwiftUI-`extension Color` med `Color(red:green:blue:)` (som SD lager) mister P3 og lys/mørk; `Color(.displayP3, red:…)` kan brukes for P3 i kode.
- For CSS bør eksporten skrive `--token: #hex;` med `@supports`-blokk eller direkte `oklch()`/`color(display-p3 …)` når brukeren velger vid gamut, og lys/mørk som `light-dark()` (krever `color-scheme`) eller `prefers-color-scheme`-media-query som fallback for eldre nettlesere.
- Compose-eksport er triviell: `val navn = Color(0xAARRGGBB)` i to `object`/skjema-sett; P3 krever `Color(r,g,b,a, ColorSpaces.DisplayP3)`, som ikke er standard i SD-utdata.

### Gaps
- Fant ingen offisiell Apple-side (ny dokumentasjon) som beskriver `appearances`/`contrast: high` i `Contents.json`; kilden er Xcode-generert fil + arkivert referanse. `developer.apple.com/documentation/xcode/asset-management` og `supporting-dark-mode-in-your-interface` ga 404/tomt innhold ved henting.
- Compose-støtte for Display P3 i `Color` ble ikke undersøkt mot primærkilde.

## 7. Finnes anbefalte navnekonvensjoner for fargetokens?

### Takeaway
Ingen navnekonvensjon er del av DTCG-spesifikasjonen (den regulerer bare forbudte tegn). Bransjekonsensus er tre lag — primitiver (`blue.500`), semantiske (`color.text.primary`, `color.bg.*`, `color.border.*`) og komponent (`button.primary.background`) — med segmentrekkefølge kategori → rolle/egenskap → variant → tilstand.

### Cited Findings
- Tre lag: primitiver («raw values, context-free like blue-500»), semantiske («color-primary»), komponent («button-bg») — [alwaystwisted.com: Design token naming conventions](https://www.alwaystwisted.com/articles/design-token-naming-conventions) (artikkel datert 23. april 2026)
- Anbefalte segmenter i rekkefølge: Category (`color`) → Property/Role (`text`, `background`, `border`, `surface`) → Variant (`primary`, `secondary`, `danger`) → State (`hover`, `active`, `disabled`, `focus`); eksempler `color.text.error`, `color.button.primary.hover`; «A name like `color-text-red` describes a visual value...A name like `color-text-error` describes intent, which stays stable.» — samme kilde
- Alternativ konvensjon `--color-{name}-{part}[-{state}]` med `bg` (mettet fyll for knapper/badges), `fg` (tekst/ikon på flaten), `border`, `surface` (bakgrunnsfyll) — [dxos ui-theme DESIGN_SYSTEM.md](https://cdn.jsdelivr.net/npm/@dxos/ui-theme@0.9.0/src/css/DESIGN_SYSTEM.md)
- Primitiv-mønster `$[type]-[hue]-[tone]` (`$color-blue-10`), semantiske typer `$fg`, `$bg`, `$border` — [VTEX Shoreline: Color best practices](https://shoreline.vtex.com/foundations/color/best-practices)
- DTCG: navn kan ikke inneholde `{ } .` og ikke starte med `$`; case-sensitive — [Format 2025.10](https://www.designtokens.org/TR/2025.10/format/)
- Figma-eksport av Material Theme Builder bruker `md_theme_light_primary` / `md_theme_dark_primary` (modus i navnet) — [developer.android.com](https://developer.android.com/develop/ui/compose/designsystems/material3); Radix bruker `{farge}-{1..12}` og `{farge}-a{1..12}` — [radix-ui.com](https://www.radix-ui.com/colors/docs/overview/usage)
- Figma normaliserer DTCG-grupper til `/`-stier (`color/accent/light`) — [Figma Help](https://help.figma.com/hc/en-us/articles/15343816063383-Modes-for-variables)

### Inferences
- For en palettapp som eksporterer en brukerlaget palett: la brukeren velge mellom «primitiv» navngiving (`color.{palettnavn}.{trinn}` f.eks. `color.brand.500`) og «semantisk» (`color.bg.primary`, `color.fg.primary`, `color.border.default`), og hold modus *utenfor* navnet (egen fil/modus) — det er både DTCG-Resolver- og Figma-modus-modellen. Materials `md_theme_light_*` med modus i navnet er den gamle, Compose-spesifikke stilen.
- Toneskala-trinn 50/100…900 (Material/Tailwind) eller 1–12 (Radix) er begge etablert; DTCG krever at trinnene er gruppenøkler uten punktum (`"500"` er gyldig nøkkel).

### Gaps
- Fant ingen offisiell konvensjon fra DTCG, Figma eller Tokens Studio; alt er praksisartikler. Brad Frosts «design tokens/colors»-side ga 404 ved henting.
