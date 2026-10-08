import FargeKjerne
import SwiftData
import SwiftUI

/// Skriftfargene i en palett (fra 1.3, valgfritt): en rad med skriftfargene, der hver kan endres, gis navn eller fjernes,
/// og «+» for flere (høyst `Skriftfarger.maksAntall`). Hver farge i paletten får skriftfargen som leses best og når 4,5:1,
/// med mindre brukeren har valgt selv i fargens meny.
struct SkriftfargeRad: View {
    @Bindable var dokument: PalettDokument
    @Environment(\.modelContext) private var kontekst
    @State private var navngis: PalettFarge?

    private func binding(_ id: UUID) -> Binding<Farge> {
        Binding(get: { dokument.tekstfarger.first { $0.id == id }?.farge ?? Farge(lineærR: 0, g: 0, b: 0) },
                set: { ny in
                    kontekst.angresteg("Endre skriftfarge") {
                        var t = dokument.tekstfarger
                        if let i = t.firstIndex(where: { $0.id == id }) { t[i].farge = ny }
                        dokument.tekstfarger = t
                    }
                })
    }

    private func fjern(_ id: UUID) {
        kontekst.angresteg("Fjern skriftfarge") {
            dokument.tekstfarger.removeAll { $0.id == id }
            // Farger som hadde valgt denne skriftfargen, går tilbake til automatisk.
            var f = dokument.farger
            for i in f.indices where f[i].tekstfarge == id { f[i].tekstfarge = nil }
            dokument.farger = f
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Skriftfarger", systemImage: "textformat").font(.headline)
                Spacer()
                Menu("Valg for skriftfargene", systemImage: "ellipsis.circle") {
                    Button("Foreslå på nytt fra paletten", systemImage: "wand.and.stars") {
                        kontekst.angresteg("Foreslå skriftfarger") {
                            dokument.tekstfarger = Skriftfarger.forslag(for: dokument.farger.map(\.farge))
                            var f = dokument.farger
                            for i in f.indices { f[i].tekstfarge = nil }
                            dokument.farger = f
                        }
                    }
                    Button("Fjern skriftfargene", systemImage: "trash", role: .destructive) {
                        kontekst.angresteg("Fjern skriftfargene") {
                            dokument.tekstfarger = []
                            var f = dokument.farger
                            for i in f.indices { f[i].tekstfarge = nil }
                            dokument.farger = f
                        }
                    }
                }
                .labelStyle(.iconOnly)
                .menuIndicator(.hidden)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dokument.tekstfarger) { t in
                        let id = t.id
                        FargeVelgerMeny(tittel: t.visningsnavn, farge: binding(id), visHvitOgSort: true,
                                        ekstra: AnyView(Group {
                                            Button("Gi navn …", systemImage: "character.cursor.ibeam") { navngis = t }
                                            Button("Fjern", systemImage: "trash", role: .destructive) { fjern(id) }
                                        })) {
                            HStack(spacing: 6) {
                                Circle().fill(t.farge.swiftUI)
                                    .overlay(Circle().strokeBorder(.secondary.opacity(0.5), lineWidth: 1))
                                    .frame(width: 18, height: 18)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(t.visningsnavn).font(.caption.weight(.semibold)).lineLimit(1)
                                    Text(t.farge.hex()).font(.caption2.monospaced()).foregroundStyle(Color.sekundærTekst)
                                }
                            }
                            .foregroundStyle(Color.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.kortbakgrunn, in: Capsule())
                            .overlay(Capsule().strokeBorder(.secondary.opacity(0.25), lineWidth: 1))
                        }
                    }
                    if dokument.tekstfarger.count < Skriftfarger.maksAntall {
                        Button {
                            kontekst.angresteg("Legg til skriftfarge") {
                                let nr = dokument.tekstfarger.count + 1
                                let grunn = Skriftfarger.forslag(for: dokument.farger.map(\.farge))[1].farge
                                dokument.tekstfarger.append(PalettFarge(navn: String(localized: "Skriftfarge \(nr)"), farge: grunn))
                            }
                        } label: {
                            Image(systemName: "plus").font(.callout.weight(.semibold))
                                .frame(width: 34, height: 34)
                                .background(Color.kortbakgrunn, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Legg til skriftfarge")
                    }
                }
                .padding(.vertical, 2)
            }
            Text("Hver farge får skriftfargen som leses best og når minst 4,5:1. Velg selv i fargens meny.")
                .font(.footnote)
                .foregroundStyle(Color.sekundærTekst)
        }
        .sheet(item: $navngis) { t in
            NavngiArk(farge: t) { navn in
                var liste = dokument.tekstfarger
                if let i = liste.firstIndex(where: { $0.id == t.id }) { liste[i].navn = navn }
                dokument.tekstfarger = liste
            }
        }
    }
}

/// Når paletten ikke har skriftfarger: en kort forklaring og «Definer skriftfarger» (vises bare i Skriftkontrast, så
/// funksjonen ikke presses på).
struct SkriftfargeInnledning: View {
    @Bindable var dokument: PalettDokument
    @Environment(\.modelContext) private var kontekst

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vil du bestemme tekstfargene på paletten selv, for eksempel en nær hvit og en nær sort med et preg av palettens farger, kan du definere skriftfarger. Ellers brukes sort eller hvit.")
                .font(.footnote)
                .foregroundStyle(Color.sekundærTekst)
            Button("Definer skriftfarger", systemImage: "textformat") {
                kontekst.angresteg("Definer skriftfarger") {
                    dokument.tekstfarger = Skriftfarger.forslag(for: dokument.farger.map(\.farge))
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

/// Valget av skriftfarge for én farge i paletten (i fargens meny): automatisk eller en bestemt skriftfarge.
struct SkriftfargeValgMeny: View {
    @Bindable var dokument: PalettDokument
    let farge: PalettFarge

    var body: some View {
        Menu("Skriftfarge", systemImage: "textformat") {
            Picker("Skriftfarge", selection: Binding(get: { farge.tekstfarge }, set: { ny in
                var f = dokument.farger
                if let i = f.firstIndex(where: { $0.id == farge.id }) { f[i].tekstfarge = ny }
                dokument.farger = f
            })) {
                Text("Automatisk").tag(UUID?.none)
                ForEach(dokument.tekstfarger) { t in
                    let v = Skriftfarger.vurdering(tekst: t.farge, på: farge.farge)
                    Text(t.visningsnavn + (v == .tekst ? "" : v == .storTekst ? String(localized: " (bare stor tekst)") : String(localized: " (for lav kontrast)")))
                        .tag(UUID?.some(t.id))
                }
            }
            .pickerStyle(.inline)
        }
    }
}
