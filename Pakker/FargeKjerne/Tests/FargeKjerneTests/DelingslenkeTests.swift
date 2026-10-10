import Foundation
import Testing
@testable import FargeKjerne

@Suite("Delingslenker")
struct DelingslenkeTests {
    /// Faste eksempler. Lenkene de gir står i `Testlenker.json`, som også visningssiden på kolorist.no testes mot.
    static var eksempler: [(navn: String, innhold: DeltInnhold)] {
        let tegl = Farge(hex: "#B66248")!
        let farge = DeltInnhold(slag: .farge, farger: [
            DeltFarge(tegl, navn: "Tegl", representasjon: Fargerepresentasjon(modell: .cieLab, farge: tegl)),
        ])
        let kyst = ["#1F3A4D", "#3F6E85", "#8FB3C7", "#E6DCC8", "#C8553D"]
        var kystfarger = zip(kyst, ["Dyp fjord", "Kystblå", "Disig himmel", "Sand", "Naust"]).map {
            DeltFarge(Farge(hex: $0)!, navn: $1)
        }
        kystfarger[4] = DeltFarge(Farge(hex: "#C8553D")!, navn: "Naust",
                                  representasjon: Fargerepresentasjon(rom: .icc(id: "kCGColorSpaceGenericCMYK", navn: "Generisk CMYK"),
                                                                      verdier: [10, 78, 82, 2], tekst: "10 / 78 / 82 / 2%"))
        let palett = DeltInnhold(slag: .palett, navn: "Nordisk kyst", farger: kystfarger, gradienter: [
            DeltGradient(navn: "Skumring", stopp: [DeltStopp(DeltFarge(Farge(hex: "#1F3A4D")!)), DeltStopp(DeltFarge(Farge(hex: "#F29E6D")!))],
                         antall: 7),
        ])
        let gradient = DeltInnhold(slag: .gradient, gradienter: [
            DeltGradient(navn: "Solnedgang",
                         stopp: [DeltStopp(DeltFarge(Farge(hex: "#2B2D6E")!), posisjon: 0),
                                 DeltStopp(DeltFarge(Farge(hex: "#C8553D")!), posisjon: 0.3),
                                 DeltStopp(DeltFarge(Farge(hex: "#F2B84B")!), posisjon: 1)],
                         antall: 9, trinn: Lyshetstrinn(antallLysere: 2, antallMørkere: 2, lysereSteg: 0.08, mørkereSteg: 0.08)),
        ])
        let grunn = Farge(hex: "#2F7FD8")!
        let triade = Harmoni.triade.farger(fra: grunn, sirkel: .okLCH, gamut: .displayP3).map { DeltFarge($0) }
        let harmoni = DeltInnhold(slag: .harmoni, navn: "Triade", farger: triade,
                                  harmoni: DeltHarmoni(harmoni: .triade, sirkel: .okLCH, grunn: grunn, antall: nil, vinkel: nil,
                                                       lyshetsrekkefølge: .naturlig, grunnIndeks: 0))
        // Utenfor sRGB (bare P3) og halvt gjennomsiktig: hex er gamut-kartlagt.
        let bred = DeltInnhold(slag: .farge, farger: [
            DeltFarge(Farge(okLCH: OKLCH(l: 0.75, c: 0.25, h: 145), alfa: 0.5), navn: "Klar grønn"),
        ])
        return [("farge", farge), ("palett", palett), ("gradient", gradient), ("harmoni", harmoni), ("bred", bred)]
    }

    @Test func rundturForAlleSlag() throws {
        for (navn, innhold) in Self.eksempler {
            let lenke = try Delingslenke.lenke(innhold)
            #expect(lenke.absoluteString.hasPrefix("https://kolorist.no/l#z"), "\(navn)")
            let lest = try Delingslenke.les(lenke)
            #expect(lest == innhold, "\(navn)")
        }
    }

