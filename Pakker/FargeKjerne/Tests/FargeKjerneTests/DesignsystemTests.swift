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
