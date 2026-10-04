import SwiftUI

/// ⓘ-knapp med en forklaring i en boble, så lengre tekst ikke tar plass i skjemaet.
struct InfoKnapp<Innhold: View>: View {
    var tittel: LocalizedStringKey = "Mer om dette"
    @ViewBuilder var innhold: Innhold
    @State private var vis = false

    var body: some View {
        Button { vis = true } label: {
            Image(systemName: "info.circle")
                .imageScale(.medium)
                .foregroundStyle(.tint)
                .minsteTrykkflate()
        }
        // .plain: knapper med andre stiler reagerer ikke i bunnteksten til en seksjon.
        .buttonStyle(.plain)
        .accessibilityLabel(Text(tittel))
        .popover(isPresented: $vis) {
            VStack(alignment: .leading, spacing: 10) { innhold }
                .font(.callout)
                .frame(width: 320, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }
}

extension View {
    /// Trykkflate på minst 44 × 44 pt (Apples HIG for iOS og iPadOS) rundt et lite symbol, uten å endre utseende
    /// eller oppsett: flaten går ut over symbolet. På Mac holder 28 pt.
    func minsteTrykkflate() -> some View {
        #if os(macOS)
        let side: CGFloat = 28
        #else
        let side: CGFloat = 44
        #endif
        return self
            .frame(minWidth: side, minHeight: side)
            .contentShape(Rectangle())
            .padding(.vertical, -12)
            .padding(.horizontal, -10)
    }
}