    @Test func fargenKommerTilbakeNøyaktig() throws {
        let f = Farge(hex: "#B66248")!
        let lest = try Delingslenke.les(Delingslenke.lenke(DeltInnhold(slag: .farge, farger: [DeltFarge(f)])))
        #expect(lest.farger[0].farge.avstandOK(til: f) < 0.0001)
        #expect(lest.farger[0].farge.hex() == "#B66248")
    }

    @Test func gradientMedFlereStopp() throws {
        let innhold = Self.eksempler.first { $0.navn == "gradient" }!.innhold
        let lest = try Delingslenke.les(Delingslenke.lenke(innhold))
        #expect(lest.gradienter[0].stopp.count == 3)
        #expect(lest.gradienter[0].stopp.map(\.posisjon) == [0, 0.3, 1])
        #expect(lest.gradienter[0].trinn?.lyshetstrinn.antallLysere == 2)
    }

    @Test func iccRepresentasjonBareMedProfilen() throws {
        let innhold = Self.eksempler.first { $0.navn == "palett" }!.innhold
        let naust = try Delingslenke.les(Delingslenke.lenke(innhold)).farger[4]
        #expect(naust.representasjon(harProfil: { _ in false }) == nil)
        #expect(naust.representasjon(harProfil: { $0 == "kCGColorSpaceGenericCMYK" })?.tekst == "10 / 78 / 82 / 2%")
        let tegl = Self.eksempler[0].innhold.farger[0]
        #expect(tegl.representasjon(harProfil: { _ in false })?.rom == .modell(.cieLab))
    }

    /// Lenker laget før 1.3.1 kan ha en fargemodell som er tatt ut (og feltet `mu`): fargen leses, uten representasjon.
    @Test func uttattModellILenkeGirFargeUtenRepresentasjon() throws {
        let lest = try Delingslenke.les(URL(string: "https://kolorist.no/l#zq1ZKU7KKrlbKBpIGeqYWFkYmOgZ6BpYGlhYg2tzA0ixWRym3VMlKydAgSMFU30JJRykPyAtJTc8BMouAzNz8lNScHKvc0rxiIA0SBCnwRXBLUHQXlQHtMjTQMdWxABpdAZRzMjMzMrFQqgVyQUrTEovSU4EKgeoMawE")!)
        #expect(lest.farger[0].farge.hex() == "#B66248")
        #expect(lest.farger[0].representasjon(harProfil: { _ in true }) == nil)
    }

    @Test func koloristSkjemaOgWwwGodtas() throws {
        let fragment = try Delingslenke.kode(Self.eksempler[0].innhold)
        for adresse in ["kolorist://l#\(fragment)", "https://www.kolorist.no/l/#\(fragment)"] {
            #expect(try Delingslenke.les(URL(string: adresse)!) == Self.eksempler[0].innhold, "\(adresse)")
        }
    }

    @Test func fremmedeOgSkadedeLenkerAvvises() throws {
        let fragment = try Delingslenke.kode(Self.eksempler[0].innhold)
        #expect(throws: Delingslenke.Feil.ikkeKoloristlenke) { try Delingslenke.les(URL(string: "https://eksempel.no/l#\(fragment)")!) }
        #expect(throws: Delingslenke.Feil.ikkeKoloristlenke) { try Delingslenke.les(URL(string: "https://kolorist.no/annet#\(fragment)")!) }
        #expect(throws: Delingslenke.Feil.skadet) { try Delingslenke.les(URL(string: "https://kolorist.no/l#\(fragment.dropLast(12))")!) }
        #expect(throws: Delingslenke.Feil.skadet) { try Delingslenke.les(URL(string: "https://kolorist.no/l#zIkkeBase64!!")!) }
    }

    @Test func forMangeFargerAvvises() throws {
        let mange = DeltInnhold(slag: .palett, farger: (0..<300).map { DeltFarge(Farge(okLCH: OKLCH(l: 0.5, c: 0.1, h: Double($0)))) })
        // Skriving sjekker bare lengden; lesing sjekker antallet.
        if let lenke = try? Delingslenke.lenke(mange) {
            #expect(throws: Delingslenke.Feil.forStor) { try Delingslenke.les(lenke) }
        }
    }

