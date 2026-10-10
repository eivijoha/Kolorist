import Foundation
import Testing
@testable import FargeKjerne

/// Testvektorer for fargeregningen, så andre implementasjoner (f.eks. TypeScript på web) kan testes mot FargeKjerne,
/// som er fasiten. Fila `Testvektorer/Fargeregning.json` lages herfra og kontrolleres ved hver testkjøring.
/// Sett miljøvariabelen `LAG_TESTVEKTORER=1` for å skrive fila på nytt etter en bevisst endring i regningen.
@Suite("Testvektorer")
struct TestvektorerTests {
    static let fil = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Testvektorer/Fargeregning.json")

    /// Inndata: sRGB-hex, OKLCH (også utenfor gamut) og Display P3.
    static var farger: [(navn: String, inn: [String: Any], farge: Farge)] {
        var ut: [(String, [String: Any], Farge)] = []
        for hex in ["#000000", "#FFFFFF", "#808080", "#767676", "#9E9E9E", "#0A0A0A", "#FAFAFA", "#FF0000", "#00FF00",
                    "#0000FF", "#FFFF00", "#00FFFF", "#FF00FF", "#537BB0", "#C8553D", "#1F3A4D", "#E6DCC8", "#F29E6D",
                    "#2F7FD8", "#55911E", "#6A3D9A", "#F9D71C"] {
            ut.append(("hex \(hex)", ["hex": hex], Farge(hex: hex)!))
        }
        for (l, c, h) in [(0.7, 0.3, 140.0), (0.6, 0.35, 30.0), (0.5, 0.3, 265.0), (0.9, 0.2, 100.0), (0.4, 0.25, 320.0),
                          (0.95, 0.1, 200.0), (0.62, 0.17, 30.0), (0.3, 0.05, 250.0)] {
            ut.append(("oklch \(l) \(c) \(h)", ["oklch": [l, c, h]], Farge(okLCH: OKLCH(l: l, c: c, h: h))))
        }
        for (r, g, b) in [(1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0), (0.2, 0.8, 0.4)] {
            ut.append(("display-p3 \(r) \(g) \(b)", ["displayP3": [r, g, b]], Farge(displayP3: DisplayP3(r: r, g: g, b: b))))
        }
        return ut
    }

    /// Par (tekst/forgrunn, bakgrunn) for kontrast og fargeavstand.
    static let par: [(String, String)] = [
        ("#000000", "#FFFFFF"), ("#FFFFFF", "#000000"), ("#767676", "#FFFFFF"), ("#FFFFFF", "#537BB0"),
        ("#000000", "#537BB0"), ("#FFFFFF", "#F29E6D"), ("#C8553D", "#E6DCC8"), ("#1F3A4D", "#8FB3C7"),
        ("#555555", "#AAAAAA"), ("#2F7FD8", "#C94F62"), ("#808080", "#808081"), ("#FF0000", "#00FF00"),
    ]

    static func tall(_ v: Double) -> Double { (v * 1e12).rounded() / 1e12 }
    static func liste(_ v: [Double]) -> [Double] { v.map(tall) }

