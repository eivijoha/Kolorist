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
        let miljøer = bibliotek.visteLysmiljøer.isEmpty ? [bibliotek.gjeldendeLysmiljø] : bibliotek.visteLysmiljøer
        Form {
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

    private func fargeseksjon(_ farge: Farge, _ miljøer: [Lysmiljø], _ aktiv: Binding<Farge>) -> some View {
        PanelSeksjon(panel: .fargeILys) {
            FargeValgRad(tittel: String(localized: "Farge"), farge: aktiv)
            Picker("Vis", selection: $somFoto) {
                Text("Slik øyet ser det").tag(false)
                Text("Som et foto").tag(true)
            }
            .pickerStyle(.segmented)
            // To prøver i bredden på iPhone, flere på iPad og Mac.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12, alignment: .top)], spacing: 22) {
                ForEach(miljøer) { prøve(farge, $0) }
            }
            .padding(.vertical, 4)
            if miljøer.contains(where: \.harUjevntSpekter) {
                Label("Lysrør og LED har ujevne spektre. Fargens spekter er anslått, så en ekte flate med samme farge på skjermen kan endre seg annerledes i slikt lys (metameri).", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(Color.sekundærTekst)
            }
        } fot: {
            VStack(alignment: .leading, spacing: 6) {
                Text(somFoto
                     ? "Prøvene viser fargen med lysets fulle fargestikk, slik et foto med dagslys-hvitbalanse ville vist den. Fargeskiftet (ΔE00) er hvor mye fargen endrer karakter når øyet har tilpasset seg fullt; over 3 merkes det tydelig. Strekene viser hvor godt lyset er kjent: fire for kjent spekter, færre når bare lysets farge er målt eller lysstyrken er anslått. Velg lysmiljøene med haken i lista under."
                     : "Prøvene viser fargen slik den oppleves i hvert lysmiljø: øyet tilpasser seg lysets farge nesten helt, og svakt lys gir mindre fargerike farger. Fargeskiftet (ΔE00) er hvor mye fargen endrer karakter når øyet har tilpasset seg fullt; over 3 merkes det tydelig. Strekene viser hvor godt lyset er kjent: fire for kjent spekter, færre når bare lysets farge er målt eller lysstyrken er anslått. Velg lysmiljøene med haken i lista under.")
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
