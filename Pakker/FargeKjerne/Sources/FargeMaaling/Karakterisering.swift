import FargeKjerne
import Foundation

/// Hvordan et kamera gjengir farger, tilpasset fra et bilde av et referansekort: en tonekurve per kanal fra de
/// nøytrale feltene, og deretter en matrise (eller et rotpolynom) fra kamerafarger til XYZ.
public struct Kamerakarakterisering: Hashable, Codable, Sendable {
    public enum Modell: String, Hashable, Codable, Sendable, CaseIterable {
        /// 3×3-matrise. Robust, lite overtilpasning.
        case matrise
        /// Rotpolynom av grad 2 (Finlayson mfl. 2015): R, G, B, √RG, √GB, √RB. Uavhengig av eksponering.
        case rotpolynom
    }

    public var modell: Modell
    /// Tonekurve per kanal: lineær = forsterkning · verdi^gamma.
    public var gamma: [Double]
    public var forsterkning: [Double]
    /// Egenskaper × 3 (X, Y, Z).
    public var koeffisienter: [[Double]]
    /// Lyset fasiten ble regnet ut under. D65 betyr at modellen kompenserer for lyset i bildet direkte.
    public var lys: Lyskilde
    /// Kameraets snittfarge for de nøytrale feltene (Y = 1). Viser lysets farge når hvitbalansen er låst.
    public var kameraHvit: XYZ
    public var statistikk: Statistikk

    public struct Statistikk: Hashable, Codable, Sendable {
        public var antallFelt: Int
        public var snittΔE: Double
        public var maksΔE: Double
        /// Snitt-ΔE2000 når hvert felt forutsies av en modell tilpasset uten det (et ærligere mål på nøyaktigheten).
        public var kryssvalidertSnittΔE: Double
        public var kryssvalidertMaksΔE: Double
        /// ΔE2000 per felt (kryssvalidert).
        public var avvik: [Double]
    }

    /// Lineariserte kameraverdier.
    public func lineær(_ f: Farge) -> [Double] {
        [f.r, f.g, f.b].enumerated().map { i, v in v <= 0 ? 0 : forsterkning[i] * pow(v, gamma[i]) }
    }

    /// Modellens XYZ under `lys` (hvitt har Y = 1).
    public func xyz(fraKamera f: Farge) -> XYZ {
        let x = Self.egenskaper(lineær(f), modell: modell)
        let v = (0..<3).map { j in zip(x, koeffisienter).reduce(0) { $0 + $1.0 * $1.1[j] } }
        return XYZ(x: v[0], y: v[1], z: v[2])
    }

    /// Fargen slik flaten ser ut i dagslys.
    public func farge(fraKamera f: Farge) -> Farge {
        Farge(xyz: CAT16.tilpass(xyz(fraKamera: f), fra: lys.hvitpunkt, til: Lyskilde.d65.hvitpunkt), alfa: f.alfa)
    }

    static func egenskaper(_ v: [Double], modell: Modell) -> [Double] {
        switch modell {
        case .matrise: return v
        case .rotpolynom:
            let (r, g, b) = (max(v[0], 0), max(v[1], 0), max(v[2], 0))
            return [r, g, b, sqrt(r * g), sqrt(g * b), sqrt(r * b)]
        }
    }

    /// Tilpasser begge modellene og velger den med lavest kryssvalidert snitt-ΔE00.
    public static func beste(kamera: [Farge], referanse: Referansekort, lys: Lyskilde = .d65) -> Kamerakarakterisering? {
        Modell.allCases.compactMap { tilpass(kamera: kamera, referanse: referanse, lys: lys, modell: $0) }
            .min { $0.statistikk.kryssvalidertSnittΔE < $1.statistikk.kryssvalidertSnittΔE }
    }

