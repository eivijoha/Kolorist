import Foundation

/// README.md for en eksportert designsystem-mappe: rollene, fargene per modus, hva hver farge er til, kontrollen av
/// kontrasten og hvordan filene brukes. På appens språk.
extension DesignsystemEksport {
    static func readme(_ ds: Designsystem, _ temaer: [Designtema], formater: Set<Format>, navn: String, dato: Date,
                       avsender: Avsender) -> String {
        func t(_ s: String.LocalizationValue) -> String { String(localized: s, bundle: .module) }
        let tittel = navn.isEmpty ? t("Designsystem") : navn
        var l: [String] = []

        l.append("# \(String(localized: "\(tittel) – designsystem", bundle: .module))")
        l.append("")
        let app = avsender.lenke.map { "[\(avsender.app)](\($0.absoluteString))" } ?? avsender.app
        let dag = dato.formatted(date: .long, time: .omitted)
        if let utvikler = avsender.utvikler {
            l.append(String(localized: "Laget med \(app) av \(utvikler), \(dag), fra en palett.", bundle: .module))
        } else {
            l.append(String(localized: "Laget med \(app), \(dag), fra en palett.", bundle: .module))
        }
        l.append(t("Fargene er i sRGB, som alle skjermer og Figma forstår, og som WCAG-kontrasten regnes i."))
        if formater.contains(.css) {
            l.append(t("CSS-fila har i tillegg Display P3 der fargene går utenfor sRGB."))
        }
        l.append("")

        // Roller
        l.append("## \(t("Roller"))")
        l.append("")
        l.append(t("Hver rolle har én grunnfarge. Fargene i hver modus er utledet fra den: grunnfargen brukes uendret der den holder kravene, ellers får den samme kulør med lysheten (CIE L*) som trengs."))
        l.append("")
        l.append("| \(t("Rolle")) | \(t("Grunnfarge")) | \(t("Brukes til")) |")
        l.append("|---|---|---|")
        for rolle in Designrolle.allCases {
            l.append("| \(rolle.readmeNavn) | `\(ds[rolle].hex())` | \(rolle.readmeBruk) |")
        }
        for egen in ds.egneRoller {
            l.append("| \(egen.navn) | `\(egen.farge.hex())` | \(egen.mal.readmeBruk) |")
        }
        l.append("")
        l.append(String(localized: "Skriftfarger: lys `\(ds.lysTekst.hex())` (tekst i mørk modus) og mørk `\(ds.mørkTekst.hex())` (tekst i lys modus).", bundle: .module))
        l.append("")

        // Fargene per modus
        l.append("## \(t("Farger per modus"))")
        l.append("")
        l.append(t("Bruk disse navnene i koden, ikke grunnfargene: de bytter riktig mellom lys og mørk modus og ved økt kontrast."))
        l.append("")
        l.append(t("Navnene er de samme i alle filene, bare skrevet slik hvert verktøy vil ha dem:"))
        l.append("")
        l.append("| Design tokens | Figma | CSS | Xcode |")
        l.append("|---|---|---|---|")
        l.append("| `color.text.secondary` | `color/text/secondary` | `--color-text-secondary` | `textSecondary` |")
        l.append("")
        l.append("| Token | \(t("Brukes til")) | " + temaer.map(\.modus.readmeNavn).joined(separator: " | ") + " |")
        l.append("|---|---|" + temaer.map { _ in "---|" }.joined())
        if let første = temaer.first {
            for (i, token) in første.tokens.enumerated() {
                let verdier = temaer.map { "`\($0.tokens[i].farge.hex())`" }.joined(separator: " | ")
                l.append("| `\(token.navn)` | \(Self.bruk(token.navn, egne: første.egne)) | \(verdier) |")
            }
        }
        l.append("")

        // Kontrast
        l.append("## \(t("Kontrast"))")
        l.append("")
        l.append(t("Fargeparene i vanlige komponenter er kontrollert mot WCAG 2 (AA) i alle moduser og i tilstandene normal, trykket, fokus og deaktivert: tekst minst 4,5:1 ([1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)), kanter og kontroller minst 3:1 ([1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html), fra WCAG 2.1). Deaktiverte kontroller er unntatt."))
        l.append("")
        var avvik: [String] = []
        for tema in temaer {
            for tilstand in Komponenttilstand.allCases {
                for s in tema.sjekker(tilstand) where !s.består {
                    let (fg, bg) = Self.tokenpar(s.par, tilstand, rolle: s.rolletoken ?? "")
                    let forhold = Kontrasttest(forgrunn: s.forgrunn, bakgrunn: s.bakgrunn).formatert
                    let krav = s.krav.minimum.map { $0.formatted(.number.precision(.fractionLength($0 == 3 ? 0 : 1))) } ?? ""
                    avvik.append("- \(tema.modus.readmeNavn), \(tilstand.readmeNavn): `\(fg)` / `\(bg)` – \(forhold) (\(String(localized: "krav \(krav):1, WCAG \(s.krav.suksesskriterium ?? "")", bundle: .module)))")
                }
            }
        }
        if avvik.isEmpty {
            l.append(t("Alle fargeparene holder kravet i alle moduser og tilstander."))
        } else {
            l.append(t("Disse parene holder ikke kravet (forgrunn / bakgrunn):"))
            l.append("")
            l.append(contentsOf: avvik)
        }
        l.append("")

        // Skalaer
        l.append("## \(t("Skalaer"))")
        l.append("")
        l.append(t("Hver rolle har en toneskala fra 50 (lysest) til 950 (mørkest) med samme lyshet (L*) på hvert trinn i alle roller. Trinn 400 holder minst 3:1 og trinn 600 minst 4,5:1 mot hvitt, uansett kulør."))
        if formater.contains(.designTokens) {
            l.append(t("Skalaene ligger under `palette` i `tokens/primitives.tokens.json`."))
        }
        l.append("")

        // Bruk
        l.append("## \(t("Bruk"))")
        l.append("")
        if formater.contains(.xcode) {
            let katalog = "\(navn.isEmpty ? "Designsystem" : navn).xcassets"
            l.append("### Xcode (SwiftUI, UIKit, AppKit)")
            l.append("")
            l.append(String(localized: "Dra `\(katalog)` inn i Xcode-prosjektet. Hver farge er et fargesett med fire varianter: lys, mørk og begge med økt kontrast. Systemet velger varianten selv etter utseende og tilgjengelighetsinnstillingen «Øk kontrast».", bundle: .module))
            l.append("")
            l.append("```swift")
            l.append("Text(\"Hei\").foregroundStyle(Color(.textPrimary))")
            l.append("Button(\"Lagre\") {}.buttonStyle(.borderedProminent).tint(Color(.backgroundAccent)).foregroundStyle(Color(.textOnAccent))")
            l.append("RoundedRectangle(cornerRadius: 12).fill(Color(.backgroundSurface))")
            l.append("```")
            l.append("")
            l.append(t("Fra Xcode 15 lager Xcode `Color(.navn)` og `UIColor(resource:)` for hvert fargesett. Navnet er stien uten `color`, i camelCase: `color.text.on-accent` heter `textOnAccent`."))
            l.append("")
        }
        if formater.contains(.designTokens) {
            l.append("### Design tokens (DTCG 2025.10)")
            l.append("")
            l.append(t("`tokens/primitives.tokens.json` har skalaene og alle fargene som brukes, under `palette`, gruppert etter rolle og navngitt etter trinn eller L* (`l44`). Hver modus har sin fil (`light`, `dark`, `light-ic`, `dark-ic`) med de semantiske fargene under `color` som alias til primitivene, for eksempel `{palette.accent.l44}`. `tokens/resolver.json` binder dem sammen etter Resolver-modulen i DTCG 2025.10: velg konteksten `theme` (light, dark, light-ic eller dark-ic) i verktøyet som leser filene."))
            l.append("")
            l.append(t("Verktøy uten støtte for resolver kan lese primitivene og én modusfil om gangen."))
            l.append("")
        }
        if formater.contains(.figma) {
            l.append("### Figma")
            l.append("")
            l.append(t("1. Velg ingenting på lerretet, og klikk «Open variables» i panelet til høyre. Variables-visningen åpnes i et eget vindu."))
            l.append(t("2. Lag en ny samling i den visningen."))
            l.append(t("3. Dra alle fire filene i `figma/` inn i visningen samtidig. Hver fil blir en modus: light, dark, light-ic og dark-ic."))
            l.append("")
            l.append(t("Fargene ligger under `color`, i gruppene `background`, `text` og `border`, med samme navn som i de andre filene: `color/text/secondary`, `color/background/danger` og så videre."))
            l.append("")
            l.append(t("Fire moduser krever et betalt Figma-abonnement eller Education. Med gratisabonnementet kan en samling bare ha én modus: importer da `light.tokens.json` alene. Vil du oppdatere en samling som finnes, høyreklikker du en modus og velger «Import mode»."))
            l.append("")
            l.append(t("Filene har fargeverdiene direkte (ikke alias), fordi Figma bare importerer variabler som finnes i alle filene."))
            l.append("")
        }
        if formater.contains(.css) {
            let fil = "\(Identifikator.kebab(navn, reserve: "designsystem")).css"
            l.append("### CSS")
            l.append("")
            l.append(String(localized: "Lenk inn `\(fil)` og bruk variablene. Lys og mørk følger nettleserens innstilling via `light-dark()`, og økt kontrast følger `prefers-contrast: more`.", bundle: .module))
            l.append("")
            l.append("```html")
            l.append("<link rel=\"stylesheet\" href=\"\(fil)\">")
            l.append("```")
            l.append("")
            l.append("```css")
            l.append("body { background: var(--color-background-page); color: var(--color-text-primary); }")
            l.append(".kort { background: var(--color-background-surface); border: 1px solid var(--color-border-separator); }")
            l.append("button.hoved { background: var(--color-background-accent); color: var(--color-text-on-accent); }")
            l.append("button.hoved:active { background: var(--color-background-accent-pressed); }")
            l.append("button:focus-visible { outline: 2px solid var(--color-border-focus); outline-offset: 2px; }")
            l.append("input { background: var(--color-background-surface); border: 1px solid var(--color-border-control); color: var(--color-text-primary); }")
            l.append("input::placeholder { color: var(--color-text-placeholder); }")
            l.append("a { color: var(--color-text-accent); }")
            l.append("```")
            l.append("")
            l.append(t("Sett `color-scheme: light` eller `color-scheme: dark` på et element for å låse modusen der."))
            l.append("")
            l.append(t("Når fargene går utenfor sRGB, står de også i Display P3 nederst i fila, bak `@supports (color: color(display-p3 0 0 0))` og `@media (color-gamut: p3)`. Nettlesere og skjermer uten P3 bruker sRGB-verdiene. P3-fargene har samme lyshet (L*) som sRGB-fargene, så kontrasten er den samme."))
            l.append("")
        }
        l.append("## \(t("Gode råd"))")
        l.append("")
        l.append("- " + t("Bruk `color.text.on-accent` for tekst og ikoner på `color.background.accent`, og `color.text.accent` for tekst på `color.background.accent-subtle`. Det er parene som er kontrollert."))
        l.append("- " + t("`color.border.separator` er dekorativ. Bruk `color.border.control` når kanten er det som viser at noe er en kontroll, for eksempel et tekstfelt."))
        l.append("- " + t("Ikke la farge alene bære meningen i varsler: bruk ikon og tekst sammen med fargene for danger, success og warning."))
        l.append("- " + t("Endrer du en farge, sjekk kontrasten på nytt. I Kolorist vises den under Komponenter i designsystemet."))
        l.append("")

        // Navngiving og kilder
        l.append("## \(t("Navngiving og struktur"))")
        l.append("")
        l.append("- " + t("**To lag.** Primitivene (`palette`) er rene verdier uten mening: skalaer og fargene som brukes. De semantiske fargene (`color`) sier hva fargen er til, bytter med modus og peker på primitivene. Komponenter bør bruke de semantiske fargene, ikke primitivene direkte."))
        l.append("- " + t("**Bruk, ikke utseende.** Navnene beskriver hva fargen er til (`color.text.danger`), ikke hvordan den ser ut (`red`). Da holder navnet når fargen endres."))
        l.append("- " + t("**Egenskapen først.** Navnet bygges som kategori, egenskap, variant og tilstand: `color` · `background` · `accent` · `pressed`. Derfor har aksenten tre navn med samme verdi: flate, tekst og fokusring."))
        l.append("- " + t("**Modus utenfor navnet.** Lys, mørk og økt kontrast er egne filer eller varianter, ikke en del av navnet."))
        l.append("- " + t("**Retning på skalaene.** 50 er lysest og 950 mørkest. Retningen er ikke standardisert, så den står her."))
        l.append("")
        l.append(t("Kilder:"))
        l.append("")
        l.append("- [Design Tokens Format Module 2025.10](https://www.designtokens.org/TR/2025.10/format/) " + t("og") + " [Resolver Module 2025.10](https://www.designtokens.org/TR/2025.10/resolver/) – W3C Design Tokens Community Group")
        l.append("- [Atlassian: Design tokens](https://atlassian.design/foundations/tokens/design-tokens/) – " + t("navn etter mønsteret Foundation.Property.Modifier"))
        l.append("- [Nathan Curtis: Naming Tokens in Design Systems](https://medium.com/eightshapes-llc/naming-tokens-in-design-systems-9e86c7444676) – " + t("nivåene i et tokennavn"))
        l.append("- [Brad Frost: Subatomic – design tokens](https://bradfrost.com/blog/post/subatomic-design-tokens-course-chapter-2-now-live/) – " + t("lagene primitiv, semantisk og komponent"))
        l.append("- [GitHub Primer: Color](https://primer.style/foundations/color/overview) – " + t("grunnverdier, funksjonelle farger og moduser"))
        l.append("- [Figma: Modes for variables](https://help.figma.com/hc/en-us/articles/15343816063383-Modes-for-variables) – " + t("import av design tokens som variabler"))
        l.append("")
        return l.joined(separator: "\n")
    }

