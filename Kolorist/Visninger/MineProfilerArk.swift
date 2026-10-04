import CoreGraphics
import FargeKjerne
import FargeMaaling
import SwiftUI
import UniformTypeIdentifiers

/// Oversikt over importerte ICC-profiler og fargebiblioteker («Mine fargerom»), med import og sletting.
/// Sletting fjerner filen fra iCloud Drive › Kolorist › Profiler, og dermed fra alle enhetene.
struct MineProfilerArk: View {
    /// Profilen som vises i Studio («Vis også»); settes tilbake til sRGB hvis den slettes.
    @Binding var valgtID: String
    @Environment(ProfilBibliotek.self) private var bibliotek
    @Environment(\.dismiss) private var lukk
    /// Det som skal slettes, etter bekreftelse. Én dialog for begge typene – to `confirmationDialog`
    /// på samme visning hindrer hverandre i å presenteres.
    enum Sletting: Identifiable {
        case profil(ICCProfil), bibliotek(Fargebibliotek)
        var id: String { switch self { case .profil(let p): p.id; case .bibliotek(let b): b.id } }
        var navn: String { switch self { case .profil(let p): p.navn; case .bibliotek(let b): b.navn } }
    }
    @State private var slettes: Sletting?
    /// Én importknapp for alle formatene: typen avgjøres av filinnholdet (`importerFil(fra:)`).
    @State private var importerer = false
    /// Importknappen under «Referansekort» bruker samme filvelger; dette avgjør hva filene leses som.
    @State private var importererKort = false
    @State private var lys = Lysbibliotek.delt
    @State private var visKort: Referansekort?
    /// Filer dras over arket (Mac, og iPad).
    @State private var slippMål = false
    @State private var feil: String?

    /// ICC-profiler, ASE, ACO og ACB. Bibliotektypene er ikke registrert i systemet, så de hentes fra
    /// filendelsen; `.data` slipper gjennom filer med annen endelse (innholdet avgjør).
    static let importtyper: [UTType] = ICCSeksjon.profiltyper + [
        UTType(filenameExtension: "ase"), UTType(filenameExtension: "aco"), UTType(filenameExtension: "acb"), .data,
    ].compactMap { $0 }

