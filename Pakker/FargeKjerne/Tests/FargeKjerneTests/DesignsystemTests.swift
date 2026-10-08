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
            for (navn, token) in sem where !navn.hasPrefix("$") {
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

@Suite("Designsystem-README")
struct DesignsystemReadmeTests {
    @Test func readmeMedRollerFargerOgBruk() throws {
        let ds = Designsystem(fra: Palett(navn: "Hav", farger: [PalettFarge(farge: Farge(hex: "#2F7FD8")!)]))
        let filer = DesignsystemEksport.filer(ds, formater: [.xcode, .css], navn: "Hav")
        let tekst = String(decoding: try #require(filer["README.md"]), as: UTF8.self)
        #expect(tekst.contains("#2F7FD8"))
        #expect(tekst.contains("`on-accent`"))
        #expect(tekst.contains("Hav.xcassets"))
        #expect(tekst.contains("hav.css"))
        #expect(!tekst.contains("figma/"))
        #expect(DesignsystemEksport.filer(ds, formater: [], navn: "Hav").isEmpty)
    }

    @Test func avvikListesNårRollenEndres() {
        var ds = Designsystem(fra: Palett(navn: "Hav", farger: [PalettFarge(farge: Farge(hex: "#2F7FD8")!)]))
        // En skriftfarge som ikke holder på aksenten.
        ds.lysTekst = Farge(hex: "#8899AA")!
        let tekst = String(decoding: DesignsystemEksport.filer(ds, formater: [.css], navn: "Hav")["README.md"]!, as: UTF8.self)
        #expect(tekst.contains("`on-accent` / `accent`"))
    }
}

@Suite("Designsystem-avsender")
struct DesignsystemAvsenderTests {
    @Test func avsenderIAlleFiler() throws {
        let ds = Designsystem(fra: Palett(navn: "Hav", farger: [PalettFarge(farge: Farge(hex: "#2F7FD8")!)]))
        let avsender = DesignsystemEksport.Avsender(app: "Kolorist 1.3", lenke: URL(string: "https://kolorist.no"), utvikler: "Eivind Arnstein Johansen")
        let filer = DesignsystemEksport.filer(ds, formater: Set(DesignsystemEksport.Format.allCases), navn: "Hav", avsender: avsender)
        let readme = String(decoding: filer["README.md"]!, as: UTF8.self)
        #expect(readme.contains("[Kolorist 1.3](https://kolorist.no)"))
        #expect(readme.contains("Eivind Arnstein Johansen"))
        // Figma-filene holdes fri for andre felt enn $type og $value; der står opphavet i README.
        for sti in ["hav.css", "tokens/primitives.tokens.json", "tokens/light.tokens.json", "tokens/resolver.json", "Hav.xcassets/Contents.json"] {
            let innhold = String(decoding: try #require(filer[sti]), as: UTF8.self)
            #expect(innhold.contains("Kolorist 1.3"), "\(sti)")
        }
    }
}

@Suite("Designsystem i Display P3")
struct DesignsystemP3Tests {
    private func kontrast(_ a: Farge, _ b: Farge) -> Double {
        let ya = max(a.luminans, 0), yb = max(b.luminans, 0)
        return (max(ya, yb) + 0.05) / (min(ya, yb) + 0.05)
    }

    /// P3-temaene holder kravene med kontrast regnet av den faktiske luminansen (uten klipping til sRGB).
    @Test(arguments: [25.0, 145, 200, 330])
    func p3HolderKravene(kulør: Double) {
        let grunn = Farge(okLCH: OKLCH(l: 0.62, c: 0.3, h: kulør)).gamutKartlagt(til: .displayP3)
        let ds = Designsystem(fra: Palett(navn: "T", farger: [PalettFarge(farge: grunn)]), gamut: .displayP3)
        for modus in Designmodus.allCases {
            for tilstand in Komponenttilstand.allCases {
                for s in ds.tema(modus, gamut: .displayP3).sjekker(tilstand) {
                    if let m = s.krav.minimum { #expect(kontrast(s.forgrunn, s.bakgrunn) >= m, "\(modus) \(tilstand) \(s.par)") }
                }
            }
        }
    }

    @Test func cssMedP3OgReserve() {
        let grønn = Farge(okLCH: OKLCH(l: 0.62, c: 0.28, h: 145)).gamutKartlagt(til: .displayP3)
        #expect(!grønn.erInnenfor(.sRGB))
        let ds = Designsystem(navn: "P3", roller: [.aksent: grønn, .sekundær: grønn], lysTekst: Farge(hex: "#FAFAFA")!, mørkTekst: Farge(hex: "#141414")!)
        let css = String(decoding: DesignsystemEksport.filer(ds, formater: [.css], navn: "P3")["p3.css"]!, as: UTF8.self)
        #expect(css.contains("--accent: light-dark(#"))
        #expect(css.contains("@supports (color: color(display-p3 0 0 0))"))
        #expect(css.contains("@media (color-gamut: p3)"))
        #expect(css.contains("--accent: light-dark(color(display-p3 "))
        // Nøytralene er like i begge og står bare i sRGB-delen.
        #expect(!css.contains("--surface: light-dark(color(display-p3"))
    }

    /// En merkefarge i sRGB står bare i sRGB-delen; statusfargene (standard) og nøytralene står der de skiller seg.
    @Test func merkefargeISRGBUtenP3() {
        let ds = Designsystem(fra: Palett(navn: "Grå", farger: [PalettFarge(farge: Farge(hex: "#336699")!)]))
        let css = String(decoding: DesignsystemEksport.filer(ds, formater: [.css], navn: "Grå")["gra.css"]!, as: UTF8.self)
        #expect(!css.contains("--accent: light-dark(color(display-p3"))
        #expect(!css.contains("--text: light-dark(color(display-p3"))
    }
}

@Suite("Designsystem for Figma")
struct DesignsystemFigmaTests {
    /// Figma krever `$type` og `$value` på hvert token og like tokennavn i alle filene.
    @Test func hvertTokenHarTypeOgVerdi() throws {
        let ds = Designsystem(fra: Palett(navn: "Hav", farger: [PalettFarge(farge: Farge(hex: "#2F7FD8")!)]))
        let filer = DesignsystemEksport.filer(ds, formater: [.figma], navn: "Hav")
        var navnesett: [Set<String>] = []
        for modus in Designmodus.allCases {
            let data = try #require(filer["figma/\(modus.tokennavn).tokens.json"])
            let rot = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let farger = try #require(rot["color"] as? [String: Any])
            #expect(Set(farger.keys) == ["background", "text", "border", "accent", "control", "disabled", "status"])
            // Går gjennom gruppene: et token har `$type` og `$value`, en gruppe har bare undergrupper og tokens.
            var navn = Set<String>()
            func gå(_ gruppe: [String: Any], _ sti: String) throws {
                #expect(!gruppe.keys.contains { $0.hasPrefix("$") })
                for (nøkkel, innhold) in gruppe {
                    let objekt = try #require(innhold as? [String: Any])
                    if let type = objekt["$type"] as? String {
                        #expect(type == "color")
                        let v = try #require(objekt["$value"] as? [String: Any])
                        #expect(v["colorSpace"] as? String == "srgb")
                        #expect((v["hex"] as? String)?.count == 7)
                        navn.insert(sti + nøkkel)
                    } else {
                        try gå(objekt, sti + nøkkel + "/")
                    }
                }
            }
            try gå(farger, "color/")
            #expect(navn.count == ds.tema(modus).tokens.count)
            #expect(navn.contains("color/text/secondary"))
            #expect(navn.contains("color/status/danger/bg"))
            #expect(navn.contains("color/status/warning/label"))
            #expect(Set(ds.tema(modus).tokens.map { DesignsystemEksport.figmanavn($0.navn) }) == navn)
            navnesett.append(navn)
        }
        #expect(Set(navnesett).count == 1)
    }
}
