import FargeKjerne
@testable import FargeMaaling
import Foundation
import Testing

@Suite("Lysmiljø og kompensasjon")
struct LysmiljoTests {
    let farger = ["#1B3A6B", "#F2B84B", "#C40233", "#7A4E8F", "#808080", "#00A86B"].map { Farge(hex: $0)! }

    func ΔE(_ a: Farge, _ b: Farge) -> Double { Fargeavstand.deltaE2000(a.cieLab, b.cieLab) }

    @Test func anslåttSpekterGirFargenIDagslys() {
        for f in farger {
            let r = Refleksjonsestimat.spektrum(for: f)
            let v = Kolorimetri.xyz(refleksjon: r, under: Lyskilde.d65.spektrum!)
            #expect(ΔE(Farge(xyz: v), f) < 0.05)
        }
        // Grått gir et flatt spekter.
        let grå = Refleksjonsestimat.spektrum(for: Farge(hex: "#808080")!)
        #expect((grå.verdier.max()! - grå.verdier.min()!) < 0.01)
    }

    /// Et D65-miljø med samme lysstyrke som skjermen endrer ingenting.
    @Test func dagslysVedSkjermensLysstyrkeErUendret() {
        let miljø = Lysmiljø(navn: "Dagslys", lyskilde: .d65, lux: 32 * .pi / 0.2)
        for f in farger { #expect(ΔE(miljø.sett(f), f) < 0.1) }
    }

    @Test func glødelysGjørFargeneVarmere() {
        let miljø = Lysmiljø(navn: "Stua", lyskilde: .sortlegeme(kelvin: 2700), lux: 150)
        let hvit = miljø.sett(Farge(hex: "#FFFFFF")!).cieLab
        #expect(hvit.b > 5)   // gulere, siden øyet ikke tilpasser seg fullt
        let blå = miljø.sett(Farge(hex: "#1B3A6B")!)
        #expect(ΔE(blå, Farge(hex: "#1B3A6B")!) > 1.5)
    }

    @Test func svaktLysGirMindreFargerikeFarger() {
        let sterkt = Lysmiljø(navn: "Sterkt", lyskilde: .d65, lux: 2000)
        let svakt = Lysmiljø(navn: "Svakt", lyskilde: .d65, lux: 20)
        let f = Farge(hex: "#C40233")!
        let c = { (x: Farge) in hypot(x.cieLab.a, x.cieLab.b) }
        #expect(c(svakt.sett(f)) < c(sterkt.sett(f)))   // Hunt-effekten
    }

    /// Trebåndslysrør skifter karakter på farger mer enn et sortlegeme med samme fargetemperatur.
    @Test func fargeskiftErStørreITrebåndslys() throws {
        let fl11 = Lysmiljø(navn: "FL11", lyskilde: .cie("FL11"))
        let t = try #require(Lyskilde.cie("FL11").fargetemperatur)
        let planck = Lysmiljø(navn: "Planck", lyskilde: .sortlegeme(kelvin: t.kelvin))
        let snitt = { (m: Lysmiljø) in self.farger.map { m.fargeskift($0) }.reduce(0, +) / Double(self.farger.count) }
        #expect(snitt(fl11) > snitt(planck))
        #expect(Lysmiljø(navn: "D65", lyskilde: .d65).fargeskift(farger[0]) < 0.05)
    }

    @Test func kompensasjonFraHvitpunktOpphevesAvLyset() {
        let lys = Lyskilde.sortlegeme(kelvin: 3000)
        for f in farger {
            let iLyset = Farge(xyz: CAT16.tilpass(f.xyz, fra: Lyskilde.d65.hvitpunkt, til: lys.hvitpunkt))
            #expect(ΔE(Lyskompensasjon.hvitpunkt(lys).kompensert(iLyset), f) < 0.01)
        }
    }

    @Test func gråkortGirRiktigLyshet() {
        let lys = Lyskilde.cie("LED-B2")
        // Kameraet ser alt 40 % mørkere og i lysets farge.
        func iBildet(_ f: Farge) -> Farge {
            let v = CAT16.tilpass(f.xyz, fra: Lyskilde.d65.hvitpunkt, til: lys.hvitpunkt)
            return Farge(xyz: XYZ(x: v.x * 0.6, y: v.y * 0.6, z: v.z * 0.6))
        }
        let kort = Farge(xyz: XYZ(x: 0.18 * 0.9505, y: 0.18, z: 0.18 * 1.089))
        let komp = Lyskompensasjon.gråkort(målt: iBildet(kort), refleksjon: 0.18)
        for f in farger { #expect(ΔE(komp.kompensert(iBildet(f)), f) < 0.1) }
        let t = komp.fargetemperatur!
        #expect(abs(t.kelvin - 3000) < 150)
    }

    @Test func luxFraEksponering() {
        // f/1.8, 1/50 s, ISO 100, midtgrått kort som er riktig eksponert: L = 12.5 · 3.24 / (0.02 · 100) ≈ 20 cd/m².
        let l = Eksponeringsmåling.luminans(lineærVerdi: 0.18, blender: 1.8, lukkertid: 1.0 / 50, iso: 100)
        #expect(abs(l - 20.25) < 0.01)
        #expect(abs(Eksponeringsmåling.lux(luminans: l, refleksjon: 0.18) - 353.4) < 0.5)
    }

    @Test func anslåttLuxUtenKort() {
        // Samme eksponering uten kort: bildet antas å reflektere 18 % i snitt, altså som det midtgrå kortet over.
        #expect(abs(Eksponeringsmåling.anslåttLux(blender: 1.8, lukkertid: 1.0 / 50, iso: 100) - 353.4) < 0.5)
        // Typisk stue om kvelden (f/1.8, 1/60 s, ISO 400): rundt 100 lx.
        let stue = Eksponeringsmåling.anslåttLux(blender: 1.8, lukkertid: 1.0 / 60, iso: 400)
        #expect(stue > 60 && stue < 150)
    }

    @Test func fargegjengivelse() throws {
        let prøver = (0..<12).map { i -> Spektrum in
            // Syntetiske, glatte refleksjonsspektre (ikke ekte kortdata).
            let senter = 400 + Double(i) * 28
            return Spektrum(start: 380, steg: 5, verdier: (0..<81).map { j in
                0.1 + 0.6 * exp(-pow((380 + Double(j) * 5 - senter) / 45, 2))
            })
        }
        let d65 = try #require(Fargegjengivelse.anslag(lys: Lyskilde.d65.spektrum!, prøver: prøver))
        let glød = try #require(Fargegjengivelse.anslag(lys: Kolorimetri.sortlegeme(kelvin: 2700), prøver: prøver))
        let fl2 = try #require(Fargegjengivelse.anslag(lys: Lyskilde.cie("FL2").spektrum!, prøver: prøver))
        #expect(d65.indeks > 98)
        #expect(glød.indeks > 99)
        #expect(fl2.indeks < d65.indeks - 5)
        #expect(Lystype.anslå(kelvin: 2700, duv: 0, fargegjengivelse: glød.indeks) == .glødelys)
        #expect(Lystype.anslå(kelvin: 4200, duv: 0.008) == .grønnstikk)
    }

    @Test func lysmiljøKanLagres() throws {
        let miljø = Lysmiljø(navn: "Kontoret", lyskilde: .cie("LED-B3"), lux: 500,
                             måling: Lysmåling(kelvin: 4100, duv: -0.001, lux: 480, metode: .gråkort))
        let data = try JSONEncoder().encode(miljø)
        #expect(try JSONDecoder().decode(Lysmiljø.self, from: data) == miljø)
    }
}

@Suite("Paletter i lys")
struct PalettILysTests {
    @Test func svaktLysFørerMørkeFargerSammen() {
        // To mørke, ulike farger: tydelig ulike på skjermen, men nesten like i svakt lys.
        let farger = [Farge(hex: "#2A1E3C")!, Farge(hex: "#1E2E3A")!, Farge(hex: "#F2B84B")!]
        let svakt = Lysmiljø(navn: "Svakt", lyskilde: .sortlegeme(kelvin: 2700), lux: 5)
        let sterkt = Lysmiljø(navn: "Sterkt", lyskilde: .d65, lux: 500)
        #expect(sterkt.sammenfallendePar(farger, påSkjerm: 4, iLyset: 3).isEmpty)
        let iSvakt = svakt.sammenfallendePar(farger, påSkjerm: 4, iLyset: 100).first { $0.a == 0 && $0.b == 1 }!.iLyset
        let iSterkt = sterkt.sammenfallendePar(farger, påSkjerm: 4, iLyset: 100).first { $0.a == 0 && $0.b == 1 }!.iLyset
        #expect(iSvakt < iSterkt * 0.8)
        #expect(svakt.fargeskift(farger).count == 3)
    }
}