    /// Hva en semantisk token er til.
    static func bruk(_ token: String, egne: [EgenRolleFarger] = []) -> String {
        func t(_ s: String.LocalizationValue) -> String { String(localized: s, bundle: .module) }
        for e in egne {
            let n = e.tokennavn, navn = e.navn
            switch token {
            case "color.background.\(n)":
                switch e.mal {
                case .status: return String(localized: "Flate for «\(navn)»", bundle: .module)
                case .aksent: return String(localized: "Fylt flate for «\(navn)» (knapp)", bundle: .module)
                case .markering: return String(localized: "Svak flate for «\(navn)» (etikett)", bundle: .module)
                }
            case "color.background.\(n)-pressed": return String(localized: "«\(navn)» når den trykkes", bundle: .module)
            case "color.text.on-\(n)": return String(localized: "Tekst og ikoner på «\(navn)»", bundle: .module)
            case "color.text.\(n)":
                return e.mal == .aksent ? String(localized: "Tekst og lenker i «\(navn)»", bundle: .module)
                                        : String(localized: "Tekst og ikon for «\(navn)»", bundle: .module)
            case "color.border.\(n)": return String(localized: "Tydelig farge for «\(navn)»: kant, ikon, diagram", bundle: .module)
            default: continue
            }
        }
        switch token {
        case "color.background.page": return t("Sidebakgrunn")
        case "color.background.surface": return t("Kort, celler, felt og fanelinje")
        case "color.background.accent": return t("Hovedknapp og valgt element")
        case "color.background.accent-pressed": return t("Hovedknapp når den trykkes")
        case "color.background.accent-subtle": return t("Sekundærknapp og valgt rad")
        case "color.background.switch-on": return t("Bryter som er på")
        case "color.background.danger": return t("Flate for feilmelding")
        case "color.background.success": return t("Flate for bekreftelse")
        case "color.background.warning": return t("Flate for advarsel")
        case "color.background.disabled": return t("Deaktivert kontroll")
        case "color.text.primary": return t("Tekst")
        case "color.text.secondary": return t("Hjelpetekst og sekundær tekst")
        case "color.text.placeholder": return t("Plassholder i tekstfelt")
        case "color.text.on-accent": return t("Tekst og ikoner på aksentflaten")
        case "color.text.accent": return t("Lenker, og tekst på sekundærknapp")
        case "color.text.danger": return t("Feiltekst, ikon og slettehandling")
        case "color.text.success": return t("Bekreftelse, tekst og ikon")
        case "color.text.warning": return t("Tekst og ikon på advarselsflaten")
        case "color.text.disabled": return t("Tekst i deaktivert kontroll")
        case "color.border.control": return t("Kant som viser en kontroll (tekstfelt)")
        case "color.border.separator": return t("Skillelinjer (dekorativ)")
        case "color.border.focus": return t("Fokusring")
        default: return ""
        }
    }

