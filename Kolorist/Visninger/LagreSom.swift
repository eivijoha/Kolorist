import FargeKjerne
import Observation
import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Formatene i «Lagre som», gruppert etter hvor filene skal brukes.
enum Lagringsformat: String, CaseIterable, Identifiable {
    case ase, aco, indesign, figmaVariabler, tokensStudio, css, designTokens, swiftUI, gpl, svg, hexListe, pdf

    var id: String { rawValue }
    var eksportformat: Eksportformat? { Eksportformat(rawValue: rawValue) }
    var navn: String {
        switch self {
        case .indesign: String(localized: "InDesign-utklipp med gradienter (.idms)")
        case .pdf: String(localized: "PDF med fargeflater (A4)")
        default: eksportformat?.navn ?? rawValue
        }
    }
    var filendelse: String {
        switch self {
        case .indesign: "idms"
        case .pdf: "pdf"
        default: eksportformat?.filendelse ?? rawValue
        }
    }

    enum Gruppe: CaseIterable, Identifiable {
        case adobe, figma, nett, apple, åpne, andre, utskrift
        var id: Self { self }

        var tittel: LocalizedStringKey {
            switch self {
            case .adobe: "Adobe-programmer"
            case .figma: "Figma"
            case .nett: "Nett og design tokens"
            case .apple: "Apple-utvikling"
            case .åpne: "GIMP, Inkscape og Krita"
            case .andre: "Andre"
            case .utskrift: "Utskrift"
            }
        }
    }

    var gruppe: Gruppe {
        switch self {
        case .ase, .aco, .indesign: .adobe
        case .figmaVariabler, .tokensStudio: .figma
        case .css, .designTokens: .nett
        case .swiftUI: .apple
        case .gpl: .åpne
        case .svg, .hexListe: .andre
        case .pdf: .utskrift
        }
    }
}

/// Det som lagres: en palett, eller én farge som en palett med én farge.
struct Lagringsinnhold {
    var navn: String
    var farger: [PalettFarge]
    var gradienter: [PalettGradient] = []
    /// Skriftfargene (fra 1.3), når innholdet er én palett med skriftfarger.
    var tekstfarger: [PalettFarge] = []
    /// Flere paletter (en palettgruppe): ASE får én fargegruppe per palett og PDF én palett per side. Tom for én palett.
    var deler: [(palett: Palett, gradienter: [PalettGradient])] = []

    /// En palettgruppe: alle fargene og gradientene, og palettene hver for seg.
    static func gruppe(navn: String, paletter: [PalettDokument]) -> Lagringsinnhold {
        Lagringsinnhold(navn: navn, farger: paletter.flatMap(\.farger), gradienter: paletter.flatMap(\.gradienter),
                        deler: paletter.map { ($0.palett, $0.gradienter) })
    }
}

/// Formatene brukeren valgte sist (huskes på enheten).
@MainActor
@Observable
final class LagreSomValg {
    static let delt = LagreSomValg()
    private static let nøkkel = "lagreSom.formater"

    private(set) var formater: Set<Lagringsformat>

    private init() {
        formater = Set((UserDefaults.standard.stringArray(forKey: Self.nøkkel) ?? ["ase", "pdf"]).compactMap(Lagringsformat.init(rawValue:)))
    }

    func sett(_ format: Lagringsformat, _ på: Bool) {
        if på { formater.insert(format) } else { formater.remove(format) }
        UserDefaults.standard.set(formater.map(\.rawValue).sorted(), forKey: Self.nøkkel)
    }
}

/// «Lagre som …»: velg formater etter hvor filene skal brukes, og lagre dem i en mappe (også i OneDrive, Jottacloud og
/// andre tjenester i Filer) eller del dem.
struct LagreSomArk: View {
    let innhold: Lagringsinnhold
    @State private var valg = LagreSomValg.delt
    @State private var filer: [URL] = []
    @State private var velgerMappe = false
    @State private var feil: String?
    @Environment(\.dismiss) private var lukk

    private var filnavn: String { Self.rentFilnavn(innhold.navn) }

