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
        .accessibilityElement()
        .accessibilityLabel(tittel)
        .accessibilityValue(verdiTekst)
        .accessibilityAdjustableAction { retning in
            let steg = stegForTilgjengelighet ?? (område.upperBound - område.lowerBound) / 50
            let ny = verdi + (retning == .increment ? steg : -steg)
            verdi = min(max(ny, område.lowerBound), område.upperBound)
        }
    }
}

/// Glider med to håndtak i samme fargespor, for et spenn med start og slutt (f.eks. kulørene i en tonebane). En
/// strek under sporet viser buen mellom dem; `retning` sier hvilken vei rundt (positiv = mot høyere verdier), og
/// buen fortsetter fra den andre enden når den går forbi enden av sporet (kulør er sirkulær).
struct ToHåndtakGlider: View {
    @Binding var start: Double
    @Binding var slutt: Double
    let område: ClosedRange<Double>
    let spor: [Color]
    let startfarge: Color
    let sluttfarge: Color
    /// Hvilken vei buen går fra start til slutt (+1 eller −1).
    var retning: Double = 1
    var startTittel: Text = Text("Start")
    var sluttTittel: Text = Text("Slutt")
    var startTekst: String = ""
    var sluttTekst: String = ""
    var stegForTilgjengelighet: Double? = nil

    private let høyde: CGFloat = 10
    private let tommel: CGFloat = 26
    /// Håndtaket som dras, valgt ved starten av bevegelsen (det nærmeste).
    @State private var drarStart: Bool?

    private var spenn: Double { område.upperBound - område.lowerBound }
    private func andel(_ v: Double) -> Double { spenn > 0 ? min(max((v - område.lowerBound) / spenn, 0), 1) : 0 }

    /// Buen fra start til slutt som ett eller to stykker (andeler 0…1), delt der den går forbi enden av sporet.
    private var buestykker: [ClosedRange<Double>] {
        let a = andel(start), b = andel(slutt)
        if retning >= 0 { return a <= b ? [a...b] : [a...1, 0...b] }
        return b <= a ? [b...a] : [0...a, b...1]
    }

    private func håndtak(_ farge: Color) -> some View {
        Circle()
            .fill(farge)
            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
            .overlay(Circle().strokeBorder(Color.black.opacity(0.25), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            .frame(width: tommel, height: tommel)
    }

    var body: some View {
        GeometryReader { geo in
            let løp = max(geo.size.width - tommel, 1)
            let midt = geo.size.height / 2
            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(LinearGradient(colors: spor.isEmpty ? [.gray] : spor, startPoint: .leading, endPoint: .trailing))
                    .frame(width: løp + høyde, height: høyde)
                    .overlay(Capsule().strokeBorder(Color.sekundærTekst.opacity(0.35), lineWidth: 0.5))
                    .offset(x: tommel / 2 - høyde / 2, y: midt - høyde / 2)
                // Buen mellom håndtakene, rett under sporet.
                ForEach(Array(buestykker.enumerated()), id: \.offset) { _, stykke in
                    Capsule()
                        .fill(Color.primary.opacity(0.55))
                        .frame(width: max((stykke.upperBound - stykke.lowerBound) * løp, 3), height: 3)
                        .offset(x: tommel / 2 + stykke.lowerBound * løp, y: midt + tommel / 2 + 2)
                }
                håndtak(startfarge)
                    .offset(x: andel(start) * løp, y: midt - tommel / 2)
                    .accessibilityElement()
                    .accessibilityLabel(startTittel)
                    .accessibilityValue(startTekst)
                    .accessibilityAdjustableAction { juster(&start, $0) }
                håndtak(sluttfarge)
                    .offset(x: andel(slutt) * løp, y: midt - tommel / 2)
                    .accessibilityElement()
                    .accessibilityLabel(sluttTittel)
                    .accessibilityValue(sluttTekst)
                    .accessibilityAdjustableAction { juster(&slutt, $0) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let t = min(max((g.location.x - tommel / 2) / løp, 0), 1)
                        if drarStart == nil {
                            // Det nærmeste håndtaket; like nær: det som ligger i retningen man drar.
                            let ds = abs(t - andel(start)), de = abs(t - andel(slutt))
                            drarStart = abs(ds - de) < 0.01 ? (g.translation.width < 0) == (andel(start) <= andel(slutt)) : ds < de
                        }
                        let v = område.lowerBound + t * spenn
                        if drarStart == true { start = v } else { slutt = v }
                    }
                    .onEnded { _ in drarStart = nil }
            )
        }
        .frame(height: 50)
        .accessibilityElement(children: .contain)
    }

    private func juster(_ verdi: inout Double, _ retning: AccessibilityAdjustmentDirection) {
        let steg = stegForTilgjengelighet ?? spenn / 50
        verdi = min(max(verdi + (retning == .increment ? steg : -steg), område.lowerBound), område.upperBound)
    }
}
