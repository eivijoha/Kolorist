import FargeKjerne
import FargeMaaling
import SwiftUI

/// Velger av lysmiljø: egne, standarder og eksempler.
struct LysmiljøVelger: View {
    var tittel: LocalizedStringKey = "Betraktningsforhold"
    @Binding var valgt: UUID?
    /// Med et valg for «ingen» (f.eks. «Dagslys, som LRV»).
    var ingen: LocalizedStringKey? = nil
    @State private var bibliotek = Lysbibliotek.delt

    var body: some View {
        Picker(tittel, selection: $valgt) {
            if let ingen { Text(ingen).tag(UUID?.none) }
            if !bibliotek.lysmiljøer.isEmpty {
                Section("Mine betraktningsforhold") {
                    ForEach(bibliotek.lysmiljøer) { Text($0.navn).tag(Optional($0.id)) }
                }
            }
            if !bibliotek.synligeEksempler.isEmpty {
                Section("Betraktningsforhold") {
                    ForEach(bibliotek.synligeEksempler) { Text($0.navn).tag(Optional($0.id)) }
                }
            }
            if !bibliotek.synligeStandarder.isEmpty {
                Section("Standarder") {
                    ForEach(bibliotek.synligeStandarder) { Text($0.navn).tag(Optional($0.id)) }
                }
            }
        }
    }
}

/// Valgene for lysmiljø i en meny, gruppert med skiller og overskrift (en Picker i en Menu blir én flat liste).
struct LysmiljøMenyvalg: View {
    @Binding var valgt: UUID?
    @State private var bibliotek = Lysbibliotek.delt

    var body: some View {
        gruppe("Mine betraktningsforhold", bibliotek.lysmiljøer)
        gruppe("Betraktningsforhold", bibliotek.synligeEksempler)
        gruppe("Standarder", bibliotek.synligeStandarder)
    }

    @ViewBuilder
    private func gruppe(_ tittel: LocalizedStringKey, _ miljøer: [Lysmiljø]) -> some View {
        if !miljøer.isEmpty {
            Section(tittel) {
                ForEach(miljøer) { miljø in
                    Toggle(miljø.navn, isOn: Binding(get: { valgt == miljø.id }, set: { if $0 { valgt = miljø.id } }))
                }
            }
        }
    }
}

/// «Se i lys» i palettvisningen: hver farge i lysmiljøet, fargeskiftet, og fargepar som blir vanskelige å skille.
/// Beregnes én gang per tegning; slås opp etter fargens id.
struct PalettLys {
    let miljø: Lysmiljø
    let somFoto: Bool
    let farger: [PalettFarge]
    let analyse: PalettILys
    private let indeks: [UUID: Int]

    init(farger: [PalettFarge], miljø: Lysmiljø, somFoto: Bool) {
        self.miljø = miljø
        self.somFoto = somFoto
        self.farger = farger
        analyse = miljø.palett(farger.map(\.farge))
        indeks = Dictionary(farger.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { a, _ in a })
    }

    /// Fargen slik den vises i lyset (øyets inntrykk, eller som et foto).
    func iLyset(_ pf: PalettFarge) -> Farge? {
        guard let i = indeks[pf.id] else { return nil }
        return somFoto ? miljø.somFoto(pf.farge) : analyse.sett[i]
    }

    func skift(_ pf: PalettFarge) -> Double? { indeks[pf.id].map { analyse.fargeskift[$0] } }
}

