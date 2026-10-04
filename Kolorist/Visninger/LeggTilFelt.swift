import FargeKjerne
import SwiftUI

/// Stiplet felt sist (eller først) i en fargeliste: viser fargen som legges til – den aktive fargen – med et pluss.
/// Erstatter plussknappen i verktøylinjen, så man ser både hvor fargen havner og hvilken farge det er.
struct LeggTilFelt: View {
    let farge: Farge
    /// Navnet på fargen som legges til (f.eks. et filament), vist i stedet for hex-verdien.
    var navn: String? = nil
    var hjørne: CGFloat = 12
    /// Med tekst («Legg til» og hex) i store ruter; bare plusset i små prøver.
    var visTekst = true
    let leggTil: () -> Void

    var body: some View {
        // Trykk-gest i stedet for knapp: feltet står også i palettrader som selv åpner paletten ved trykk.
        ZStack {
            RoundedRectangle(cornerRadius: hjørne, style: .continuous)
                .strokeBorder(Color.sekundærTekst.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            RoundedRectangle(cornerRadius: max(hjørne - innfelling / 2, 2), style: .continuous)
                .fill(farge.swiftUI)
                .padding(innfelling)
                .overlay(alignment: .bottomLeading) {
                    if visTekst {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Legg til").font(.caption.weight(.semibold))
                            if let navn, !navn.isEmpty {
                                Text(navn).font(.caption2).lineLimit(2)
                            } else {
                                Text(farge.hex()).font(.caption2.monospaced())
                            }
                        }
                        .foregroundStyle(farge.lesbarTekstfarge.swiftUI)
                        .padding(innfelling + 8)
                    }
                }
            Image(systemName: "plus")
                .font(visTekst ? .title2.weight(.semibold) : .caption.weight(.bold))
                .foregroundStyle(farge.lesbarTekstfarge.swiftUI)
        }
        .contentShape(RoundedRectangle(cornerRadius: hjørne, style: .continuous))
        .onTapGesture(perform: leggTil)
        #if os(iOS)
        .hoverEffect(.highlight)
        #endif
        .help("Legg til aktiv farge")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Legg til aktiv farge, \(navn.flatMap { $0.isEmpty ? nil : $0 } ?? farge.hex())")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { leggTil() }
    }

    private var innfelling: CGFloat { visTekst ? 6 : 4 }
}