    @Test func kildenFølgerMedOgFremmedeLenkerFjernes() throws {
        let kilde = Fargekilde(produsent: "Produsent", navn: "Rød", materiale: "PLA",
                               lenke: URL(string: "https://filamentcolors.xyz/swatch/1/"), målt: true, td: 1.2, kildenavn: "FilamentColors.xyz")
        let pf = PalettFarge(navn: "Produsent Rød (PLA)", farge: Farge(hex: "#C8553D")!, kilde: kilde)
        let lest = try Delingslenke.les(Delingslenke.lenke(DeltInnhold(slag: .farge, farger: [DeltFarge(pf)])))
        #expect(lest.farger[0].palettFarge(harProfil: { _ in false }).kilde == kilde)

        var falsk = DeltFarge(pf)
        falsk.kilde?.lenke = "https://eksempel.no/lur"
        let lestFalsk = try Delingslenke.les(Delingslenke.lenke(DeltInnhold(slag: .farge, farger: [falsk])))
        #expect(lestFalsk.farger[0].kilde?.lenke == nil)
        #expect(lestFalsk.farger[0].palettFarge(harProfil: { _ in false }).kilde?.lenke == nil)
    }

    @Test func tekstRenses() throws {
        var innhold = Self.eksempler[0].innhold
        innhold.navn = "Farge\u{0007}navn" + String(repeating: "x", count: 500)
        let lest = try Delingslenke.les(Delingslenke.lenke(innhold))
        #expect(lest.navn?.contains("\u{0007}") == false)
        #expect((lest.navn?.count ?? 0) <= Delingslenke.maksNavn)
    }

    @Test func språketFølgerMed() throws {
        var innhold = Self.eksempler.first { $0.navn == "palett" }!.innhold
        innhold.språk = "en"
        #expect(try Delingslenke.les(Delingslenke.lenke(innhold)).språk == "en")
        innhold.språk = "<script>"
        #expect(try Delingslenke.les(Delingslenke.lenke(innhold)).språk == nil)
    }

    @Test func lengdenErRimelig() throws {
        let palett = Self.eksempler.first { $0.navn == "palett" }!.innhold
        #expect(try Delingslenke.lenke(palett).absoluteString.count < 1000)
    }

    /// Lenkene for eksemplene skal ikke endre seg (formatet er stabilt), og visningssiden testes mot de samme.
    /// Sett miljøvariabelen `LAG_TESTLENKER=1` for å skrive fila på nytt etter en bevisst formatendring.
    @Test func testlenkerErStabile() throws {
        let fil = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Testlenker.json")
        var nye: [[String: Any]] = []
        for (navn, innhold) in Self.eksempler {
            // Språket følger maskinen testen kjører på; testlenkene er uten, som eldre lenker.
            var innhold = innhold
            innhold.språk = nil
            let lenke = try Delingslenke.lenke(innhold).absoluteString
            let farger = (innhold.farger + innhold.gradienter.flatMap { $0.stopp.map(\.farge) }).map { f -> [String: Any] in
                let lab = f.farge.cieLab, lch = f.farge.okLCH
                return ["hex": f.farge.hex(), "okLCH": [lch.l, lch.c, lch.h], "cieLab": [lab.l, lab.a, lab.b]]
            }
            nye.append(["navn": navn, "lenke": lenke, "slag": innhold.slag?.rawValue ?? "", "farger": farger])
        }
        if ProcessInfo.processInfo.environment["LAG_TESTLENKER"] == "1" {
            let data = try JSONSerialization.data(withJSONObject: nye, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            try data.write(to: fil)
            return
        }
        let lagret = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: fil)) as? [[String: Any]])
        #expect(lagret.map { $0["lenke"] as? String } == nye.map { $0["lenke"] as? String })
    }
}
