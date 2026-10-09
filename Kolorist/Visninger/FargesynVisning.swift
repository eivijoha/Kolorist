import FargeKjerne
import SwiftData
import SwiftUI

/// Vurdering › Fargesyn: hvordan en palett ser ut med fargesynsavvik (CVD), og hvilke fargepar
/// som blir vanskelige å skille.
struct FargesynVurdering: View {
    @Query(sort: \PalettDokument.opprettet, order: .reverse) private var paletter: [PalettDokument]
    /// Valgt palett, husket mellom oppstarter.
    @AppStorage("vurderingPalett") private var valgtIDTekst = ""
    @AppStorage("fargesynGrad") private var grad = 1.0
    /// Åpent kamera med fargesynsfilter.
    @State private var kameratype: Fargesynstype?

    private var valgt: PalettDokument? {
        paletter.first { $0.id.uuidString == valgtIDTekst } ?? paletter.first
    }

    @Environment(\.presentasjonsmodus) private var presentasjon
    /// Avviket fargefeltet sammenligner med normalt syn (deutan, det vanligste, som standard).
    @AppStorage("fargesynVis") private var visTekst = Fargesynstype.deutan.rawValue
    private var vis: Fargesynstype { Fargesynstype(rawValue: visTekst) ?? .deutan }

    var body: some View {
        if paletter.isEmpty {
            ContentUnavailableView("Ingen paletter", systemImage: "swatchpalette",
                                   description: Text("Lag en palett først, så kan den vurderes her."))
                .navigationTitle("Fargesyn")
        } else if let valgt {
            let farger = valgt.farger
            // Analysen (O(n²) per type) regnes én gang per tegning og deles av fargefeltet og seksjonene.
            let analyse = Fargesynstype.allCases.map {
                ($0, Fargesynsanalyse.forvekslinger(i: farger.map(\.farge), type: $0, grad: grad))
            }
            GeometryReader { geo in
                let bred = Breddeoppsett.erBred(geo.size)
                // AnyLayout bevarer skjemaets tilstand når enheten roteres.
                let oppsett = bred ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
                oppsett {
                    kort(valgt, analyse: analyse, bred: bred)
                        .frame(width: bred ? geo.size.width / 2 : nil)
                    Form {
                        Section {
                            HStack(spacing: 10) {
                                Text("Grad")
                                Slider(value: $grad, in: 0.1...1, step: 0.1)
                                Text(grad, format: .percent.precision(.fractionLength(0)))
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(Color.sekundærTekst)
                                    .frame(width: 48, alignment: .trailing)
                            }
                        } footer: { Group {
                            Text(grad >= 1 ? "100 % er fullstendig avvik (dikromasi). Lavere verdier tilsvarer delvis avvik (anomal trikromasi), som er vanligere."
                                           : "Delvis avvik (anomal trikromasi). 100 % er fullstendig avvik.")
                        }.foregroundStyle(Color.sekundærTekst) }

                        Section {
                            stripe(String(localized: "Normalt syn"), undertekst: nil, farger: farger.map(\.farge), antall: nil, kamera: nil)
                            // Etter utbredelse, vanligst først.
                            ForEach(analyse, id: \.0) { type, forvekslinger in
                                stripe(grad >= 1 ? type.navn : type.delvisNavn, undertekst: "\(type.beskrivelse). \(type.utbredelse).",
                                       farger: farger.map { $0.farge.simulert(type, grad: grad) }, antall: forvekslinger.count,
                                       kamera: { kameratype = type })
                            }
                        } header: {
                            Text("Slik ser paletten ut").foregroundStyle(Color.sekundærTekst)
                        } footer: {
                            Text("Typene står etter hvor vanlige de er. Tallene gjelder personer av nordeuropeisk opprinnelse og omfatter både delvis og fullstendig avvik; delvis avvik er langt vanligst. Kilde: J. Birch, JOSA A 29(3), 2012.")
                                .foregroundStyle(Color.sekundærTekst)
                        }

                        forvekslingsseksjon(farger, alle: analyse.flatMap(\.1))
                    }
                    .formStyle(.grouped)
                    #if os(iOS)
                    .listSectionSpacing(.compact)
                    #endif
                    .contentMargins(.top, 0, for: .scrollContent)
                }
                .background(Color.skjemabakgrunn)
            }
            .navigationTitle("Fargesyn")
            #if os(iOS)
            .fullScreenCover(item: $kameratype) { FargesynKamera(type: $0) }
            #else
            .sheet(item: $kameratype) { FargesynKamera(type: $0) }
            #endif
        }
    }