    /// Tokennavnene for et kontrollert par (forgrunn, bakgrunn) i en tilstand.
    static func tokenpar(_ par: Komponentpar, _ tilstand: Komponenttilstand, rolle n: String = "") -> (String, String) {
        let av = tilstand == .deaktivert, trykket = tilstand == .trykket
        func c(_ s: String) -> String { "color." + s }
        switch par {
        case .tekst: return (c("text.primary"), c("background.surface"))
        case .sekundærtekst: return (c("text.secondary"), c("background.page"))
        case .plassholder: return (c(av ? "text.disabled" : "text.placeholder"), c("background.surface"))
        case .lenke: return (c("text.accent"), c("background.page"))
        case .destruktiv: return (c(av ? "text.disabled" : "text.danger"), c("background.page"))
        case .knappetekst:
            return av ? (c("text.disabled"), c("background.disabled"))
                      : (c("text.on-accent"), c(trykket ? "background.accent-pressed" : "background.accent"))
        case .tonetKnapp:
            return av ? (c("text.disabled"), c("background.disabled"))
                      : (c(trykket ? "background.accent-pressed" : "text.accent"), c("background.accent-subtle"))
        case .feltkant: return (c(av ? "border.separator" : "border.control"), c("background.surface"))
        case .bryter: return (c(av ? "background.disabled" : "background.switch-on"), c("background.surface"))
        case .fokusring: return (c("border.focus"), c("background.surface"))
        case .feilvarsel: return (c("text.danger"), c("background.danger"))
        case .suksessvarsel: return (c("text.success"), c("background.success"))
        case .advarselvarsel: return (c("text.warning"), c("background.warning"))
        case .egenVarsel: return (c("text.\(n)"), c("background.\(n)"))
        case .egenKnapp:
            return av ? (c("text.disabled"), c("background.disabled"))
                      : (c("text.on-\(n)"), c(trykket ? "background.\(n)-pressed" : "background.\(n)"))
        case .egenEtikettkant: return (c("border.\(n)"), c("background.surface"))
        case .egenEtikettekst: return (c("text.primary"), c("background.\(n)"))
        }
    }
}