    /// Tilpasser en karakterisering. `kamera` er fargene kameraet ga for feltene, i kortets rekkefølge.
    public static func tilpass(kamera: [Farge], referanse: Referansekort, lys: Lyskilde = .d65,
                               modell: Modell = .matrise) -> Kamerakarakterisering? {
        let n = min(kamera.count, referanse.felt.count)
        let minimum = modell == .matrise ? 4 : 8
        guard n >= minimum else { return nil }
        let mål = referanse.felt.prefix(n).map { $0.verdi.xyz(under: lys) }
        let nøytrale = referanse.nøytrale.filter { $0 < n }
        guard var k = tilpass(kamera: kamera, mål: mål, nøytrale: nøytrale, indekser: Array(0..<n), lys: lys, modell: modell)
        else { return nil }

        if !nøytrale.isEmpty {
            let sum = nøytrale.reduce(XYZ(x: 0, y: 0, z: 0)) { s, i in
                let v = kamera[i].xyz
                return XYZ(x: s.x + v.x, y: s.y + v.y, z: s.z + v.z)
            }
            if sum.y > 0 { k.kameraHvit = XYZ(x: sum.x / sum.y, y: 1, z: sum.z / sum.y) }
        }

        // Treffsikkerhet, i Lab etter tilpasning til dagslys så tallene kan sammenlignes på tvers av lys.
        let tilD65 = CAT16.matrise(fra: lys.hvitpunkt, til: Lyskilde.d65.hvitpunkt)
        func avvik(_ v: XYZ, _ i: Int) -> Double {
            Fargeavstand.deltaE2000(Farge(xyz: tilD65.ganget(v)).cieLab, Farge(xyz: tilD65.ganget(mål[i])).cieLab)
        }
        let direkte = (0..<n).map { avvik(k.xyz(fraKamera: kamera[$0]), $0) }
        // Kryssvalidert: både tonekurven og matrisen tilpasses uten feltet som forutsies.
        let kryss = (0..<n).map { i -> Double in
            let uten = (0..<n).filter { $0 != i }
            guard let ki = tilpass(kamera: kamera, mål: mål, nøytrale: nøytrale.filter { $0 != i }, indekser: uten,
                                   lys: lys, modell: modell) else { return direkte[i] }
            return avvik(ki.xyz(fraKamera: kamera[i]), i)
        }
        k.statistikk = Statistikk(antallFelt: n,
                                  snittΔE: direkte.reduce(0, +) / Double(n), maksΔE: direkte.max() ?? 0,
                                  kryssvalidertSnittΔE: kryss.reduce(0, +) / Double(n), kryssvalidertMaksΔE: kryss.max() ?? 0,
                                  avvik: kryss)
        return k
    }

    /// Tonekurve og matrise fra feltene i `indekser` (uten statistikk).
    static func tilpass(kamera: [Farge], mål: [XYZ], nøytrale: [Int], indekser: [Int], lys: Lyskilde,
                        modell: Modell) -> Kamerakarakterisering? {
        // Tonekurve: log(Y_ref) = log(forsterkning) + gamma · log(kamera), per kanal, fra de nøytrale feltene.
        var gamma = [1.0, 1.0, 1.0], forsterkning = [1.0, 1.0, 1.0]
        for kanal in 0..<3 {
            let punkter = nøytrale.compactMap { i -> (Double, Double)? in
                let v = [kamera[i].r, kamera[i].g, kamera[i].b][kanal]
                return v > 0.003 && mål[i].y > 0.003 ? (log(v), log(mål[i].y)) : nil
            }
            if punkter.count >= 3 {
                let mx = punkter.map(\.0).reduce(0, +) / Double(punkter.count)
                let my = punkter.map(\.1).reduce(0, +) / Double(punkter.count)
                let sxx = punkter.reduce(0) { $0 + ($1.0 - mx) * ($1.0 - mx) }
                let sxy = punkter.reduce(0) { $0 + ($1.0 - mx) * ($1.1 - my) }
                if sxx > 1e-9 {
                    gamma[kanal] = min(max(sxy / sxx, 0.5), 2)
                    forsterkning[kanal] = exp(my - gamma[kanal] * mx)
                }
            } else if let (x, y) = punkter.first {
                forsterkning[kanal] = exp(y - x)
            }
        }
        var k = Kamerakarakterisering(modell: modell, gamma: gamma, forsterkning: forsterkning, koeffisienter: [],
                                      lys: lys, kameraHvit: XYZ(x: 0.9505, y: 1, z: 1.089),
                                      statistikk: Statistikk(antallFelt: indekser.count, snittΔE: 0, maksΔE: 0,
                                                             kryssvalidertSnittΔE: 0, kryssvalidertMaksΔE: 0, avvik: []))
        let x = indekser.map { egenskaper(k.lineær(kamera[$0]), modell: modell) }
        let y = indekser.map { [mål[$0].x, mål[$0].y, mål[$0].z] }
        guard let koeff = Lineær.minsteKvadrater(x, y, ridge: 1e-6) else { return nil }
        k.koeffisienter = koeff
        return k
    }
}