    var body: some View {
        NavigationStack {
            Form {
                ForEach(Lagringsformat.Gruppe.allCases) { gruppe in
                    Section(gruppe.tittel) {
                        ForEach(Lagringsformat.allCases.filter { $0.gruppe == gruppe }) { f in
                            Toggle(isOn: Binding(get: { valg.formater.contains(f) }, set: { valg.sett(f, $0) })) {
                                Text(f.navn)
                            }
                        }
                    }
                }
                Section {
                } footer: {
                    Text("Filene får navnet «\(filnavn)». «Lagre» lar deg velge eller opprette en mappe – også i OneDrive, Jottacloud og andre tjenester. «Del» sender filene med e-post, Teams, AirDrop og andre apper.")
                }
            }
            .formStyle(.grouped)
            // Knappene står fast nederst, så de ikke forsvinner under formatlista.
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button { lagre() } label: {
                        Label("Lagre …", systemImage: "folder").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    ShareLink(items: filer) {
                        Label("Del …", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
                .disabled(filer.isEmpty)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .navigationTitle("Lagre som")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Ferdig") { lukk() } } }
            .task(id: valg.formater) { filer = lagFiler() }
            #if os(iOS)
            .sheet(isPresented: $velgerMappe) { Eksportvelger(filer: filer).ignoresSafeArea() }
            #endif
            .alert("Kunne ikke lagre", isPresented: Binding(get: { feil != nil }, set: { if !$0 { feil = nil } })) {
                Button("OK") {}
            } message: { Text(feil ?? "") }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 560)
        #endif
    }

    /// Filene i de valgte formatene, i en midlertidig mappe.
    private func lagFiler() -> [URL] {
        let mappe = FileManager.default.temporaryDirectory.appendingPathComponent("Kolorist-lagre-\(UUID().uuidString)", isDirectory: true)
        let palett = Palett(navn: innhold.navn, farger: innhold.farger, tekstfarger: innhold.tekstfarger)
        do {
            try FileManager.default.createDirectory(at: mappe, withIntermediateDirectories: true)
            return try Lagringsformat.allCases.filter { valg.formater.contains($0) }.map { f in
                let url = mappe.appendingPathComponent("\(filnavn).\(f.filendelse)")
                let data: Data
                switch f {
                case .pdf:
                    data = innhold.deler.isEmpty ? PalettUtskrift.pdf(for: palett, gradienter: innhold.gradienter)
                                                 : PalettUtskrift.pdf(for: innhold.deler)
                case .ase where !innhold.deler.isEmpty:
                    data = Eksportformat.ase.data(for: innhold.deler.map(\.palett), navn: innhold.navn)
                case .indesign:
                    // Fargene som fargeprøver og ruter, gradientene som ekte gradienter (dra inn eller plasser i InDesign).
                    let gradienter = innhold.gradienter.map {
                        IDMSEksport.Gradient(navn: $0.navn, stopp: Gradientstopp.forenklet(gjennom: [$0.oppsett.fra, $0.oppsett.til]))
                    }
                    data = Data(IDMSEksport.snippet(farger: innhold.farger, gradienter: gradienter).utf8)
                default: data = f.eksportformat?.data(for: palett) ?? Data()
                }
                try data.write(to: url, options: .atomic)
                return url
            }
        } catch {
            feil = error.localizedDescription
            return []
        }
    }

    private func lagre() {
        #if os(iOS)
        velgerMappe = true
        #else
        // Mac: velg (eller opprett) en mappe i Finder, og kopier filene dit.
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = String(localized: "Lagre")
        panel.message = String(localized: "Velg mappa filene skal lagres i.")
        guard panel.runModal() == .OK, let mål = panel.url else { return }
        do {
            for url in filer {
                let fil = mål.appendingPathComponent(url.lastPathComponent)
                if FileManager.default.fileExists(atPath: fil.path) { try FileManager.default.removeItem(at: fil) }
                try FileManager.default.copyItem(at: url, to: fil)
            }
        } catch {
            feil = error.localizedDescription
        }
        #endif
    }

    /// Filnavn uten tegn som ikke tåles på Windows eller i skytjenester, og aldri tomt.
    static func rentFilnavn(_ navn: String) -> String {
        let rent = navn.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>")).joined(separator: "-")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        return rent.isEmpty ? String(localized: "Uten navn") : rent
    }
}

#if os(iOS)
/// Systemets eksportvelger for ferdige filer: velg mappe (eller opprett en) i Filer, også i OneDrive, Jottacloud o.l.
struct Eksportvelger: UIViewControllerRepresentable {
    let filer: [URL]

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forExporting: filer, asCopy: true)
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}
}
#endif

/// Paletten «Lagre som …» (⇧⌘S) gjelder, der brukeren står. Lik ved samme id, så menyen ikke bygges om hele tiden.
struct Palettlagring: Equatable {
    let id: UUID
    let lagreSom: () -> Void

    static func == (a: Palettlagring, b: Palettlagring) -> Bool { a.id == b.id }
}

extension FocusedValues {
    @Entry var palettlagring: Palettlagring?
}
