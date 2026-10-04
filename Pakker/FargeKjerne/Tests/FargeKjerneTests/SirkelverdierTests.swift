import FargeKjerne
import Foundation
import Testing

@Suite("Munsell-trinn og sirkelverdier")
struct SirkelverdierTests {
    @Test func munsellTrinn() {
        #expect(Munsell.avrundetValør(4.4) == 4)
        #expect(Munsell.avrundetValør(10.7) == 10)
        #expect(Munsell.avrundetKroma(13.1) == 14)
        #expect(Munsell.avrundetKroma(0.9) == 0)
        #expect(Munsell(kulør: 5, valør: Munsell.avrundetValør(4.2), kroma: Munsell.avrundetKroma(13.4)).notasjon == "5R 4/14")
    }

    @Test func verditekstPerSirkel() {
        let f = Farge(hex: "#2F7FD8")!
        #expect(Fargesirkel.munsell.verditekst(for: f) == f.munsell.notasjon)
        #expect(Fargesirkel.okLCH.verditekst(for: f).hasPrefix("OKLCH 59 % 0.156 254°"))
        #expect(Fargesirkel.hsl.verditekst(for: f).hasPrefix("HSL 212°"))
        #expect(Fargesirkel.ryb.verditekst(for: f).hasPrefix("RYB "))
        #expect(Fargesirkel.cieLCH.verditekst(for: Farge(hex: "#808080")!).hasSuffix(" 0°"))
    }

    /// Uavhengig av språk (testene kan kjøre på engelsk).
    @Test func heringSammensetning() {
        #expect(!Hering.sammensetning(vinkel: 0).contains("%"))
        #expect(Hering.sammensetning(vinkel: 27).hasPrefix("70 % "))
        #expect(Hering.sammensetning(vinkel: 27).contains(", 30 % "))
        #expect(Hering.sammensetning(vinkel: 315).hasPrefix("50 % "))
    }
}
