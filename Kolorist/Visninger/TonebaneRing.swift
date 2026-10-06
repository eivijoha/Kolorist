import FargeKjerne
import SwiftUI

/// Kulørring for en tonebane: ringen viser kulørene i valgt fargesirkel, med to håndtak for start- og sluttkuløren og en
/// bue med pil som viser banen fra start til slutt. Banen går i den retningen man drar, og kan gå helt rundt (opptil
/// 360°) – den snur ikke til korteste vei. Flytter man det ene håndtaket, står det andre stille. Midten (flaten for
/// lyshet og metning) legges inni ringen.
struct TonebaneRing<Midt: View>: View {
    /// Startkulør (OKLCH-grader) og spenn i grader med fortegn (positiv = mot høyere vinkel i sirkelen), −360…360.
    let start: Double
    let spenn: Double
    /// Ringens farge ved en vinkel i valgt fargesirkel.
    let ringfarge: (Double) -> Color
    /// Fargen ved en OKLCH-kulør (til håndtakene).
    let farge: (Double) -> Color
    /// OKLCH-kulør → vinkel i valgt fargesirkel, og omvendt.
    let vinkel: (Double) -> Double
    let kulør: (Double) -> Double
    var tekst: (Double) -> String = { "\(Int($0.rounded()))°" }
    var stegForTilgjengelighet: Double = 5
    /// Ny start og nytt spenn.
    var endre: (Double, Double) -> Void
    @ViewBuilder var midt: Midt

    private enum Håndtak { case start, slutt }
    @State private var drar: Håndtak?
    /// Kuløren (OKLCH) der fingeren var sist, så bevegelsen kan følges rundt 0°/360° uten hopp.
    @State private var sisteKulør: Double?

    private let bånd: CGFloat = 22
    private let tommel: CGFloat = 28

    private var slutt: Double { Self.normaliser(start + spenn) }

    static func normaliser(_ h: Double) -> Double {
        let v = h.truncatingRemainder(dividingBy: 360)
        return v < 0 ? v + 360 : v
    }

    /// Korteste forskjell b − a i grader (−180…180), for små bevegelser.
    private static func steg(_ a: Double, _ b: Double) -> Double {
        var d = (b - a).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }

    private func punkt(_ v: Double, radius: CGFloat, senter: CGPoint) -> CGPoint {
        let r = (v - 90) * .pi / 180
        return CGPoint(x: senter.x + cos(r) * radius, y: senter.y + sin(r) * radius)
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let senter = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let ytre = side / 2 - tommel / 2
            let ringR = ytre - bånd / 2
            let baneR = ytre - bånd - 8
            let indre = baneR - 6
            ZStack {
                Canvas { ctx, _ in
                    // Ringen, i 2°-stykker.
                    for i in 0..<180 {
                        let a0 = Double(i) * 2
                        var sti = Path()
                        sti.addArc(center: senter, radius: ringR, startAngle: .degrees(a0 - 90), endAngle: .degrees(a0 + 2.4 - 90), clockwise: false)
                        ctx.stroke(sti, with: .color(ringfarge(a0 + 1)), lineWidth: bånd)
                    }
                    // Banen fra start til slutt, med pil i sluttenden.
                    let n = max(Int(abs(spenn) / 2), 2)
                    var bane = Path()
                    var siste = CGPoint.zero, nestSiste = CGPoint.zero
                    for i in 0...n {
                        let p = punkt(vinkel(Self.normaliser(start + spenn * Double(i) / Double(n))), radius: baneR, senter: senter)
                        if i == 0 { bane.move(to: p) } else { bane.addLine(to: p) }
                        nestSiste = siste
                        siste = p
                    }
                    ctx.stroke(bane, with: .color(.primary.opacity(0.55)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    if abs(spenn) > 4 {
                        let dx = siste.x - nestSiste.x, dy = siste.y - nestSiste.y
                        let l = max(sqrt(dx * dx + dy * dy), 0.001)
                        let (ux, uy) = (dx / l, dy / l)
                        var pil = Path()
                        pil.move(to: CGPoint(x: siste.x + ux * 4, y: siste.y + uy * 4))
                        pil.addLine(to: CGPoint(x: siste.x - ux * 7 - uy * 6, y: siste.y - uy * 7 + ux * 6))
                        pil.addLine(to: CGPoint(x: siste.x - ux * 7 + uy * 6, y: siste.y - uy * 7 - ux * 6))
                        pil.closeSubpath()
                        ctx.fill(pil, with: .color(.primary.opacity(0.7)))
                    }
                }
                // Ringen tar imot dra; midten har sine egne bevegelser.
                Ring(ytre: side / 2, indre: indre)
                    .fill(Color.clear)
                    .contentShape(Ring(ytre: side / 2, indre: indre), eoFill: true)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { g in dra(til: g.location, senter: senter) }
                            .onEnded { _ in drar = nil; sisteKulør = nil }
                    )
                midt
                    .frame(width: indre * 1.36, height: indre * 1.36)
                    .position(senter)
                håndtak(kulør: start, tittel: Text("Kulør, start"), senter: senter, radius: ringR) { endre(Self.normaliser(start + $0), spenn - $0) }
                håndtak(kulør: slutt, tittel: Text("Kulør, slutt"), senter: senter, radius: ringR) { endre(start, min(max(spenn + $0, -360), 360)) }
            }
        }
    }

    private func håndtak(kulør h: Double, tittel: Text, senter: CGPoint, radius: CGFloat, juster: @escaping (Double) -> Void) -> some View {
        Circle()
            .fill(farge(h))
            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
            .overlay(Circle().strokeBorder(Color.black.opacity(0.25), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            .frame(width: tommel, height: tommel)
            .position(punkt(vinkel(h), radius: radius, senter: senter))
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel(tittel)
            .accessibilityValue(tekst(vinkel(h)))
            .accessibilityAdjustableAction { juster($0 == .increment ? stegForTilgjengelighet : -stegForTilgjengelighet) }
    }

    private func dra(til p: CGPoint, senter: CGPoint) {
        let v = atan2(p.y - senter.y, p.x - senter.x) * 180 / .pi + 90
        let h = kulør(Self.normaliser(v))
        if drar == nil {
            // Det nærmeste håndtaket, målt i sirkelens vinkler.
            let ds = abs(Self.steg(vinkel(start), v)), de = abs(Self.steg(vinkel(slutt), v))
            drar = de <= ds ? .slutt : .start
            sisteKulør = drar == .slutt ? slutt : start
        }
        guard let forrige = sisteKulør else { return }
        let d = Self.steg(forrige, h)
        sisteKulør = h
        switch drar {
        case .slutt:
            endre(start, min(max(spenn + d, -360), 360))
        case .start:
            // Sluttkuløren står stille: spennet endres like mye motsatt vei.
            let nyttSpenn = min(max(spenn - d, -360), 360)
            endre(Self.normaliser(start + (spenn - nyttSpenn)), nyttSpenn)
        case nil: break
        }
    }
}

/// Ring mellom to radier (fylles med partallsregelen).
private nonisolated struct Ring: Shape {
    let ytre: CGFloat
    let indre: CGFloat

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.addEllipse(in: CGRect(x: c.x - ytre, y: c.y - ytre, width: ytre * 2, height: ytre * 2))
        p.addEllipse(in: CGRect(x: c.x - indre, y: c.y - indre, width: indre * 2, height: indre * 2))
        return p
    }
}
