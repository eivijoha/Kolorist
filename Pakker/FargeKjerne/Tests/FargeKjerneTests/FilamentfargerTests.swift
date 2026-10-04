import Foundation
import Testing
@testable import FargeKjerne

@Suite("Filamentfarger")
struct FilamentfargerTests {
    @Test func uttrekketLastes() throws {
        let om = try #require(Filamentfarger.om)
        let biblioteker = Filamentfarger.biblioteker
        #expect(biblioteker.count == 5)
        #expect(biblioteker.reduce(0) { $0 + $1.farger.count } == om.antall)
        #expect(om.lisens == "CC BY 4.0")
        #expect(Set(biblioteker.map(\.id)).count == biblioteker.count)
        #expect(biblioteker.allSatisfy { Fargebibliotek.erBibliotekID($0.id) })
    }

    @Test func hverToneLenkerTilKilden() throws {
        let pla = try #require(Filamentfarger.biblioteker.first { $0.id == "bib:filament-pla" })
        for tone in pla.farger.prefix(50) {
            let kilde = try #require(tone.kilde)
            #expect(kilde.lenke?.absoluteString.hasPrefix("https://filamentcolors.xyz/swatch/") == true)
            #expect(kilde.produsent?.isEmpty == false && kilde.materiale?.isEmpty == false)
            #expect(kilde.målt != nil)
        }
        let målt = Filamentfarger.biblioteker.flatMap(\.farger).filter { $0.kilde?.målt == true }.count
        #expect(målt == Filamentfarger.om?.målt)
    }

    /// FilamentColors.xyz' eget eksempel (Blizzard White PCTG): Lab 93,56/−1,18/−1,16 (D65, 10°) gir hex E9EDED
    /// hos dem (uten observatørtilpasning). Kolorists omregning skal ligge svært nær.
    @Test func omregningFraD65_10() {
        let f = Filamentfarger.farge(labD65_10: CIELab(l: 93.56, a: -1.18, b: -1.16))
        #expect(f.deltaE2000(til: Farge(hex: "#E9EDED")!) < 1)
        // Nøytral grå forblir nøytral.
        let grå = Filamentfarger.farge(labD65_10: CIELab(l: 50, a: 0, b: 0)).okLCH
        #expect(grå.c < 0.003)
    }

    @Test func kildenLagresMedFargen() throws {
        let tone = try #require(Filamentfarger.biblioteker.first?.farger.first)
        let data = try JSONEncoder().encode(tone)
        let lest = try JSONDecoder().decode(PalettFarge.self, from: data)
        #expect(lest.kilde == tone.kilde)
    }
}
