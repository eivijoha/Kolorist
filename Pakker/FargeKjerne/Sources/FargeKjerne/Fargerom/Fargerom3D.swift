#if canImport(CoreGraphics)
import CoreGraphics
import Foundation
import simd

/// Farger i 3D, i to rom med modellkoordinater omtrent i [−1, 1] (y opp):
///
/// - **Fargekule (OKLCH):** lysheten langs den grå aksen (sort nederst, hvit øverst), kuløren rundt aksen og metningen ut
///   mot overflaten, som andel av høyeste kroma innenfor gamut ved fargens lyshet og kulør (overflaten = så mettet som
///   fargen kan bli). Farger utenfor gamut ligger utenfor kula.
/// - **OKLab:** L opp (0…1), a og b ut (±0,32) – rommet overgangene regnes i, der en overgang er en rett linje.
/// - **CIELab (D50, som ICC):** L* opp, a* og b* ut, ±128 – fargerom (gamutskall) fra ICC-profiler i sin virkelige form.
///
/// Kuløren går fra +a* mot +b* i begge rom (x = a*, z = −b*), så de kan sammenlignes.
public enum Fargerom3D {
    /// En flate som rutenett: `kolonner` × `rader` punkter, med fargen i hvert punkt.
    public struct Flate: Sendable {
        public let kolonner: Int
        public let rader: Int
        public let punkter: [SIMD3<Double>]
        public let farger: [Farge]
        /// Om kolonnene går rundt (første og siste kolonne er samme sted, som rundt en kule).
        public let lukket: Bool

        public init(kolonner: Int, rader: Int, punkter: [SIMD3<Double>], farger: [Farge], lukket: Bool = false) {
            self.kolonner = kolonner
            self.rader = rader
            self.punkter = punkter
            self.farger = farger
            self.lukket = lukket
        }

        public func indeks(_ kolonne: Int, _ rad: Int) -> Int { rad * kolonner + kolonne }

        /// Samme flate med punktene regnet om (f.eks. fra CIELab til OKLab) ut fra fargene.
        public func omplassert(_ posisjon: (Farge) -> SIMD3<Double>) -> Flate {
            Flate(kolonner: kolonner, rader: rader, punkter: farger.map(posisjon), farger: farger, lukket: lukket)
        }

        /// Trekantene i rutenettet (indekser i `punkter`).
        public var trekanter: [SIMD3<Int32>] {
            guard kolonner >= 2, rader >= 2 else { return [] }
            var t: [SIMD3<Int32>] = []
            t.reserveCapacity((kolonner - 1) * (rader - 1) * 2)
            for j in 0..<(rader - 1) {
                for i in 0..<(kolonner - 1) {
                    let a = Int32(indeks(i, j)), b = Int32(indeks(i + 1, j)), c = Int32(indeks(i, j + 1)), d = Int32(indeks(i + 1, j + 1))
                    t.append(.init(a, b, d))
                    t.append(.init(a, d, c))
                }
            }
            return t
        }
    }

    // MARK: - Fargekule (OKLCH)

    /// Punktet for en lyshet (0…1), metning (andel av høyeste kroma, 1 = overflaten) og kulør (OKLCH-grader).
    public static func kuleposisjon(lyshet: Double, metning: Double, kulør: Double) -> SIMD3<Double> {
        let y = 2 * min(max(lyshet, 0), 1) - 1
        let r = max(metning, 0) * max(1 - y * y, 0).squareRoot()
        let h = kulør * .pi / 180
        return .init(r * cos(h), y, -r * sin(h))
    }

    /// Fargens plass i fargekula. Metningen er kroma som andel av høyeste kroma innenfor `gamut` (opptil 1,5 for farger
    /// utenfor).
    public static func kuleposisjon(_ farge: Farge, gamut: Gamut = .sRGB) -> SIMD3<Double> {
        let lch = farge.okLCH
        let maks = Farge.maksKroma(lyshet: lch.l, kulør: lch.h, i: gamut)
        let metning = maks > 0.0001 ? min(lch.c / maks, 1.5) : 0
        return kuleposisjon(lyshet: lch.l, metning: metning, kulør: lch.h)
    }

