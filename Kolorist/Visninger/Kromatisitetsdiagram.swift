import FargeKjerne
import FargeMaaling
import SwiftUI

/// CIE 1931-kromatisitetsdiagram (xy) med palettens farger og forvirringslinjene for et fargesynsavvik: linjer gjennom
/// avvikets kopunkt. Farger nær samme linje kan forveksles (gitt lik lyshet); vanskelige par fra analysen er streket
/// sammen i rødt. Svake linjer i vifte bak viser retningen linjene går i for avviket.
struct Kromatisitetsdiagram: View {
    let farger: [Farge]
    let type: Fargesynstype
    /// Vanskelige par for avviket (indekser i `farger`).
    var forvekslinger: [Forveksling] = []
    @State private var fyll: CGImage?

    /// Utsnittet av diagrammet (x 0…0,8, y 0…0,9).
    nonisolated private static let maksX = 0.8, maksY = 0.9

    var body: some View {
        Canvas { ctx, størrelse in
            let marg: CGFloat = 22
            let r = CGRect(x: marg, y: 8, width: størrelse.width - marg - 8, height: størrelse.height - marg - 8)
            func p(_ q: Kromatisitet.Punkt) -> CGPoint {
                CGPoint(x: r.minX + q.x / Self.maksX * r.width, y: r.maxY - q.y / Self.maksY * r.height)
            }
            var kurve = Path()
            for (i, (_, q)) in Kromatisitet.spektralkurve.enumerated() {
                i == 0 ? kurve.move(to: p(q)) : kurve.addLine(to: p(q))
            }
            kurve.closeSubpath()
            if let fyll {
                ctx.draw(Image(decorative: fyll, scale: 1), in: r)
            }
            ctx.stroke(kurve, with: .color(.primary.opacity(0.45)), lineWidth: 1)

            // sRGB-trekanten, til å orientere seg.
            let srgb = Kromatisitet.hjørner { Farge(lineærR: $0, g: $1, b: $2) }
            var trekant = Path()
            trekant.addLines(srgb.map(p))
            trekant.closeSubpath()
            ctx.stroke(trekant, with: .color(.primary.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            if let k = Kromatisitet.kopunkt(type) {
                var klippet = ctx
                klippet.clip(to: kurve)
                // Vifte av svake linjer gjennom kopunktet.
                let mot = Kromatisitet.Punkt(x: 0.31, y: 0.33)
                let grunn = atan2(mot.y - k.y, mot.x - k.x)
                for i in -14...14 {
                    let v = grunn + Double(i) * 0.045
                    let fjern = Kromatisitet.Punkt(x: k.x + cos(v) * 3, y: k.y + sin(v) * 3)
                    var linje = Path()
                    linje.move(to: p(k)); linje.addLine(to: p(fjern))
                    klippet.stroke(linje, with: .color(.black.opacity(0.12)), lineWidth: 0.75)
                }
                // Forvirringslinjen gjennom hver farge.
                for f in farger {
                    let q = Kromatisitet.punkt(f)
                    let v = atan2(q.y - k.y, q.x - k.x)
                    let fjern = Kromatisitet.Punkt(x: k.x + cos(v) * 3, y: k.y + sin(v) * 3)
                    var linje = Path()
                    linje.move(to: p(k)); linje.addLine(to: p(fjern))
                    klippet.stroke(linje, with: .color(f.lesbarTekstfarge == Farge(lineærR: 1, g: 1, b: 1) ? .white.opacity(0.7) : .black.opacity(0.45)),
                                   lineWidth: 1)
                }
            }
            // Vanskelige par streket sammen.
            for f in forvekslinger where farger.indices.contains(f.i) && farger.indices.contains(f.j) {
                var linje = Path()
                linje.move(to: p(Kromatisitet.punkt(farger[f.i]))); linje.addLine(to: p(Kromatisitet.punkt(farger[f.j])))
                ctx.stroke(linje, with: .color(Color.feil), lineWidth: f.alvorlig ? 3 : 2)
            }
            for f in farger {
                let q = p(Kromatisitet.punkt(f))
                let sirkel = Path(ellipseIn: CGRect(x: q.x - 7, y: q.y - 7, width: 14, height: 14))
                ctx.fill(sirkel, with: .color(f.swiftUI))
                ctx.stroke(sirkel, with: .color(.white), lineWidth: 2)
                ctx.stroke(sirkel.strokedPath(StrokeStyle(lineWidth: 2)), with: .color(.black.opacity(0.3)), lineWidth: 0.5)
            }
            // Akser.
            for (tekst, punkt) in [("x", CGPoint(x: r.maxX - 4, y: r.maxY + 12)), ("y", CGPoint(x: r.minX - 12, y: r.minY + 6))] {
                ctx.draw(Text(verbatim: tekst).font(.caption.weight(.semibold)).foregroundStyle(Color.sekundærTekst), at: punkt)
            }
            for nm in [460, 480, 500, 520, 540, 560, 580, 600, 620] {
                let q = p(Kromatisitet.punkt(nm: Double(nm)))
                ctx.draw(Text(verbatim: "\(nm)").font(.system(size: 9)).foregroundStyle(Color.sekundærTekst), at: CGPoint(x: q.x + (nm < 510 ? -12 : 12), y: q.y))
            }
        }
        .aspectRatio(0.95, contentMode: .fit)
        .task { if fyll == nil { fyll = await Task.detached(priority: .utility) { Self.fyllbilde }.value } }
        .accessibilityElement()
        .accessibilityLabel(Text("Kromatisitetsdiagram med forvirringslinjer for \(type.navn)"))
        .accessibilityValue(Text(forvekslinger.isEmpty ? String(localized: "Ingen vanskelige par") : String(localized: "\(forvekslinger.count) vanskelige par")))
    }

    /// Fyllet: hver xy som en lys farge med den kromatisiteten (gamut-kartlagt til Display P3) – en illustrasjon,
    /// kanten blir P3-kanten.
    /// Regnes én gang (tungt: hver piksel gamut-kartlegges).
    nonisolated private static let fyllbilde: CGImage? = lagFyll(bredde: 240, høyde: 270)

    nonisolated private static func lagFyll(bredde: Int, høyde: Int) -> CGImage? {
        guard let rom = CGColorSpace(name: CGColorSpace.displayP3),
              let ctx = CGContext(data: nil, width: bredde, height: høyde, bitsPerComponent: 8, bytesPerRow: bredde * 4,
                                  space: rom, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let piksler = ctx.data?.assumingMemoryBound(to: UInt8.self)
        else { return nil }
        let kurve = CGMutablePath()
        for (i, (_, q)) in Kromatisitet.spektralkurve.enumerated() {
            let pt = CGPoint(x: q.x / maksX * Double(bredde), y: (1 - q.y / maksY) * Double(høyde))
            i == 0 ? kurve.move(to: pt) : kurve.addLine(to: pt)
        }
        kurve.closeSubpath()
        let topp = (0..<360).map { Farge.toppunktLyshet(kulør: Double($0), i: .displayP3) }
        for py in 0..<høyde {
            for px in 0..<bredde {
                let q = CGPoint(x: Double(px) + 0.5, y: Double(py) + 0.5)
                guard kurve.contains(q) else { continue }
                let x = q.x / Double(bredde) * maksX, y = (1 - q.y / Double(høyde)) * maksY
                let lch = Farge(xyz: XYZ(x: x / y, y: 1, z: (1 - x - y) / y)).okLCH
                let kulør = (lch.h.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
                let t = exp(-lch.c / 0.05)
                let lyshet = topp[Int(kulør) % 360] * (1 - t) + 0.94 * t
                let f = Farge(okLCH: OKLCH(l: lyshet, c: lch.c, h: lch.h)).gamutKartlagt(til: .displayP3).displayP3
                let i = (py * bredde + px) * 4
                piksler[i] = UInt8((min(max(f.r, 0), 1) * 255).rounded())
                piksler[i + 1] = UInt8((min(max(f.g, 0), 1) * 255).rounded())
                piksler[i + 2] = UInt8((min(max(f.b, 0), 1) * 255).rounded())
                piksler[i + 3] = 255
            }
        }
        return ctx.makeImage()
    }
}
