import Foundation

/// Stopp for en OKLab-overgang i programmer som interpolerer i gammakodet sRGB (Figma, Sketch, SVG, CSS uten
/// `in oklab`). Så få stopp som mulig: bare der sRGB-blandingen mellom to nabostopp avviker merkbart fra OKLab.
public enum Gradientstopp {
    /// - Parameters:
    ///   - nøkler: fargene overgangen går gjennom (som i Overgang).
    ///   - toleranse: største avvik (ΔE00) mellom programmets blanding og OKLab-overgangen. 1 er så vidt merkbart.
    /// - Returns: stopp med posisjon 0…1, alltid med første og siste farge.
    public static func forenklet(gjennom nøkler: [Farge], toleranse: Double = 1) -> [(farge: Farge, posisjon: Double)] {
        guard nøkler.count > 1 else { return nøkler.map { ($0, 0) } }
        // Tette prøver langs OKLab-overgangen; de forenklede stoppene velges blant dem.
        let prøver = Overgang.toner(gjennom: nøkler, stegMellom: max(4, 64 / (nøkler.count - 1)))
        let n = prøver.count - 1
        // Nøklene skal alltid være med (de er knekkpunkter i overgangen).
        let segment = max(1, n / (nøkler.count - 1))
        var behold = Set([0, n] + (1..<(nøkler.count - 1)).map { $0 * segment })
        func del(_ a: Int, _ b: Int) {
            guard b - a > 1 else { return }
            let sa = prøver[a].sRGB, sb = prøver[b].sRGB
            var verst = 0.0, indeks = a
            for k in (a + 1)..<b {
                let t = Double(k - a) / Double(b - a)
                let blandet = Farge(sRGB: SRGB(r: sa.r + (sb.r - sa.r) * t, g: sa.g + (sb.g - sa.g) * t, b: sa.b + (sb.b - sa.b) * t))
                let avvik = blandet.deltaE2000(til: prøver[k])
                if avvik > verst { verst = avvik; indeks = k }
            }
            if verst > toleranse {
                behold.insert(indeks)
                del(a, indeks)
                del(indeks, b)
            }
        }
        let faste = behold.sorted()
        for (a, b) in zip(faste, faste.dropFirst()) { del(a, b) }
        return behold.sorted().map { (prøver[$0], Double($0) / Double(n)) }
    }
}