    /// Overflaten av fargekula: den mest mettede fargen innenfor `gamut` ved hver lyshet og kulør.
    public static func kuleflate(gamut: Gamut = .sRGB, kolonner: Int = 73, rader: Int = 33) -> Flate {
        let kolonner = max(kolonner, 2), rader = max(rader, 2)
        var punkter: [SIMD3<Double>] = [], farger: [Farge] = []
        for j in 0..<rader {
            let l = Double(j) / Double(rader - 1)
            for i in 0..<kolonner {
                let h = Double(i) / Double(kolonner - 1) * 360
                punkter.append(kuleposisjon(lyshet: l, metning: 1, kulør: h))
                let c = Farge.maksKroma(lyshet: min(max(l, 0.001), 0.999), kulør: h, i: gamut)
                farger.append(Farge(okLCH: OKLCH(l: l, c: c, h: h)).gamutKartlagt(til: gamut))
            }
        }
        return Flate(kolonner: kolonner, rader: rader, punkter: punkter, farger: farger, lukket: true)
    }

    // MARK: - OKLab

    /// Fargens plass i OKLab: x = a/0,32, y = 2L − 1, z = −b/0,32.
    public static func oklabposisjon(_ farge: Farge) -> SIMD3<Double> {
        let lab = farge.okLab
        return .init(lab.a / 0.32, 2 * lab.l - 1, -lab.b / 0.32)
    }

    // MARK: - CIELab

    /// Fargens plass i CIELab (D50): x = a*/128, y = L*/50 − 1, z = −b*/128.
    public static func labposisjon(_ farge: Farge) -> SIMD3<Double> {
        let lab = farge.cieLab
        return .init(lab.a / 128, lab.l / 50 - 1, -lab.b / 128)
    }

    /// Overflaten av fargerommet til en profil (gamutskallet): de seks sidene av enhetskuben i profilens komponenter,
    /// regnet om til CIELab. For CMYK brukes C, M og Y med K = min(C, M, Y) mot den mørke enden – en tilnærming, siden
    /// det nøyaktige skallet avhenger av separasjonen i profilen. `nil` for profiler som ikke er RGB eller CMYK.
    /// Skallet er det enheten faktisk gjengir, så enhetsverdiene regnes om kolorimetrisk (`hensikt.kolorimetrisk`:
    /// absolutt med papirhvitt, ellers relativ) uansett valgt hensikt.
    public static func gamutskall(_ profil: ICCProfil, oppløsning n: Int = 16,
                                  hensikt: Gjengivelseshensikt = .relativKolorimetrisk) -> [Flate]? {
        guard profil.modell == .rgb || profil.modell == .cmyk else { return nil }
        let farge: (Double, Double, Double) -> Farge
        if profil.id == ICCProfil.sRGB.id {
            farge = { Farge(sRGB: SRGB(r: $0, g: $1, b: $2)) }
        } else if profil.id == ICCProfil.displayP3.id {
            farge = { Farge(displayP3: DisplayP3(r: $0, g: $1, b: $2)) }
        } else if profil.modell == .cmyk {
            farge = { a, b, c in
                Farge(komponenter: [a, b, c, min(a, b, c)], i: profil, hensikt: hensikt.kolorimetrisk) ?? Farge(lineærR: 0, g: 0, b: 0)
            }
        } else {
            farge = { a, b, c in Farge(komponenter: [a, b, c], i: profil, hensikt: hensikt.kolorimetrisk) ?? Farge(lineærR: 0, g: 0, b: 0) }
        }
        return (0..<6).map { side in
            var punkter: [SIMD3<Double>] = [], farger: [Farge] = []
            for j in 0...n {
                for i in 0...n {
                    let k = kubepunkt(side, Double(i) / Double(n), Double(j) / Double(n))
                    let f = farge(k.x, k.y, k.z)
                    farger.append(f)
                    punkter.append(labposisjon(f))
                }
            }
            return Flate(kolonner: n + 1, rader: n + 1, punkter: punkter, farger: farger)
        }
    }

    /// Punkt (u, v) ∈ [0, 1]² på side `side` (0…5) av enhetskuben: aksen `side / 2` er 0 eller 1, de to andre er u og v.
    static func kubepunkt(_ side: Int, _ u: Double, _ v: Double) -> SIMD3<Double> {
        let fast = Double(side % 2)
        switch side / 2 {
        case 0: return .init(fast, u, v)
        case 1: return .init(v, fast, u)
        default: return .init(u, v, fast)
        }
    }

    // MARK: - USDZ

