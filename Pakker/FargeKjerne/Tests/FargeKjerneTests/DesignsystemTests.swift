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
        #expect(sett.contains("Hav.xcassets/textOnAccent.colorset/Contents.json"))
        let json = try #require(JSONSerialization.jsonObject(with: filer["Hav.xcassets/backgroundAccent.colorset/Contents.json"]!) as? [String: Any])
        let farger = try #require(json["colors"] as? [[String: Any]])
        #expect(farger.count == 4)
        let utseender = farger.compactMap { $0["appearances"] as? [[String: String]] }.flatMap { $0 }
        #expect(utseender.contains { $0["appearance"] == "contrast" && $0["value"] == "high" })
    }

    @Test func aliasPekerPåPrimitiver() throws {
        let filer = DesignsystemEksport.filer(ds, formater: [.designTokens], navn: "Hav")
        let prim = try #require(JSONSerialization.jsonObject(with: filer["tokens/primitives.tokens.json"]!) as? [String: Any])
        let palett = try #require(prim["palette"] as? [String: Any])
        for modus in Designmodus.allCases {
            let fil = try #require(filer["tokens/\(modus.tokennavn).tokens.json"])
            let farger = try #require((JSONSerialization.jsonObject(with: fil) as? [String: Any])?["color"] as? [String: Any])
            var antall = 0
            for (egenskap, innhold) in farger where !egenskap.hasPrefix("$") {
                let gruppe = try #require(innhold as? [String: Any])
                for (navn, token) in gruppe {
                    let verdi = (token as? [String: Any])?["$value"]
                    let alias = try #require(verdi as? String, "\(modus) \(egenskap).\(navn) er ikke alias")
                    let sti = alias.dropFirst().dropLast().split(separator: ".").map(String.init)
                    #expect(sti.count == 3 && sti[0] == "palette")
                    #expect((palett[sti[1]] as? [String: Any])?[sti[2]] != nil, "\(alias) finnes ikke")
                    antall += 1
                }
            }
            #expect(antall == ds.tema(modus).tokens.count)
        }
        #expect(filer["tokens/resolver.json"] != nil)
    }

    @Test func cssMedLightDark() {
        let css = String(decoding: DesignsystemEksport.filer(ds, formater: [.css], navn: "Hav")["hav.css"]!, as: UTF8.self)
        #expect(css.contains("color-scheme: light dark;"))
        #expect(css.contains("--color-background-accent: light-dark(#"))
        #expect(css.contains("--color-text-secondary: light-dark(#"))
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
        #expect(tekst.contains("`color.text.on-accent`"))
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
        #expect(tekst.contains("`color.text.on-accent` / `color.background.accent`"))
    }
}

@Suite("Designsystem-avsender")
struct DesignsystemAvsenderTests {
    @Test func sammeNavnIAlleFormater() {
        let t = Designsystem(fra: Palett(navn: "Hav", farger: [PalettFarge(farge: Farge(hex: "#2F7FD8")!)])).tema(.lys).tokens
        let sekundær = t.first { $0.sti == ["text", "secondary"] }!
        #expect(sekundær.navn == "color.text.secondary")
        #expect(sekundær.figmanavn == "color/text/secondary")
        #expect(sekundær.cssNavn == "--color-text-secondary")
        #expect(sekundær.xcodeNavn == "textSecondary")
        #expect(Set(t.map(\.navn)).count == t.count)
        #expect(Set(t.map(\.xcodeNavn)).count == t.count)
    }

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
        #expect(css.contains("--color-background-accent: light-dark(#"))
        #expect(css.contains("@supports (color: color(display-p3 0 0 0))"))
        #expect(css.contains("@media (color-gamut: p3)"))
        #expect(css.contains("--color-background-accent: light-dark(color(display-p3 "))
        // Nøytralene er like i begge og står bare i sRGB-delen.
        #expect(!css.contains("--color-background-surface: light-dark(color(display-p3"))
    }

    /// En merkefarge i sRGB står bare i sRGB-delen; statusfargene (standard) og nøytralene står der de skiller seg.
    @Test func merkefargeISRGBUtenP3() {
        let ds = Designsystem(fra: Palett(navn: "Grå", farger: [PalettFarge(farge: Farge(hex: "#336699")!)]))
        let css = String(decoding: DesignsystemEksport.filer(ds, formater: [.css], navn: "Grå")["gra.css"]!, as: UTF8.self)
        #expect(!css.contains("--color-background-accent: light-dark(color(display-p3"))
        #expect(!css.contains("--color-text-primary: light-dark(color(display-p3"))
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
            #expect(Set(farger.keys) == ["background", "text", "border"])
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
            #expect(navn.contains("color/background/danger"))
            #expect(navn.contains("color/border/focus"))
            #expect(Set(ds.tema(modus).tokens.map(\.figmanavn)) == navn)
            navnesett.append(navn)
        }
        #expect(Set(navnesett).count == 1)
    }
}

