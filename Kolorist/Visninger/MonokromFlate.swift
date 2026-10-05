import FargeKjerne
import SwiftUI

/// Lyshet–metning-planet for én kulør (OKLCH): lyshet loddrett, kroma vannrett, med fargene innenfor gamut og
/// grensen der de slutter. Streken for en monokromatisk harmoni ligger oppå; dra endepunktene for å flytte den,
/// og tonene fordeler seg jevnt langs streken.
struct LyshetMetningFlate: View {
    let kulør: Double
    let gamut: Gamut
    @Binding var strek: Monokromstrek
    let toner: [Farge]
    /// Grunnfargen, vist som en liten ring for å orientere seg.
    let grunnfarge: Farge
    var velg: (Farge) -> Void = { _ in }

    /// Endepunktet som dras (a eller b), valgt ved starten av bevegelsen.
    @State private var drar: WritableKeyPath<Monokromstrek, Monokromstrek.Punkt>?
    /// Om bevegelsen har startet (og om den startet nær et endepunkt).
    @State private var startet = false

    private static let rader = 40, kolonner = 40
    private let marg: CGFloat = 14

    /// Høyeste kroma for kuløren ved noen lyshet: flatens bredde.
    private var kromaområde: Double {
        let maks = (1..<40).map { Farge.maksKroma(lyshet: Double($0) / 40, kulør: kulør, i: gamut) }.max() ?? 0.1
        return max(maks, 0.02) * 1.04
    }

    private func punkt(_ p: Monokromstrek.Punkt, i r: CGRect, kromaområde: Double) -> CGPoint {
        CGPoint(x: r.minX + r.width * p.kroma(kulør: kulør, gamut: gamut) / kromaområde,
                y: r.maxY - r.height * p.lyshet)
    }

    private func punkt(for f: Farge, i r: CGRect, kromaområde: Double) -> CGPoint {
        let lch = f.okLCH
        return CGPoint(x: r.minX + r.width * min(lch.c / kromaområde, 1), y: r.maxY - r.height * lch.l)
    }

