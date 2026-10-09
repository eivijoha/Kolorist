import FargeKjerne
import FargeMaaling
import SwiftUI

/// Vurdering › Lys: den aktive fargen i lysmiljøene som er merket, og lysmiljøene selv (egne, eksempler og
/// standarder). Hele paletter ses i lys fra paletten.
struct LysVurdering: View {
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @State private var bibliotek = Lysbibliotek.delt
    /// Som et foto: lysets fulle fargestikk, uten øyets tilpasning.
    @AppStorage("seILys.somFoto") private var somFoto = false
    @State private var leggIPalett: [PalettFarge]?
    @State private var måler = false

    var body: some View {
        @Bindable var arbeidsbenk = arbeidsbenk
        let farge = arbeidsbenk.aktivFarge
        let primær = bibliotek.gjeldendeLysmiljø
        // Prøvene under: de andre merkede lysmiljøene (det primære står i feltet øverst).
        let miljøer = bibliotek.visteLysmiljøer.filter { $0.id != primær.id }
        Form {
            toppfelt(farge, primær, $arbeidsbenk.aktivFarge)
            // Panelene i brukerens rekkefølge, sammenleggbare (Panelinnstillinger, synkronisert).
            ForEach(Panelinnstillinger.delt.paneler(for: .lys)) { panel in
                if panel == .fargeILys { fargeseksjon(farge, miljøer, $arbeidsbenk.aktivFarge) }
                else { LysmiljøSeksjon(panel: panel) { måler = true } }
            }
            TilpassKnapp(skjerm: .lys)
        }
        .formStyle(.grouped)
        .navigationTitle("Lys")
        .sheet(isPresented: Binding(get: { leggIPalett != nil }, set: { if !$0 { leggIPalett = nil } })) {
            VelgPalettArk(farger: leggIPalett ?? [])
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $måler) { LysmålingArk() }
        #endif
    }

