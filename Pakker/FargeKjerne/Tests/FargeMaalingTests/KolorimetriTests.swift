import FargeKjerne
@testable import FargeMaaling
import Foundation
import Testing

/// Referanseverdiene er regnet ut med colour-science 0.4.4.
@Suite("Kolorimetri og fargetemperatur")
struct KolorimetriTests {
    @Test(arguments: [
        (Lyskilde.dagslys(kelvin: 6504), 0.31272, 0.32903),
        (Lyskilde.dagslys(kelvin: 5003), 0.34567, 0.35851),
        (Lyskilde.a, 0.44758, 0.40745),
        (Lyskilde.cie("FL2"), 0.37207, 0.37512),
        (Lyskilde.cie("LED-B3"), 0.37561, 0.37229),
    ])
    func kromatisitet(lys: Lyskilde, x: Double, y: Double) {
        let p = Kolorimetri.xy(lys.hvitpunkt)
        #expect(abs(p.x - x) < 0.0002)
        #expect(abs(p.y - y) < 0.0002)
    }

    @Test(arguments: [
        (0.31272, 0.32903, 6502.97, 0.0032),
        (0.44758, 0.40745, 2855.53, 0.0),
        (0.37207, 0.37512, 4224.48, 0.0018),
        (0.37561, 0.37229, 4102.50, -0.0007),
    ])
    func fargetemperaturOhno(x: Double, y: Double, kelvin: Double, duv: Double) throws {
        let t = try #require(Kolorimetri.fargetemperatur(x: x, y: y))
        #expect(abs(t.kelvin - kelvin) < 5)
        #expect(abs(t.duv - duv) < 0.0003)
    }

    @Test func fargetemperaturOgTilbake() throws {
        for (k, duv) in [(2700.0, 0.0), (4000, 0.004), (6500, -0.003), (12000, 0.002)] {
            let p = Kolorimetri.xy(kelvin: k, duv: duv)
            let t = try #require(Kolorimetri.fargetemperatur(x: p.x, y: p.y))
            #expect(abs(t.kelvin - k) / k < 0.002)
            #expect(abs(t.duv - duv) < 0.0002)
        }
    }

    @Test func perfektHvitFårLysetsHvitpunkt() {
        let hvit = Spektrum(start: 380, steg: 400, verdier: [1, 1])
        let lys = Lyskilde.cie("FL11").spektrum!
        let v = Kolorimetri.xyz(refleksjon: hvit, under: lys)
        let w = Kolorimetri.xyz(lyskilde: lys)
        #expect(abs(v.x - w.x) < 1e-9 && abs(v.y - 1) < 1e-9 && abs(v.z - w.z) < 1e-9)
    }

    @Test func spekterInterpoleres() {
        let s = Spektrum(start: 400, steg: 10, verdier: [0, 1, 0.5])
        #expect(s.verdi(ved: 405) == 0.5)
        #expect(s.verdi(ved: 415) == 0.75)
        #expect(s.verdi(ved: 300) == 0)
        #expect(s.verdi(ved: 800) == 0.5)
    }
}

@Suite("CAM16")
struct CAM16Tests {
    let xyz = XYZ(x: 0.1931, y: 0.2393, z: 0.1014)
    let hvit = XYZ(x: 0.9505, y: 1, z: 1.0888)

    @Test func framoverGjennomsnittlig() {
        let k = CAM16(Visningsforhold(hvit: hvit, adaptasjonsluminans: 318.31)).korrelater(xyz)
        #expect(abs(k.j - 45.3771) < 0.01)
        #expect(abs(k.c - 33.7721) < 0.01)
        #expect(abs(k.h - 120.9989) < 0.01)
        #expect(abs(k.m - 35.1056) < 0.01)
        #expect(abs(k.s - 41.511) < 0.01)
        #expect(abs(k.q - 203.7275) < 0.02)
    }

    @Test func framoverDempet() {
        let k = CAM16(Visningsforhold(hvit: hvit, adaptasjonsluminans: 20, omgivelse: .dempet)).korrelater(xyz)
        #expect(abs(k.j - 50.5638) < 0.01)
        #expect(abs(k.c - 32.9728) < 0.01)
        #expect(abs(k.h - 123.6057) < 0.01)
        #expect(abs(k.m - 27.2159) < 0.01)
    }

    @Test func tilbakeGirSammeFarge() {
        for forhold in [Visningsforhold.skjerm, .rom(hvit: Lyskilde.a.hvitpunkt, lux: 150),
                        Visningsforhold(hvit: hvit, adaptasjonsluminans: 4, omgivelse: .mørk)] {
            let modell = CAM16(forhold)
            for farge in ["#1B3A6B", "#F2B84B", "#C40233", "#FFFFFF", "#202020", "#00A86B"] {
                let v = Farge(hex: farge)!.xyz
                let tilbake = modell.xyz(modell.korrelater(v))
                #expect(abs(tilbake.x - v.x) < 1e-6 && abs(tilbake.y - v.y) < 1e-6 && abs(tilbake.z - v.z) < 1e-6)
            }
        }
    }

    @Test func cat16BeholderHvittOgFlytterHvitpunkt() {
        let a = Lyskilde.a.hvitpunkt, d65 = Lyskilde.d65.hvitpunkt
        let v = CAT16.tilpass(a, fra: a, til: d65)
        #expect(abs(v.x - d65.x) < 1e-9 && abs(v.y - d65.y) < 1e-9 && abs(v.z - d65.z) < 1e-9)
        let delvis = CAT16.tilpass(a, fra: a, til: d65, grad: 0)
        #expect(abs(delvis.x - a.x) < 1e-9)
    }
}
