import SwiftUI

/// Glider med fargespor: sporet viser fargene man får ved å flytte nettopp denne komponenten,
/// med de andre komponentene som de er (f.eks. kulør ved gjeldende lyshet og kroma).
struct FargeGlider: View {
    @Binding var verdi: Double
    let område: ClosedRange<Double>
    /// Farger jevnt fordelt langs sporet, fra laveste til høyeste verdi.
    let spor: [Color]
    /// Fargen ved gjeldende verdi (fyller tommelen).
    let gjeldende: Color
    var tittel: Text = Text("")
    var verdiTekst: String = ""
    var stegForTilgjengelighet: Double? = nil
    /// Om verdien gir en farge innenfor fargerommet som vises (f.eks. «Vis som» i Studio). Delene av sporet utenfor
    /// stripes, med et merke der grensen går. `nil` = ingen grense. Regnes i bakgrunnen, og bare når `grensenøkkel`
    /// endres (den skal beskrive alt predikatet avhenger av: rommet og de andre komponentene).
    var innenfor: (@Sendable (Double) -> Bool)? = nil
    var grensenøkkel: String = ""
    @State private var utenforDeler: [ClosedRange<Double>] = []

    private let høyde: CGFloat = 10
    private let tommel: CGFloat = 26

    private var andel: Double {
        let spenn = område.upperBound - område.lowerBound
        return spenn > 0 ? min(max((verdi - område.lowerBound) / spenn, 0), 1) : 0
    }

    var body: some View {
        GeometryReader { geo in
            let bredde = geo.size.width
            let løp = max(bredde - tommel, 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(colors: spor.isEmpty ? [.gray] : spor, startPoint: .leading, endPoint: .trailing))
                    .frame(height: høyde)
                    .overlay {
                        if innenfor != nil, !utenforDeler.isEmpty { Gamutgrense(utenfor: utenforDeler) }
                    }
                    .overlay(Capsule().strokeBorder(Color.sekundærTekst.opacity(0.35), lineWidth: 0.5))
                    .padding(.horizontal, tommel / 2 - høyde / 2)
                Circle()
                    .fill(gjeldende)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    .overlay(Circle().strokeBorder(Color.black.opacity(0.25), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    .frame(width: tommel, height: tommel)
                    .offset(x: andel * løp)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { g in
                    let t = min(max((g.location.x - tommel / 2) / løp, 0), 1)
                    verdi = område.lowerBound + t * (område.upperBound - område.lowerBound)
                }
            )
        }
        .frame(height: 44)
        .task(id: innenfor == nil ? "" : grensenøkkel) {
            guard let innenfor else { utenforDeler = []; return }
            let o = område
            let deler = await Task.detached(priority: .userInitiated) { Self.utenfor(innenfor, område: o) }.value
            if !Task.isCancelled { utenforDeler = deler }
        }
        .accessibilityElement()
        .accessibilityHint(innenfor.map { $0(verdi) ? Text("") : Text("Utenfor fargerommet") } ?? Text(""))
        .accessibilityLabel(tittel)
        .accessibilityValue(verdiTekst)
        .accessibilityAdjustableAction { retning in
            let steg = stegForTilgjengelighet ?? (område.upperBound - område.lowerBound) / 50
            let ny = verdi + (retning == .increment ? steg : -steg)
            verdi = min(max(ny, område.lowerBound), område.upperBound)
        }
    }

    /// Delene av området (som andeler 0…1) der fargen er utenfor: 40 prøver, og hver grense funnet nøyaktig ved halvering.
    nonisolated static func utenfor(_ innenfor: (Double) -> Bool, område: ClosedRange<Double>) -> [ClosedRange<Double>] {
        let n = 40
        let spenn = område.upperBound - område.lowerBound
        func inne(_ t: Double) -> Bool { innenfor(område.lowerBound + t * spenn) }
        func grense(_ a: Double, _ b: Double, inneVedA: Bool) -> Double {
            var (lav, høy) = (a, b)
            for _ in 0..<8 {
                let midt = (lav + høy) / 2
                if inne(midt) == inneVedA { lav = midt } else { høy = midt }
            }
            return (lav + høy) / 2
        }
        var deler: [ClosedRange<Double>] = []
        var forrige = inne(0)
        var start: Double? = forrige ? nil : 0
        for k in 1...n {
            let t = Double(k) / Double(n)
            let nå = inne(t)
            if nå != forrige {
                let g = grense(Double(k - 1) / Double(n), t, inneVedA: forrige)
                if nå { if let s = start { deler.append(s...g) }; start = nil } else { start = g }
                forrige = nå
            }
        }
        if let s = start { deler.append(s...1) }
        return deler
    }
}

/// Striper over delene av et spor som er utenfor fargerommet, og et merke ved hver grense.
struct Gamutgrense: View {
    /// Andeler 0…1 av sporet.
    let utenfor: [ClosedRange<Double>]

    var body: some View {
        Canvas { ctx, størrelse in
            let w = størrelse.width, h = størrelse.height
            for del in utenfor {
                let rute = CGRect(x: del.lowerBound * w, y: 0, width: (del.upperBound - del.lowerBound) * w, height: h)
                var klippet = ctx
                klippet.clip(to: Path(rute))
                klippet.tegnGamutstriper(i: rute, avstand: 4)
                // Merket ved grensen (ikke ved endene av sporet).
                for g in [del.lowerBound, del.upperBound] where g > 0.001 && g < 0.999 {
                    var linje = Path()
                    linje.move(to: CGPoint(x: g * w, y: -3)); linje.addLine(to: CGPoint(x: g * w, y: h + 3))
                    ctx.stroke(linje, with: .color(.primary.opacity(0.8)), lineWidth: 1.5)
                }
            }
        }
        .clipShape(Capsule())
        .allowsHitTesting(false)
    }
}

extension GraphicsContext {
    /// Skrå striper over et område utenfor fargerommet (hvit med en mørk skygge, så de ses på både lyse og mørke farger).
    /// Klipp konteksten til området først.
    func tegnGamutstriper(i rute: CGRect, avstand: CGFloat) {
        var striper = Path()
        let h = rute.height
        var x = rute.minX - h
        while x < rute.maxX + h {
            striper.move(to: CGPoint(x: x, y: rute.maxY)); striper.addLine(to: CGPoint(x: x + h, y: rute.minY))
            x += avstand
        }
        stroke(striper, with: .color(.white.opacity(0.65)), lineWidth: 1.2)
        stroke(striper.offsetBy(dx: 1.4, dy: 0), with: .color(.black.opacity(0.3)), lineWidth: 0.8)
    }
}
