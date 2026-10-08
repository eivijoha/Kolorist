import Foundation

/// Eksport av et designsystem (fra 1.3). Hvert format gir filer med relative stier, så appen kan legge dem i en mappe.
///
/// - Xcode: en asset catalog med ett fargesett per semantisk token, med variantene lys, mørk og økt kontrast
///   (`luminosity: dark`, `contrast: high`; kontrollert med `actool`, som gir UIAppearanceHighContrastAny/Dark).
/// - Design tokens (DTCG 2025.10): `primitives.tokens.json` med skalaene og fargene som brukes, én fil per modus der de
///   semantiske tokenene er alias til primitivene, og `resolver.json` (Resolver-modulen 2025.10) som binder dem sammen.
/// - Figma: én fil per modus med verdiene (sRGB og hex), som Figma importerer som én modus per fil. Alias brukes ikke, siden
///   Figma bare importerer tokens som finnes i alle filene.
/// - CSS: custom properties med `light-dark()` og `color-scheme: light dark`, og økt kontrast under
///   `@media (prefers-contrast: more)`.
public enum DesignsystemEksport {
    /// Hvem som laget filene, skrevet inn i hver fil (README, CSS, tokens, Figma og asset catalog).
    public struct Avsender: Sendable, Hashable {
        /// F.eks. «Kolorist 1.3».
        public var app: String
        public var lenke: URL?
        public var utvikler: String?

        public init(app: String, lenke: URL? = nil, utvikler: String? = nil) {
            self.app = app
            self.lenke = lenke
            self.utvikler = utvikler
        }

        /// «Kolorist 1.3 (https://kolorist.no) av …» uten Markdown.
        var tekst: String {
            var t = app
            if let lenke { t += " (\(lenke.absoluteString))" }
            if let utvikler { t += String(localized: " av \(utvikler)", bundle: .module) }
            return t
        }

        /// Til `$extensions` i tokenfilene.
        var utvidelse: [String: Any] {
            var u: [String: Any] = ["generator": app]
            if let lenke { u["url"] = lenke.absoluteString }
            if let utvikler { u["author"] = utvikler }
            return ["no.engenett.kolorist": u]
        }
    }

    public enum Format: String, CaseIterable, Sendable, Identifiable {
        case xcode, designTokens, figma, css
        public var id: String { rawValue }
    }

    /// Filene for de valgte formatene: relativ sti → innhold. `navn` brukes i filnavn (asset catalog og CSS).
    /// Med minst ett format følger en README.md med (rollene, fargene per modus, kontrasten og bruken).
    public static func filer(_ ds: Designsystem, formater: Set<Format>, navn: String, dato: Date = .now,
                             avsender: Avsender = Avsender(app: "Kolorist")) -> [String: Data] {
        var ut: [String: Data] = [:]
        let temaer = Designmodus.allCases.map { ds.tema($0) }
        if formater.contains(.xcode) { ut.merge(xcode(temaer, navn: navn, avsender: avsender)) { $1 } }
        if formater.contains(.designTokens) { ut.merge(designTokens(ds, temaer, avsender: avsender)) { $1 } }
        if formater.contains(.figma) { ut.merge(figma(temaer, avsender: avsender)) { $1 } }
        if formater.contains(.css) {
            let p3 = Designmodus.allCases.map { ds.tema($0, gamut: .displayP3) }
            ut["\(Identifikator.kebab(navn, reserve: "designsystem")).css"] = Data(css(temaer, p3: p3, navn: navn, avsender: avsender).utf8)
        }
        if !formater.isEmpty {
            ut["README.md"] = Data(readme(ds, temaer, formater: formater, navn: navn, dato: dato, avsender: avsender).utf8)
        }
        return ut
    }

    // MARK: Xcode

    static func xcode(_ temaer: [Designtema], navn: String, avsender: Avsender) -> [String: Data] {
        let katalog = "\(navn.isEmpty ? "Designsystem" : navn).xcassets"
        var ut: [String: Data] = [:]
        // Xcode godtar fritekst i «author».
        let info: [String: Any] = ["author": avsender.app, "version": 1]
        ut["\(katalog)/Contents.json"] = json(["info": info])
        guard let lys = temaer.first(where: { $0.modus == .lys }) else { return ut }
        for (i, token) in lys.tokens.enumerated() {
            var farger: [[String: Any]] = []
            for tema in temaer {
                let farge = tema.tokens[i].farge
                var variant: [String: Any] = ["idiom": "universal", "color": xcodeFarge(farge)]
                var utseende: [[String: String]] = []
                if tema.modus.erMørk { utseende.append(["appearance": "luminosity", "value": "dark"]) }
                if tema.modus.øktKontrast { utseende.append(["appearance": "contrast", "value": "high"]) }
                if !utseende.isEmpty { variant["appearances"] = utseende }
                farger.append(variant)
            }
            ut["\(katalog)/\(Identifikator.camel(token.navn, reserve: "farge")).colorset/Contents.json"] =
                json(["colors": farger, "info": info])
        }
        return ut
    }

