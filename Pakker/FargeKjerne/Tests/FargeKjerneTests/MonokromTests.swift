import Foundation
import Testing
@testable import FargeKjerne

@Suite("Monokrom")
struct MonokromTests {
    @Test func tonerLangsStreken() {
        let grunn = Farge(hex: "#2F7FD8")!
        let strek = Monokromstrek.standard(for: grunn)
        let kulør = grunn.okLCH.h
        let toner = strek.toner(kulør: kulør, antall: 6)
        #expect(toner.count == 6)
        // Lysest først, grunnfargen sist, jevnt nedover.
        let l = toner.map(\.okLCH.l)
        #expect(zip(l, l.dropFirst()).allSatisfy { $0 > $1 })
        #expect(abs(l.first! - strek.a.lyshet) < 0.01 && abs(l.last! - strek.b.lyshet) < 0.01)
        #expect(toner.last!.avstandOK(til: grunn) < 0.002)
        // Samme kulør (unntatt nær grått, der kuløren er ubestemt) og innenfor gamut.
        for t in toner where t.okLCH.c > 0.02 {
            #expect(abs(Harmoni.normaliser(t.okLCH.h - kulør + 180) - 180) < 2)
        }
        #expect(toner.allSatisfy { $0.gamutKartlagt(til: .displayP3).avstandOK(til: $0) < 1e-6 })
    }

    @Test func metningErAndelAvGamut() {
        let strek = Monokromstrek(a: .init(lyshet: 0.7, metning: 1), b: .init(lyshet: 0.4, metning: 0))
        let toner = strek.toner(kulør: 150, antall: 2, gamut: .sRGB)
        #expect(abs(toner[0].okLCH.c - Farge.maksKroma(lyshet: 0.7, kulør: 150, i: .sRGB)) < 0.005)
        #expect(toner[1].okLCH.c < 0.001)
    }

    @Test func tekstRundtur() {
        let strek = Monokromstrek(a: .init(lyshet: 0.9, metning: 0.2), b: .init(lyshet: 0.3, metning: 0.8))
        #expect(Monokromstrek(tekst: strek.tekst) == strek)
        #expect(Monokromstrek(tekst: "tull") == nil)
    }

    @Test func grupperDekkerAlleHarmonieneIRekkefølge() {
        #expect(Harmoni.grupper.flatMap { $0 } == Harmoni.allCases)
    }

    @Test func harmonienHarAntallMenIkkeVinkel() {
        #expect(Harmoni.monokrom.harAntall && !Harmoni.monokrom.harVinkel)
        #expect(Harmoni.monokrom.forskyvninger(antall: 5) == [0, 0, 0, 0, 0])
    }

    /// Tonebane: kuløren går spennet i valgt retning (ikke korteste vei), opptil en hel runde, og lyshet og metning
    /// følger streken som i monokrom.
    @Test func tonebaneGårIValgtRetning() {
        let strek = Monokromstrek(a: .init(lyshet: 0.8, metning: 0.4), b: .init(lyshet: 0.45, metning: 0.9))
        func nær(_ h: Double, _ mål: Double) -> Bool {
            var d = abs(h - mål).truncatingRemainder(dividingBy: 360); if d > 180 { d = 360 - d }
            return d < 3
        }
        // 330° og +60°: over 0° til 30°.
        let kort = strek.toner(fraKulør: 330, spenn: 60, antall: 5, gamut: .sRGB).map(\.okLCH.h)
        #expect(zip(kort, [330.0, 345, 0, 15, 30]).allSatisfy { nær($0, $1) }, "\(kort)")
        // Samme endepunkter den lange veien (−300°): gjennom 180°.
        let lang = strek.toner(fraKulør: 330, spenn: -300, antall: 5, gamut: .sRGB).map(\.okLCH.h)
        #expect(zip(lang, [330.0, 255, 180, 105, 30]).allSatisfy { nær($0, $1) }, "\(lang)")
        // En hel runde: start- og sluttkulør er like, mellomtonene går rundt.
        let runde = strek.toner(fraKulør: 0, spenn: 360, antall: 5, gamut: .sRGB).map(\.okLCH.h)
        #expect(nær(runde[0], 0) && nær(runde[2], 180) && nær(runde[4], 0), "\(runde)")
        let toner = strek.toner(fraKulør: 330, spenn: 60, antall: 5, gamut: .sRGB)
        #expect(abs(toner[0].okLCH.l - 0.8) < 0.01 && abs(toner[4].okLCH.l - 0.45) < 0.01)
        // Spenn 0 gir samme toner som monokrom.
        let lik = strek.toner(fraKulør: 200, spenn: 0, antall: 4, gamut: .sRGB)
        #expect(zip(lik, strek.toner(kulør: 200, antall: 4, gamut: .sRGB)).allSatisfy { $0.avstandOK(til: $1) < 1e-9 })
        #expect(Harmoni.grupper[0] == [.monokrom, .tonebane])
    }
}
