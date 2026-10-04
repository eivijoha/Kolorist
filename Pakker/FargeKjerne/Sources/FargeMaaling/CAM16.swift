import FargeKjerne
import Foundation

/// Omgivelsene rundt det som ses (CIECAM02/CAM16).
public enum Omgivelse: String, Hashable, Codable, Sendable, CaseIterable {
    /// Flater i et opplyst rom, utskrift.
    case gjennomsnittlig
    /// Skjerm i et svakt opplyst rom, TV.
    case dempet
    /// Projektor i mørkt rom.
    case mørk

    var f: Double { switch self { case .gjennomsnittlig: 1.0; case .dempet: 0.9; case .mørk: 0.8 } }
    var c: Double { switch self { case .gjennomsnittlig: 0.69; case .dempet: 0.59; case .mørk: 0.525 } }
    var nc: Double { f }
}

/// Visningsforholdene for en fargeinntrykksmodell.
public struct Visningsforhold: Hashable, Codable, Sendable {
    /// Hvitpunktet, med Y = 1.
    public var hvit: XYZ
    /// Adaptasjonsluminansen L_A i cd/m² (typisk 20 % av luminansen til hvitt).
    public var adaptasjonsluminans: Double
    /// Bakgrunnens relative luminans Y_b (0–100, typisk 20).
    public var bakgrunn: Double
    public var omgivelse: Omgivelse
    /// Full adaptasjon (D = 1) i stedet for å beregne graden av adaptasjon.
    public var fullAdaptasjon: Bool

    public init(hvit: XYZ, adaptasjonsluminans: Double, bakgrunn: Double = 20, omgivelse: Omgivelse = .gjennomsnittlig,
                fullAdaptasjon: Bool = false) {
        self.hvit = hvit
        self.adaptasjonsluminans = adaptasjonsluminans
        self.bakgrunn = bakgrunn
        self.omgivelse = omgivelse
        self.fullAdaptasjon = fullAdaptasjon
    }

    /// Flater i et rom opplyst med en gitt belysningsstyrke (lux): L_A = E/π · Y_b/100.
    public static func rom(hvit: XYZ, lux: Double, bakgrunn: Double = 20) -> Visningsforhold {
        Visningsforhold(hvit: hvit, adaptasjonsluminans: lux / .pi * bakgrunn / 100, bakgrunn: bakgrunn)
    }

    /// En sRGB-skjerm med D65-hvitt på 160 cd/m² i et normalt opplyst rom – referansen for det appen viser.
    public static let skjerm = Visningsforhold(hvit: Lyskilde.d65.hvitpunkt, adaptasjonsluminans: 32)
}

/// Korrelatene i CAM16: lyshet J, kroma C, kulørvinkel h, fargerikhet M, metning s og klarhet Q.
public struct CAM16Korrelater: Hashable, Codable, Sendable {
    public var j, c, h, m, s, q: Double
}

/// CAM16 (Li mfl. 2017), med CAT16 for kromatisk adaptasjon.
public struct CAM16: Sendable {
    public let forhold: Visningsforhold

    static let m16 = Matrise3([
        [0.401288, 0.650173, -0.051461],
        [-0.250268, 1.204414, 0.045854],
        [-0.002079, 0.048952, 0.953127],
    ])
    static let m16Invers = m16.invertert

    let d: (Double, Double, Double)
    let fl, n, z, nbb, aw: Double

    public init(_ forhold: Visningsforhold) {
        self.forhold = forhold
        let hvit = XYZ(x: forhold.hvit.x * 100, y: forhold.hvit.y * 100, z: forhold.hvit.z * 100)
        let la = forhold.adaptasjonsluminans
        let grad = forhold.fullAdaptasjon ? 1
            : min(max(forhold.omgivelse.f * (1 - (1 / 3.6) * exp((-la - 42) / 92)), 0), 1)
        let rgbw = Self.m16.ganget(hvit)
        d = (grad * hvit.y / rgbw.x + 1 - grad, grad * hvit.y / rgbw.y + 1 - grad, grad * hvit.y / rgbw.z + 1 - grad)
        let k = 1 / (5 * la + 1)
        let k4 = pow(k, 4)
        fl = 0.2 * k4 * (5 * la) + 0.1 * pow(1 - k4, 2) * cbrt(5 * la)
        n = forhold.bakgrunn / hvit.y
        z = 1.48 + sqrt(n)
        nbb = 0.725 * pow(1 / n, 0.2)
        let fl0 = fl
        let tilpasset = { (v: Double) -> Double in Self.etterTilpasning(v, fl: fl0) }
        let (rw, gw, bw) = (tilpasset(rgbw.x * d.0), tilpasset(rgbw.y * d.1), tilpasset(rgbw.z * d.2))
        aw = (2 * rw + gw + 0.05 * bw - 0.305) * nbb
    }

    static func etterTilpasning(_ v: Double, fl: Double) -> Double {
        let p = pow(fl * abs(v) / 100, 0.42)
        return (v < 0 ? -1 : 1) * 400 * p / (p + 27.13) + 0.1
    }

    static func førTilpasning(_ v: Double, fl: Double) -> Double {
        let a = abs(v - 0.1)
        return (v - 0.1 < 0 ? -1 : 1) * 100 / fl * pow(27.13 * a / (400 - a), 1 / 0.42)
    }