    var body: some View {
        NavigationStack {
            List {
                if bibliotek.importerte.isEmpty && bibliotek.fargebiblioteker.isEmpty {
                    ContentUnavailableView("Ingen egne fargerom", systemImage: "doc.badge.plus",
                                           description: Text("Importer ICC-profiler eller fargebiblioteker nedenfor. De vises under «Vis som» i Studio."))
                }
                if !bibliotek.importerte.isEmpty {
                    Section("ICC-profiler") {
                        ForEach(bibliotek.importerte) { profil in
                            rad(profil)
                                #if os(iOS)
                                .swipeActions {
                                    Button("Slett", systemImage: "trash", role: .destructive) { slettes = .profil(profil) }
                                }
                                #endif
                        }
                    }
                }
                if !bibliotek.fargebiblioteker.isEmpty {
                    Section {
                        ForEach(bibliotek.fargebiblioteker) { b in
                            bibliotekrad(b)
                                #if os(iOS)
                                .swipeActions {
                                    Button("Slett", systemImage: "trash", role: .destructive) { slettes = .bibliotek(b) }
                                }
                                #endif
                        }
                        // Forklaring som rad, ikke fotnote: fotnoter i en liste kortes av på Mac.
                        Text("Velges under «Vis som» i Studio. Da låses farger, toner og harmonier til bibliotekets toner, og fargeflaten viser tonenavnene.")
                            .forklaring()
                    } header: {
                        Text("Fargebiblioteker")
                    }
                }
                if let om = Filamentfarger.om {
                    Section {
                        ForEach(Filamentfarger.biblioteker) { b in innebygdRad(b) }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Filamentfarger for 3D-print fra FilamentColors.xyz: \(om.antall) prøver fra mange produsenter, \(om.målt) av dem målt med kolorimeter. Resten er anslått fra foto og merket slik. Farger lenker til prøver hos FilamentColors.xyz.")
                            Text("Dataene er lisensiert under CC BY 4.0. Kolorist har valgt ut opplysninger og regnet om fargene (uttrekk \(om.hentet)) og er ikke tilknyttet FilamentColors.xyz.")
                            HStack(spacing: 16) {
                                if let lenke = om.kildelenke { Link("FilamentColors.xyz", destination: lenke) }
                                if let lenke = om.lisenslenke { Link("CC BY 4.0", destination: lenke) }
                            }
                            MetodeHenvisning(.filamentfarger, .cieLab)
                        }
                        .forklaring()
                    } header: {
                        Text("Innebygde fargebiblioteker")
                    }
                }
                Section {
                    Button("Importer …", systemImage: "square.and.arrow.down") { importererKort = false; importerer = true }
                    VStack(alignment: .leading, spacing: 6) {
                        #if os(macOS)
                        Text("Du kan også dra filer hit.")
                        #endif
                        Text("ICC-profiler: .icc og .icm – for eksempel trykkprofilen fra trykkeriet (FOGRA, GRACoL) eller en skjermprofil.")
                        Text("Fargebiblioteker: .ase (Adobe Swatch Exchange), .aco (Photoshop-fargeprøver) og .acb (Adobe Color Book) – fargekart med navngitte toner. Kolorist leverer ingen fargekart fra fargesystemer; du importerer dine egne. Når du deler farger som lenke, deles fargeverdiene, men ikke tonenavnene fra bibliotekene du har importert.")
                        Text(bibliotek.brukerICloud
                             ? "Filene ligger i iCloud Drive › Kolorist › Profiler og synkroniseres mellom enhetene dine."
                             : "Filene lagres på denne enheten (iCloud Drive er ikke tilgjengelig).")
                    }
                    .forklaring()
                } header: {
                    Text("Importer")
                }
                Section {
                    ForEach(lys.referansekort) { kort in
                        Button { visKort = kort } label: { kortrad(kort) }
                            .buttonStyle(.plain)
                            .swipeActions { Button("Slett", systemImage: "trash", role: .destructive) { lys.slett(kort) } }
                            .contextMenu { Button("Slett", systemImage: "trash", role: .destructive) { lys.slett(kort) } }
                    }
                    Button("Importer referanseverdier …", systemImage: "square.grid.3x2") { importererKort = true; importerer = true }
                    #if os(macOS)
                    Text("Referansekort med kjente verdier gir nøyaktig lyskompensasjon i Utplukk – på iPhone og iPad, og på Mac med iPhone som kamera (Continuity) – og synkroniseres mellom enhetene. Verdiene følger ikke med appen; importer filen som hører til kortet ditt: CGATS (.txt, .cgats, .it8), CxF3, CSV/TSV eller en tabell med Lab-, XYZ- eller spektralverdier. Spektre gir fasiten i ethvert lys.")
                        .forklaring()
                    #else
                    Text("Referansekort med kjente verdier gir nøyaktig lyskompensasjon i Utplukk og et anslag av lyset. Verdiene følger ikke med appen; importer filen som hører til kortet ditt: CGATS (.txt, .cgats, .it8), CxF3, CSV/TSV eller en tabell med Lab-, XYZ- eller spektralverdier. Spektre gir fasiten i ethvert lys.")
                        .forklaring()
                    #endif
                } header: {
                    Text("Referansekort")
                }
            }
            .navigationTitle("Mine fargerom")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } } }
            .confirmationDialog(slettes.map { String(localized: "Slette «\($0.navn)»?") } ?? "",
                                isPresented: Binding(get: { slettes != nil }, set: { if !$0 { slettes = nil } }),
                                titleVisibility: .visible, presenting: slettes) { hva in
                switch hva {
                case .profil(let profil): Button("Slett profilen", role: .destructive) { slett(profil) }
                case .bibliotek(let b):
                    Button("Slett biblioteket", role: .destructive) {
                        if valgtID == b.id { valgtID = ICCProfil.sRGB.id }
                        bibliotek.fjern(b)
                        slettes = nil
                    }
                }
                Button("Avbryt", role: .cancel) {}
            } message: { hva in
                switch hva {
                case .profil:
                    Text(bibliotek.brukerICloud
                         ? "Filen slettes fra iCloud Drive og forsvinner fra alle enhetene dine. Farger som er lagret i profilen, beholder verdiene sine."
                         : "Filen slettes fra denne enheten. Farger som er lagret i profilen, beholder verdiene sine.")
                case .bibliotek:
                    Text(bibliotek.brukerICloud
                         ? "Filen slettes fra iCloud Drive og forsvinner fra alle enhetene dine."
                         : "Filen slettes fra denne enheten.")
                }
            }
            .fileImporter(isPresented: $importerer, allowedContentTypes: Self.importtyper, allowsMultipleSelection: true) { resultat in
                do {
                    let urler = try resultat.get()
                    if importererKort { importerKort(urler) } else { importer(urler) }
                } catch { feil = error.localizedDescription }
            }
            .sheet(item: $visKort) { ReferansekortDetalj(kort: $0) }
            // Slipp filer på arket (Finder på Mac, Filer på iPad).
            .dropDestination(for: URL.self) { urler, _ in
                let filer = urler.filter(\.isFileURL)
                guard !filer.isEmpty else { return false }
                importer(filer)
                return true
            } isTargeted: { slippMål = $0 }
            .overlay {
                if slippMål {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8, 5]))
                        .padding(6)
                        .allowsHitTesting(false)
                }
            }
            .alert("Kunne ikke importere", isPresented: Binding(get: { feil != nil }, set: { if !$0 { feil = nil } })) {
                Button("OK") {}
            } message: {
                Text(feil ?? "")
            }
        }
        #if os(macOS)
        // Høyt nok til at importdelen og forklaringene synes uten å rulle.
        .frame(minWidth: 520, idealWidth: 560, minHeight: 620, idealHeight: 680)
        #endif
    }

    /// Importerer filene som finnes gyldige; de andre samles i én feilmelding. Tekst- og XML-filer som slippes
    /// på arket, leses som referanseverdier.
    private func importer(_ urler: [URL]) {
        var feilmeldinger: [String] = []
        for url in urler {
            if Self.kortendelser.contains(url.pathExtension.lowercased()) {
                importerKort([url])
                continue
            }
            do { try bibliotek.importerFil(fra: url) } catch { feilmeldinger.append(error.localizedDescription) }
        }
        if !feilmeldinger.isEmpty { feil = feilmeldinger.joined(separator: "\n") }
    }

    static let kortendelser: Set<String> = ["txt", "csv", "tsv", "cgats", "it8", "ti1", "ti3", "cxf", "xml"]

    private func importerKort(_ urler: [URL]) {
        var feilmeldinger: [String] = []
        for url in urler {
            let tilgang = url.startAccessingSecurityScopedResource()
            defer { if tilgang { url.stopAccessingSecurityScopedResource() } }
            do {
                let kort = try Referanseimport.les(Data(contentsOf: url), filnavn: url.lastPathComponent)
                lys.leggTil(kort)
                visKort = kort
            } catch {
                feilmeldinger.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        if !feilmeldinger.isEmpty { feil = feilmeldinger.joined(separator: "\n") }
    }

    private func kortrad(_ kort: Referansekort) -> some View {
        HStack(spacing: 12) {
            PalettStripe(farger: kort.felt.prefix(12).map(\.verdi.farge)).frame(width: 56, height: 28).clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(kort.navn).lineLimit(2)
                Text(String(localized: "\(kort.felt.count) felt") + (kort.harSpektre ? " · " + String(localized: "spektre") : ""))
                    .font(.caption)
                    .foregroundStyle(Color.sekundærTekst)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.tertiærTekst)
        }
        .contentShape(Rectangle())
    }

    private func rad(_ profil: ICCProfil) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(profil.navn).lineLimit(2)
                Text(profil.modellnavn + (profil.id == valgtID ? " · " + String(localized: "vises i Studio") : ""))
                    .font(.caption)
                    .foregroundStyle(Color.sekundærTekst)
            }
            Spacer()
            #if os(macOS)
            Button("Slett", systemImage: "trash") { slettes = .profil(profil) }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Slett profilen")
            #endif
        }
    }

    private func bibliotekrad(_ b: Fargebibliotek) -> some View {
        HStack(spacing: 12) {
            PalettStripe(farger: b.farger.prefix(12).map(\.farge)).frame(width: 56, height: 28).clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(b.navn).lineLimit(2)
                Text(String(localized: "\(b.farger.count) toner") + (b.id == valgtID ? " · " + String(localized: "vises i Studio") : ""))
                    .font(.caption)
                    .foregroundStyle(Color.sekundærTekst)
            }
            Spacer()
            #if os(macOS)
            Button("Slett", systemImage: "trash") { slettes = .bibliotek(b) }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Slett biblioteket")
            #endif
        }
    }

    /// Et innebygd bibliotek: kan velges, ikke slettes.
    private func innebygdRad(_ b: Fargebibliotek) -> some View {
        HStack(spacing: 12) {
            PalettStripe(farger: b.farger.prefix(12).map(\.farge)).frame(width: 56, height: 28).clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(b.navn).lineLimit(2)
                Text(String(localized: "\(b.farger.count) toner") + (b.id == valgtID ? " · " + String(localized: "vises i Studio") : ""))
                    .font(.caption)
                    .foregroundStyle(Color.sekundærTekst)
            }
        }
    }

    private func slett(_ profil: ICCProfil) {
        if valgtID == profil.id { valgtID = ICCProfil.sRGB.id }
        bibliotek.fjern(profil)
        slettes = nil
    }
}

extension ICCProfil {
    /// Fargemodellen som kort tekst («CMYK», «RGB», «Gråtone», «Lab»).
    var modellnavn: String {
        switch modell {
        case .cmyk: "CMYK"
        case .rgb: "RGB"
        case .monochrome: String(localized: "Gråtone")
        case .lab: "Lab"
        default: String(localized: "\(antallKomponenter) kanaler")
        }
    }
}

private extension View {
    /// Forklarende tekst i en rad: liten, dempet og alltid brutt over flere linjer (aldri avkortet).
    func forklaring() -> some View {
        font(.footnote)
            .foregroundStyle(Color.sekundærTekst)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