extension Rollemal {
    var readmeBruk: String {
        switch self {
        case .status: String(localized: "Egen rolle, som status: tekst og ikon på en tonet flate", bundle: .module)
        case .aksent: String(localized: "Egen rolle, som aksent: fylt knapp med tekst på, og lenker", bundle: .module)
        case .markering: String(localized: "Egen rolle, markering: svak flate og tydelig kant (etiketter, diagrammer)", bundle: .module)
        }
    }
}

extension Designrolle {
    var readmeNavn: String {
        switch self {
        case .aksent: String(localized: "Aksent", bundle: .module)
        case .sekundær: String(localized: "Sekundær", bundle: .module)
        case .nøytral: String(localized: "Nøytral", bundle: .module)
        case .feil: String(localized: "Feil", bundle: .module)
        case .suksess: String(localized: "Suksess", bundle: .module)
        case .advarsel: String(localized: "Advarsel", bundle: .module)
        }
    }

    var readmeBruk: String {
        switch self {
        case .aksent: String(localized: "Hovedknapp, lenker, valgt fane og fokusring", bundle: .module)
        case .sekundær: String(localized: "Brytere som er på", bundle: .module)
        case .nøytral: String(localized: "Bakgrunn, flater, tekst, kanter og skillelinjer", bundle: .module)
        case .feil: String(localized: "Feilmeldinger og slettehandlinger", bundle: .module)
        case .suksess: String(localized: "Bekreftelser", bundle: .module)
        case .advarsel: String(localized: "Advarsler: gul flate med mørk tekst", bundle: .module)
        }
    }
}

extension Designmodus {
    var readmeNavn: String {
        switch self {
        case .lys: String(localized: "Lys", bundle: .module)
        case .mørk: String(localized: "Mørk", bundle: .module)
        case .lysØktKontrast: String(localized: "Lys, økt kontrast", bundle: .module)
        case .mørkØktKontrast: String(localized: "Mørk, økt kontrast", bundle: .module)
        }
    }
}

extension Komponenttilstand {
    var readmeNavn: String {
        switch self {
        case .normal: String(localized: "normal", bundle: .module)
        case .trykket: String(localized: "trykket", bundle: .module)
        case .fokus: String(localized: "fokus", bundle: .module)
        case .deaktivert: String(localized: "deaktivert", bundle: .module)
        }
    }
}
