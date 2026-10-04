import FargeKjerne
import Foundation
import Observation

/// Formatene som kan skrives til delingsmappa: eksportformatene og A4-PDF-en.
enum Delingsformat: String, CaseIterable, Identifiable {
    case ase, aco, figmaVariabler, tokensStudio, svg, css, designTokens, gpl, swiftUI, hexListe, pdf

    var id: String { rawValue }
    var eksportformat: Eksportformat? { Eksportformat(rawValue: rawValue) }
    var navn: String { eksportformat?.navn ?? String(localized: "PDF med fargeflater (A4)") }
    var filendelse: String { eksportformat?.filendelse ?? "pdf" }
}

/// Deling av paletter som filer i en mappe brukeren velger i Filer – OneDrive, Google Drive, Dropbox, iCloud Drive
/// eller en nettverksdisk – så kolleger på Windows og andre maskiner kan åpne dem. Kolorist snakker ikke med noen
/// tjeneste selv; tjenestens egen app laster opp filene.
///
/// Mønsteret er det samme som den delte mappa i Studieblikk (`SharedFolderStore`): bokmerke til mappa, som fornyes når
/// det er utdatert; koordinert, atomisk skriving utenfor hovedtråden; og ingen sletting av filer i mappa.
@MainActor
@Observable
final class Delingsmappe {
    static let delt = Delingsmappe()

    enum Status: Equatable {
        case ikkeKoblet
        case koblet(mappenavn: String)
        /// Bokmerket finnes, men mappa kan ikke åpnes (flyttet, slettet, eller tjenestens app er fjernet).
        case utenTilgang
    }

    private(set) var status: Status = .ikkeKoblet
    private(set) var formater: Set<Delingsformat>
    /// Skriv alle paletter på nytt når de endres.
    var holdOppdatert: Bool {
        didSet { UserDefaults.standard.set(holdOppdatert, forKey: Nøkkel.holdOppdatert) }
    }
    private(set) var arbeider = false
    private(set) var sisteResultat: Resultat?

    struct Resultat: Equatable {
        var antall: Int
        var tid: Date
        var feil: String?
    }

    /// Bokmerket gjelder bare denne enheten, så det lagres lokalt (ikke i iCloud).
    private enum Nøkkel {
        static let bokmerke = "deling.bokmerke"
        static let formater = "deling.formater"
        static let holdOppdatert = "deling.holdOppdatert"
        static let filnavn = "deling.filnavn"
        static let skrevet = "deling.skrevet"
    }

    /// Filnavnet (uten endelse) hver palett er skrevet under, så navnebytter flytter filene og like navn ikke
    /// overskriver hverandre.
    private var filnavn: [String: String] {
        didSet { UserDefaults.standard.set(filnavn, forKey: Nøkkel.filnavn) }
    }
    /// Når hver palett sist ble skrevet, med formatene den ble skrevet i (for å skrive bare det som er endret).
    private var skrevet: [String: String] {
        didSet { UserDefaults.standard.set(skrevet, forKey: Nøkkel.skrevet) }
    }