    static func vektorer() -> [String: Any] {
        let fargevektorer = farger.map { navn, inn, f -> [String: Any] in
            let srgb = f.sRGB, xyz = f.xyz, oklab = f.okLab, oklch = f.okLCH, lab = f.cieLab, lch = f.cieLCH
            let p3 = f.displayP3, hsl = f.hsl, hsb = f.hsb
            let kartS = f.gamutKartlagt(til: .sRGB), kartP = f.gamutKartlagt(til: .displayP3)
            return [
                "navn": navn, "inn": inn,
                "lineærSRGB": liste([f.r, f.g, f.b]),
                "sRGB": liste([srgb.r, srgb.g, srgb.b]),
                "xyzD65": liste([xyz.x, xyz.y, xyz.z]),
                "oklab": liste([oklab.l, oklab.a, oklab.b]),
                "oklch": liste([oklch.l, oklch.c, oklch.h]),
                "cieLabD50": liste([lab.l, lab.a, lab.b]),
                "cieLCHD50": liste([lch.l, lch.c, lch.h]),
                "displayP3": liste([p3.r, p3.g, p3.b]),
                "hsl": liste([hsl.h, hsl.s, hsl.l]),
                "hsb": liste([hsb.h, hsb.s, hsb.b]),
                "iSRGB": f.erISRGB,
                "iDisplayP3": f.erIDisplayP3,
                "gamutKartlagtSRGB": liste([kartS.sRGB.r, kartS.sRGB.g, kartS.sRGB.b]),
                "gamutKartlagtDisplayP3": liste([kartP.displayP3.r, kartP.displayP3.g, kartP.displayP3.b]),
                "hex": f.hex(),
                "lrv": tall(f.lrv),
            ]
        }
        let parvektorer = par.map { tekst, bakgrunn -> [String: Any] in
            let t = Farge(hex: tekst)!, b = Farge(hex: bakgrunn)!
            return [
                "tekst": tekst, "bakgrunn": bakgrunn,
                "wcagKontrast": tall(t.wcagKontrast(mot: b)),
                "deltaE2000": tall(Fargeavstand.deltaE2000(t.cieLab, b.cieLab)),
                "deltaE76": tall(Fargeavstand.deltaE76(t.cieLab, b.cieLab)),
                "deltaEOK": tall(t.avstandOK(til: b)),
                "lrvForskjell": tall(Flatekontrast(t, b).lrvForskjell),
                "weberFlatePaaBakgrunn": tall(Flatekontrast(t, b).weber),
                "michelson": tall(Flatekontrast(t, b).michelson),
                "lesbarTekstfargePåBakgrunn": b.lesbarTekstfarge.hex(),
            ]
        }
        return [
            "beskrivelse": "Testvektorer for fargeregningen i FargeKjerne (Kolorist). Lages av TestvektorerTests; se README.md.",
            "versjon": 1,
            "konvensjoner": [
                "sRGB og Display P3": "gamma-kodet, 0–1, ikke klippet (verdier utenfor 0–1 betyr utenfor gamut)",
                "lineærSRGB": "utvidet lineær sRGB, fargens kanoniske form i Kolorist",
                "xyzD65": "CIE XYZ, D65, Y = 1 for hvitt",
                "oklab/oklch": "Björn Ottosson 2020; L 0–1, kulør i grader",
                "cieLabD50": "CIELab med D50 som hvitpunkt (ICC), Bradford fra D65; L 0–100",
                "hsl/hsb": "på sRGB klippet til 0–1; kulør i grader, metning/lyshet 0–1",
                "gamutKartlagt": "CSS Color 4: kroma reduseres i OKLCH (JND 0,02) til fargen er innenfor",
                "hex": "sRGB etter gamut-kartlegging",
                "lrv": "lysrefleksjonsverdi i prosent: Y × 100 av sRGB-klippet farge",
                "wcagKontrast": "WCAG 2.x, (L1 + 0,05) / (L2 + 0,05) på sRGB-klippet luminans",
                "deltaE2000/deltaE76": "på CIELab D50",
                "deltaEOK": "euklidsk avstand i OKLab (ikke ×100)",
                "lrvForskjell": "|LRV tekst − LRV bakgrunn| i poeng (BS 8300)",
                "weberFlatePaaBakgrunn": "|Yo − Yb| / Yb med «tekst» som flate og bakgrunnen som referanse (TEK17, NS 11001); Yb minst 0,5",
                "michelson": "|Y1 − Y2| / (Y1 + Y2) (ISO 21542)",
                "toleranse": "tallene er avrundet til 12 desimaler; 1e-9 er en rimelig toleranse",
            ],
            "farger": fargevektorer,
            "par": parvektorer,
        ]
    }

    @Test func testvektoreneStemmer() throws {
        let nye = Self.vektorer()
        if ProcessInfo.processInfo.environment["LAG_TESTVEKTORER"] == "1" {
            try FileManager.default.createDirectory(at: Self.fil.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: nye, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            try data.write(to: Self.fil)
            return
        }
        let lagret = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: Self.fil)) as? [String: Any])
        let lagredeFarger = try #require(lagret["farger"] as? [[String: Any]])
        let nyeFarger = try #require(nye["farger"] as? [[String: Any]])
        #expect(lagredeFarger.count == nyeFarger.count)
        for (a, b) in zip(lagredeFarger, nyeFarger) {
            for nøkkel in ["lineærSRGB", "sRGB", "xyzD65", "oklab", "oklch", "cieLabD50", "displayP3", "gamutKartlagtSRGB", "gamutKartlagtDisplayP3"] {
                let x = try #require(a[nøkkel] as? [Double]), y = try #require(b[nøkkel] as? [Double])
                #expect(zip(x, y).allSatisfy { abs($0 - $1) < 1e-9 }, "\(a["navn"] ?? "") \(nøkkel)")
            }
            #expect(a["hex"] as? String == b["hex"] as? String)
        }
        let lagredePar = try #require(lagret["par"] as? [[String: Any]])
        let nyePar = try #require(nye["par"] as? [[String: Any]])
        for (a, b) in zip(lagredePar, nyePar) {
            for nøkkel in ["wcagKontrast", "deltaE2000", "deltaE76", "deltaEOK", "lrvForskjell", "weberFlatePaaBakgrunn", "michelson"] {
                let x = try #require(a[nøkkel] as? Double), y = try #require(b[nøkkel] as? Double)
                #expect(abs(x - y) < 1e-9, "\(a["tekst"] ?? "") på \(a["bakgrunn"] ?? "") \(nøkkel)")
            }
        }
    }
}
