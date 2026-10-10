import Foundation

public extension Farge {
    /// WCAG 2.x kontrastforhold (1…21), beregnet på sRGB-klippet luminans.
    func wcagKontrast(mot annen: Farge) -> Double {
        let a = klippet(til: .sRGB).luminans, b = annen.klippet(til: .sRGB).luminans
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// Grensen for lys tekst (fra 1.4): lys tekst velges når den gir minst 2,7:1 etter WCAG 2. Velges i stedet den som gir
    /// høyest forhold, skifter hvit og sort tekst ved L* ≈ 50, og mettede mellomtoner (blått, rødt, grønt) får sort tekst.
    /// Med grensen skifter de ved L* ≈ 65, slik øyet foretrekker. Grensen er satt etter visuell vurdering.
    static let lysTekstgrense = 2.7

    /// Passende tekstfarge (sort/hvit) oppå denne fargen: hvit når hvit gir minst `lysTekstgrense` (2,7:1) etter WCAG 2,
    /// ellers sort.
    var lesbarTekstfarge: Farge { lesbarTekstfarge(krav: nil) }

    /// Som `lesbarTekstfarge`, med WCAG 2 som gulv: holder ikke den foretrukne tekstfargen `krav` (f.eks. 4,5 for vanlig
    /// tekst), velges den andre når den gjør det.
    func lesbarTekstfarge(krav: Double?) -> Farge {
        let hvit = Farge(lineærR: 1, g: 1, b: 1), sort = Farge(lineærR: 0, g: 0, b: 0)
        return Farge.foretrukketTekst(blant: [hvit, sort], på: self, farge: { $0 }, krav: krav) ?? sort
    }

    /// Tekstfargen blant `kandidater` på `bakgrunn`: den lyse kandidaten med høyest kontrast når den når
    /// `lysTekstgrense`, ellers kandidaten med høyest kontrast. Med `krav` velges heller en kandidat som holder kravet,
    /// og holder ingen, den med høyest kontrast.
    static func foretrukketTekst<T>(blant kandidater: [T], på bakgrunn: Farge, farge: (T) -> Farge, krav: Double?) -> T? {
        let yb = bakgrunn.klippet(til: .sRGB).luminans
        let vurdert = kandidater.map { k -> (k: T, kontrast: Double, lys: Bool) in
            let f = farge(k).lagtOver(bakgrunn)
            return (k, f.wcagKontrast(mot: bakgrunn), f.klippet(til: .sRGB).luminans > yb)
        }
        guard let høyest = vurdert.max(by: { $0.kontrast < $1.kontrast }) else { return nil }
        let lys = vurdert.filter(\.lys).max(by: { $0.kontrast < $1.kontrast })
        let valgt = lys.flatMap { $0.kontrast >= lysTekstgrense ? $0 : nil } ?? høyest
        if let krav, valgt.kontrast < krav {
            // WCAG 2 er gulvet: en kandidat som holder kravet, ellers den som kommer nærmest.
            return (vurdert.filter({ $0.kontrast >= krav }).max(by: { $0.kontrast < $1.kontrast }) ?? høyest).k
        }
        return valgt.k
    }
}
