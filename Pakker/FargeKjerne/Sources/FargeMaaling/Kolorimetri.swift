import FargeKjerne
import Foundation

/// CIE-data fra `CIEData.json`: 1931 2°-observatøren, basisfunksjoner for dagslysserien og standardlyskilder,
/// 380–780 nm i steg på 5 nm (CIE 15:2018).
struct CIEData: Decodable, Sendable {
    struct Observatør: Decodable, Sendable { let x, y, z: [Double] }
    let kilde: String
    let start: Double
    let steg: Double
    let observatør: Observatør
    let dagslys: [String: [Double]]
    let lyskilder: [String: [Double]]

    static let delt: CIEData = {
        guard let url = Bundle.module.url(forResource: "CIEData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cie = try? JSONDecoder().decode(CIEData.self, from: data)
        else { fatalError("CIEData.json mangler i FargeMaaling") }
        return cie
    }()

    var antall: Int { observatør.y.count }
    func bølgelengde(_ i: Int) -> Double { start + Double(i) * steg }
    func spektrum(_ verdier: [Double]) -> Spektrum { Spektrum(start: start, steg: steg, verdier: verdier) }
}

/// Fra spekter til farge, og fargetemperatur (CIE 15:2018; korrelert fargetemperatur etter Ohno 2013).
public enum Kolorimetri {
    /// XYZ for en lyskilde, skalert så Y = 1.
    public static func xyz(lyskilde s: Spektrum) -> XYZ {
        let cie = CIEData.delt
        var x = 0.0, y = 0.0, z = 0.0
        for i in 0..<cie.antall {
            let e = s.verdi(ved: cie.bølgelengde(i))
            x += e * cie.observatør.x[i]; y += e * cie.observatør.y[i]; z += e * cie.observatør.z[i]
        }
        guard y > 0 else { return XYZ(x: 0, y: 0, z: 0) }
        return XYZ(x: x / y, y: 1, z: z / y)
    }

    /// XYZ for en flate med gitt refleksjon under en lyskilde, skalert så en perfekt hvit flate har Y = 1.
    public static func xyz(refleksjon r: Spektrum, under lys: Spektrum) -> XYZ {
        let cie = CIEData.delt
        var x = 0.0, y = 0.0, z = 0.0, n = 0.0
        for i in 0..<cie.antall {
            let nm = cie.bølgelengde(i)
            let e = lys.verdi(ved: nm), ρ = r.verdi(ved: nm)
            x += ρ * e * cie.observatør.x[i]; y += ρ * e * cie.observatør.y[i]; z += ρ * e * cie.observatør.z[i]
            n += e * cie.observatør.y[i]
        }
        guard n > 0 else { return XYZ(x: 0, y: 0, z: 0) }
        return XYZ(x: x / n, y: y / n, z: z / n)
    }

    /// Kromatisitet xy.
    public static func xy(_ v: XYZ) -> (x: Double, y: Double) {
        let s = v.x + v.y + v.z
        return s > 0 ? (v.x / s, v.y / s) : (0.3127, 0.3290)
    }

    /// XYZ med Y = 1 for en kromatisitet.
    public static func xyz(x: Double, y: Double) -> XYZ { XYZ(x: x / y, y: 1, z: (1 - x - y) / y) }

    /// CIE 1960 uv (brukes for fargetemperatur).
    static func uv(x: Double, y: Double) -> (u: Double, v: Double) {
        let d = -2 * x + 12 * y + 3
        return (4 * x / d, 6 * y / d)
    }

    static func xy(u: Double, v: Double) -> (x: Double, y: Double) {
        let d = 2 * u - 8 * v + 4
        return (3 * u / d, 2 * v / d)
    }

    // MARK: Sortlegeme og fargetemperatur

    /// Plancks stråling ved en temperatur (relativ, 380–780 nm i steg på 5 nm), med c₂ = 1,4388 × 10⁻² m·K.
    public static func sortlegeme(kelvin t: Double) -> Spektrum {
        let cie = CIEData.delt
        let c2 = 1.4388e-2
        let verdier = (0..<cie.antall).map { i -> Double in
            let λ = cie.bølgelengde(i) * 1e-9
            return 1 / (pow(λ, 5) * (exp(c2 / (λ * t)) - 1))
        }
        let maks = verdier.max() ?? 1
        return cie.spektrum(verdier.map { $0 / maks * 100 })
    }

    /// Plancks kurve i uv, fra 1000 til 30 000 K i steg på 1 % (for Ohnos metode).
    private static let planckTabell: [(t: Double, u: Double, v: Double)] = {
        var tabell: [(Double, Double, Double)] = []
        var t = 1000.0
        while t <= 30000 {
            let p = xy(xyz(lyskilde: sortlegeme(kelvin: t)))
            let (u, v) = uv(x: p.x, y: p.y)
            tabell.append((t, u, v))
            t *= 1.01
        }
        return tabell
    }()

