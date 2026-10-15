import FargeKjerne
import SwiftData
import SwiftUI

/// «Gradienter» i Paletter: lagrede overganger som kort. Trykk åpner gradienten i Overgang.
struct GradientSeksjon: View {
    @Environment(\.modelContext) private var kontekst
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Query(sort: \LagretGradient.endret, order: .reverse) private var gradienter: [LagretGradient]
    @State private var slettes: LagretGradient?

    var body: some View {
        Listeseksjon("gradienter", tittel: "Gradienter") {
            if gradienter.isEmpty {
                Text("Ingen gradienter ennå. Lagre en fra Overgang med + på gradienten.")
                    .font(.callout)
                    .foregroundStyle(Color.sekundærTekst)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 12, alignment: .top)],
                      alignment: .leading, spacing: 12) {
                ForEach(gradienter) { g in
                    if let oppsett = g.oppsett {
                        // Sveip til venstre for å slette (iPhone/iPad), som palettkortene.
                        SveipForÅSlette(slett: { slettes = g }) {
                        GradientKort(navn: g.navn, oppsett: oppsett)
                            .onTapGesture { arbeidsbenk.åpne(oppsett) }
                            .accessibilityAction { arbeidsbenk.åpne(oppsett) }
                            .gradientmeny(oppsett, navn: g.navn, åpne: { arbeidsbenk.åpne(oppsett) }, giNavn: { navn in
                                kontekst.angresteg("Gi gradienten navn") { g.navn = navn; g.endret = .now }
                            }, slett: { slettes = g })
                        }
                    }
                }
            }
        }
        // Varsel midt på skjermen (ikke en popover som havner der kortet sto på iPad).
        .alert("Slette «\(slettes?.navn ?? "")»?", isPresented: Binding(get: { slettes != nil }, set: { if !$0 { slettes = nil } })) {
            Button("Avbryt", role: .cancel) {}
            Button("Slett gradient", role: .destructive) {
                if let slettes { kontekst.angresteg("Slett gradient") { kontekst.delete(slettes) } }
            }
        } message: {
            #if os(macOS)
            Text("Du kan angre med ⌘Z.")
            #else
            Text("Rist for å angre.")
            #endif
        }
    }
}

/// Kort for én lagret gradient: navn, glidende forhåndsvisning (OKLab) og tonene.
struct GradientKort: View {
    let navn: String
    let oppsett: Gradientoppsett

    var body: some View {
        let prøver = Overgang.toner(fra: oppsett.fra, til: oppsett.til, antall: 24)
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(navn.isEmpty ? String(localized: "Uten navn") : navn).font(.headline).lineLimit(1)
                    Spacer()
                    Text("\(oppsett.antall) toner").font(.caption).foregroundStyle(Color.sekundærTekst).monospacedDigit()
                }
                LinearGradient(stops: prøver.enumerated().map { Gradient.Stop(color: $1.swiftUI, location: Double($0) / 23) },
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                HStack(spacing: 3) {
                    ForEach(Array(oppsett.toner.enumerated()), id: \.offset) { _, f in
                        RoundedRectangle(cornerRadius: 4, style: .continuous).fill(f.swiftUI).frame(height: 14)
                    }
                }
                HStack {
                    Text(oppsett.fra.hex())
                    Spacer()
                    Text(oppsett.til.hex())
                }
                .font(.caption2.monospaced())
                .foregroundStyle(Color.sekundærTekst)
            }
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.tertiærTekst)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(navn), \(oppsett.fra.hex()) til \(oppsett.til.hex()), \(oppsett.antall) toner")
        .accessibilityHint("Åpner gradienten i Overgang")
        .accessibilityAddTraits(.isButton)
    }
}
