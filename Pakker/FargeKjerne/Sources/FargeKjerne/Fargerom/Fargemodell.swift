import Foundation

/// Fargemodellene brukeren kan redigere i. Gir et felles grensesnitt for
/// glidebrytere, tallfelt og tekstformatering, uavhengig av rommet.
public enum Fargemodell: String, CaseIterable, Codable, Sendable, Identifiable {
    case okLCH, okLab, cieLCH, cieLab, munsell, hsb, hsl, rgb, displayP3, cmyk

    public var id: String { rawValue }

    /// Modellene som tilbys som redigeringsvelger. Display P3 utelates: RGB-gliderne dekker
    /// samme behov, og P3-verdiene vises og kan kopieres under «Verdier».
    public static let redigerbare: [Fargemodell] = allCases.filter { $0 != .displayP3 }

    public var navn: String {
        switch self {
        case .okLCH: "OKLCH"
        case .okLab: "OKLab"
        case .cieLCH: "LCH"
        case .cieLab: "CIELab"
        case .hsb: "HSB"
        case .hsl: "HSL"
        case .rgb: "RGB"
        case .displayP3: "Display P3"
        case .cmyk: "CMYK"
        case .munsell: "Munsell"
        }
    }

    public struct Komponent: Sendable, Hashable {
        /// Hvordan verdien (0…1 for prosent og kanal) vises for brukeren.
        public enum Visning: Sendable, Hashable {
            /// Som tallet selv, med `desimaler`.
            case tall
            /// I prosent (CMYK, metning og lysstyrke) – som i trykkfagene og CSS.
            case prosent
            /// En RGB-kanal: vises etter brukerens valg av bitdybde (0–255, 0–1023 …) eller som desimal 0–1.
            case kanal
        }

        public let navn: String
        public let kortnavn: String
        public let område: ClosedRange<Double>
        /// Antall desimaler som gir meningsfull presisjon i visning (for `.tall`).
        public let desimaler: Int
        public let erKulør: Bool
        public let visning: Visning
    }

    public var komponenter: [Komponent] {
        func k(_ n: String, _ kn: String, _ o: ClosedRange<Double>, _ d: Int, kulør: Bool = false, _ v: Komponent.Visning = .tall) -> Komponent {
            Komponent(navn: n, kortnavn: kn, område: o, desimaler: d, erKulør: kulør, visning: v)
        }
        switch self {
        case .okLCH: return [k(String(localized: "Lyshet", bundle: .module), "L", 0...1, 3), k(String(localized: "Kroma", bundle: .module), "C", 0...0.4, 3), k(String(localized: "Kulør", bundle: .module), "H", 0...360, 1, kulør: true)]
        case .okLab: return [k(String(localized: "Lyshet", bundle: .module), "L", 0...1, 3), k(String(localized: "Grønn–rød", bundle: .module), "a", -0.4...0.4, 3), k(String(localized: "Blå–gul", bundle: .module), "b", -0.4...0.4, 3)]
        case .cieLCH: return [k(String(localized: "Lyshet", bundle: .module), "L", 0...100, 1), k(String(localized: "Kroma", bundle: .module), "C", 0...150, 1), k(String(localized: "Kulør", bundle: .module), "H", 0...360, 1, kulør: true)]
        case .cieLab: return [k(String(localized: "Lyshet", bundle: .module), "L", 0...100, 1), k(String(localized: "Grønn–rød", bundle: .module), "a", -128...127, 1), k(String(localized: "Blå–gul", bundle: .module), "b", -128...127, 1)]
        case .hsb: return [k(String(localized: "Kulør", bundle: .module), "H", 0...360, 0, kulør: true), k(String(localized: "Metning", bundle: .module), "S", 0...1, 3, .prosent), k(String(localized: "Lysstyrke", bundle: .module), "B", 0...1, 3, .prosent)]
        case .hsl: return [k(String(localized: "Kulør", bundle: .module), "H", 0...360, 0, kulør: true), k(String(localized: "Metning", bundle: .module), "S", 0...1, 3, .prosent), k(String(localized: "Lyshet", bundle: .module), "L", 0...1, 3, .prosent)]
        case .rgb, .displayP3: return [k(String(localized: "Rød", bundle: .module), "R", 0...1, 3, .kanal), k(String(localized: "Grønn", bundle: .module), "G", 0...1, 3, .kanal), k(String(localized: "Blå", bundle: .module), "B", 0...1, 3, .kanal)]
        // Munsell: kulør 0–100 rundt sirkelen (5 = 5R, 15 = 5YR … 95 = 5RP), valør 0–10, kroma 0–30.
        case .munsell: return [k(String(localized: "Kulør", bundle: .module), "H", 0...100, 1, kulør: true), k(String(localized: "Valør", bundle: .module), "V", 0...10, 1), k(String(localized: "Kroma", bundle: .module), "C", 0...30, 1)]
        case .cmyk: return [k("Cyan", "C", 0...1, 3, .prosent), k("Magenta", "M", 0...1, 3, .prosent), k(String(localized: "Gul", bundle: .module), "Y", 0...1, 3, .prosent), k(String(localized: "Sort", bundle: .module), "K", 0...1, 3, .prosent)]
        }
    }

    /// Fargens komponentverdier i denne modellen.
    public func verdier(for f: Farge) -> [Double] {
        switch self {
        case .okLCH: let v = f.okLCH; return [v.l, v.c, v.h]
        case .okLab: let v = f.okLab; return [v.l, v.a, v.b]
        case .cieLCH: let v = f.cieLCH; return [v.l, v.c, v.h]
        case .cieLab: let v = f.cieLab; return [v.l, v.a, v.b]
        case .hsb: let v = f.hsb; return [v.h, v.s, v.b]
        case .hsl: let v = f.hsl; return [v.h, v.s, v.l]
        case .rgb: let v = f.sRGB; return [v.r, v.g, v.b]
        case .displayP3: let v = f.displayP3; return [v.r, v.g, v.b]
        case .cmyk: let v = f.naivCMYK; return [v.c, v.m, v.y, v.k]
        case .munsell: let m = f.munsell; return [m.kulør, m.valør, m.kroma]
        }
    }

