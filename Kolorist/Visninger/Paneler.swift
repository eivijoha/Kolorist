import FargeKjerne
import SwiftUI

/// Et sammenleggbart panel i et skjema: overskrift med pil, og innhold og fotnote som skjules når
/// panelet er lagt sammen. Tilstanden lagres i ``Panelinnstillinger`` og synkroniseres.
struct PanelSeksjon<Innhold: View, Fot: View>: View {
    let panel: Panelinnstillinger.Panel
    var tittel: String? = nil
    @ViewBuilder var innhold: Innhold
    @ViewBuilder var fot: Fot
    @State private var innstillinger = Panelinnstillinger.delt

    var body: some View {
        #if os(macOS)
        // Mac: systemets sammenleggbare seksjon, som trekker seg sammen (rader inn og ut i en egen seksjon tones bare
        // inn og ut). Fotnoten står nederst i panelet, siden slike seksjoner ikke har bunntekst.
        Section(isExpanded: Binding(get: { !innstillinger.erLagtSammen(panel) },
                                    set: { innstillinger.settLagtSammen(panel, !$0) })) {
            innhold
            fot.font(.footnote).foregroundStyle(Color.sekundærTekst)
        } header: {
            Text(tittel ?? panel.navn)
        }
        #else
        let sammen = innstillinger.erLagtSammen(panel)
        Section {
            if !sammen { innhold }
        } header: {
            PanelHode(tittel: tittel ?? panel.navn, sammen: sammen) {
                withAnimation(.snappy) { innstillinger.veksle(panel) }
            }
        } footer: {
            if !sammen { fot }
        }
        #endif
    }
}

extension PanelSeksjon where Fot == EmptyView {
    init(panel: Panelinnstillinger.Panel, tittel: String? = nil, @ViewBuilder innhold: () -> Innhold) {
        self.init(panel: panel, tittel: tittel, innhold: innhold, fot: { EmptyView() })
    }
}

/// Overskrift med tittel og pil som legger panelet sammen eller åpner det. Hele overskriften kan trykkes.
struct PanelHode: View {
    let tittel: String
    let sammen: Bool
    var veksle: () -> Void

    var body: some View {
        Button(action: veksle) {
            HStack(spacing: 6) {
                Text(tittel)
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .rotationEffect(.degrees(sammen ? -90 : 0))
            }
            .foregroundStyle(Color.sekundærTekst)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tittel)
        .accessibilityValue(sammen ? String(localized: "Lagt sammen") : String(localized: "Åpen"))
        .accessibilityHint(sammen ? String(localized: "Viser panelet") : String(localized: "Legger panelet sammen"))
    }
}

/// «Tilpass visningen …» nederst i et skjema.
struct TilpassKnapp: View {
    let skjerm: Panelinnstillinger.Skjerm
    @State private var vis = false

    var body: some View {
        Section {
            Button("Tilpass visningen …", systemImage: "rectangle.3.group") { vis = true }
        }
        .sheet(isPresented: $vis) { TilpasningArk(skjerm: skjerm) }
    }
}

/// Rekkefølge og åpne/lagt sammen for panelene på en skjerm, og (i Studio) hvilke verdier som vises.
struct TilpasningArk: View {
    let skjerm: Panelinnstillinger.Skjerm
    @State private var innstillinger = Panelinnstillinger.delt
    @Environment(\.dismiss) private var lukk

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(innstillinger.paneler(for: skjerm)) { panel in
                        Toggle(isOn: Binding(get: { !innstillinger.erLagtSammen(panel) },
                                             set: { innstillinger.settLagtSammen(panel, !$0) })) {
                            Text(panel.navn)
                        }
                    }
                    .onMove { innstillinger.flytt(skjerm, fra: $0, til: $1) }
                } header: {
                    Text("Paneler")
                } footer: {
                    Text("Dra for å endre rekkefølgen. Slå av for å legge panelet sammen – det kan også gjøres med pilen i overskriften.")
                }

                if skjerm == .studioFarge {
                    Section {
                        ForEach(innstillinger.verdier) { verdi in
                            Toggle(verdi.navn, isOn: Binding(get: { innstillinger.viser(verdi) },
                                                             set: { innstillinger.settViser(verdi, $0) }))
                        }
                        .onMove { innstillinger.flyttVerdier(fra: $0, til: $1) }
                    } header: {
                        Text("Verdier som vises")
                    } footer: {
                        Text("Dra for å endre rekkefølgen under «Verdier». Du kan også skjule en verdi ved å sveipe fra høyre på den. Oppsettet synkroniseres via iCloud.")
                    }
                }

                Section {
                    Button("Tilbakestill", role: .destructive) { innstillinger.tilbakestill(skjerm) }
                }
            }
            #if os(iOS)
            .environment(\.editMode, .constant(.active))
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle("Tilpass visningen")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } } }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 480)
        #endif
    }
}

/// Seksjon i en rullbar liste (Paletter): overskrift med pil som legger seksjonen sammen, og valgfrie knapper til
/// høyre. Hvilke seksjoner som er lagt sammen, huskes på enheten.
struct Listeseksjon<Innhold: View, Tillegg: View>: View {
    let tittel: LocalizedStringKey
    @ViewBuilder var tillegg: Tillegg
    @ViewBuilder var innhold: Innhold
    @AppStorage private var sammen: Bool

    init(_ id: String, tittel: LocalizedStringKey, @ViewBuilder tillegg: () -> Tillegg, @ViewBuilder innhold: () -> Innhold) {
        self.tittel = tittel
        self.tillegg = tillegg()
        self.innhold = innhold()
        _sammen = AppStorage(wrappedValue: false, "listeseksjon.sammen.\(id)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button { withAnimation(.snappy) { sammen.toggle() } } label: {
                    HStack(spacing: 6) {
                        Text(tittel).font(.title3.weight(.semibold)).foregroundStyle(Color.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.sekundærTekst)
                            .rotationEffect(.degrees(sammen ? -90 : 0))
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(sammen ? String(localized: "Lagt sammen") : String(localized: "Åpen"))
                .accessibilityHint(sammen ? String(localized: "Viser seksjonen") : String(localized: "Legger seksjonen sammen"))
                Spacer()
                tillegg
            }
            if !sammen { innhold }
        }
    }
}

extension Listeseksjon where Tillegg == EmptyView {
    init(_ id: String, tittel: LocalizedStringKey, @ViewBuilder innhold: () -> Innhold) {
        self.init(id, tittel: tittel, tillegg: { EmptyView() }, innhold: innhold)
    }
}