    private init() {
        let d = UserDefaults.standard
        formater = Set((d.stringArray(forKey: Nøkkel.formater) ?? ["ase", "pdf"]).compactMap(Delingsformat.init(rawValue:)))
        holdOppdatert = d.object(forKey: Nøkkel.holdOppdatert) as? Bool ?? true
        filnavn = d.dictionary(forKey: Nøkkel.filnavn) as? [String: String] ?? [:]
        skrevet = d.dictionary(forKey: Nøkkel.skrevet) as? [String: String] ?? [:]
        #if DEBUG
        // Test: `-delingstest Mappe` kobler til en mappe i appens Dokumenter (uten mappevelgeren).
        if let navn = d.string(forKey: "delingstest"),
           let dokumenter = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = dokumenter.appendingPathComponent(navn, isDirectory: true)
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            try? kobleTil(url)
        }
        #endif
        oppdaterStatus()
    }

    var erKoblet: Bool { if case .koblet = status { true } else { false } }

    // MARK: Kobling

    func kobleTil(_ url: URL) throws {
        let startet = url.startAccessingSecurityScopedResource()
        defer { if startet { url.stopAccessingSecurityScopedResource() } }
        UserDefaults.standard.set(try url.bookmarkData(options: Self.bokmerkevalg, includingResourceValuesForKeys: nil, relativeTo: nil),
                                  forKey: Nøkkel.bokmerke)
        // Ny mappe: alt skrives på nytt dit.
        filnavn = [:]
        skrevet = [:]
        sisteResultat = nil
        oppdaterStatus()
    }

    func kobleFra() {
        UserDefaults.standard.removeObject(forKey: Nøkkel.bokmerke)
        filnavn = [:]
        skrevet = [:]
        sisteResultat = nil
        oppdaterStatus()
    }

    func settFormat(_ format: Delingsformat, _ på: Bool) {
        if på { formater.insert(format) } else { formater.remove(format) }
        UserDefaults.standard.set(formater.map(\.rawValue).sorted(), forKey: Nøkkel.formater)
    }

    #if os(macOS)
    private static let bokmerkevalg: URL.BookmarkCreationOptions = .withSecurityScope
    private static let oppløsningsvalg: URL.BookmarkResolutionOptions = .withSecurityScope
    #else
    private static let bokmerkevalg: URL.BookmarkCreationOptions = []
    private static let oppløsningsvalg: URL.BookmarkResolutionOptions = []
    #endif

    /// Mappa fra bokmerket; et utdatert bokmerke fornyes (som `resolveURL` i Studieblikk).
    private func mappe() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: Nøkkel.bokmerke) else { return nil }
        var utdatert = false
        guard let url = try? URL(resolvingBookmarkData: data, options: Self.oppløsningsvalg, relativeTo: nil,
                                 bookmarkDataIsStale: &utdatert) else { return nil }
        if utdatert {
            let startet = url.startAccessingSecurityScopedResource()
            defer { if startet { url.stopAccessingSecurityScopedResource() } }
            if let nytt = try? url.bookmarkData(options: Self.bokmerkevalg, includingResourceValuesForKeys: nil, relativeTo: nil) {
                UserDefaults.standard.set(nytt, forKey: Nøkkel.bokmerke)
            }
        }
        return url
    }

    func oppdaterStatus() {
        guard UserDefaults.standard.data(forKey: Nøkkel.bokmerke) != nil else { status = .ikkeKoblet; return }
        guard let url = mappe() else { status = .utenTilgang; return }
        let startet = url.startAccessingSecurityScopedResource()
        defer { if startet { url.stopAccessingSecurityScopedResource() } }
        var erMappe: ObjCBool = false
        status = FileManager.default.fileExists(atPath: url.path, isDirectory: &erMappe) && erMappe.boolValue
            ? .koblet(mappenavn: url.lastPathComponent) : .utenTilgang
    }

    // MARK: Skriving

    /// Skriver palettene som er endret siden sist (eller alle med `alle`), i de valgte formatene.
    func synk(_ paletter: [PalettDokument], alle: Bool = false) async {
        guard erKoblet, !formater.isEmpty, !arbeider else { return }
        let formatnøkkel = formater.map(\.rawValue).sorted().joined(separator: ",")
        let endrede = paletter.filter { p in
            alle || skrevet[p.id.uuidString] != Self.merke(p, formatnøkkel)
        }
        guard !endrede.isEmpty else { return }
        await skriv(endrede, blant: paletter, formatnøkkel: formatnøkkel)
    }

    /// Skriver én palett nå (fra palettens meny).
    func del(_ palett: PalettDokument, blant paletter: [PalettDokument]) async {
        guard erKoblet, !formater.isEmpty, !arbeider else { return }
        await skriv([palett], blant: paletter, formatnøkkel: formater.map(\.rawValue).sorted().joined(separator: ","))
    }

    /// Filnavn per palett: palettens navn, med løpenummer når to paletter heter det samme. Rekkefølgen er fast
    /// (eldst først), så navnene ikke bytter plass mellom skrivingene.
    private static func filnavn(for paletter: [PalettDokument]) -> [String: String] {
        var navn: [String: String] = [:]
        var brukt: Set<String> = []
        for p in paletter.sorted(by: { $0.opprettet < $1.opprettet }) {
            let grunn = rentFilnavn(p.navn)
            var kandidat = grunn, n = 2
            while brukt.contains(kandidat.lowercased()) { kandidat = "\(grunn) \(n)"; n += 1 }
            brukt.insert(kandidat.lowercased())
            navn[p.id.uuidString] = kandidat
        }
        return navn
    }

    /// Alle palettene som filer i de valgte formatene, i en midlertidig mappe – til eksport én gang til en mappe
    /// brukeren velger (også i skytjenester som ikke gir fast tilgang til mapper på iPhone og iPad).
    func eksportfiler(_ paletter: [PalettDokument]) throws -> [URL] {
        let mappe = FileManager.default.temporaryDirectory.appendingPathComponent("Kolorist-eksport-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: mappe, withIntermediateDirectories: true)
        let navn = Self.filnavn(for: paletter)
        var urler: [URL] = []
        for p in paletter {
            guard let grunn = navn[p.id.uuidString] else { continue }
            for f in formater.sorted(by: { $0.rawValue < $1.rawValue }) {
                let url = mappe.appendingPathComponent("\(grunn).\(f.filendelse)")
                try (f.eksportformat?.data(for: p.palett) ?? PalettUtskrift.pdf(for: p)).write(to: url, options: .atomic)
                urler.append(url)
            }
        }
        return urler
    }

    private static func merke(_ p: PalettDokument, _ formatnøkkel: String) -> String {
        "\(p.endret.timeIntervalSinceReferenceDate)|\(p.navn)|\(formatnøkkel)"
    }

    private func skriv(_ endrede: [PalettDokument], blant alle: [PalettDokument], formatnøkkel: String) async {
        guard let rot = mappe() else { status = .utenTilgang; return }
        arbeider = true
        defer { arbeider = false }

        let nyeNavn = Self.filnavn(for: alle)

        // Paletter som må bytte filnavn fordi en annen palett har tatt navnet, skrives også (og filene flyttes).
        let berørte = endrede + alle.filter { p in
            !endrede.contains { $0.id == p.id } && filnavn[p.id.uuidString].map { $0 != nyeNavn[p.id.uuidString] } == true
        }

        // Innholdet lages her (PDF-en bruker profilene og innstillingene); bare filskrivingen går utenfor hovedtråden.
        var jobber: [Filjobb] = []
        for p in berørte {
            let id = p.id.uuidString
            guard let navn = nyeNavn[id] else { continue }
            let filer = formater.sorted { $0.rawValue < $1.rawValue }.map { f -> (String, Data) in
                let data = f.eksportformat?.data(for: p.palett) ?? PalettUtskrift.pdf(for: p)
                return ("\(navn).\(f.filendelse)", data)
            }
            let gamle = filnavn[id].flatMap { $0 == navn ? nil : $0 }
            jobber.append(Filjobb(id: id, filer: filer,
                                  flytt: gamle.map { g in formater.map { ("\(g).\($0.filendelse)", "\(navn).\($0.filendelse)") } } ?? []))
        }

        let utfall = await Task.detached(priority: .userInitiated) { Self.utfør(jobber, i: rot) }.value
        for id in utfall.fullført {
            filnavn[id] = nyeNavn[id]
            if let p = berørte.first(where: { $0.id.uuidString == id }) { skrevet[id] = Self.merke(p, formatnøkkel) }
        }
        sisteResultat = Resultat(antall: utfall.fullført.count, tid: .now, feil: utfall.feil)
        if utfall.feil != nil { oppdaterStatus() }
    }

    nonisolated private struct Filjobb: Sendable {
        var id: String
        var filer: [(String, Data)]
        /// Filer fra et tidligere navn på paletten, som flyttes til det nye (ikke slettes).
        var flytt: [(String, String)]
    }

    nonisolated private static func utfør(_ jobber: [Filjobb], i rot: URL) -> (fullført: [String], feil: String?) {
        let startet = rot.startAccessingSecurityScopedResource()
        defer { if startet { rot.stopAccessingSecurityScopedResource() } }
        var fullført: [String] = [], feil: String?
        // Alle flyttinger først, i flere runder: en fil flyttes når målet er ledig, så «Skog» kan bli «Skog 2» før en
        // annen palett tar navnet «Skog».
        let fm = FileManager.default
        var ventende = jobber.flatMap(\.flytt).filter { $0.0 != $0.1 }
        var framgang = true
        while framgang && !ventende.isEmpty {
            framgang = false
            ventende.removeAll { fra, til in
                let a = rot.appendingPathComponent(fra), b = rot.appendingPathComponent(til)
                guard fm.fileExists(atPath: a.path) else { return true }
                guard !fm.fileExists(atPath: b.path) else { return false }
                try? koordinertFlytt(a, til: b)
                framgang = true
                return true
            }
        }
        for jobb in jobber {
            do {
                for (navn, data) in jobb.filer {
                    try koordinertSkriv(data, til: rot.appendingPathComponent(navn))
                }
                fullført.append(jobb.id)
            } catch {
                feil = error.localizedDescription
            }
        }
        return (fullført, feil)
    }

    /// Koordinert, atomisk skriving, så tjenestens app ser en ren erstatning og ikke en halvskrevet fil
    /// (`coordinatedWrite` i Studieblikk).
    nonisolated private static func koordinertSkriv(_ data: Data, til url: URL) throws {
        var koordineringsfeil: NSError?, skrivefeil: Error?
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forReplacing, error: &koordineringsfeil) { faktisk in
            do { try data.write(to: faktisk, options: .atomic) } catch { skrivefeil = error }
        }
        if let koordineringsfeil { throw koordineringsfeil }
        if let skrivefeil { throw skrivefeil }
    }

    nonisolated private static func koordinertFlytt(_ fra: URL, til: URL) throws {
        var koordineringsfeil: NSError?, flyttefeil: Error?
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: fra, options: .forMoving,
                                                         writingItemAt: til, options: .forReplacing,
                                                         error: &koordineringsfeil) { a, b in
            do { try FileManager.default.moveItem(at: a, to: b) } catch { flyttefeil = error }
        }
        if let koordineringsfeil { throw koordineringsfeil }
        if let flyttefeil { throw flyttefeil }
    }

    /// Filnavn uten tegn som ikke tåles på Windows eller i skytjenester, og aldri tomt.
    nonisolated static func rentFilnavn(_ navn: String) -> String {
        let rent = navn.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>")).joined(separator: "-")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        return rent.isEmpty ? String(localized: "Uten navn") : rent
    }
}
