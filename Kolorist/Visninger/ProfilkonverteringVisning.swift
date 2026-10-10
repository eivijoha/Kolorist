import FargeKjerne
import SwiftUI

/// Konverter farger fra én ICC-profil til en annen med valgt gjengivelseshensikt,
/// og se resultatet for alle fire hensiktene side om side.
struct ProfilkonverteringVisning: View {
    @Environment(ProfilBibliotek.self) private var bibliotek
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @AppStorage("konverterFra") private var fraID = ICCProfil.sRGB.id
    @AppStorage("konverterTil") private var tilID = ICCProfil.genericCMYK.id
    @AppStorage("konverterHensikt") private var hensikt: Gjengivelseshensikt = .relativKolorimetrisk
    /// Studios kildefargerom for CMYK og RGB (samme lagring som i FargeEditor).
    @AppStorage("kildeprofil.cmyk") private var kildeCMYK = ICCProfil.genericCMYK.id
    @AppStorage("kildeprofil.rgb") private var kildeRGB = ICCProfil.sRGB.id
    @State private var verdier: [Double] = []
    @Environment(\.dismiss) private var lukk

    private var fra: ICCProfil { bibliotek.profil(id: fraID) ?? .sRGB }
    private var til: ICCProfil { bibliotek.profil(id: tilID) ?? .genericCMYK }

    private var kildefarge: Farge? { Farge(komponenter: gyldigeVerdier, i: fra) }

    /// Verdiene tilpasset kildeprofilens antall komponenter.
    private var gyldigeVerdier: [Double] {
        verdier.count == fra.antallKomponenter ? verdier : (arbeidsbenk.aktivFarge.komponenter(i: fra) ?? Array(repeating: 0, count: fra.antallKomponenter))
    }

    var body: some View {
        Form {
            Seksjon("Fra") {
                profilvelger("Kildeprofil", valgt: $fraID)
                if fra.kanRedigeres {
                    ForEach(Array(fra.komponentnavn.enumerated()), id: \.offset) { i, navn in
                        if i < gyldigeVerdier.count { komponentrad(navn: navn, indeks: i) }
                    }
                } else {
                    Text("Verdier for denne profiltypen hentes fra aktiv farge.").font(.callout).foregroundStyle(Color.sekundærTekst)
                }
                Button("Hent fra aktiv farge", systemImage: "arrow.down.circle") {
                    verdier = arbeidsbenk.aktivFarge.komponenter(i: fra) ?? []
                }
            }

            Seksjon("Til") {
                profilvelger("Målprofil", valgt: $tilID)
                Picker("Gjengivelseshensikt", selection: $hensikt) {
                    ForEach(Gjengivelseshensikt.allCases, id: \.self) { Text($0.visningsnavn).tag($0) }
                }
                if let resultat = ICCProfil.konverter(gyldigeVerdier, fra: fra, til: til, hensikt: hensikt) {
                    let målfarge = Farge(komponenter: resultat, i: til)
                    HStack(spacing: 0) {
                        (kildefarge ?? .init(lineærR: 0, g: 0, b: 0)).swiftUI
                        (målfarge ?? .init(lineærR: 0, g: 0, b: 0)).swiftUI
                    }
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VerdiRad(navn: til.komponentnavn.joined(separator: " "), tekst: formatert(resultat, i: til)) {
                        Utklippstavle.kopierTekst(formatert(resultat, i: til))
                    }
                    if let målfarge {
                        Button("Bruk som aktiv farge", systemImage: "slider.horizontal.3") {
                            bruk(resultat, farge: målfarge)
                        }
                    }
                }
            }

            Section {
                ForEach(Gjengivelseshensikt.allCases, id: \.self) { h in
                    hensiktsrad(h)
                }
            } header: { Group {
                Text("Alle gjengivelseshensikter")
            }.foregroundStyle(Color.sekundærTekst) } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    KortForklaring("ΔE00 måler avviket fra kildefargen.") { Text("ΔE00 måler avviket fra kildefargen. Hensiktene skiller seg bare når profilene har egne tabeller for dem, typisk CMYK-profiler fra trykkerier; rene matriseprofiler som sRGB og Display P3 gir samme svar for alle.") }
                    MetodeHenvisning(.icc, .ciede2000)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Konverter mellom profiler")
        .onChange(of: fraID) { verdier = [] }
    }

    /// Gjør resultatet til aktiv farge i målprofilens fargemodell og fargerom, med nøyaktig de konverterte verdiene
    /// (ikke en ny rundtur gjennom profilen, som kan gi andre, likeverdige verdier – f.eks. annen sortgenerering).
    private func bruk(_ resultat: [Double], farge: Farge) {
        switch til.modell {
        case .cmyk:
            kildeCMYK = til.id
            arbeidsbenk.modell = .cmyk
        case .rgb:
            kildeRGB = til.id
            arbeidsbenk.modell = .rgb
        case .lab:
            arbeidsbenk.modell = .cieLab
        default:
            break
        }
        // Verdiene settes før fargen, så en begrensning til målprofilen ikke regner fargen om.
        arbeidsbenk.profilverdier = .init(profilID: til.id, verdier: resultat, farge: farge)
        arbeidsbenk.aktivFarge = farge
        arbeidsbenk.valgtFane = .studio
        // Tilbake til Studio, der fargen nå vises i målprofilens verdier.
        lukk()
    }

    private func profilvelger(_ tittel: LocalizedStringKey, valgt: Binding<String>) -> some View {
        Picker(tittel, selection: valgt) {
            Seksjon("Innebygde") { ForEach(ICCProfil.innebygde) { Text($0.navn).tag($0.id) } }
            if !bibliotek.importerte.isEmpty {
                Seksjon("Importerte") { ForEach(bibliotek.importerte) { Text($0.navn).tag($0.id) } }
            }
            #if os(macOS)
            // Profilene installert på Macen, én seksjon per mappe (Systemet, Maskinen, Displays …).
            let installerte = bibliotek.installerte.filter { p in !bibliotek.importerte.contains { $0.id == p.id } }
            let grupper = Dictionary(grouping: installerte) { bibliotek.installertGruppe[$0.id] ?? String(localized: "Andre") }
            ForEach(grupper.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }, id: \.self) { gruppe in
                Section(String(localized: "Installert: \(gruppe)")) {
                    ForEach(grupper[gruppe] ?? []) { Text(bibliotek.visningsnavn($0)).tag($0.id) }
                }
            }
            #endif
        }
    }