    var body: some View {
        GeometryReader { geo in
            let r = CGRect(origin: .zero, size: geo.size).insetBy(dx: marg, dy: marg)
            let kromaområde = kromaområde
            let pa = punkt(strek.a, i: r, kromaområde: kromaområde)
            let pb = punkt(strek.b, i: r, kromaområde: kromaområde)
            Canvas { ctx, _ in
                // Gamut-grensen for kuløren som en jevn kurve, og fargene innenfor den (rad for rad, klippet til kurven).
                var grense = Path()
                grense.move(to: CGPoint(x: r.minX, y: r.maxY))
                for i in 0...120 {
                    let l = Double(i) / 120
                    let maks = Farge.maksKroma(lyshet: l, kulør: kulør, i: gamut)
                    grense.addLine(to: CGPoint(x: r.minX + r.width * maks / kromaområde, y: r.maxY - r.height * l))
                }
                grense.addLine(to: CGPoint(x: r.minX, y: r.minY))
                grense.closeSubpath()
                let celleH = r.height / CGFloat(Self.rader), celleB = r.width / CGFloat(Self.kolonner)
                ctx.drawLayer { lag in
                    lag.clip(to: grense)
                    for rad in 0..<Self.rader {
                        let l = (Double(rad) + 0.5) / Double(Self.rader)
                        let maks = Farge.maksKroma(lyshet: l, kulør: kulør, i: gamut)
                        let y = r.maxY - CGFloat(rad + 1) * celleH
                        // Én celle ekstra forbi grensen ved denne lysheten; kurven klipper bort resten.
                        let antall = min(Int((r.width * maks / kromaområde / celleB).rounded(.up)) + 1, Self.kolonner)
                        for k in 0..<antall {
                            let c = min((Double(k) + 0.5) * Double(celleB / r.width) * kromaområde, maks)
                            let farge = Farge(okLCH: OKLCH(l: l, c: c, h: kulør)).gamutKartlagt(til: gamut)
                            // Litt overlapp, så det ikke blir fuger mellom cellene.
                            lag.fill(Path(CGRect(x: r.minX + CGFloat(k) * celleB, y: y, width: celleB + 0.5, height: celleH + 0.5)),
                                     with: .color(farge.swiftUI))
                        }
                    }
                }
                ctx.stroke(grense, with: .color(.primary.opacity(0.3)), lineWidth: 1)

                // Streken og tonene langs den.
                var linje = Path()
                linje.move(to: pa)
                linje.addLine(to: pb)
                ctx.stroke(linje, with: .color(.white.opacity(0.9)), lineWidth: 3)
                ctx.stroke(linje, with: .color(.black.opacity(0.55)), lineWidth: 1)
                for (i, tone) in toner.enumerated() {
                    let t = toner.count > 1 ? CGFloat(i) / CGFloat(toner.count - 1) : 0
                    let p = CGPoint(x: pa.x + (pb.x - pa.x) * t, y: pa.y + (pb.y - pa.y) * t)
                    let endepunkt = i == 0 || i == toner.count - 1
                    let d: CGFloat = endepunkt ? 28 : 16
                    let rute = CGRect(x: p.x - d / 2, y: p.y - d / 2, width: d, height: d)
                    ctx.fill(Path(ellipseIn: rute), with: .color(tone.swiftUI))
                    ctx.stroke(Path(ellipseIn: rute), with: .color(tone.lesbarTekstfarge.swiftUI), lineWidth: endepunkt ? 3 : 2)
                }

                // Grunnfargen som en liten ring.
                let g = punkt(for: grunnfarge, i: r, kromaområde: kromaområde)
                ctx.stroke(Path(ellipseIn: CGRect(x: g.x - 6, y: g.y - 6, width: 12, height: 12)),
                           with: .color(grunnfarge.lesbarTekstfarge.swiftUI), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        if !startet {
                            startet = true
                            // Bare nær et endepunkt; et trykk andre steder (f.eks. på en tone) flytter ingenting.
                            let da = hypot(v.startLocation.x - pa.x, v.startLocation.y - pa.y)
                            let db = hypot(v.startLocation.x - pb.x, v.startLocation.y - pb.y)
                            if min(da, db) < 32 { drar = da <= db ? \.a : \.b }
                        }
                        guard let drar else { return }
                        let l = Double((r.maxY - v.location.y) / r.height)
                        let c = max(Double((v.location.x - r.minX) / r.width) * kromaområde, 0)
                        strek[keyPath: drar] = .fra(lyshet: min(max(l, 0.02), 0.98), kroma: c, kulør: kulør, gamut: gamut)
                    }
                    .onEnded { v in
                        // Et trykk uten bevegelse på en tone gjør den til aktiv farge.
                        if hypot(v.translation.width, v.translation.height) < 4,
                           let nærmeste = nærmesteTone(v.location, pa: pa, pb: pb), nærmeste.avstand < 18 {
                            velg(toner[nærmeste.indeks])
                        }
                        drar = nil
                        startet = false
                    }
            )
            .overlay(alignment: .bottomTrailing) {
                Text("Metning →").font(.caption2).foregroundStyle(Color.sekundærTekst).padding(.trailing, marg).padding(.bottom, 0)
                    .offset(y: marg - 2)
            }
            .overlay(alignment: .topLeading) {
                Text("↑ Lyshet").font(.caption2).foregroundStyle(Color.sekundærTekst).padding(.leading, marg)
                    .offset(y: -2)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Lyshet og metning"))
        .accessibilityValue(Text("Fra lyshet \(Int(strek.a.lyshet * 100)) % og metning \(Int(strek.a.metning * 100)) % til lyshet \(Int(strek.b.lyshet * 100)) % og metning \(Int(strek.b.metning * 100)) %"))
    }

    private func nærmesteTone(_ p: CGPoint, pa: CGPoint, pb: CGPoint) -> (indeks: Int, avstand: CGFloat)? {
        guard !toner.isEmpty else { return nil }
        return toner.indices.map { i -> (Int, CGFloat) in
            let t = toner.count > 1 ? CGFloat(i) / CGFloat(toner.count - 1) : 0
            let q = CGPoint(x: pa.x + (pb.x - pa.x) * t, y: pa.y + (pb.y - pa.y) * t)
            return (i, hypot(p.x - q.x, p.y - q.y))
        }.min { $0.1 < $1.1 }.map { (indeks: $0.0, avstand: $0.1) }
    }
}
