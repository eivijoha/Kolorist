import CoreGraphics
import FargeKjerne
import SwiftUI

/// Tonebanen i en halvgjennomsiktig fargekule (OKLCH), til forklaringen bak ⓘ: kuløren går rundt den grå aksen,
/// lysheten opp (lys) og ned (mørk), og metningen ut mot overflaten (så mettet som kuløren kan bli innenfor sRGB) eller
/// inn mot aksen (grått). Tonene ligger der de hører hjemme, også inne i kula. Kula er dreid så kuløren midt på banen
/// vender mot betrakteren, og vippet litt, så man ser ovenfra; det som ligger bak midten, er svakere.
struct TonebaneKule: View {
    let strek: Monokromstrek
    /// Startkulør (OKLCH-grader) og spenn med fortegn, som i `Monokromstrek.toner(fraKulør:spenn:antall:)`.
    let startKulør: Double
    let spenn: Double
    let antall: Int

    @State private var kule: CGImage?

    /// Vinkelen kula vippes mot betrakteren (sett ovenfra).
    nonisolated private static let vipp = 22.0 * .pi / 180
    nonisolated private static let piksler = 240
    /// Hvor dekkende overflaten er.
    nonisolated private static let dekning = 0.45

    private var midtkulør: Double { startKulør + spenn / 2 }