    private func komponentrad(navn: String, indeks i: Int) -> some View {
        HStack {
            Text(navn).frame(width: 36, alignment: .leading)
            Slider(value: Binding(
                get: { gyldigeVerdier.indices.contains(i) ? gyldigeVerdier[i] : 0 },
                set: { ny in
                    var v = gyldigeVerdier
                    guard v.indices.contains(i) else { return }
                    v[i] = ny
                    verdier = v
                }
            ), in: 0...1)
            TextField("", value: Binding(
                get: {
                    guard gyldigeVerdier.indices.contains(i) else { return 0 }
                    let faktor = pow(10, Double(fra.visningsdesimaler))
                    return (gyldigeVerdier[i] * fra.visningsskala * faktor).rounded() / faktor
                },
                set: { ny in
                    var v = gyldigeVerdier
                    guard v.indices.contains(i) else { return }
                    v[i] = min(max(ny / fra.visningsskala, 0), 1)
                    verdier = v
                }
            ), format: .number)
            .multilineTextAlignment(.trailing)
            .frame(width: 64)
            .monospacedDigit()
            #if os(iOS)
            .keyboardType(fra.visningsdesimaler > 0 ? .decimalPad : .numberPad)
            #endif
            Text(fra.visningsenhet).foregroundStyle(Color.sekundærTekst).frame(minWidth: 12)
        }
    }

    private func hensiktsrad(_ h: Gjengivelseshensikt) -> some View {
        let resultat = ICCProfil.konverter(gyldigeVerdier, fra: fra, til: til, hensikt: h)
        let målfarge = resultat.flatMap { Farge(komponenter: $0, i: til) }
        var avvik: Double?
        if let kildefarge, let målfarge { avvik = kildefarge.deltaE2000(til: målfarge) }
        return HStack(spacing: 10) {
            (målfarge ?? .init(lineærR: 0, g: 0, b: 0)).swiftUI
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 1) {
                Text(h.visningsnavn).fontWeight(h == hensikt ? .semibold : .regular)
                if let resultat {
                    Text(formatert(resultat, i: til)).font(.caption.monospaced()).foregroundStyle(Color.sekundærTekst)
                }
            }
            Spacer()
            if let avvik {
                Text("ΔE00 \(avvik, format: .number.precision(.fractionLength(2)))")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(avvik > 2 ? Color.advarsel : Color.sekundærTekst)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { hensikt = h }
    }

    private func formatert(_ v: [Double], i profil: ICCProfil) -> String { profil.formatert(v) }
}