    /// Kortet øverst, som Kontrast og Fargesyn: valget av betraktningsforhold på egen linje, så fargen på skjermen (trykk
    /// for å endre) og i det valgte betraktningsforholdet i et stort felt, med lyset, kvaliteten og fargeskiftet under.
    private func toppfelt(_ farge: Farge, _ miljø: Lysmiljø, _ aktiv: Binding<Farge>) -> some View {
        let iLyset = somFoto ? miljø.somFoto(farge) : miljø.sett(farge)
        let skift = miljø.fargeskift(farge)
        return Section {
            HStack(spacing: 8) {
                // Egen nøkkel: kort etikett på engelsk («Condition»), så den ikke kolliderer med valget.
                Text(String(localized: "lys.etikett.betraktningsforhold", defaultValue: "Betraktningsforhold"))
                    .foregroundStyle(Color.sekundærTekst).lineLimit(1).fixedSize()
                Spacer(minLength: 0)
                Menu {
                LysmiljøMenyvalg(valgt: Binding(get: { miljø.id }, set: { bibliotek.valgtLysmiljø = $0 }))
            } label: {
                HStack(spacing: 6) {
                    Text(miljø.navn).lineLimit(1).truncationMode(.tail)
                    Image(systemName: "chevron.up.chevron.down").font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color.accentColor)
                .contentShape(Rectangle())
                }
                .menuIndicator(.hidden)
                .accessibilityLabel("Betraktningsforhold: \(miljø.navn)")
                .accessibilityHint("Velg betraktningsforholdet fargen vises under")
            }
            .listRowSeparator(.hidden)
            HStack(spacing: 0) {
                // Fargen som eget lag bak menyen, så flatene møtes i en rett kant (menyen avrunder på iOS 26).
                ZStack {
                    aktiv.wrappedValue.swiftUI
                    FargeVelgerMeny(tittel: String(localized: "Farge"), farge: aktiv) {
                        flatetekst(String(localized: "På skjermen"), farge: aktiv.wrappedValue) {
                            HStack(spacing: 4) {
                                Text(aktiv.wrappedValue.hex()).koloristFont(.caption, design: .monospaced)
                                Image(systemName: "chevron.up.chevron.down").font(.caption2)
                            }
                            .opacity(0.85)
                        }
                    }
                }
                flatetekst(String(localized: "Under betraktningsforholdet"), farge: iLyset) {
                    Text(iLyset.hex()).koloristFont(.caption, design: .monospaced).opacity(0.85)
                }
                .background(iLyset.swiftUI)
                .accessibilityElement(children: .combine)
            }
            .frame(height: 140)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            HStack(spacing: 6) {
                Text(Lysbeskrivelse.tekst(miljø)).monospacedDigit()
                LyskvalitetMerke(kvalitet: miljø.kvalitet)
                Spacer()
                Text("ΔE00 \(skift, format: .number.precision(.fractionLength(1)))")
                    .monospacedDigit()
                    .foregroundStyle(skift >= 3 ? Color.advarsel : Color.sekundærTekst)
            }
            .font(.callout)
            .foregroundStyle(Color.sekundærTekst)
            Picker("Vis", selection: $somFoto) {
                Text("Slik øyet ser det").tag(false)
                Text("Som et foto").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    /// Tekst rett på en flate i lesbar farge, som i Kontrast: tittel øverst og verdien nederst.
    private func flatetekst<Bunn: View>(_ tittel: String, farge: Farge, @ViewBuilder bunn: () -> Bunn) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(tittel).koloristFont(.caption, weight: .semibold).lineLimit(2).minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            bunn()
        }
        .foregroundStyle(farge.lesbarTekstfarge.swiftUI)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
    }

    private func fargeseksjon(_ farge: Farge, _ miljøer: [Lysmiljø], _ aktiv: Binding<Farge>) -> some View {
        PanelSeksjon(panel: .fargeILys) {
            if miljøer.isEmpty {
                Text("Merk flere betraktningsforhold med haken i lista under for å sammenligne.")
                    .font(.callout).foregroundStyle(Color.sekundærTekst)
            } else {
                // To prøver i bredden på iPhone, flere på iPad og Mac.
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12, alignment: .top)], spacing: 22) {
                    ForEach(miljøer) { prøve(farge, $0) }
                }
                .padding(.vertical, 4)
            }
        } fot: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Fargeskift (ΔE00) over 3 merkes tydelig.")
                    InfoKnapp { Lysforklaring(somFoto: somFoto, ujevntSpekter: (miljøer + [bibliotek.gjeldendeLysmiljø]).contains(where: \.harUjevntSpekter)) }
                }
                MetodeHenvisning(.cam16, .kolorimetri, .ciede2000)
            }
        }
    }

    /// Én prøve: fargen i lyset, navnet på lyset, lyset (K og lx) og fargeskiftet.
    private func prøve(_ farge: Farge, _ miljø: Lysmiljø) -> some View {
        let skift = miljø.fargeskift(farge)
        // Teksten tett inntil sin egen prøve, og god avstand til neste rad, så det er tydelig hva som hører sammen.
        return VStack(alignment: .leading, spacing: 6) {
            FargeRute(farge: somFoto ? miljø.somFoto(farge) : miljø.sett(farge), visTekst: false, hjørne: 8,
                      leggIPalett: { leggIPalett = [PalettFarge(farge: $0, opphav: .manuell)] },
                      åpneIStudio: { arbeidsbenk.visIStudio($0) }, valgBoble: true)
                .frame(height: 64)
            VStack(alignment: .leading, spacing: 1) {
                Text(miljø.navn).font(.callout).lineLimit(2)
                HStack(spacing: 4) {
                    Text(Lysbeskrivelse.tekst(miljø)).monospacedDigit()
                    LyskvalitetMerke(kvalitet: miljø.kvalitet)
                }
                .font(.caption).foregroundStyle(Color.sekundærTekst)
                Text("ΔE00 \(skift, format: .number.precision(.fractionLength(1)))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(skift >= 3 ? Color.advarsel : Color.sekundærTekst)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