    private static func xcodeFarge(_ f: Farge) -> [String: Any] {
        let v = f.gamutKartlagt(til: .sRGB).sRGB
        func k(_ x: Double) -> String { String(format: "%.3f", min(max(x, 0), 1)) }
        return ["color-space": "srgb",
                "components": ["red": k(v.r), "green": k(v.g), "blue": k(v.b), "alpha": k(f.alfa)]]
    }

    // MARK: Design tokens (DTCG)

    /// Primitivene: en gruppe per rolle (og «text» for skriftfargene) med skalaen 50–950 og fargene temaene bruker utenfor
    /// skalaen, navngitt etter L* («l96»). Svarer også med alias-stien for hver farge (etter hex).
    static func primitiver(_ ds: Designsystem, _ temaer: [Designtema]) -> (grupper: [(String, [(String, Farge)])], alias: [String: String]) {
        var grupper: [(String, [(String, Farge)])] = []
        var alias: [String: String] = [:]
        func legg(_ gruppe: String, _ farger: [(String, Farge)]) {
            var brukt = Set<String>()
            var liste: [(String, Farge)] = []
            for (n, f) in farger {
                let hex = f.hex()
                if alias[hex] != nil { continue }
                var navn = n, i = 2
                while brukt.contains(navn) { navn = "\(n)-\(i)"; i += 1 }
                brukt.insert(navn)
                alias[hex] = "{color.\(gruppe).\(navn)}"
                liste.append((navn, f))
            }
            if !liste.isEmpty { grupper.append((gruppe, liste)) }
        }
        func lNavn(_ f: Farge) -> String { "l\(Int(f.lStjerne.rounded()))" }
        // Skalaene først, så semantiske farger som er lik et trinn, blir alias til trinnet.
        let roller: [Designrolle] = [.aksent, .sekundær, .nøytral, .feil, .suksess, .advarsel]
        var ekstra: [String: [(String, Farge)]] = [:]
        for tema in temaer {
            for (navn, farge) in tema.tokens { ekstra[gruppe(for: navn), default: []].append((lNavn(farge), farge)) }
        }
        for rolle in roller {
            let skala = ds.skala(for: rolle)
            legg(rolle.tokennavn, zip(Designsystem.trinnavn, skala).map { ($0, $1) } + (ekstra[rolle.tokennavn] ?? [])
                .sorted { $0.1.lStjerne > $1.1.lStjerne })
        }
        legg("text", (ekstra["text"] ?? []).sorted { $0.1.lStjerne > $1.1.lStjerne })
        return (grupper, alias)
    }

    /// Hvilken primitiv gruppe en semantisk token hører til.
    static func gruppe(for token: String) -> String {
        switch token {
        case "text", "on-accent", "warning-text": "text"
        case "accent", "accent-pressed", "accent-subtle": "accent"
        case "secondary": "secondary"
        case let t where t.hasPrefix("danger"): "danger"
        case let t where t.hasPrefix("success"): "success"
        case let t where t.hasPrefix("warning"): "warning"
        default: "neutral"
        }
    }

    static func designTokens(_ ds: Designsystem, _ temaer: [Designtema], avsender: Avsender) -> [String: Data] {
        let (grupper, alias) = primitiver(ds, temaer)
        var farge: [String: Any] = ["$type": "color", "$description": avsender.tekst, "$extensions": avsender.utvidelse]
        for (gruppe, liste) in grupper {
            var g: [String: Any] = [:]
            for (n, f) in liste { g[n] = ["$value": dtcgVerdi(f)] }
            farge[gruppe] = g
        }
        var ut: [String: Data] = ["tokens/primitives.tokens.json": json(["color": farge])]
        for tema in temaer {
            var semantisk: [String: Any] = ["$type": "color", "$description": avsender.tekst, "$extensions": avsender.utvidelse]
            for (navn, f) in tema.tokens {
                semantisk[navn] = ["$value": alias[f.hex()].map { $0 as Any } ?? dtcgVerdi(f)]
            }
            ut["tokens/\(tema.modus.tokennavn).tokens.json"] = json(["semantic": semantisk])
        }
        let kontekster = Dictionary(uniqueKeysWithValues: temaer.map {
            ($0.modus.tokennavn, [["$ref": "\($0.modus.tokennavn).tokens.json"]])
        })
        ut["tokens/resolver.json"] = json([
            "$schema": "https://www.designtokens.org/schemas/2025.10/resolver.json",
            "name": ds.navn,
            "description": avsender.tekst,
            "sets": ["primitives": ["sources": [["$ref": "primitives.tokens.json"]]]],
            "modifiers": ["theme": ["contexts": kontekster, "default": "light"]],
            "resolutionOrder": [["$ref": "#/sets/primitives"], ["$ref": "#/modifiers/theme"]],
        ])
        return ut
    }

    private static func dtcgVerdi(_ f: Farge) -> [String: Any] {
        let v = f.gamutKartlagt(til: .sRGB).sRGB
        return ["colorSpace": "srgb",
                "components": [v.r, v.g, v.b].map { (min(max($0, 0), 1) * 10000).rounded() / 10000 },
                "alpha": f.alfa, "hex": f.hex()]
    }

