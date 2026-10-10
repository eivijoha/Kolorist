#if os(macOS)
import Foundation
import Testing
@testable import FargeKjerne

@Suite("Installerte ICC-profiler")
struct InstallerteProfilerTests {
    @Test func finnerSystemetsGenerickeCMYK() throws {
        let alle = InstallerteProfiler.finn()
        let cmyk = try #require(alle.first { $0.url.lastPathComponent == "Generic CMYK Profile.icc" })
        #expect(cmyk.klasse == .utdata)
        #expect(cmyk.datarom == .cmyk)
        #expect(cmyk.plassering == .system)
        #expect(cmyk.kanBrukesSomFargerom)
        let profil = try #require(cmyk.profil())
        #expect(profil.modell == .cmyk)
        #expect(profil.antallKomponenter == 4)
    }

    @Test func filtrererPåKlasseOgDatarom() {
        let trykk = InstallerteProfiler.finn(klasser: [.utdata], datarom: [.cmyk])
        #expect(!trykk.isEmpty)
        #expect(trykk.allSatisfy { $0.klasse == .utdata && $0.datarom == .cmyk })
        let rgb = InstallerteProfiler.finn(datarom: [.rgb])
        #expect(rgb.contains { $0.url.lastPathComponent == "Display P3.icc" })
        #expect(rgb.allSatisfy { $0.datarom == .rgb })
    }

    @Test func entydigeOgSorterteNavn() {
        let alle = InstallerteProfiler.finn()
        #expect(Set(alle.map(\.id)).count == alle.count)
        let navn = alle.map(\.visningsnavn)
        #expect(navn == navn.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }

    @Test func plasseringOgGruppe() {
        let hjem = URL(fileURLWithPath: "/Users/test")
        let (p1, g1) = InstallerteProfiler.plassering(for: URL(fileURLWithPath: "/Library/ColorSync/Profiles/Displays/A.icc"), hjem: hjem)
        #expect(p1 == .maskin && g1 == "Displays")
        let (p2, g2) = InstallerteProfiler.plassering(for: URL(fileURLWithPath: "/Users/test/Library/ColorSync/Profiles/B.icc"), hjem: hjem)
        #expect(p2 == .bruker && g2 == InstallertProfil.Plassering.bruker.navn)
        let (p3, _) = InstallerteProfiler.plassering(for: URL(fileURLWithPath: "/tmp/C.icc"), hjem: hjem)
        #expect(p3 == .annen)
    }
}
#endif
