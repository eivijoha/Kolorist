import Foundation

/// Monokromatisk harmoni: én kulør i flere toner langs en strek i et kvadrat med lyshet loddrett og metning
/// vannrett. Metningen er andel av høyeste kroma innenfor gamut ved punktets lyshet (0 = grå, 1 = så mettet som
/// kuløren kan bli der), så hele kvadratet er gyldige farger og streken beholder formen når kuløren endres.
///
/// Tonene fordeles jevnt i lyshet og metningsandel – rett langs streken i kvadratet brukeren ser og drar i. Det er
/// et bevisst unntak fra interpolasjon i OKLab: en rett linje i OKLab ville bøyd seg i kvadratet.
public struct Monokromstrek: Equatable, Sendable {
    public struct Punkt: Equatable, Sendable {
        /// OKLCH-lyshet (0…1).
        public var lyshet: Double
        /// Kroma som andel av høyeste kroma innenfor gamut ved denne lysheten og kuløren (0…1).
        public var metning: Double

        public init(lyshet: Double, metning: Double) {
            self.lyshet = min(max(lyshet, 0), 1)
            self.metning = min(max(metning, 0), 1)
        }

        /// Kroma for punktet ved en kulør.
        public func kroma(kulør: Double, gamut: Gamut) -> Double {
            metning * Farge.maksKroma(lyshet: lyshet, kulør: kulør, i: gamut)
        }

        /// Fargen i punktet ved en kulør.
        public func farge(kulør: Double, gamut: Gamut) -> Farge {
            Farge(okLCH: OKLCH(l: lyshet, c: kroma(kulør: kulør, gamut: gamut), h: kulør)).gamutKartlagt(til: gamut)
        }

        /// Punktet for en lyshet og kroma, med kroma begrenset til gamut.
        public static func fra(lyshet: Double, kroma: Double, kulør: Double, gamut: Gamut) -> Punkt {
            let l = min(max(lyshet, 0), 1)
            let maks = Farge.maksKroma(lyshet: l, kulør: kulør, i: gamut)
            return Punkt(lyshet: l, metning: maks > 0 ? kroma / maks : 0)
        }
    }

    public var a: Punkt
    public var b: Punkt

    public init(a: Punkt, b: Punkt) {
        self.a = a
        self.b = b
    }

    /// En strek fra en lys, dempet tone til grunnfargen selv, så grunnfargen er den siste tonen. En lys grunnfarge
    /// får i stedet en mørkere tone i den andre enden.
    public static func standard(for grunn: Farge, gamut: Gamut = .displayP3) -> Monokromstrek {
        let lch = grunn.okLCH
        let maks = Farge.maksKroma(lyshet: lch.l, kulør: lch.h, i: gamut)
        let metning = maks > 0 ? min(lch.c / maks, 1) : 0
        let grunnpunkt = Punkt(lyshet: lch.l, metning: metning)
        let annen = lch.l < 0.75 ? Punkt(lyshet: min(lch.l + 0.3, 0.94), metning: metning * 0.3)
                                 : Punkt(lyshet: lch.l - 0.4, metning: min(metning * 1.2, 1))
        return Monokromstrek(a: annen, b: grunnpunkt)
    }

    /// `antall` toner fra `a` til `b` ved en kulør (OKLCH-grader), jevnt fordelt i lyshet og metningsandel.
    public func toner(kulør: Double, antall: Int, gamut: Gamut = .displayP3) -> [Farge] {
        let n = max(antall, 2)
        return (0..<n).map { i in
            let t = Double(i) / Double(n - 1)
            let p = Punkt(lyshet: a.lyshet + (b.lyshet - a.lyshet) * t, metning: a.metning + (b.metning - a.metning) * t)
            return p.farge(kulør: kulør, gamut: gamut)
        }
    }

    /// Tonebane: `antall` toner fra `a` til `b` der kuløren også går fra `kulørA` til `kulørB` (OKLCH-grader), i bue den
    /// korteste veien rundt sirkelen. Lyshet, metningsandel og kulør fordeles jevnt, så banen går gjennom alle tre
    /// dimensjonene. Metningen er andel av høyeste kroma ved hver tones egen lyshet og kulør, som i monokrom.
    public func toner(fraKulør kulørA: Double, tilKulør kulørB: Double, antall: Int, gamut: Gamut = .displayP3) -> [Farge] {
        let n = max(antall, 2)
        var d = (kulørB - kulørA).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return (0..<n).map { i in
            let t = Double(i) / Double(n - 1)
            let p = Punkt(lyshet: a.lyshet + (b.lyshet - a.lyshet) * t, metning: a.metning + (b.metning - a.metning) * t)
            let h = (kulørA + d * t).truncatingRemainder(dividingBy: 360)
            return p.farge(kulør: h < 0 ? h + 360 : h, gamut: gamut)
        }
    }

    /// Som tekst til lagring («l1 m1 l2 m2»).
    public var tekst: String {
        [a.lyshet, a.metning, b.lyshet, b.metning].map { String(format: "%.4f", $0) }.joined(separator: " ")
    }

    public init?(tekst: String) {
        let v = tekst.split(separator: " ").compactMap { Double($0) }
        guard v.count == 4, v.allSatisfy(\.isFinite) else { return nil }
        self.init(a: Punkt(lyshet: v[0], metning: v[1]), b: Punkt(lyshet: v[2], metning: v[3]))
    }
}