@Suite("Egne roller i designsystemet")
struct EgneRollerTests {
    private func system(_ egne: [EgenRolle]) -> Designsystem {
        var ds = Designsystem(fra: Palett(navn: "Hav", farger: [PalettFarge(farge: Farge(hex: "#2F7FD8")!)]))
        ds.egneRoller = egne
        return ds
    }

    @Test func eldreDataUtenEgneRollerLeses() throws {
        let ds = system([])
        let data = try JSONEncoder().encode(ds)
        #expect(!String(decoding: data, as: UTF8.self).contains("egneRoller"))
        #expect(try JSONDecoder().decode(Designsystem.self, from: data).egneRoller.isEmpty)
        let med = system([.info])
        #expect(try JSONDecoder().decode(Designsystem.self, from: JSONEncoder().encode(med)) == med)
    }

    @Test func tokennavnErUnikeOgGyldige() {
        let ds = system([EgenRolle(navn: "Tilbud på kjøtt", farge: Farge(hex: "#C04040")!, mal: .status),
                         EgenRolle(navn: "Accent", farge: Farge(hex: "#40A040")!, mal: .aksent),
                         EgenRolle(navn: "Kategori", farge: Farge(hex: "#8040C0")!, mal: .markering),
                         EgenRolle(navn: "kategori", farge: Farge(hex: "#408080")!, mal: .markering)])
        #expect(ds.egneTokennavn == ["tilbud-pa-kjott", "accent-2", "kategori", "kategori-2"])
        let navn = ds.tema(.lys).tokens.map(\.navn)
        #expect(Set(navn).count == navn.count)
        #expect(navn.contains("color.background.tilbud-pa-kjott"))
        #expect(navn.contains("color.text.on-accent-2"))
        #expect(navn.contains("color.background.accent-2-pressed"))
        #expect(navn.contains("color.border.kategori"))
    }

    /// Alle maler holder kravene i alle moduser og tilstander, for mange kulører og lysheter.
    @Test(arguments: [0.0, 60, 120, 180, 240, 300])
    func egneRollerHolderKravene(kulør: Double) {
        for l in [0.35, 0.6, 0.85] {
            let f = Farge(okLCH: OKLCH(l: l, c: 0.15, h: kulør)).gamutKartlagt(til: .sRGB)
            let ds = system(Rollemal.allCases.map { EgenRolle(navn: $0.rawValue, farge: f, mal: $0) })
            for modus in Designmodus.allCases {
                for tilstand in Komponenttilstand.allCases {
                    for s in ds.tema(modus).sjekker(tilstand) where s.rolle != nil {
                        #expect(s.består, "\(modus) \(tilstand) \(s.id): \(s.forhold)")
                    }
                }
            }
        }
    }

