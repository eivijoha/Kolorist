import FargeKjerne
import FargeMaaling
import SwiftUI

/// Velger av lysmiljø: egne, standarder og eksempler.
struct LysmiljøVelger: View {
    var tittel: LocalizedStringKey = "Lysmiljø"
    @Binding var valgt: UUID?
    /// Med et valg for «ingen» (f.eks. «Dagslys, som LRV»).
    var ingen: LocalizedStringKey? = nil
    @State private var bibliotek = Lysbibliotek.delt

    var body: some View {
        Picker(tittel, selection: $valgt) {
            if let ingen { Text(ingen).tag(UUID?.none) }
            if !bibliotek.lysmiljøer.isEmpty {
                Section("Mine lysmiljøer") {
                    ForEach(bibliotek.lysmiljøer) { Text($0.navn).tag(Optional($0.id)) }
                }
            }
            Section("Standarder") {
                ForEach(Lysbibliotek.standarder) { Text($0.navn).tag(Optional($0.id)) }
            }
            Section("Eksempler") {
                ForEach(Lysbibliotek.innebygde) { Text($0.navn).tag(Optional($0.id)) }
            }
        }
    }
}

/// Hele paletten i et lysmiljø: hver farge på skjermen og i lyset, fargeskiftet, og fargepar som blir vanskelige
/// å skille.
struct PalettILysArk: View {
    let navn: String
    let farger: [PalettFarge]
    @State private var bibliotek = Lysbibliotek.delt
    @AppStorage("seILys.somFoto") private var somFoto = false
    @Environment(\.dismiss) private var lukk

    var body: some View {
        let miljø = bibliotek.gjeldendeLysmiljø
        let ff = farger.map(\.farge)
        let analyse = miljø.palett(ff)
        let skift = analyse.fargeskift, par = analyse.sammenfallendePar
        NavigationStack {
            Form {
                Section {
                    LysmiljøVelger(valgt: Binding(get: { miljø.id }, set: { bibliotek.valgtLysmiljø = $0 }))
                    Picker("Vis", selection: $somFoto) {
                        Text("Slik øyet ser det").tag(false)
                        Text("Som et foto").tag(true)
                    }
                    .pickerStyle(.segmented)
                    LabeledContent("Lys") { Text(Lysbeskrivelse.tekst(miljø)).monospacedDigit() }
                    if miljø.harUjevntSpekter {
                        Label("Lysrør og LED har ujevne spektre. Fargenes spektre er anslått, så ekte flater kan endre seg annerledes (metameri).", systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(Color.sekundærTekst)
                    }
                }
                Section {
                    ForEach(Array(farger.enumerated()), id: \.offset) { i, pf in
                        HStack(spacing: 10) {
                            pf.farge.swiftUI.frame(width: 44, height: 36).clipShape(RoundedRectangle(cornerRadius: 6))
                            (somFoto ? miljø.somFoto(pf.farge) : analyse.sett[i]).swiftUI
                                .frame(width: 44, height: 36).clipShape(RoundedRectangle(cornerRadius: 6))
                            Text(pf.etikett).lineLimit(1)
                            Spacer()
                            Text("ΔE00 \(skift[i], format: .number.precision(.fractionLength(1)))")
                                .monospacedDigit()
                                .foregroundStyle(skift[i] >= 3 ? Color.advarsel : Color.sekundærTekst)
                        }
                        .accessibilityElement(children: .combine)
                    }
                } header: {
                    Text("På skjermen · i lyset")
                } footer: {
                    Text("Fargeskiftet er hvor mye fargen endrer karakter når øyet har tilpasset seg lyset; over 3 merkes det tydelig.")
                }
                if !par.isEmpty {
                    Section {
                        ForEach(par, id: \.self) { p in
                            HStack(spacing: 6) {
                                analyse.sett[p.a].swiftUI.frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 5))
                                analyse.sett[p.b].swiftUI.frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 5))
                                Text("\(farger[p.a].etikett) og \(farger[p.b].etikett)").lineLimit(2)
                                Spacer()
                                Text("ΔE00 \(p.påSkjerm, format: .number.precision(.fractionLength(0))) → \(p.iLyset, format: .number.precision(.fractionLength(1)))")
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(Color.advarsel)
                            }
                        }
                    } header: {
                        Text("Vanskelige å skille i dette lyset")
                    } footer: {
                        Text("Fargepar som skilles godt på skjermen (ΔE00 minst 6), men nesten ikke i lyset (under 3) – typisk i svakt lys, der fargene blir mindre fargerike.")
                    }
                }
                Section {
                    MetodeHenvisning(.cam16, .kolorimetri, .ciede2000)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "«\(navn)» i lys"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } } }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 560)
        #endif
    }
}

/// Lyset i palettvurderingen: farger som skifter tydelig og fargepar som blir vanskelige å skille i vanlige lys.
struct LysVurderingSeksjon: View {
    let farger: [PalettFarge]
    @State private var bibliotek = Lysbibliotek.delt

    /// Egne lysmiljøer og et utvalg typiske.
    private var miljøer: [Lysmiljø] { bibliotek.lysmiljøer + Lysbibliotek.typiske }

    var body: some View {
        let ff = farger.map(\.farge)
        Section {
            ForEach(miljøer) { miljø in
                let analyse = miljø.palett(ff)
                let skift = analyse.fargeskift.indices.filter { analyse.fargeskift[$0] >= 3 }
                let par = analyse.sammenfallendePar
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(miljø.navn).font(.callout.weight(.semibold))
                        if skift.isEmpty && par.isEmpty {
                            Text("Fargene holder seg.").font(.callout).foregroundStyle(Color.sekundærTekst)
                        }
                        if !skift.isEmpty {
                            Text(skift.count == 1
                                 ? "1 farge skifter tydelig: \(skift.map { farger[$0].etikett }.joined(separator: ", "))"
                                 : "\(skift.count) farger skifter tydelig: \(skift.map { farger[$0].etikett }.joined(separator: ", "))")
                                .font(.callout).foregroundStyle(Color.sekundærTekst)
                        }
                        if !par.isEmpty {
                            Text(par.count == 1
                                 ? "1 fargepar blir vanskelig å skille: \(par.map { "\(farger[$0.a].etikett)/\(farger[$0.b].etikett)" }.joined(separator: ", "))"
                                 : "\(par.count) fargepar blir vanskelige å skille: \(par.map { "\(farger[$0.a].etikett)/\(farger[$0.b].etikett)" }.joined(separator: ", "))")
                                .font(.callout).foregroundStyle(Color.sekundærTekst)
                        }
                    }
                } icon: {
                    Image(systemName: skift.isEmpty && par.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(skift.isEmpty && par.isEmpty ? Color.suksess : Color.advarsel)
                }
            }
        } header: {
            Text("Lys")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hvordan fargene holder seg i ulike lys: fargeskift over 3 ΔE00, og fargepar som skilles godt på skjermen men nesten ikke i lyset. Egne lysmiljøer tas med.")
                MetodeHenvisning(.cam16, .kolorimetri, .ciede2000)
            }
        }
    }
}

extension PalettFarge {
    /// Navnet, eller hex-verdien for farger uten navn.
    var etikett: String { navn.isEmpty ? farge.hex() : navn }
}