    /// Lager en farge fra komponentverdier i denne modellen.
    public func farge(fra v: [Double], alfa: Double = 1) -> Farge {
        precondition(v.count == komponenter.count, "Feil antall komponenter for \(navn)")
        switch self {
        case .okLCH: return Farge(okLCH: OKLCH(l: v[0], c: v[1], h: v[2]), alfa: alfa)
        case .okLab: return Farge(okLab: OKLab(l: v[0], a: v[1], b: v[2]), alfa: alfa)
        case .cieLCH: return Farge(cieLCH: CIELCH(l: v[0], c: v[1], h: v[2]), alfa: alfa)
        case .cieLab: return Farge(cieLab: CIELab(l: v[0], a: v[1], b: v[2]), alfa: alfa)
        case .hsb: return Farge(hsb: HSB(h: v[0], s: v[1], b: v[2]), alfa: alfa)
        case .hsl: return Farge(hsl: HSL(h: v[0], s: v[1], l: v[2]), alfa: alfa)
        case .rgb: return Farge(sRGB: SRGB(r: v[0], g: v[1], b: v[2]), alfa: alfa)
        case .displayP3: return Farge(displayP3: DisplayP3(r: v[0], g: v[1], b: v[2]), alfa: alfa)
        case .cmyk: return Farge(naivCMYK: CMYK(c: v[0], m: v[1], y: v[2], k: v[3]), alfa: alfa)
        case .munsell:
            // Utenfor renotasjonsdataene (svært lav valør eller ekstrem kroma): grå med samme valør.
            let m = Munsell(kulør: v[0], valør: v[1], kroma: v[2])
            return Farge(munsell: m, alfa: alfa) ?? Farge(munsell: Munsell(kulør: 0, valør: v[1], kroma: 0), alfa: alfa) ?? Farge(lineærR: 0, g: 0, b: 0, alfa: alfa)
        }
    }

    /// Kort tekst for smale fargefelt: modellnavn og verdier, med prosent inntil tallet – «OKLCH 59% 0.156 254°»,
    /// «Lab 55 −3 −45», «HSL 254° 60% 52%», «CMYK 78/41/0/0%», «5PB 5/14» (Munsell).
    public func kortTekst(for f: Farge) -> String {
        func n(_ v: Double, _ d: Int = 0) -> String { String(format: "%.\(d)f", v) }
        func kulør(_ c: Double, _ h: Double, grense: Double) -> String { n(c < grense ? 0 : h) }
        switch self {
        case .okLCH:
            let l = f.okLCH
            return "OKLCH \(n(l.l * 100))% \(n(l.c, 3)) \(kulør(l.c, l.h, grense: 0.002))°"
        case .okLab:
            let l = f.okLab
            return "OKLab \(n(l.l * 100))% \(n(l.a, 3)) \(n(l.b, 3))"
        case .cieLCH:
            let l = f.cieLCH
            return "LCH \(n(l.l)) \(n(l.c)) \(kulør(l.c, l.h, grense: 0.5))°"
        case .cieLab:
            let l = f.cieLab
            return "Lab \(n(l.l)) \(n(l.a)) \(n(l.b))"
        case .hsb:
            let v = verdier(for: f)
            return "HSB \(n(v[0]))° \(n(v[1] * 100))% \(n(v[2] * 100))%"
        case .hsl:
            let h = f.hsl
            return "HSL \(n(h.h))° \(n(h.s * 100))% \(n(h.l * 100))%"
        case .rgb: return f.hex()
        case .displayP3:
            let p = f.displayP3
            return "P3 \(n(p.r, 3)) \(n(p.g, 3)) \(n(p.b, 3))"
        case .cmyk:
            return "CMYK " + verdier(for: f).prefix(4).map { n($0 * 100) }.joined(separator: "/") + "%"
        case .munsell: return f.munsell.notasjon
        }
    }

    /// Tekst etter CSS Color 4 der det finnes en CSS-syntaks, ellers en lesbar notasjon.
    public func tekst(for f: Farge) -> String {
        let v = verdier(for: f)
        func t(_ i: Int, _ d: Int? = nil) -> String {
            String(format: "%.\(d ?? komponenter[i].desimaler)f", v[i])
        }
        func prosent(_ i: Int) -> String { String(format: "%.1f%%", v[i] * 100) }
        switch self {
        case .okLCH: return "oklch(\(t(0)) \(t(1)) \(t(2)))"
        case .okLab: return "oklab(\(t(0)) \(t(1)) \(t(2)))"
        case .cieLCH: return "lch(\(t(0)) \(t(1)) \(t(2)))"
        case .cieLab: return "lab(\(t(0)) \(t(1)) \(t(2)))"
        case .hsb: return "hsb(\(t(0)) \(prosent(1)) \(prosent(2)))"
        case .hsl: return "hsl(\(t(0)) \(prosent(1)) \(prosent(2)))"
        case .rgb: return "rgb(\(v.prefix(3).map { String(Int(($0.klampet(0, 1) * 255).rounded())) }.joined(separator: " ")))"
        case .displayP3: return "color(display-p3 \(t(0, 4)) \(t(1, 4)) \(t(2, 4)))"
        case .cmyk: return "cmyk(\((0..<4).map(prosent).joined(separator: " ")))"
        case .munsell: return f.munsell.notasjon
        }
    }
}
