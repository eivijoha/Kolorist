import FargeKjerne
import Foundation
import Testing

@Suite("Sirkelverdier")
struct SirkelverdierTests {
    @Test func verditekstPerSirkel() {
        let f = Farge(hex: "#2F7FD8")!
        #expect(Fargesirkel.okLCH.verditekst(for: f).hasPrefix("OKLCH 59% 0.156 254°"))
        #expect(Fargesirkel.hsl.verditekst(for: f).hasPrefix("HSL 212°"))
        #expect(Fargesirkel.ryb.verditekst(for: f).hasPrefix("RYB "))
        #expect(Fargesirkel.cieLCH.verditekst(for: Farge(hex: "#808080")!).hasSuffix(" 0°"))
    }

    @Test func kortTekstPerModell() {
        let f = Farge(hex: "#2F7FD8")!
        #expect(Fargemodell.okLCH.kortTekst(for: f) == "OKLCH 59% 0.156 254°")
        #expect(Fargemodell.rgb.kortTekst(for: f) == "#2F7FD8")
        #expect(Fargemodell.cmyk.kortTekst(for: f).hasPrefix("CMYK ") && Fargemodell.cmyk.kortTekst(for: f).hasSuffix("%"))
        #expect(Fargesirkel.okLCH.verditekst(for: f) == Fargemodell.okLCH.kortTekst(for: f))
    }

    /// Uavhengig av språk (testene kan kjøre på engelsk).
    @Test func heringSammensetning() {
        #expect(!Hering.sammensetning(vinkel: 0).contains("%"))
        #expect(Hering.sammensetning(vinkel: 27).hasPrefix("70% "))
        #expect(Hering.sammensetning(vinkel: 27).contains(", 30% "))
        #expect(Hering.sammensetning(vinkel: 315).hasPrefix("50% "))
    }
}
