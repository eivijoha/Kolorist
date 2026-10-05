import FargeKjerne
import FargeMaaling
import SwiftUI
import UniformTypeIdentifiers

/// Fargestyring i Studio for profilen valgt under «Vis også»: verdiene i profilen, gjengivelseshensikt,
/// varsel utenfor gamut og justering innenfor profilen. Egne profiler importeres under «Mine fargerom».
struct ICCSeksjon: View {
    @Binding var farge: Farge
    /// Profilen fra «Vis også» – én felles profil i Studio.
    @Binding var profilID: String
    /// Åpner «Mine fargerom». Arket presenteres av Studio – et `.sheet` på en seksjon i et skjema er upålitelig.
    @Binding var visMineFargerom: Bool
    @Environment(ProfilBibliotek.self) private var bibliotek
    @AppStorage("gjengivelseshensikt") private var hensikt: Gjengivelseshensikt = .relativKolorimetrisk
    /// Visningslyset for «Vis som» (tom = D50, ICC-standarden).
    @AppStorage("visningslys") private var visningslysID = ""
    @State private var lysbibliotek = Lysbibliotek.delt

    private var profil: ICCProfil { bibliotek.profil(id: profilID) ?? .sRGB }

    var body: some View {
        PanelSeksjon(panel: .fargestyring) {
            Picker("Gjengivelse", selection: $hensikt) {
                ForEach(Gjengivelseshensikt.allCases, id: \.self) { Text($0.visningsnavn).tag($0) }
            }
            // Lyset fargen til høyre i fargefeltet («Vis som») vises i. D50 er standard i ICC-fargestyring.
            LabeledContent("Visningslys") {
                Menu {
                    Toggle("D50 (ICC-standard)", isOn: Binding(get: { visningslysID.isEmpty }, set: { if $0 { visningslysID = "" } }))
                    Toggle(Lysbibliotek.d65Visning.navn, isOn: Binding(get: { visningslysID == Lysbibliotek.d65Visning.id.uuidString },
                                                                      set: { if $0 { visningslysID = Lysbibliotek.d65Visning.id.uuidString } }))
                    Divider()
                    LysmiljøMenyvalg(valgt: Binding(get: { UUID(uuidString: visningslysID) },
                                                    set: { visningslysID = $0?.uuidString ?? "" }))
                } label: {
                    Text(lysbibliotek.visningslys(id: visningslysID)?.navn ?? String(localized: "D50 (ICC-standard)"))
                        .lineLimit(1)
                }
                .fixedSize()
            }

            if let verdier = farge.komponenter(i: profil, hensikt: hensikt) {
                LabeledContent(profil.komponentnavn.joined(separator: " ")) {
                    Text(formatert(verdier))
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                }
                .contextMenu {
                    Button("Kopier verdier") { Utklippstavle.kopierTekst(formatert(verdier)) }
                }
                if let avvik = farge.avvik(i: profil, hensikt: hensikt), avvik > 0.02 {
                    Text("Utenfor profilens gamut (ΔE\u{2009}OK \(avvik, format: .number.precision(.fractionLength(3))))")
                        .foregroundStyle(Color.advarsel)
                        .font(.callout)
                }
                if profil.kanRedigeres {
                    DisclosureGroup {
                        ProfilGlidere(profil: profil, farge: $farge)
                    } label: {
                        Text("Juster innenfor \(profil.navn)")
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            NavigationLink {
                ProfilkonverteringVisning()
            } label: {
                Label("Konverter mellom profiler …", systemImage: "arrow.triangle.swap")
            }
            // Import og sletting av ICC-profiler og fargebiblioteker, med bekreftelse.
            Button { visMineFargerom = true } label: {
                Label("Mine fargerom …", systemImage: "books.vertical")
            }
        } fot: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Visningslys: ICC-fargestyring regner i D50, som er standard. Med et annet lys vises fargen til høyre i fargefeltet slik den oppleves i det lyset; verdiene er de samme.")
                MetodeHenvisning(.icc, .renCMYK, .ciede2000)
                Text(bibliotek.brukerICloud
                     ? "Importerte ICC-profiler og fargebiblioteker ligger i iCloud Drive › Kolorist › Profiler og synkroniseres mellom enhetene. Du kan også legge filer der fra Filer eller Finder."
                     : "Importerte ICC-profiler og fargebiblioteker lagres på denne enheten (iCloud Drive er ikke tilgjengelig).")
                    .font(.caption)
            }
        }
    }

    static let profiltyper: [UTType] = [
        UTType("com.apple.colorsync-profile"), UTType(filenameExtension: "icc"), UTType(filenameExtension: "icm"),
    ].compactMap { $0 }

    private func formatert(_ v: [Double]) -> String { profil.formatert(v) }
}

extension ICCProfil {
    /// Visningsskala etter bransjekonvensjon: RGB 0–255, CMYK og grå i prosent.
    var visningsskala: Double { modell == .rgb ? 255 : 100 }
    /// Enhet som vises etter tallene («%» for CMYK/grå, ingen for RGB).
    var visningsenhet: String { modell == .rgb ? "" : "%" }