    /// En scene å eksportere: flater (med tekstur fra fargene), punkter (små kuler i sin farge) og streker (rør).
    public struct Scene: Sendable {
        public var flater: [(flate: Flate, opasitet: Double)]
        public var punkter: [(posisjon: SIMD3<Double>, farge: Farge, radius: Double)]
        public var streker: [(punkter: [SIMD3<Double>], farge: Farge, radius: Double)]

        public init(flater: [(flate: Flate, opasitet: Double)] = [], punkter: [(posisjon: SIMD3<Double>, farge: Farge, radius: Double)] = [],
                    streker: [(punkter: [SIMD3<Double>], farge: Farge, radius: Double)] = []) {
            self.flater = flater
            self.punkter = punkter
            self.streker = streker
        }

        /// Scenen som USDZ: modellen `størrelse` meter høy (standard 20 cm), stående på gulvet, fargene i sRGB.
        /// `rundetid`: sekunder per runde om modellen skal rotere rundt den grå aksen (Hurtigvisning og AR Quick Look
        /// spiller den av i løkke); `nil` står den stille.
        public func usdz(navn: String, størrelse: Float = 0.2, rundetid: Double? = nil) -> Data {
            let skala = størrelse / 2
            func p(_ v: SIMD3<Double>) -> SIMD3<Float> { SIMD3<Float>(Float(v.x), Float(v.y) + 1, Float(v.z)) * skala }
            func rgb(_ f: Farge) -> SIMD3<Float> {
                let s = f.gamutKartlagt(til: .sRGB).sRGB
                return .init(Float(s.r), Float(s.g), Float(s.b))
            }
            var mesher: [USDScene.Mesh] = [], teksturer: [String: Data] = [:]
            for (nr, (flate, opasitet)) in flater.enumerated() {
                let tekstur = "flate\(nr).png"
                let uv = (0..<flate.rader).flatMap { j in
                    (0..<flate.kolonner).map { i in
                        SIMD2<Float>((Float(i) + 0.5) / Float(flate.kolonner), 1 - (Float(j) + 0.5) / Float(flate.rader))
                    }
                }
                teksturer[tekstur] = USDScene.png(bredde: flate.kolonner, høyde: flate.rader) { x, y in
                    let s = flate.farger[flate.indeks(x, y)].gamutKartlagt(til: .sRGB).sRGB
                    return .init(s.r, s.g, s.b)
                }
                mesher.append(.init(navn: "Flate\(nr)", punkter: flate.punkter.map(p), uv: uv, trekanter: flate.trekanter,
                                    tekstur: tekstur, opasitet: Float(opasitet)))
            }
            for (nr, s) in streker.enumerated() {
                mesher.append(.rør(navn: "Strek\(nr)", langs: s.punkter.map(p), radius: Float(s.radius) * skala, farge: rgb(s.farge)))
            }
            // Alle punktene i én flate, med fargene i et teksturatlas (én piksel per punkt): få materialer også for
            // tusenvis av farger (f.eks. et fargebibliotek).
            if !punkter.isEmpty {
                let side = Int(Double(punkter.count).squareRoot().rounded(.up))
                let oppløsning = punkter.count > 200 ? 4 : 10
                var samlet = USDScene.Mesh(navn: "Farger", punkter: [], trekanter: [], tekstur: "farger.png")
                for (nr, punkt) in punkter.enumerated() {
                    let kule = USDScene.Mesh.kule(navn: "", sentrum: p(punkt.posisjon), radius: Float(punkt.radius) * skala,
                                                  farge: .zero, oppløsning: oppløsning)
                    let start = Int32(samlet.punkter.count)
                    let st = SIMD2<Float>((Float(nr % side) + 0.5) / Float(side), 1 - (Float(nr / side) + 0.5) / Float(side))
                    samlet.punkter += kule.punkter
                    samlet.uv += Array(repeating: st, count: kule.punkter.count)
                    samlet.trekanter += kule.trekanter.map { $0 &+ start }
                }
                mesher.append(samlet)
                teksturer["farger.png"] = USDScene.png(bredde: side, høyde: side) { x, y in
                    let nr = y * side + x
                    guard nr < punkter.count else { return .init(0.5, 0.5, 0.5) }
                    let s = punkter[nr].farge.gamutKartlagt(til: .sRGB).sRGB
                    return .init(s.r, s.g, s.b)
                }
            }
            return USDScene(navn: navn, mesher: mesher, teksturer: teksturer, rundetid: rundetid).usdz()
        }
    }
}
#endif
