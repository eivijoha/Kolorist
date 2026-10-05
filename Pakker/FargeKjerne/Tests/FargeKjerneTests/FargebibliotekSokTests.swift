import Foundation
import Testing
@testable import FargeKjerne

@Suite("Søk i fargebibliotek")
struct FargebibliotekSøkTests {
    /// Det raske søket (Lab-avstand først, ΔE2000 for de nærmeste) gir samme tone som et fullt ΔE2000-søk.
    @Test func sammeSomFulltSøk() throws {
        let bibliotek = try #require(Filamentfarger.biblioteker.first { $0.id == "bib:filament-alle" })
        var generator = SystemRandomNumberGenerator()
        var avvik = 0
        for _ in 0..<400 {
            let f = Farge(okLab: OKLab(l: .random(in: 0.2...0.95, using: &generator), a: .random(in: -0.25...0.25, using: &generator),
                                       b: .random(in: -0.25...0.25, using: &generator))).gamutKartlagt(til: .displayP3)
            let fullt = bibliotek.farger.min { f.deltaE2000(til: $0.farge) < f.deltaE2000(til: $1.farge) }!
            let raskt = try #require(bibliotek.nærmeste(til: f))
            if abs(raskt.avstand - f.deltaE2000(til: fullt.farge)) > 1e-9 { avvik += 1 }
        }
        #expect(avvik == 0)
    }
}