    func formatert(_ v: [Double]) -> String {
        switch modell {
        case .lab: return v.map { String(format: "%.1f", $0) }.joined(separator: " / ")
        default:
            let tall = v.map { String(format: "%.0f", $0 * visningsskala) }.joined(separator: " / ")
            return tall + visningsenhet
        }
    }
}

/// Glidere i profilens egne komponenter (f.eks. CMYK-prosenter fra trykkeriet).
private struct ProfilGlidere: View {
    let profil: ICCProfil
    @Binding var farge: Farge
    @State private var verdier: [Double] = []

    private var gjeldende: [Double] {
        verdier.count == profil.antallKomponenter ? verdier : (farge.komponenter(i: profil) ?? [])
    }

    /// Fargene langs sporet: komponent `i` fra 0 til 1 i profilen, de andre som de er.
    private func spor(for i: Int, prøver: Int = 16) -> [Color] {
        let basis = gjeldende
        guard basis.indices.contains(i) else { return [] }
        return (0..<prøver).compactMap { n in
            var v = basis
            v[i] = Double(n) / Double(prøver - 1)
            return Farge(komponenter: v, i: profil, alfa: 1)?.swiftUI
        }
    }

    var body: some View {
        ForEach(Array(profil.komponentnavn.enumerated()), id: \.offset) { i, navn in
            if i < gjeldende.count {
                HStack {
                    Text(navn).frame(width: 36, alignment: .leading)
                    FargeGlider(verdi: Binding(
                        get: { gjeldende.indices.contains(i) ? gjeldende[i] : 0 },
                        set: { ny in
                            var v = gjeldende
                            guard v.indices.contains(i) else { return }
                            v[i] = ny
                            verdier = v
                            if let f = Farge(komponenter: v, i: profil, alfa: farge.alfa) { farge = f }
                        }
                    ), område: 0...1, spor: spor(for: i), gjeldende: farge.swiftUI,
                       tittel: Text(navn),
                       verdiTekst: (gjeldende[i] * profil.visningsskala).formatted(.number.precision(.fractionLength(0))),
                       stegForTilgjengelighet: 0.01)
                    Text(gjeldende[i] * profil.visningsskala, format: .number.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .onChange(of: profil.id) { verdier = [] }
        .onChange(of: farge) { _, ny in
            // Nullstill når fargen er endret utenfra (ikke av disse gliderne).
            if let egen = Farge(komponenter: verdier, i: profil, alfa: ny.alfa), egen.avstandOK(til: ny) > 1e-3 { verdier = [] }
        }
    }
}

extension Gjengivelseshensikt {
    var visningsnavn: String {
        switch self {
        case .perseptuell: String(localized: "Perseptuell")
        case .relativKolorimetrisk: String(localized: "Relativ kolorimetrisk")
        case .metning: String(localized: "Metning")
        case .absoluttKolorimetrisk: String(localized: "Absolutt kolorimetrisk")
        }
    }
}
