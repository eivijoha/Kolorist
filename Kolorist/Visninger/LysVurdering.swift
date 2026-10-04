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
                else { LysmiljøSeksjon(panel: panel) }
            }
            TilpassKnapp(skjerm: .lys)
        }
        .formStyle(.grouped)
        .navigationTitle("Lys")
        .sheet(isPresented: Binding(get: { leggIPalett != nil }, set: { if !$0 { leggIPalett = nil } })) {
            VelgPalettArk(farger: leggIPalett ?? [])
        }
    }

    /// Stort felt øverst, som i Forskjell: fargen på skjermen (trykk for å endre) og i det primære lysmiljøet (trykk for
    /// å velge lysmiljø), med lyset, kvaliteten og fargeskiftet under.
    private func toppfelt(_ farge: Farge, _ miljø: Lysmiljø, _ aktiv: Binding<Farge>) -> some View {
        let iLyset = somFoto ? miljø.somFoto(farge) : miljø.sett(farge)
        let skift = miljø.fargeskift(farge)
        return Section {
            HStack(spacing: 0) {
                FargeflateVelger(tittel: String(localized: "Farge"), farge: aktiv, kant: .leading)
                Menu {
                    LysmiljøMenyvalg(valgt: Binding(get: { miljø.id }, set: { bibliotek.valgtLysmiljø = $0 }))
                } label: {
                    iLyset.swiftUI
                        .overlay(alignment: .bottomTrailing) {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                Text(miljø.navn).lineLimit(1)
                                Image(systemName: "chevron.up.chevron.down").font(.caption2.weight(.semibold))
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.regularMaterial, in: Capsule())
                            .padding(10)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(Flatetrykk())
                .menuIndicator(.hidden)
                .accessibilityLabel("Lysmiljø: \(miljø.navn)")
                .accessibilityHint("Velg lysmiljøet fargen vises i")
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.secondary.opacity(0.3), lineWidth: 1))
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
        }
    }

    private func fargeseksjon(_ farge: Farge, _ miljøer: [Lysmiljø], _ aktiv: Binding<Farge>) -> some View {
        PanelSeksjon(panel: .fargeILys) {
            if miljøer.isEmpty {
                Text("Merk flere lysmiljøer med haken i lista under for å sammenligne.")
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
                      leggIPalett: { leggIPalett = [PalettFarge(farge: $0, opphav: .manuell)] }, valgBoble: true)
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
