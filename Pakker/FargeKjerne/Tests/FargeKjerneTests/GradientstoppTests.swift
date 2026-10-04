import Testing
@testable import FargeKjerne

@Suite("Gradientstopp")
struct GradientstoppTests {
    @Test func likeFargerGirToStopp() {
        let a = Farge(hex: "#1F3A4D")!, b = Farge(hex: "#2A4A60")!
        #expect(Gradientstopp.forenklet(gjennom: [a, b]).count == 2)
    }

    @Test func blåTilGulTrengerFlereMenFå() {
        let stopp = Gradientstopp.forenklet(gjennom: [Farge(hex: "#1B3A6B")!, Farge(hex: "#F2B84B")!])
        #expect(stopp.count > 2 && stopp.count <= 8)
        #expect(stopp.first!.posisjon == 0 && stopp.last!.posisjon == 1)
    }

    @Test func avvikUnderToleranse() {
        let nøkler = [Farge(hex: "#1B3A6B")!, Farge(hex: "#F2B84B")!]
        let stopp = Gradientstopp.forenklet(gjennom: nøkler)
        let fasit = Overgang.toner(gjennom: nøkler, stegMellom: 98)
        for (i, f) in fasit.enumerated() {
            let t = Double(i) / Double(fasit.count - 1)
            let j = stopp.lastIndex { $0.posisjon <= t } ?? 0
            let k = min(j + 1, stopp.count - 1)
            let (p, q) = (stopp[j], stopp[k])
            let u = q.posisjon > p.posisjon ? (t - p.posisjon) / (q.posisjon - p.posisjon) : 0
            let a = p.farge.sRGB, b = q.farge.sRGB
            let blandet = Farge(sRGB: SRGB(r: a.r + (b.r - a.r) * u, g: a.g + (b.g - a.g) * u, b: a.b + (b.b - a.b) * u))
            #expect(blandet.deltaE2000(til: f) < 1.6)
        }
    }
}
