import Foundation

/// Skriftfarger i en palett (fra 1.3): fargene tekst skal ha på palettens farger – typisk én nær hvit for mørke farger og
/// én nær sort for lyse. Valgfritt; uten skriftfarger brukes sort eller hvit (`Farge.lesbarTekstfarge`).
///
/// Valget for hver palettfarge er automatisk med mindre brukeren har valgt selv: den skriftfargen som gir høyest
/// kontrastforhold etter WCAG 2 (4,5:1 er kravet i regelverket for vanlig tekst).
public enum Skriftfarger {
    /// Høyst så mange skriftfarger per palett.
    public static let maksAntall = 4

    /// Hvor godt en skriftfarge holder som tekst på en bakgrunn, etter WCAG 2 (1.4.3).
    public enum Vurdering: Sendable, Equatable {
        /// Minst 4,5:1 – holder for all tekst.
        case tekst
        /// 3:1 til 4,5:1 – bare stor tekst (minst 24 px, eller 18,66 px fet).
        case storTekst
        /// Under 3:1.
        case feiler
    }

    public static func vurdering(tekst: Farge, på bakgrunn: Farge) -> Vurdering {
        let k = tekst.lagtOver(bakgrunn).wcagKontrast(mot: bakgrunn)
        return k >= 4.5 ? .tekst : k >= 3 ? .storTekst : .feiler
    }

    /// Den beste skriftfargen for en bakgrunn blant `kandidater` (se typen), eller `nil` uten kandidater.
    public static func beste(for bakgrunn: Farge, blant kandidater: [PalettFarge]) -> PalettFarge? {
        func wcag(_ k: PalettFarge) -> Double { k.farge.lagtOver(bakgrunn).wcagKontrast(mot: bakgrunn) }
        return kandidater.max(by: { wcag($0) < wcag($1) })
    }

    /// To forslag til skriftfarger, med et svakt preg av palettens kulør: «Lys tekst» (CIE L* 97) og «Mørk tekst» (L* 14).
    /// Kuløren er snittet av fargenes kulør vektet med kroma; grå paletter gir nøytrale skriftfarger.
    public static func forslag(for farger: [Farge], gamut: Gamut = .displayP3) -> [PalettFarge] {
        var x = 0.0, y = 0.0, vekt = 0.0
        for f in farger {
            let lch = f.okLCH
            guard lch.c > 0.03 else { continue }
            x += cos(lch.h * .pi / 180) * lch.c
            y += sin(lch.h * .pi / 180) * lch.c
            vekt += lch.c
        }
        let harKulør = vekt > 0 && hypot(x, y) / vekt > 0.2
        let kulør = harKulør ? (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360) : 0
        let lys = Farge.medLStjerne(97, kroma: harKulør ? 0.008 : 0, kulør: kulør, gamut: gamut)
        let mørk = Farge.medLStjerne(14, kroma: harKulør ? 0.02 : 0, kulør: kulør, gamut: gamut)
        return [PalettFarge(navn: String(localized: "Lys tekst", bundle: .module), farge: lys),
                PalettFarge(navn: String(localized: "Mørk tekst", bundle: .module), farge: mørk)]
    }
}

public extension Palett {
    /// Skriftfargen for en palettfarge: den brukeren har valgt, ellers den beste (`Skriftfarger.beste`). `nil` når paletten
    /// ikke har skriftfarger.
    func skriftfarge(for pf: PalettFarge) -> PalettFarge? {
        guard !tekstfarger.isEmpty else { return nil }
        if let id = pf.tekstfarge, let valgt = tekstfarger.first(where: { $0.id == id }) { return valgt }
        return Skriftfarger.beste(for: pf.farge, blant: tekstfarger)
    }
}

public extension Farge {
    /// CIE-lysheten L* (0–100) for luminansen Y (D65, relativ til hvitt) – samme Y som WCAG-kontrast regnes av, så lik L*
    /// gir lik kontrast. (`cieLab` er D50 og gir litt andre verdier for mettede farger.)
    var lStjerne: Double {
        let y = max(luminans, 0)
        return y > 216.0 / 24389 ? 116 * cbrt(y) - 16 : y * 24389 / 27
    }

    /// Fargen med gitt kroma og kulør i OKLCH og L* = `mål` (0–100, se `lStjerne`). OKLCH-lysheten løses ved binærsøk, så
    /// lysheten – og dermed WCAG-kontrasten – blir eksakt for alle kulører; kroma senkes ved gamut-kartlegging.
    static func medLStjerne(_ mål: Double, kroma: Double, kulør: Double, gamut: Gamut = .displayP3) -> Farge {
        let m = min(max(mål, 0), 100)
        func farge(_ l: Double) -> Farge { Farge(okLCH: OKLCH(l: l, c: kroma, h: kulør)).gamutKartlagt(til: gamut) }
        var lav = 0.0, høy = 1.0
        for _ in 0..<40 {
            let midt = (lav + høy) / 2
            if farge(midt).lStjerne < m { lav = midt } else { høy = midt }
        }
        return farge((lav + høy) / 2)
    }
}
