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
        l.append("")
        l.append(String(localized: "Skriftfarger: lys `\(ds.lysTekst.hex())` (tekst i mørk modus) og mørk `\(ds.mørkTekst.hex())` (tekst i lys modus).", bundle: .module))
        l.append("")

        // Fargene per modus
        l.append("## \(t("Farger per modus"))")
        l.append("")
        l.append(t("Bruk disse navnene i koden, ikke grunnfargene: de bytter riktig mellom lys og mørk modus og ved økt kontrast."))
        l.append("")
        l.append("| Token | \(t("Brukes til")) | " + temaer.map(\.modus.readmeNavn).joined(separator: " | ") + " |")
        l.append("|---|---|" + temaer.map { _ in "---|" }.joined())
        if let første = temaer.first {
            for (i, token) in første.tokens.enumerated() {
                let verdier = temaer.map { "`\($0.tokens[i].farge.hex())`" }.joined(separator: " | ")
                l.append("| `\(token.navn)` | \(Self.bruk(token.navn)) | \(verdier) |")
            }
        }
        l.append("")

        // Kontrast
        l.append("## \(t("Kontrast"))")
        l.append("")
        l.append(t("Fargeparene i vanlige komponenter er kontrollert mot WCAG 2 (AA) i alle moduser og i tilstandene normal, trykket, fokus og deaktivert: tekst minst 4,5:1 (1.4.3), kanter og kontroller minst 3:1 (1.4.11, fra WCAG 2.1). Deaktiverte kontroller er unntatt."))
        l.append("")
        var avvik: [String] = []
        for tema in temaer {
            for tilstand in Komponenttilstand.allCases {
                for s in tema.sjekker(tilstand) where !s.består {
                    let (fg, bg) = Self.tokenpar(s.par, tilstand)
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
        l.append(t("Hver rolle har en toneskala fra 50 til 950 med samme lyshet (L*) på hvert trinn i alle roller. Trinn 400 holder minst 3:1 og trinn 600 minst 4,5:1 mot hvitt, uansett kulør."))
        if formater.contains(.designTokens) {
            l.append(t("Skalaene ligger i `tokens/primitives.tokens.json`."))
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
            l.append("Text(\"Hei\").foregroundStyle(Color(.text))")
            l.append("Button(\"Lagre\") {}.buttonStyle(.borderedProminent).tint(Color(.accent)).foregroundStyle(Color(.onAccent))")
            l.append("RoundedRectangle(cornerRadius: 12).fill(Color(.surface))")
            l.append("```")
            l.append("")
            l.append(t("Fra Xcode 15 lager Xcode `Color(.navn)` og `UIColor(resource:)` for hvert fargesett. Bindestrek i navnene blir camelCase: `on-accent` heter `onAccent`."))
            l.append("")
        }
        if formater.contains(.designTokens) {
            l.append("### Design tokens (DTCG 2025.10)")
            l.append("")
            l.append(t("`tokens/primitives.tokens.json` har skalaene og alle fargene som brukes, gruppert etter rolle og navngitt etter trinn eller L* (`l44`). Hver modus har sin fil (`light`, `dark`, `light-ic`, `dark-ic`) med de semantiske fargene som alias til primitivene, for eksempel `{color.accent.l44}`. `tokens/resolver.json` binder dem sammen etter Resolver-modulen i DTCG 2025.10: velg konteksten `theme` (light, dark, light-ic eller dark-ic) i verktøyet som leser filene."))
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
            l.append(t("Fargene ligger under `color`, i gruppene background, text, border, accent, control og status (med danger, success og warning). Navnene er de samme som i CSS og Xcode: `color/text/text-secondary` i Figma er `--text-secondary` i CSS og `textSecondary` i Xcode."))
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
            l.append("body { background: var(--bg); color: var(--text); }")
            l.append(".kort { background: var(--surface); border: 1px solid var(--separator); }")
            l.append("button.hoved { background: var(--accent); color: var(--on-accent); }")
            l.append("button.hoved:active { background: var(--accent-pressed); }")
            l.append("button:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }")
            l.append("input { background: var(--surface); border: 1px solid var(--border); color: var(--text); }")
            l.append("input::placeholder { color: var(--placeholder); }")
            l.append("```")
            l.append("")
            l.append(t("Sett `color-scheme: light` eller `color-scheme: dark` på et element for å låse modusen der."))
            l.append("")
            l.append(t("Når fargene går utenfor sRGB, står de også i Display P3 nederst i fila, bak `@supports (color: color(display-p3 0 0 0))` og `@media (color-gamut: p3)`. Nettlesere og skjermer uten P3 bruker sRGB-verdiene. P3-fargene har samme lyshet (L*) som sRGB-fargene, så kontrasten er den samme."))
            l.append("")
        }
        l.append("## \(t("Gode råd"))")
        l.append("")
        l.append("- " + t("Bruk `on-accent` for tekst og ikoner på `accent`, og `accent` for tekst på `accent-subtle`. Det er parene som er kontrollert."))
        l.append("- " + t("`separator` er dekorativ. Bruk `border` når kanten er det som viser at noe er en kontroll, for eksempel et tekstfelt."))
        l.append("- " + t("Ikke la farge alene bære meningen i varsler: bruk ikon og tekst sammen med `danger`, `success` og `warning`."))
        l.append("- " + t("Endrer du en farge, sjekk kontrasten på nytt. I Kolorist vises den under Komponenter i designsystemet."))
        l.append("")
        return l.joined(separator: "\n")
    }

    /// Hva en semantisk token er til.
    static func bruk(_ token: String) -> String {
        func t(_ s: String.LocalizationValue) -> String { String(localized: s, bundle: .module) }
        switch token {
        case "bg": return t("Sidebakgrunn")
        case "surface": return t("Kort, celler, felt og fanelinje")
        case "text": return t("Tekst")
        case "text-secondary": return t("Hjelpetekst og sekundær tekst")
        case "placeholder": return t("Plassholder i tekstfelt")
        case "border": return t("Kant som viser en kontroll (tekstfelt)")
        case "separator": return t("Skillelinjer (dekorativ)")
        case "accent": return t("Hovedknapp, lenker, valgt fane, fokusring")
        case "accent-pressed": return t("Hovedknapp når den trykkes")
        case "on-accent": return t("Tekst og ikoner på aksent")
        case "accent-subtle": return t("Sekundærknapp og valgt rad")
        case "secondary": return t("Bryter som er på")
        case "disabled-bg": return t("Deaktivert kontroll")
        case "disabled-text": return t("Tekst i deaktivert kontroll")
        case "danger-text": return t("Feiltekst, ikon og slettehandling")
        case "danger-bg": return t("Flate for feilmelding")
        case "success-text": return t("Bekreftelse, tekst og ikon")
        case "success-bg": return t("Flate for bekreftelse")
        case "warning-text": return t("Tekst og ikon på advarselsflaten")
        case "warning-bg": return t("Flate for advarsel")
        default: return ""
        }
    }

    /// Tokennavnene for et kontrollert par (forgrunn, bakgrunn) i en tilstand.
    static func tokenpar(_ par: Komponentpar, _ tilstand: Komponenttilstand) -> (String, String) {
        let av = tilstand == .deaktivert, trykket = tilstand == .trykket
        switch par {
        case .tekst: return ("text", "surface")
        case .sekundærtekst: return ("text-secondary", "bg")
        case .plassholder: return (av ? "disabled-text" : "placeholder", "surface")
        case .lenke: return ("accent", "bg")
        case .destruktiv: return (av ? "disabled-text" : "danger-text", "bg")
        case .knappetekst: return av ? ("disabled-text", "disabled-bg") : ("on-accent", trykket ? "accent-pressed" : "accent")
        case .tonetKnapp: return av ? ("disabled-text", "disabled-bg") : (trykket ? "accent-pressed" : "accent", "accent-subtle")
        case .feltkant: return (av ? "separator" : "border", "surface")
        case .bryter: return (av ? "disabled-bg" : "secondary", "surface")
        case .fokusring: return ("accent", "surface")
        case .feilvarsel: return ("danger-text", "danger-bg")
        case .suksessvarsel: return ("success-text", "success-bg")
        case .advarselvarsel: return ("warning-text", "warning-bg")
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