    /// Fra XYZ (hvitt har Y = 1) til CAM16-korrelater.
    public func korrelater(_ xyz: XYZ) -> CAM16Korrelater {
        let rgb = Self.m16.ganget(XYZ(x: xyz.x * 100, y: xyz.y * 100, z: xyz.z * 100))
        let ra = Self.etterTilpasning(rgb.x * d.0, fl: fl)
        let ga = Self.etterTilpasning(rgb.y * d.1, fl: fl)
        let ba = Self.etterTilpasning(rgb.z * d.2, fl: fl)
        let a = ra - 12 * ga / 11 + ba / 11
        let b = (ra + ga - 2 * ba) / 9
        var h = atan2(b, a) * 180 / .pi
        if h < 0 { h += 360 }
        let et = 0.25 * (cos(h * .pi / 180 + 2) + 3.8)
        let aa = (2 * ra + ga + 0.05 * ba - 0.305) * nbb
        let j = 100 * pow(max(aa / aw, 0), forhold.omgivelse.c * z)
        let q = (4 / forhold.omgivelse.c) * sqrt(j / 100) * (aw + 4) * pow(fl, 0.25)
        let t = (50000 / 13 * forhold.omgivelse.nc * nbb * et * hypot(a, b)) / (ra + ga + 21 / 20 * ba)
        let c = pow(t, 0.9) * sqrt(j / 100) * pow(1.64 - pow(0.29, n), 0.73)
        let m = c * pow(fl, 0.25)
        let s = q > 0 ? 100 * sqrt(m / q) : 0
        return CAM16Korrelater(j: j, c: c, h: h, m: m, s: s, q: q)
    }

    /// Fra lyshet J, kroma C og kulørvinkel h tilbake til XYZ (hvitt har Y = 1).
    public func xyz(j: Double, c: Double, h: Double) -> XYZ {
        guard j > 0 else { return XYZ(x: 0, y: 0, z: 0) }
        let t = pow(c / (sqrt(j / 100) * pow(1.64 - pow(0.29, n), 0.73)), 1 / 0.9)
        let hr = h * .pi / 180
        let et = 0.25 * (cos(hr + 2) + 3.8)
        let aa = aw * pow(j / 100, 1 / (forhold.omgivelse.c * z))
        let p2 = aa / nbb + 0.305
        let p3 = 21.0 / 20
        var a = 0.0, b = 0.0
        if t > 0 {
            let p1 = (50000 / 13 * forhold.omgivelse.nc * nbb * et) / t
            let (sn, cs) = (sin(hr), cos(hr))
            if abs(sn) >= abs(cs) {
                let p4 = p1 / sn
                b = p2 * (2 + p3) * (460.0 / 1403)
                    / (p4 + (2 + p3) * (220.0 / 1403) * (cs / sn) - 27.0 / 1403 + p3 * (6300.0 / 1403))
                a = b * cs / sn
            } else {
                let p5 = p1 / cs
                a = p2 * (2 + p3) * (460.0 / 1403)
                    / (p5 + (2 + p3) * (220.0 / 1403) - (27.0 / 1403 - p3 * (6300.0 / 1403)) * (sn / cs))
                b = a * sn / cs
            }
        }
        let ra = (460 * p2 + 451 * a + 288 * b) / 1403
        let ga = (460 * p2 - 891 * a - 261 * b) / 1403
        let ba = (460 * p2 - 220 * a - 6300 * b) / 1403
        let rgb = XYZ(x: Self.førTilpasning(ra, fl: fl) / d.0, y: Self.førTilpasning(ga, fl: fl) / d.1,
                      z: Self.førTilpasning(ba, fl: fl) / d.2)
        let v = Self.m16Invers.ganget(rgb)
        return XYZ(x: v.x / 100, y: v.y / 100, z: v.z / 100)
    }

    public func xyz(_ k: CAM16Korrelater) -> XYZ { xyz(j: k.j, c: k.c, h: k.h) }

    /// Fra lyshet J, fargerikhet M og kulørvinkel h til XYZ. Fargerikheten er absolutt (M = C · F_L^¼), så samme M
    /// i et svakere lys gir lavere kroma.
    public func xyz(j: Double, m: Double, h: Double) -> XYZ { xyz(j: j, c: m / pow(fl, 0.25), h: h) }
}

/// CAT16 kromatisk adaptasjonstransformasjon.
public enum CAT16 {
    /// Matrisen som flytter farger fra ett hvitpunkt til et annet med en gitt grad av adaptasjon (1 = full).
    static func matrise(fra kilde: XYZ, til mål: XYZ, grad: Double = 1) -> Matrise3 {
        let k = CAM16.m16.ganget(kilde), m = CAM16.m16.ganget(mål)
        let skalering = Matrise3.diagonal(
            grad * (kilde.y / mål.y) * (m.x / k.x) + 1 - grad,
            grad * (kilde.y / mål.y) * (m.y / k.y) + 1 - grad,
            grad * (kilde.y / mål.y) * (m.z / k.z) + 1 - grad)
        // Skalér så hvitt beholder luminansen (mål.y/kilde.y = 1 når begge har Y = 1).
        let luminans = Matrise3.diagonal(mål.y / kilde.y, mål.y / kilde.y, mål.y / kilde.y)
        return luminans * (CAM16.m16Invers * (skalering * CAM16.m16))
    }

    public static func tilpass(_ xyz: XYZ, fra kilde: XYZ, til mål: XYZ, grad: Double = 1) -> XYZ {
        matrise(fra: kilde, til: mål, grad: grad).ganget(xyz)
    }
}