    /// Korrelert fargetemperatur (K) og avstand fra Plancks kurve (Duv; positiv over kurven, mot grønt) etter
    /// Ohnos parabelmetode (2013). `nil` utenfor 1000–30 000 K.
    public static func fargetemperatur(x: Double, y: Double) -> (kelvin: Double, duv: Double)? {
        let (u, v) = uv(x: x, y: y)
        let tabell = planckTabell
        let avstander = tabell.map { hypot($0.u - u, $0.v - v) }
        guard let i = avstander.indices.min(by: { avstander[$0] < avstander[$1] }), i > 0, i < tabell.count - 1 else { return nil }
        let (t1, t2, t3) = (tabell[i - 1].t, tabell[i].t, tabell[i + 1].t)
        let (d1, d2, d3) = (avstander[i - 1], avstander[i], avstander[i + 1])
        let nevner = (t2 - t3) * (t1 - t2) * (t3 - t1)
        let a = (t3 * (d1 - d2) + t2 * (d3 - d1) + t1 * (d2 - d3)) / nevner
        let b = -(t3 * t3 * (d1 - d2) + t2 * t2 * (d3 - d1) + t1 * t1 * (d2 - d3)) / nevner
        let c = -(d1 * (t3 - t2) * t2 * t3 + d3 * (t2 - t1) * t1 * t2 + d2 * (t1 - t3) * t3 * t1) / nevner
        let t = -b / (2 * a)
        // Duv som avstanden til kurven ved den funne temperaturen (parabelens bunnverdi er unøyaktig nær kurven,
        // der avstanden er V-formet). Positiv over kurven (større v, mot grønt).
        let p = planckUV(kelvin: t)
        let avstand = hypot(u - p.u, v - p.v)
        return (t, (v - p.v) >= 0 ? avstand : -avstand)
    }

    private static func planckUV(kelvin t: Double) -> (u: Double, v: Double) {
        let p = xy(xyz(lyskilde: sortlegeme(kelvin: t)))
        return uv(x: p.x, y: p.y)
    }

    /// Kromatisitet for en fargetemperatur og en avstand Duv fra Plancks kurve (positiv mot grønt).
    public static func xy(kelvin t: Double, duv: Double = 0) -> (x: Double, y: Double) {
        let p = planckUV(kelvin: t)
        guard duv != 0 else { return xy(u: p.u, v: p.v) }
        let a = planckUV(kelvin: t * 0.999), b = planckUV(kelvin: t * 1.001)
        // Normal på kurven, orientert mot større v (grønnere).
        var nu = -(b.v - a.v), nv = b.u - a.u
        let lengde = hypot(nu, nv)
        nu /= lengde; nv /= lengde
        if nv < 0 { nu = -nu; nv = -nv }
        return xy(u: p.u + duv * nu, v: p.v + duv * nv)
    }

    /// CIE dagslysserien ved en korrelert fargetemperatur (4000–25 000 K), CIE 15:2018.
    public static func dagslys(kelvin t: Double) -> Spektrum {
        let t = min(max(t, 4000), 25000)
        let x: Double = t <= 7000
            ? -4.6070e9 / pow(t, 3) + 2.9678e6 / (t * t) + 0.09911e3 / t + 0.244063
            : -2.0064e9 / pow(t, 3) + 1.9018e6 / (t * t) + 0.24748e3 / t + 0.237040
        let y = -3 * x * x + 2.870 * x - 0.275
        let m = 0.0241 + 0.2562 * x - 0.7341 * y
        // CIE 15:2018 runder M1 og M2 til tre desimaler.
        let m1 = ((-1.3515 - 1.7703 * x + 5.9114 * y) / m * 1000).rounded() / 1000
        let m2 = ((0.0300 - 31.4424 * x + 30.0717 * y) / m * 1000).rounded() / 1000
        let cie = CIEData.delt
        let s0 = cie.dagslys["S0"] ?? [], s1 = cie.dagslys["S1"] ?? [], s2 = cie.dagslys["S2"] ?? []
        return cie.spektrum((0..<cie.antall).map { s0[$0] + m1 * s1[$0] + m2 * s2[$0] })
    }

    /// CIE standardlys A (glødelampe), definert ved formel i CIE 15 (2856 K).
    public static var standardlysA: Spektrum {
        let cie = CIEData.delt
        let verdier = (0..<cie.antall).map { i -> Double in
            let λ = cie.bølgelengde(i)
            return 100 * pow(560 / λ, 5) * (exp(1.435e7 / (2848 * 560)) - 1) / (exp(1.435e7 / (2848 * λ)) - 1)
        }
        return cie.spektrum(verdier)
    }
}
