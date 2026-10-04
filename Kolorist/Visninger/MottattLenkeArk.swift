import FargeKjerne
import SwiftData
import SwiftUI

/// Det en lenke inneholder, med forhåndsvisning. Ingenting lagres før brukeren velger det.
struct MottattLenkeArk: View {
    let innhold: DeltInnhold
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.modelContext) private var kontekst
    @Environment(\.dismiss) private var lukk

    private var farger: [PalettFarge] { innhold.farger.map { $0.palettFarge(harProfil: Lenkedeling.harProfil) } }

    private var tittel: String {
        let navn = innhold.navn.flatMap { $0.isEmpty ? nil : $0 }
        switch innhold.slag {
        case .farge: return farger.first.map { $0.navn.isEmpty ? $0.farge.hex() : $0.navn } ?? String(localized: "Farge")
        case .palett: return navn ?? String(localized: "Palett")
        case .gradient: return innhold.gradienter.first?.navn ?? String(localized: "Gradient")
        case .harmoni: return navn ?? String(localized: "Harmoni")
        case nil: return String(localized: "Ukjent innhold")
        }
    }

    private var slagnavn: String {
        switch innhold.slag {
        case .farge: String(localized: "Farge")
        case .palett: farger.count == 1 ? String(localized: "Palett · 1 farge") : String(localized: "Palett · \(farger.count) farger")
        case .gradient: String(localized: "Gradient")
        case .harmoni: String(localized: "Harmoni")
        case nil: ""
        }
    }

    /// Farger laget i en ICC-profil mottakeren ikke har: fargen kommer med, verdiene i profilen ikke.
    private var manglerProfil: Bool {
        innhold.farger.contains { $0.rom?.hasPrefix("icc:") == true && $0.representasjon(harProfil: Lenkedeling.harProfil) == nil }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if !farger.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10, alignment: .top)], spacing: 10) {
                            ForEach(Array(farger.enumerated()), id: \.offset) { _, pf in
                                VStack(alignment: .leading, spacing: 3) {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(pf.farge.swiftUI)
                                        .frame(height: 56)
                                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.quaternary))
                                    if !pf.navn.isEmpty { Text(pf.navn).font(.caption).lineLimit(2) }
                                    Text(pf.representasjon?.tekst ?? pf.farge.hex())
                                        .font(.caption2.monospaced()).foregroundStyle(Color.sekundærTekst).lineLimit(2)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    ForEach(Array(innhold.gradienter.enumerated()), id: \.offset) { _, g in
                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(LinearGradient(stops: Lenkedeling.stopp(g), startPoint: .leading, endPoint: .trailing))
                                .frame(height: 44)
                            Text(g.stopp.count > 2
                                 ? String(localized: "\(g.navn ?? String(localized: "Gradient")) · \(g.stopp.count) fargestopp")
                                 : (g.navn ?? String(localized: "Gradient")))
                                .font(.caption)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    if let h = innhold.harmoni {
                        LabeledContent("Harmoni", value: [Harmoni(rawValue: h.harmoni)?.navn, Fargesirkel(rawValue: h.sirkel)?.navn]
                            .compactMap { $0 }.joined(separator: " · "))
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tittel).font(.title3.weight(.semibold)).foregroundStyle(.primary).textCase(nil)
                        Text(slagnavn).textCase(nil)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if innhold.gradienter.contains(where: { $0.stopp.count > 2 }) {
                            Text("Gradienter med flere enn to fargestopp lagres med første og siste stopp i denne versjonen av Kolorist.")
                        }
                        if manglerProfil {
                            Text("Noen farger er laget i en ICC-profil du ikke har. Fargene kommer med, men ikke verdiene i profilen.")
                        }
                        if innhold.versjon > Delingslenke.versjon {
                            Text("Lenken er laget med en nyere versjon av Kolorist. Noe kan mangle.")
                        }
                    }
                }

                Section { handlinger }
            }
            .formStyle(.grouped)
            .navigationTitle("Delt med deg")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { lukk() } } }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 420)
        #endif
    }

    @ViewBuilder private var handlinger: some View {
        switch innhold.slag {
        case .farge:
            if let pf = farger.first {
                Button("Lagre som enkeltfarge", systemImage: "plus.square") {
                    kontekst.insert(LagretFarge(pf))
                    lukk()
                }
                Button("Vis i Studio", systemImage: "slider.horizontal.3") {
                    arbeidsbenk.aktivFarge = pf.farge
                    arbeidsbenk.valgtFane = .studio
                    lukk()
                }
            }
        case .palett:
            Button("Legg til i paletter", systemImage: "swatchpalette") {
                let p = PalettDokument(navn: innhold.navn ?? String(localized: "Delt palett"), farger: farger)
                p.gradienter = innhold.gradienter.map {
                    PalettGradient(navn: $0.navn ?? "", oppsett: Lenkedeling.oppsett($0, standardtrinn: arbeidsbenk.lyshetstrinn))
                }
                kontekst.insert(p)
                arbeidsbenk.valgtFane = .paletter
                lukk()
            }
        case .gradient:
            if let g = innhold.gradienter.first {
                let oppsett = Lenkedeling.oppsett(g, standardtrinn: arbeidsbenk.lyshetstrinn)
                Button("Lagre i Gradienter", systemImage: "square.stack.3d.forward.dottedline") {
                    kontekst.insert(LagretGradient(navn: g.navn ?? String(localized: "Delt gradient"), oppsett: oppsett))
                    lukk()
                }
                Button("Åpne i Overgang", systemImage: "arrow.up.forward.app") {
                    arbeidsbenk.åpne(oppsett)
                    lukk()
                }
            }
        case .harmoni:
            if let h = innhold.harmoni {
                Button("Åpne i Harmoni", systemImage: "circle.hexagongrid") {
                    let d = UserDefaults.standard
                    if let harmoni = Harmoni(rawValue: h.harmoni) { d.set(harmoni.rawValue, forKey: "harmoni") }
                    if let sirkel = Fargesirkel(rawValue: h.sirkel) { d.set(sirkel.rawValue, forKey: "harmoniSirkel") }
                    if let antall = h.antall { d.set(antall, forKey: "harmoniAntall") }
                    if let vinkel = h.vinkel { d.set(vinkel, forKey: "harmoniVinkel") }
                    d.set((h.lyshetsrekkefølge.flatMap(Lyshetsrekkefølge.init(rawValue:)) ?? .lik).rawValue,
                          forKey: "harmoniLyshetsrekkefølge")
                    d.set("harmoni", forKey: "studioModus")
                    arbeidsbenk.aktivFarge = h.grunn.farge
                    arbeidsbenk.valgtFane = .studio
                    lukk()
                }
            }
            Button("Legg til som palett", systemImage: "swatchpalette") {
                kontekst.insert(PalettDokument(navn: innhold.navn ?? String(localized: "Delt harmoni"), farger: farger))
                arbeidsbenk.valgtFane = .paletter
                lukk()
            }
        case nil:
            EmptyView()
        }
    }
}

/// «Del som lenke» i menyer: åpner delingsarket med en lenke andre kan åpne i Kolorist eller i nettleseren.
/// Lenken lages først når delingen starter.
struct DelSomLenke: View {
    let navn: String
    var tittel: LocalizedStringKey = "Del som lenke"
    let innhold: @Sendable () -> DeltInnhold

    init(navn: String, tittel: LocalizedStringKey = "Del som lenke", innhold: @escaping @Sendable () -> DeltInnhold) {
        self.navn = navn
        self.tittel = tittel
        self.innhold = innhold
    }

    var body: some View {
        ShareLink(item: Lenkeelement(innhold: innhold),
                  preview: SharePreview(navn.isEmpty ? String(localized: "Kolorist") : navn)) {
            Label(tittel, systemImage: "link")
        }
    }
}

/// Delingselementet: blir til lenken når delingsarket ber om den.
nonisolated struct Lenkeelement: Transferable {
    let innhold: @Sendable () -> DeltInnhold

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { (e: Lenkeelement) in try Delingslenke.lenke(e.innhold()) }
    }
}
