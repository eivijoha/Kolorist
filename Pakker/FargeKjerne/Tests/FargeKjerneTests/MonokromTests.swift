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
}
