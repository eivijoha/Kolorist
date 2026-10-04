import FargeKjerne
import SwiftData
import SwiftUI

/// Liten gradientstripe (OKLab-overgangen mellom endepunktene), brukt i palettoversikten og -kolonnen.
struct GradientStripe: View {
    let oppsett: Gradientoppsett
    var hjørne: CGFloat = 6

    var body: some View {
        let prøver = Overgang.toner(fra: oppsett.fra, til: oppsett.til, antall: 16)
        LinearGradient(stops: prøver.enumerated().map { Gradient.Stop(color: $1.swiftUI, location: Double($0) / 15) },
                       startPoint: .leading, endPoint: .trailing)
            .clipShape(RoundedRectangle(cornerRadius: hjørne, style: .continuous))
            .accessibilityLabel(String(localized: "Gradient fra \(oppsett.fra.hex()) til \(oppsett.til.hex())"))
    }
}

/// «Legg gradienten i palett»: velg en palett, eller lag en ny med gradienten.
struct LeggGradientIPalettMeny: View {
    let oppsett: Gradientoppsett
    let navn: String
    @Environment(\.modelContext) private var kontekst
    @Query(sort: \PalettDokument.opprettet, order: .reverse) private var paletter: [PalettDokument]

    var body: some View {
        Menu("Legg gradienten i palett", systemImage: "swatchpalette") {
            ForEach(paletter) { p in
                Button(p.navn.isEmpty ? String(localized: "Uten navn") : p.navn) {
                    p.gradienter.append(PalettGradient(navn: navn, oppsett: oppsett))
                }
            }
            if !paletter.isEmpty { Divider() }
            Button("Ny palett med gradienten", systemImage: "plus") {
                let p = PalettDokument(navn: navn.isEmpty ? String(localized: "Ny palett") : navn)
                p.gradienter = [PalettGradient(navn: navn, oppsett: oppsett)]
                kontekst.insert(p)
            }
        }
    }
}

/// Gradientene i en åpen palett: navn, stripe og endepunkter. Trykk åpner gradienten i Overgang.
struct PalettGradientListe: View {
    @Bindable var dokument: PalettDokument
    @Environment(Arbeidsbenk.self) private var arbeidsbenk

    var body: some View {
        if !dokument.gradienter.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Gradienter").font(.headline)
                ForEach(dokument.gradienter) { g in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(g.navn.isEmpty ? String(localized: "Uten navn") : g.navn).font(.subheadline.weight(.semibold)).lineLimit(1)
                        GradientStripe(oppsett: g.oppsett, hjørne: 8).frame(height: 44)
                        HStack {
                            Text(g.oppsett.fra.hex())
                            Spacer()
                            Text(g.oppsett.til.hex())
                        }
                        .font(.caption2.monospaced())
                        .foregroundStyle(Color.sekundærTekst)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { åpne(g) }
                    .contextMenu {
                        Button("Åpne i Overgang", systemImage: "arrow.up.forward.app") { åpne(g) }
                        GradientKopierTilMeny(gradient: Gradientkopi(farger: [g.oppsett.fra, g.oppsett.til], navn: g.navn))
                        DelSomLenke(navn: g.navn) { Lenkedeling.gradient(g.oppsett, navn: g.navn) }
                        Button("Slett", systemImage: "trash", role: .destructive) {
                            dokument.gradienter.removeAll { $0.id == g.id }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction(named: "Åpne i Overgang") { åpne(g) }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    /// Åpner gradienten i Overgang (i palettkolonnen vises Overgang ved siden av).
    private func åpne(_ g: PalettGradient) {
        arbeidsbenk.åpne(g.oppsett)
    }
}
