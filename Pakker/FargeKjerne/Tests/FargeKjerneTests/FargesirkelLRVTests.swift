import FargeKjerne
import Testing

@Suite("Fargesirkler")
struct FargesirkelTests {
    /// Herings motfargesirkel: unik gul ligger på 0°, og motfargen (180°) er unik blå; rød ↔ grønn.
    @Test func heringsMotfarger() throws {
        let gul = Farge(hex: "#FFD300")!, blå = Farge(hex: "#0087BD")!, rød = Farge(hex: "#C40233")!
        #expect(abs(Fargesirkel.hering.vinkel(for: gul)) < 0.5 || abs(Fargesirkel.hering.vinkel(for: gul) - 360) < 0.5)
        #expect(abs(Fargesirkel.hering.vinkel(for: blå) - 180) < 0.5)
        #expect(abs(Fargesirkel.hering.vinkel(for: rød) - 90) < 0.5)
        #expect(abs(Hering.okLCHKulør(forVinkel: 180) - blå.okLCH.h) < 0.01)
        #expect(abs(Hering.okLCHKulør(forVinkel: 270) - Farge(hex: "#009F6B")!.okLCH.h) < 0.01)
        // Rundtur vinkel → kulør → vinkel
        for v in stride(from: 0.0, to: 360, by: 15) {
            #expect(abs(Hering.vinkel(forOKLCHKulør: Hering.okLCHKulør(forVinkel: v)) - v) < 0.01)
        }
    }

    /// Goethes sirkel: purpur på 0°, gul på 120° med fiolett som motfarge (300°), blå ↔ oransje.
    @Test func goethesMotfarger() throws {
        let purpur = Farge(hex: "#C2185B")!, gul = Farge(hex: "#F9D71C")!, fiolett = Farge(hex: "#6A3D9A")!
        let v = Fargesirkel.goethe.vinkel(for: purpur)
        #expect(v < 0.5 || v > 359.5)
        #expect(abs(Fargesirkel.goethe.vinkel(for: gul) - 120) < 0.5)
        #expect(abs(Fargesirkel.goethe.vinkel(for: fiolett) - 300) < 0.5)
        #expect(abs(Goethe.okLCHKulør(forVinkel: 240) - Farge(hex: "#1E63B5")!.okLCH.h) < 0.01)
        for v in stride(from: 0.0, to: 360, by: 15) {
            #expect(abs(Goethe.vinkel(forOKLCHKulør: Goethe.okLCHKulør(forVinkel: v)) - v) < 0.01)
        }
        // Uavhengig av språk (testene kan kjøre på engelsk).
        #expect(Goethe.sammensetning(vinkel: 150).hasPrefix("50% ") && Goethe.sammensetning(vinkel: 150).contains(", 50% "))
        #expect(!Goethe.sammensetning(vinkel: 120).contains("%"))
    }
}

@Suite("LRV")
struct LRVTests {
    @Test func lrvOgFlatekontrast() {
        #expect(abs(Farge(hex: "#FFFFFF")!.lrv - 100) < 0.01)
        #expect(Farge(hex: "#000000")!.lrv == 0)
        #expect(abs(Farge(hex: "#808080")!.lrv - 21.6) < 0.2)
        let k = Flatekontrast(Farge(hex: "#FFFFFF")!, Farge(hex: "#808080")!)
        #expect(k.består(.lrv30) && k.består(.luminans04) && k.består(.michelson60))
        // Weber med mørkere bakgrunn som referanse: (100 − 21,6) / 21,6 ≈ 3,6.
        #expect(abs(k.weber - 3.63) < 0.05 && k.består(.luminans08))
        // Omvendt (grå flate på hvit bakgrunn): (100 − 21,6) / 100 ≈ 0,78 – under 0,8.
        let omvendt = Flatekontrast(Farge(hex: "#808080")!, Farge(hex: "#FFFFFF")!)
        #expect(omvendt.består(.luminans04) && !omvendt.består(.luminans08))
        #expect(abs(omvendt.michelson - k.michelson) < 1e-12)
        let lik = Flatekontrast(Farge(hex: "#2F7FD8")!, Farge(hex: "#3A86DE")!)
        #expect(!lik.består(.lrv30))
        let rettet = lik.rettet(for: .lrv30, gamut: .sRGB)
        #expect(Flatekontrast(rettet, Farge(hex: "#3A86DE")!).består(.lrv30))
        // Kuløren bevares når lysheten endres.
        #expect(abs(rettet.okLCH.h - Farge(hex: "#2F7FD8")!.okLCH.h) < 8)  // gamut-kartlegging kan flytte kuløren litt
        let rettetWeber = lik.rettet(for: .luminans08, gamut: .sRGB)
        #expect(Flatekontrast(rettetWeber, Farge(hex: "#3A86DE")!).består(.luminans08))
    }

    /// Regneeksemplet i NBKF Faglig veileder 3-2024 (luminanskontrast etter TEK17): Y 43 mot 13.
    @Test func weberSomINorskPraksis() {
        #expect(abs(Flatekontrast.weber(objekt: 43, bakgrunn: 13) - 2.31) < 0.005)
        #expect(abs(Flatekontrast.weber(objekt: 13, bakgrunn: 43) - 0.70) < 0.005)
        #expect(Flatekontrast.weber(objekt: 20, bakgrunn: 0) == 40)  // sort bakgrunn: referansen er minst 0,5
        #expect(abs(Flatekontrast.michelson(43, 13) - 30.0 / 56.0) < 1e-12)
        #expect(Flatekontrastmetode.weber.krav == [.luminans04, .luminans08])
        #expect(Flatekontrastmetode.lrvForskjell.krav == [.lrv20, .lrv30])
    }
}