    /// Kortet øverst: hvor mange fargepar som blir vanskelige å skille, paletten i et stort fargefelt (med valgt
    /// fargesynsavvik simulert), og valg av palett og syn. Samme oppbygning som kontrastsjekken.
    private func kort(_ valgt: PalettDokument, analyse: [(Fargesynstype, [Forveksling])], bred: Bool) -> some View {
        let farger = valgt.farger
        let vist = farger.map { $0.farge.simulert(vis, grad: grad) }
        let antall = analyse.first { $0.0 == vis }?.1.count ?? 0
        return VStack(spacing: 0) {
            // Bare tittelen med antall vanskelige par (detaljene står lenger ned) øverst, og palettvalget på egen linje
            // under, til høyre rett over paletten det styrer (nærhet). Hver får hele bredden, så de ikke kolliderer.
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: antall == 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(antall == 0 ? Color.suksess : Color.feil)
                        .koloristFont(.title)
                    Text(antall == 0 ? String(localized: "Ingen vanskelige par")
                                     : (antall == 1 ? String(localized: "1 vanskelig par") : String(localized: "\(antall) vanskelige par")))
                        .koloristFont(.title2, weight: .bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                // Som valget av betraktningsforhold i Lys: etikett til venstre, valget til høyre.
                HStack(spacing: 8) {
                    Text("Palett").foregroundStyle(Color.sekundærTekst).lineLimit(1)
                    Spacer(minLength: 0)
                    Picker("Palett", selection: Binding(get: { valgt.id.uuidString }, set: { valgtIDTekst = $0 })) {
                        ForEach(paletter) { Text($0.navn.isEmpty ? String(localized: "Uten navn") : $0.navn).tag($0.id.uuidString) }
                    }
                    .labelsHidden()
                }
            }
            // Toppen får høyden den trenger; fargefeltet tar resten.
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(Color.primary)
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Paletten med normalt syn øverst og valgt avvik under, så de sammenlignes direkte. Én kolonne per farge,
            // med navn eller hex i den øverste når det er plass.
            GeometryReader { geo in
                let bredde = geo.size.width / CGFloat(max(vist.count, 1))
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(Array(farger.enumerated()), id: \.offset) { _, pf in
                            ZStack(alignment: .bottomLeading) {
                                pf.farge.swiftUI
                                if bredde >= 56 {
                                    Text(pf.navn.isEmpty ? pf.farge.hex() : pf.navn)
                                        .koloristFont(.caption2, weight: .medium)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                        .foregroundStyle(pf.farge.lesbarTekstfarge.swiftUI)
                                        .padding(6)
                                }
                            }
                        }
                    }
                    HStack(spacing: 0) {
                        ForEach(Array(vist.enumerated()), id: \.offset) { _, f in f.swiftUI }
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "Paletten \(valgt.navn), med normalt syn øverst og \(grad >= 1 ? vis.navn : vis.delvisNavn) under"))
            // Fanerad under fargefeltet: de fire avvikene (fulle navn når det er plass).
            ViewThatFits(in: .horizontal) {
                synsvalg(kort: false)
                synsvalg(kort: true)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 48)
        }
        .frame(height: bred ? nil : (presentasjon ? 330 : 250))
        .frame(maxHeight: bred ? .infinity : nil)
        .frame(maxWidth: .infinity)
        .background(Color.kortbakgrunn, in: Kortform.fargepanel(bred: bred))
        .clipShape(Kortform.fargepanel(bred: bred))
        .padding(.leading, 16)
        .padding(.trailing, bred ? 0 : 16)
        .padding(.top, bred ? 16 : 4)
        .padding(.bottom, bred ? 16 : 8)
    }

    /// Faner for synet fargefeltet viser.
    private func synsvalg(kort: Bool) -> some View {
        Picker("Fargesynsavvik", selection: Binding(get: { vis.rawValue }, set: { visTekst = $0 })) {
            ForEach(Fargesynstype.allCases) { type in
                Text(kort ? type.kortnavn : (grad >= 1 ? type.navn : type.delvisNavn)).tag(type.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize(horizontal: !kort, vertical: false)
    }

    private func stripe(_ tittel: String, undertekst: String?, farger: [Farge], antall: Int?, kamera: (() -> Void)?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(tittel).font(.subheadline.weight(.semibold))
                if let kamera {
                    // Kamerabildet med dette avviket, rett ved tittelen.
                    Button(action: kamera) {
                        Image(systemName: "camera.viewfinder")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(String(localized: "Se med kamera: \(tittel)"))
                    .help("Se omgivelsene med kamera")
                }
                Spacer()
                if let antall {
                    if antall == 0 {
                        Label("Ingen forvekslinger", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.suksess)
                    } else {
                        Text(antall == 1 ? "1 vanskelig par" : "\(antall) vanskelige par")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.advarsel)
                    }
                }
            }
            PalettStripe(farger: farger).frame(height: 36)
            if let undertekst {
                Text(undertekst).font(.caption).foregroundStyle(Color.sekundærTekst)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func forvekslingsseksjon(_ farger: [PalettFarge], alle: [Forveksling]) -> some View {
        Section {
            if farger.count < 2 {
                Text("Paletten trenger minst to farger.").foregroundStyle(Color.sekundærTekst)
            } else if alle.isEmpty {
                Label("Alle fargeparene kan skilles med alle typene fargesynsavvik.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.suksess)
            } else {
                ForEach(Array(alle.enumerated()), id: \.offset) { _, f in
                    parRad(f, farger: farger)
                }
            }
        } header: {
            Text("Vanskelige fargepar").foregroundStyle(Color.sekundærTekst)
        } footer: { Group {
            VStack(alignment: .leading, spacing: 6) {
                Text("Par som er tydelig ulike med normalt syn (ΔE00 ≥ 10), men kommer under 10 med avviket. Under 5 er de nesten like. Skill dem med lyshet, ikke bare kulør, eller bruk mønster, ikon eller tekst i tillegg.")
                MetodeHenvisning(.machado, .ciede2000, .cssColor4)
            }
        }.foregroundStyle(Color.sekundærTekst) }
    }

    private func parRad(_ f: Forveksling, farger: [PalettFarge]) -> some View {
        let a = farger[f.i], b = farger[f.j]
        return HStack(spacing: 12) {
            VStack(spacing: 3) {
                HStack(spacing: 0) { a.farge.swiftUI; b.farge.swiftUI }
                    .frame(width: 56, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                HStack(spacing: 0) { a.farge.simulert(f.type, grad: grad).swiftUI; b.farge.simulert(f.type, grad: grad).swiftUI }
                    .frame(width: 56, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(a.visningsnavn) og \(b.visningsnavn)").font(.subheadline).lineLimit(1)
                Text(grad >= 1 ? f.type.navn : f.type.delvisNavn).font(.caption).foregroundStyle(Color.sekundærTekst)
                Text("ΔE00 \(f.normalt, format: .number.precision(.fractionLength(1))) → \(f.simulert, format: .number.precision(.fractionLength(1)))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(f.alvorlig ? Color.feil : Color.advarsel)
            }
            Spacer(minLength: 0)
            if f.alvorlig {
                Text("Nesten like").font(.caption2.weight(.semibold)).foregroundStyle(Color.feil)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension Fargesynstype {
    /// Kort navn til fanene under fargefeltet i Fargesyn.
    var kortnavn: String {
        switch self {
        case .deutan: "Deutan"
        case .protan: "Protan"
        case .tritan: "Tritan"
        case .akromatopsi: String(localized: "Akromat.")
        }
    }
}