    var body: some View {
        Canvas { ctx, størrelse in
            let side = min(størrelse.width, størrelse.height)
            let senter = CGPoint(x: størrelse.width / 2, y: størrelse.height / 2)
            let r = side / 2 - 2
            let rute = CGRect(x: senter.x - r, y: senter.y - r, width: r * 2, height: r * 2)
            if let kule {
                // Klippet til en jevn sirkel, så kanten ikke blir hakkete av pikslene i bildet.
                var klippet = ctx
                klippet.clip(to: Path(ellipseIn: rute.insetBy(dx: 0.5, dy: 0.5)))
                klippet.draw(Image(decorative: kule, scale: 1), in: rute.insetBy(dx: -1, dy: -1))
            }
            ctx.stroke(Path(ellipseIn: rute), with: .color(.primary.opacity(0.3)), lineWidth: 1)

            // Den grå aksen (fra sort nederst til hvit øverst) og ekvator, til å orientere seg.
            let bunn = projiser(lyshet: 0, metning: 0, kulør: midtkulør, senter: senter, r: r).punkt
            let topp = projiser(lyshet: 1, metning: 0, kulør: midtkulør, senter: senter, r: r).punkt
            var akse = Path()
            akse.move(to: bunn)
            akse.addLine(to: topp)
            ctx.stroke(akse, with: .linearGradient(Gradient(colors: [.black, .white]), startPoint: bunn, endPoint: topp), lineWidth: 3)
            ctx.stroke(akse, with: .color(.primary.opacity(0.35)), lineWidth: 0.5)
            var ekvator = Path()
            for i in 0...72 {
                let p = projiser(lyshet: 0.5, metning: 1, kulør: Double(i) * 5, senter: senter, r: r).punkt
                if i == 0 { ekvator.move(to: p) } else { ekvator.addLine(to: p) }
            }
            ctx.stroke(ekvator, with: .color(.primary.opacity(0.3)), style: StrokeStyle(lineWidth: 0.75, dash: [2, 3]))

            // Banen: tett med punkter; delen bak midten er svakere.
            let n = max(Int(abs(spenn) / 3), 32)
            let punkter = (0...n).map { i in banepunkt(Double(i) / Double(n), senter: senter, r: r) }
            var foran = Path(), bak = Path()
            for i in 1..<punkter.count {
                let (p0, f0) = punkter[i - 1], (p1, f1) = punkter[i]
                if f0 && f1 { foran.move(to: p0); foran.addLine(to: p1) } else { bak.move(to: p0); bak.addLine(to: p1) }
            }
            for (sti, styrke) in [(bak, 0.45), (foran, 1.0)] {
                ctx.stroke(sti, with: .color(.white.opacity(0.95 * styrke)), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                ctx.stroke(sti, with: .color(.black.opacity(0.75 * styrke)), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }

            // Tonene, i sin egen farge; sluttonen litt større (som pilen i ringen).
            let toner = strek.toner(fraKulør: startKulør, spenn: spenn, antall: antall, gamut: .sRGB)
            for (i, tone) in toner.enumerated() {
                let t = toner.count > 1 ? Double(i) / Double(toner.count - 1) : 0
                let (p, foranMidten) = banepunkt(t, senter: senter, r: r)
                let d: CGFloat = i == toner.count - 1 ? 16 : 11
                let sirkel = Path(ellipseIn: CGRect(x: p.x - d / 2, y: p.y - d / 2, width: d, height: d))
                ctx.fill(sirkel, with: .color(tone.swiftUI.opacity(foranMidten ? 1 : 0.6)))
                ctx.stroke(sirkel, with: .color(.white.opacity(foranMidten ? 1 : 0.6)), lineWidth: 2)
            }
        }
        .frame(width: 200, height: 200)
        .frame(maxWidth: .infinity)
        .task(id: Int(midtkulør.rounded())) {
            let midt = midtkulør
            kule = await Task.detached(priority: .userInitiated) { Self.tegnKule(midtkulør: midt) }.value
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Fargekule med tonebanen"))
        .accessibilityValue(Text("Kuløren går \(Int(abs(spenn).rounded())) grader rundt kula, lysheten fra \(Int(strek.a.lyshet * 100)) % til \(Int(strek.b.lyshet * 100)) %"))
    }

    /// Punktet for andel `t` av banen (lyshet, metning og kulør som i tonene).
    private func banepunkt(_ t: Double, senter: CGPoint, r: CGFloat) -> (CGPoint, Bool) {
        let l = strek.a.lyshet + (strek.b.lyshet - strek.a.lyshet) * t
        let m = strek.a.metning + (strek.b.metning - strek.a.metning) * t
        let p = projiser(lyshet: l, metning: m, kulør: startKulør + spenn * t, senter: senter, r: r)
        return (p.punkt, p.foranMidten)
    }

    /// Lyshet opp langs aksen, metning ut mot overflaten (1 = på overflaten), kulør rundt aksen.
    private func projiser(lyshet: Double, metning: Double, kulør: Double, senter: CGPoint, r: CGFloat) -> (punkt: CGPoint, foranMidten: Bool) {
        let y = 2 * lyshet - 1
        let radius = metning * max(1 - y * y, 0).squareRoot()
        let φ = (kulør - midtkulør + 90) * .pi / 180
        let x = radius * cos(φ), z = radius * sin(φ)
        let a = Self.vipp
        let skjermY = y * cos(a) - z * sin(a)
        let dybde = y * sin(a) + z * cos(a)
        return (CGPoint(x: senter.x + x * r, y: senter.y - skjermY * r), dybde >= -0.001)
    }

    /// Forsiden av kula som bilde (sRGB, halvgjennomsiktig): på overflaten den mest mettede fargen ved hver lyshet og
    /// kulør, med litt mørkere kant så den ser rund ut.
    nonisolated private static func tegnKule(midtkulør: Double) -> CGImage? {
        let n = piksler
        var data = [UInt8](repeating: 0, count: n * n * 4)
        let a = vipp
        for py in 0..<n {
            for px in 0..<n {
                let sx = (Double(px) + 0.5) / Double(n) * 2 - 1
                let sy = 1 - (Double(py) + 0.5) / Double(n) * 2
                let d2 = sx * sx + sy * sy
                guard d2 <= 1 else { continue }
                let sz = (1 - d2).squareRoot()
                // Tilbake fra skjermen til kula (motsatt vipp).
                let y = sy * cos(a) + sz * sin(a)
                let z = -sy * sin(a) + sz * cos(a)
                let x = sx
                let l = min(max((y + 1) / 2, 0.001), 0.999)
                var kulør = atan2(z, x) * 180 / .pi - 90 + midtkulør
                kulør = kulør.truncatingRemainder(dividingBy: 360)
                if kulør < 0 { kulør += 360 }
                let c = Farge.maksKroma(lyshet: l, kulør: kulør, i: .sRGB)
                let rgb = Farge(okLCH: OKLCH(l: l, c: c, h: kulør)).gamutKartlagt(til: .sRGB).sRGB
                // Mer dekkende mot kanten (glass), og litt mørkere der, så den ser rund ut.
                let alfa = dekning + (1 - dekning) * 0.6 * (1 - sz)
                let skygge = (0.86 + 0.14 * sz) * alfa
                let i = (py * n + px) * 4
                data[i] = UInt8(min(max(rgb.r * skygge, 0), 1) * 255)
                data[i + 1] = UInt8(min(max(rgb.g * skygge, 0), 1) * 255)
                data[i + 2] = UInt8(min(max(rgb.b * skygge, 0), 1) * 255)
                data[i + 3] = UInt8(alfa * 255)
            }
        }
        guard let rom = CGColorSpace(name: CGColorSpace.sRGB),
              let leverandør = CGDataProvider(data: Data(data) as CFData) else { return nil }
        return CGImage(width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: n * 4, space: rom,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: leverandør, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}