/// Valgene over palettens farger når «Se i lys» er på: lysmiljø, og om fargene vises slik øyet ser dem eller som et foto.
struct PalettLysValg: View {
    let lys: PalettLys
    @State private var bibliotek = Lysbibliotek.delt
    @AppStorage("seILys.somFoto") private var somFoto = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Lange navn forkortes, så panelet aldri blir bredere enn skjermen.
            HStack(spacing: 8) {
                Menu {
                    LysmiljøMenyvalg(valgt: Binding(get: { lys.miljø.id }, set: { bibliotek.valgtLysmiljø = $0 }))
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                        Text(lys.miljø.navn).lineLimit(1).truncationMode(.tail)
                        Image(systemName: "chevron.up.chevron.down").font(.caption.weight(.semibold))
                    }
                    .contentShape(Rectangle())
                }
                .menuIndicator(.hidden)
                .accessibilityLabel("Betraktningsforhold: \(lys.miljø.navn)")
                .layoutPriority(1)
                Spacer(minLength: 0)
                InfoKnapp {
                    Text("Øverst i hver rute: fargen på skjermen. Nederst: fargen i lyset, med fargeskiftet.")
                    Lysforklaring(somFoto: somFoto, ujevntSpekter: lys.miljø.harUjevntSpekter)
                }
            }
            HStack(spacing: 4) {
                Text(Lysbeskrivelse.tekst(lys.miljø)).monospacedDigit()
                LyskvalitetMerke(kvalitet: lys.miljø.kvalitet)
            }
            .font(.caption)
            .foregroundStyle(Color.sekundærTekst)
            Picker("Vis", selection: $somFoto) {
                Text("Slik øyet ser det").tag(false)
                Text("Som et foto").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Nedre halvdel av en fargerute i «Se i lys»: fargen i lyset og fargeskiftet.
struct LysHalvdel: View {
    let farge: Farge
    let skift: Double
    var hjørne: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                UnevenRoundedRectangle(bottomLeadingRadius: hjørne, bottomTrailingRadius: hjørne, style: .continuous)
                    .fill(farge.swiftUI)
                    .frame(height: geo.size.height / 2)
                    .overlay(alignment: .bottomLeading) {
                        HStack(spacing: 3) {
                            if skift >= 3 { Image(systemName: "exclamationmark.triangle.fill") }
                            Text("ΔE00 \(skift, format: .number.precision(.fractionLength(1)))")
                        }
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(farge.lesbarTekstfarge.swiftUI)
                        .padding(8)
                    }
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("I lyset: \(farge.hex()), fargeskift \(skift.formatted(.number.precision(.fractionLength(1))))")
    }
}

/// Fargepar som skilles godt på skjermen, men nesten ikke i lyset; under palettens farger når «Se i lys» er på.
struct PalettLysPar: View {
    let lys: PalettLys

    var body: some View {
        let par = lys.analyse.sammenfallendePar, sett = lys.analyse.sett, farger = lys.farger
        VStack(alignment: .leading, spacing: 8) {
            if !par.isEmpty {
                Text("Vanskelige å skille i dette lyset").font(.headline)
                ForEach(par, id: \.self) { p in
                    HStack(spacing: 6) {
                        sett[p.a].swiftUI.frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 5))
                        sett[p.b].swiftUI.frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 5))
                        Text("\(farger[p.a].etikett) og \(farger[p.b].etikett)").lineLimit(2)
                        Spacer()
                        Text("ΔE00 \(p.påSkjerm, format: .number.precision(.fractionLength(0))) → \(p.iLyset, format: .number.precision(.fractionLength(1)))")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(Color.advarsel)
                    }
                    .accessibilityElement(children: .combine)
                }
                KortForklaring("Fargepar som skilles godt på skjermen, men nesten ikke i lyset.") { Text("Fargepar som skilles godt på skjermen (ΔE00 minst 6), men nesten ikke i lyset (under 3) – typisk i svakt lys, der fargene blir mindre fargerike.") }
                    .font(.footnote)
                    .foregroundStyle(Color.sekundærTekst)
            }
            MetodeHenvisning(.cam16, .kolorimetri, .ciede2000)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Lyset i palettvurderingen: farger som skifter tydelig og fargepar som blir vanskelige å skille i vanlige lys.
struct LysVurderingSeksjon: View {
    let farger: [PalettFarge]
    @State private var bibliotek = Lysbibliotek.delt

    /// Egne lysmiljøer og et utvalg typiske.
    private var miljøer: [Lysmiljø] { bibliotek.lysmiljøer + bibliotek.synligeTypiske }

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
                KortForklaring("Fargeskift over 3 ΔE00, og fargepar som blir vanskelige å skille i lyset.") { Text("Hvordan fargene holder seg i ulike lys: fargeskift over 3 ΔE00, og fargepar som skilles godt på skjermen men nesten ikke i lyset. Egne betraktningsforhold tas med.") }
                MetodeHenvisning(.cam16, .kolorimetri, .ciede2000)
            }
        }
    }
}

extension PalettFarge {
    /// Navnet, eller hex-verdien for farger uten navn.
    var etikett: String { navn.isEmpty ? farge.hex() : navn }
}