    @Test func eksportOgReadmeTarMedEgneRoller() throws {
        let ds = system([.info, EgenRolle(navn: "Kategori", farge: Farge(hex: "#8040C0")!, mal: .markering)])
        let filer = DesignsystemEksport.filer(ds, formater: Set(DesignsystemEksport.Format.allCases), navn: "Hav")
        let css = String(decoding: filer["hav.css"]!, as: UTF8.self)
        #expect(css.contains("--color-background-info: light-dark(#"))
        #expect(css.contains("--color-border-kategori: light-dark(#"))
        #expect(filer["Hav.xcassets/textInfo.colorset/Contents.json"] != nil)
        let prim = try #require(JSONSerialization.jsonObject(with: filer["tokens/primitives.tokens.json"]!) as? [String: Any])
        #expect(((prim["palette"] as? [String: Any])?["info"] as? [String: Any])?["500"] != nil)
        let readme = String(decoding: filer["README.md"]!, as: UTF8.self)
        #expect(readme.contains("| info |"))
        #expect(readme.contains("`color.border.kategori`"))
    }
}

@Suite("Designsystem i delingslenker")
struct DesignsystemLenkeTests {
    private func lenke(_ ds: Designsystem) throws -> URL {
        let innhold = DeltInnhold(slag: .palett, navn: ds.navn,
                                  farger: DeltDesignsystem.farger(ds, rollenavn: { $0.rawValue }),
                                  designsystem: DeltDesignsystem(ds))
        return try Delingslenke.lenke(innhold)
    }

    @Test func rundtur() throws {
        var ds = Designsystem(fra: Palett(navn: "Hav", farger: [PalettFarge(farge: Farge(hex: "#2F7FD8")!),
                                                                PalettFarge(farge: Farge(hex: "#C95530")!)]))
        ds.egneRoller = [.info, EgenRolle(navn: "Kategori", farge: Farge(hex: "#8040C0")!, mal: .markering)]
        let url = try lenke(ds)
        #expect(url.absoluteString.count < 4000)
        let lest = try Delingslenke.les(url)
        #expect(lest.slag == .palett)
        #expect(lest.farger.count == Designrolle.allCases.count + 2)
        let dd = try #require(lest.designsystem)
        let igjen = dd.designsystem(navn: lest.navn ?? "", farger: lest.farger)
        #expect(igjen.egneRoller.map(\.navn) == ["info", "Kategori"])
        #expect(igjen.egneRoller.map(\.mal) == [.status, .markering])
        // Samme farger i alle moduser som originalen; avrundingen i lenken kan gi én enhet i en kanal.
        func kanaler(_ f: Farge) -> [Int] {
            let h = f.hex().dropFirst()
            return stride(from: 0, to: 6, by: 2).map { Int(h.dropFirst($0).prefix(2), radix: 16)! }
        }
        for modus in Designmodus.allCases {
            for (a, b) in zip(igjen.tema(modus).tokens, ds.tema(modus).tokens) {
                #expect(zip(kanaler(a.farge), kanaler(b.farge)).allSatisfy { abs($0 - $1) <= 1 }, "\(modus) \(a.navn)")
            }
        }
        #expect(dd.moduser["dark"]?.count == dd.tokennavn.count)
        #expect(dd.tokennavn.contains("color.text.on-accent"))
    }

    @Test func skadetDesignsystemGirPalett() throws {
        let ds = Designsystem(fra: Palett(navn: "Hav", farger: [PalettFarge(farge: Farge(hex: "#2F7FD8")!)]))
        var dd = DeltDesignsystem(ds)
        dd.moduser["light"] = ["zzzzzz"]
        let innhold = DeltInnhold(slag: .palett, navn: "Hav", farger: DeltDesignsystem.farger(ds, rollenavn: { $0.rawValue }),
                                  designsystem: dd)
        let lest = try Delingslenke.les(try Delingslenke.lenke(innhold))
        #expect(lest.designsystem == nil)
        #expect(lest.farger.count == Designrolle.allCases.count)
    }
}
