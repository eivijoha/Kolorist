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
    public enum Format: String, CaseIterable, Sendable, Identifiable {
        case xcode, designTokens, figma, css
        public var id: String { rawValue }
    }

    /// Filene for de valgte formatene: relativ sti → innhold. `navn` brukes i filnavn (asset catalog og CSS).
    public static func filer(_ ds: Designsystem, formater: Set<Format>, navn: String) -> [String: Data] {
        var ut: [String: Data] = [:]
        let temaer = Designmodus.allCases.map { ds.tema($0) }
        if formater.contains(.xcode) { ut.merge(xcode(temaer, navn: navn)) { $1 } }
        if formater.contains(.designTokens) { ut.merge(designTokens(ds, temaer)) { $1 } }
        if formater.contains(.figma) { ut.merge(figma(temaer)) { $1 } }
        if formater.contains(.css) { ut["\(Identifikator.kebab(navn, reserve: "designsystem")).css"] = Data(css(temaer, navn: navn).utf8) }
        return ut
    }

    // MARK: Xcode

    static func xcode(_ temaer: [Designtema], navn: String) -> [String: Data] {
        let katalog = "\(navn.isEmpty ? "Designsystem" : navn).xcassets"
        var ut: [String: Data] = [:]
        ut["\(katalog)/Contents.json"] = json(["info": ["author": "xcode", "version": 1]])
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
                json(["colors": farger, "info": ["author": "xcode", "version": 1]])
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

    static func designTokens(_ ds: Designsystem, _ temaer: [Designtema]) -> [String: Data] {
        let (grupper, alias) = primitiver(ds, temaer)
        var farge: [String: Any] = ["$type": "color"]
        for (gruppe, liste) in grupper {
            var g: [String: Any] = [:]
            for (n, f) in liste { g[n] = ["$value": dtcgVerdi(f)] }
            farge[gruppe] = g
        }
        var ut: [String: Data] = ["tokens/primitives.tokens.json": json(["color": farge])]
        for tema in temaer {
            var semantisk: [String: Any] = ["$type": "color"]
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

    static func figma(_ temaer: [Designtema]) -> [String: Data] {
        var ut: [String: Data] = [:]
        for tema in temaer {
            var g: [String: Any] = ["$type": "color"]
            for (navn, f) in tema.tokens { g[navn] = ["$value": dtcgVerdi(f)] }
            ut["figma/\(tema.modus.tokennavn).tokens.json"] = json(["color": g])
        }
        return ut
    }

    // MARK: CSS

    static func css(_ temaer: [Designtema], navn: String) -> String {
        func tema(_ m: Designmodus) -> Designtema? { temaer.first { $0.modus == m } }
        guard let lys = tema(.lys), let mørk = tema(.mørk), let lysØK = tema(.lysØktKontrast), let mørkØK = tema(.mørkØktKontrast)
        else { return "" }
        func linjer(_ a: Designtema, _ b: Designtema, innrykk: String) -> String {
            zip(a.tokens, b.tokens).map { x, y in
                "\(innrykk)--\(x.navn): light-dark(\(x.farge.hex()), \(y.farge.hex()));"
            }.joined(separator: "\n")
        }
        return """
        /* \(navn) – designsystem eksportert fra Kolorist. Lys og mørk modus med light-dark(); økt kontrast med
           prefers-contrast. Sett color-scheme: light eller dark på et element for å låse modusen der. */
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
    }

    // MARK: Hjelp

    private static func json(_ objekt: Any) -> Data {
        (try? JSONSerialization.data(withJSONObject: objekt, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])) ?? Data()
    }
}