    // MARK: Figma

    static func figma(_ temaer: [Designtema], avsender: Avsender) -> [String: Data] {
        var ut: [String: Data] = [:]
        for tema in temaer {
            var g: [String: Any] = ["$type": "color", "$description": avsender.tekst]
            for (navn, f) in tema.tokens { g[navn] = ["$value": dtcgVerdi(f)] }
            ut["figma/\(tema.modus.tokennavn).tokens.json"] = json(["color": g])
        }
        return ut
    }

    // MARK: CSS

    /// `p3`: temaene utledet mot Display P3 (samme L* som i sRGB, så kontrasten er den samme). Fargene som går merkbart
    /// utenfor sRGB, skrives i en egen blokk bak `@supports (color: color(display-p3 …))` og `@media (color-gamut: p3)`;
    /// nettlesere og skjermer uten P3 bruker sRGB-verdiene over.
    static func css(_ temaer: [Designtema], p3: [Designtema] = [], navn: String, avsender: Avsender) -> String {
        func tema(_ m: Designmodus, _ liste: [Designtema]) -> Designtema? { liste.first { $0.modus == m } }
        guard let lys = tema(.lys, temaer), let mørk = tema(.mørk, temaer), let lysØK = tema(.lysØktKontrast, temaer),
              let mørkØK = tema(.mørkØktKontrast, temaer)
        else { return "" }
        func linjer(_ a: Designtema, _ b: Designtema, innrykk: String) -> String {
            zip(a.tokens, b.tokens).map { x, y in
                "\(innrykk)--\(x.navn): light-dark(\(x.farge.hex()), \(y.farge.hex()));"
            }.joined(separator: "\n")
        }
        var tekst = """
        /* \(navn) – designsystem fra \(avsender.tekst).
           Lys og mørk modus med light-dark(); økt kontrast med prefers-contrast. Sett color-scheme: light eller dark på
           et element for å låse modusen der. */
        :root {
          color-scheme: light dark;
        \(linjer(lys, mørk, innrykk: "  "))
        }

        @media (prefers-contrast: more) {
          :root {
        \(linjer(lysØK, mørkØK, innrykk: "    "))
          }
        }

        """
        if let p3Lys = tema(.lys, p3), let p3Mørk = tema(.mørk, p3), let p3LysØK = tema(.lysØktKontrast, p3),
           let p3MørkØK = tema(.mørkØktKontrast, p3) {
            let par = [(lys, p3Lys), (mørk, p3Mørk), (lysØK, p3LysØK), (mørkØK, p3MørkØK)]
            // Tokenene der minst én modus har en P3-farge som skiller seg fra sRGB-fargen. Samme sett i begge blokkene,
            // så P3-blokken uten økt kontrast aldri overstyrer sRGB-verdiene for økt kontrast.
            let med = lys.tokens.indices.filter { i in
                par.contains { s, p in Self.skillerSegIP3(sRGB: s.tokens[i].farge, p3: p.tokens[i].farge) }
            }
            if !med.isEmpty {
                func p3Linjer(_ a: Designtema, _ b: Designtema, innrykk: String) -> String {
                    med.map { i in
                        "\(innrykk)--\(a.tokens[i].navn): light-dark(\(Self.cssP3(a.tokens[i].farge)), \(Self.cssP3(b.tokens[i].farge)));"
                    }.joined(separator: "\n")
                }
                tekst += """

                /* Display P3 for skjermer og nettlesere som støtter det. Samme lyshet (L*) som sRGB-verdiene over, så
                   kontrasten er den samme. */
                @supports (color: color(display-p3 0 0 0)) {
                  @media (color-gamut: p3) {
                    :root {
                \(p3Linjer(p3Lys, p3Mørk, innrykk: "      "))
                    }
                  }
                  @media (color-gamut: p3) and (prefers-contrast: more) {
                    :root {
                \(p3Linjer(p3LysØK, p3MørkØK, innrykk: "      "))
                    }
                  }
                }

                """
            }
        }
        return tekst
    }

    /// P3-fargen ligger utenfor sRGB og er merkbart forskjellig fra sRGB-varianten (OKLab-avstand over 0,004).
    static func skillerSegIP3(sRGB: Farge, p3: Farge) -> Bool {
        guard !p3.erInnenfor(.sRGB) else { return false }
        let a = sRGB.okLab, b = p3.okLab
        return ((a.l - b.l) * (a.l - b.l) + (a.a - b.a) * (a.a - b.a) + (a.b - b.b) * (a.b - b.b)).squareRoot() > 0.004
    }

    static func cssP3(_ f: Farge) -> String {
        let v = f.gamutKartlagt(til: .displayP3).displayP3
        func k(_ x: Double) -> String { String(format: "%.4f", min(max(x, 0), 1)) }
        return "color(display-p3 \(k(v.r)) \(k(v.g)) \(k(v.b)))"
    }

    // MARK: Hjelp

    private static func json(_ objekt: Any) -> Data {
        (try? JSONSerialization.data(withJSONObject: objekt, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])) ?? Data()
    }
}
