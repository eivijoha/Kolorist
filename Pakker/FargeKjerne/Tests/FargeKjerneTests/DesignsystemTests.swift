import Foundation
import Testing
@testable import FargeKjerne

@Suite("Designsystem")
struct DesignsystemTests {
    private func farge(_ hex: String, _ navn: String = "") -> PalettFarge { PalettFarge(navn: navn, farge: Farge(hex: hex)!) }

    @Test func rollerFordelesAutomatisk() {
        let blå = farge("#2F7FD8"), rød = farge("#D93A2B"), grønn = farge("#2E9B4F"), grå = farge("#7A7F87"), lilla = farge("#AC58AF")
        let r = Designsystem.automatiskeRoller(for: [blå, lilla, rød, grønn, grå])
        #expect(r[.aksent]?.id == blå.id)
        #expect(r[.feil]?.id == rød.id)
        #expect(r[.suksess]?.id == grønn.id)
        #expect(r[.advarsel] == nil)
        #expect(r[.sekundær]?.id == lilla.id)
        #expect(r[.nøytral]?.id == grå.id)
    }

    @Test func merkefargenBeholdesNårDenHolder() {
        // L* ≈ 40 ligger i lys-området for aksent (25–44) og skal brukes uendret.
        let mørkBlå = Farge.medLStjerne(40, kroma: 0.15, kulør: 260)
        let ds = Designsystem(fra: Palett(navn: "T", farger: [PalettFarge(farge: mørkBlå)]))
        #expect(ds.tema(.lys).aksent.hex() == mørkBlå.hex())
        // I mørk modus må den lysere.
        #expect(ds.tema(.mørk).aksent.lStjerne >= 59.9)
    }

    /// Alle kontrollpunktene holder i alle moduser og tilstander, for mange kulører og lysheter – også etter hex.
    @Test(arguments: [0.0, 30, 60, 90, 120, 150, 200, 240, 280, 320])
    func alleParHolder(kulør: Double) {
        for l in [0.3, 0.55, 0.8] {
            let grunn = Farge(okLCH: OKLCH(l: l, c: 0.14, h: kulør)).gamutKartlagt(til: .displayP3)
            let ds = Designsystem(fra: Palett(navn: "T", farger: [PalettFarge(farge: grunn)]))
            for modus in Designmodus.allCases {
                let tema = ds.tema(modus)
                for tilstand in Komponenttilstand.allCases {
                    for s in tema.sjekker(tilstand) {
                        #expect(s.består, "\(modus) \(tilstand) \(s.par): \(s.forhold)")
                        if let m = s.krav.minimum {
                            let hex = Farge(hex: s.forgrunn.hex())!.wcagKontrast(mot: Farge(hex: s.bakgrunn.hex())!)
                            #expect(hex >= m, "hex \(modus) \(s.par): \(hex)")
                        }
                    }
                }
            }
        }
    }

    @Test func kodesOgLesesIgjen() throws {
        let ds = Designsystem(fra: Palett(navn: "Hav", farger: [farge("#2F7FD8"), farge("#C95530")]))
        let data = try JSONEncoder().encode(ds)
        let lest = try JSONDecoder().decode(Designsystem.self, from: data)
        #expect(lest == ds)
    }
}

@Suite("Designsystem-eksport")
struct DesignsystemEksportTests {
    private let ds = Designsystem(fra: Palett(navn: "Hav", farger: [PalettFarge(farge: Farge(hex: "#2F7FD8")!),
                                                                    PalettFarge(farge: Farge(hex: "#C95530")!)]))

    @Test func xcodeHarFireVarianterPerFarge() throws {
        let filer = DesignsystemEksport.filer(ds, formater: [.xcode], navn: "Hav")
        #expect(filer["Hav.xcassets/Contents.json"] != nil)
        let sett = filer.keys.filter { $0.hasSuffix(".colorset/Contents.json") }
        #expect(sett.count == ds.tema(.lys).tokens.count)
        #expect(sett.contains("Hav.xcassets/onAccent.colorset/Contents.json"))
        let json = try #require(JSONSerialization.jsonObject(with: filer["Hav.xcassets/accent.colorset/Contents.json"]!) as? [String: Any])
        let farger = try #require(json["colors"] as? [[String: Any]])
        #expect(farger.count == 4)
        let utseender = farger.compactMap { $0["appearances"] as? [[String: String]] }.flatMap { $0 }
        #expect(utseender.contains { $0["appearance"] == "contrast" && $0["value"] == "high" })
    }

    @Test func aliasPekerPåPrimitiver() throws {
        let filer = DesignsystemEksport.filer(ds, formater: [.designTokens], navn: "Hav")
        let prim = try #require(JSONSerialization.jsonObject(with: filer["tokens/primitives.tokens.json"]!) as? [String: Any])
        let farge = try #require(prim["color"] as? [String: Any])
        for modus in Designmodus.allCases {
            let fil = try #require(filer["tokens/\(modus.tokennavn).tokens.json"])
            let sem = try #require((JSONSerialization.jsonObject(with: fil) as? [String: Any])?["semantic"] as? [String: Any])
            for (navn, token) in sem where navn != "$type" {
                let verdi = (token as? [String: Any])?["$value"]
                let alias = try #require(verdi as? String, "\(modus) \(navn) er ikke alias")
                let sti = alias.dropFirst().dropLast().split(separator: ".").map(String.init)
                #expect(sti.count == 3 && sti[0] == "color")
                #expect((farge[sti[1]] as? [String: Any])?[sti[2]] != nil, "\(alias) finnes ikke")
            }
        }
        #expect(filer["tokens/resolver.json"] != nil)
    }

    @Test func cssMedLightDark() {
        let css = String(decoding: DesignsystemEksport.filer(ds, formater: [.css], navn: "Hav")["hav.css"]!, as: UTF8.self)
        #expect(css.contains("color-scheme: light dark;"))
        #expect(css.contains("--accent: light-dark(#"))
        #expect(css.contains("@media (prefers-contrast: more)"))
    }
}
