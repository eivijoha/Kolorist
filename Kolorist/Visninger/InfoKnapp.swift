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
        // Lukk boblen når knappen forsvinner (f.eks. tilbake til alle paletter): ellers kan en tom boble bli liggende
        // igjen nede til venstre i vinduet på Mac, der den mistet knappen den hørte til.
        .onDisappear { vis = false }
        .popover(isPresented: $vis) {
            let boble = VStack(alignment: .leading, spacing: 10) { innhold }
                .font(.callout)
                // Egen tekstfarge og aksent i boblen, så den ikke arver fargene fra stedet knappen står (f.eks. en fargeflate).
                .foregroundStyle(Color.primary)
                .tint(Color.accentColor)
                // Høyst 320 pt bred, men smalere når boblen får mindre plass (på iPhone havner den ofte ved siden av
                // knappen): da brytes teksten i stedet for å bli klippet i kantene.
                .frame(idealWidth: 320, maxWidth: 320, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
            // Rulles når forklaringen er høyere enn plassen boblen får.
            ViewThatFits(in: .vertical) {
                boble
                ScrollView { boble }
            }
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
            // Tilbake til omtrent symbolets størrelse i oppsettet (ca. 24 × 20 pt).
            .padding(.vertical, -(side - 20) / 2)
            .padding(.horizontal, -(side - 24) / 2)
    }
}

/// Kort forklaring i grensesnittet (høyst to linjer), med den lengre forklaringen bak ⓘ.
struct KortForklaring<Mer: View>: View {
    let tekst: Text
    @ViewBuilder var mer: Mer

    init(_ tekst: LocalizedStringKey, @ViewBuilder mer: () -> Mer) {
        self.tekst = Text(tekst)
        self.mer = mer()
    }

    init(verbatim tekst: String, @ViewBuilder mer: () -> Mer) {
        self.tekst = Text(verbatim: tekst)
        self.mer = mer()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            tekst
            InfoKnapp { mer }
        }
    }
}
