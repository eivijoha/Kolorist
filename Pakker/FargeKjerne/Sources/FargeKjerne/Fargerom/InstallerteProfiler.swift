#if os(macOS)
import ColorSync  // ColorSyncIterateInstalledProfiles; nøkkelen er «com.apple.ColorSync.ProfileURL» (kColorSyncProfileURL)
import Foundation

/// En ICC-profil som er installert på Macen: hvor den ligger, hva slags profil den er, og fargerommet til dataene.
/// Åpnes som fargerom med `profil()`.
public struct InstallertProfil: Sendable, Hashable, Identifiable {
    /// Profilklassen fra ICC-hodet (byte 12–15).
    public enum Klasse: String, Sendable, CaseIterable {
        case skjerm = "mntr", inndata = "scnr", utdata = "prtr", fargerom = "spac"
        case lenke = "link", abstrakt = "abst", navngitt = "nmcl"
    }

    /// Fargerommet til dataene fra ICC-hodet (byte 16–19).
    public enum Datarom: String, Sendable, CaseIterable {
        case rgb = "RGB ", cmyk = "CMYK", grå = "GRAY", lab = "Lab ", xyz = "XYZ "
    }

    /// Hvor profilen er installert.
    public enum Plassering: String, Sendable, CaseIterable {
        /// `/System/Library/ColorSync/Profiles`
        case system
        /// `/Library/ColorSync/Profiles`
        case maskin
        /// `~/Library/ColorSync/Profiles`
        case bruker
        /// Et annet sted ColorSync kjenner (f.eks. profiler som følger en skriverdriver).
        case annen

        public var navn: String {
            switch self {
            case .system: String(localized: "Systemet", bundle: .module)
            case .maskin: String(localized: "Maskinen", bundle: .module)
            case .bruker: String(localized: "Brukeren", bundle: .module)
            case .annen: String(localized: "Andre", bundle: .module)
            }
        }
    }

    public var id: String { url.path }
    public let url: URL
    /// Beskrivelsen i profilen («desc»), ellers filnavnet.
    public let navn: String
    /// Entydig navn til menyer: like beskrivelser (f.eks. flere «Display») får filnavnet i parentes.
    public let visningsnavn: String
    /// `nil` når klassen ikke er kjent.
    public let klasse: Klasse?
    /// `nil` når fargerommet ikke er kjent.
    public let datarom: Datarom?
    public let plassering: Plassering
    /// Første undermappe (f.eks. «Displays», «Plotter»), ellers plasseringens navn.
    public let gruppe: String

    /// Om profilen kan brukes som fargerom for farger (skjerm, inndata, utdata eller fargerom med RGB, CMYK eller grå) –
    /// ikke lenkeprofiler, abstrakte, navngitte farger eller XYZ/Lab-rom.
    public var kanBrukesSomFargerom: Bool {
        guard let klasse, let datarom else { return false }
        return [.skjerm, .inndata, .utdata, .fargerom].contains(klasse) && [.rgb, .cmyk, .grå].contains(datarom)
    }

    /// Profilen som fargerom (leser fila). `nil` når fila ikke kan leses eller ikke er en gyldig ICC-profil.
    public func profil() -> ICCProfil? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return ICCProfil(data: data, navn: url.deletingPathExtension().lastPathComponent)
    }
}

/// ICC-profiler som er installert på Macen: systemets, maskinens (`/Library`) og brukerens egne (`~/Library`), med
/// undermapper som «Displays» og egne mapper. ColorSync lister bare toppnivået, så mappene leses i tillegg rekursivt.
///
/// Virker i sandkassen uten egne rettigheter: standardprofilen for apper tillater lesing av
/// `/Library/ColorSync/Profiles` og `~/Library/ColorSync`, systemmappen kan alltid leses, og ColorSync-tjenesten er
/// tilgjengelig. På iOS og iPadOS finnes ingen installerte profiler; bruk `ICCProfil.innebygde` og filvalg.
public enum InstallerteProfiler {
    /// De installerte profilene, sortert etter visningsnavn. Uten filter tas alle med; `klasser` og `datarom` begrenser
    /// utvalget (f.eks. `klasser: [.utdata], datarom: [.cmyk]` for trykkprofiler). Leser bare hodet og beskrivelsen –
    /// fargerommet lages først med `profil()`. Kan ta litt tid med mange profiler; kall den utenfor hovedtråden.
    public static func finn(klasser: Set<InstallertProfil.Klasse>? = nil,
                            datarom: Set<InstallertProfil.Datarom>? = nil) -> [InstallertProfil] {
        let hjem = hjemmemappe
        var urler = Set<URL>()

        // ColorSync: profilene systemet selv kjenner (fungerer også i sandkassen).
        final class Samler: @unchecked Sendable { var urler: [URL] = [] }
        let samler = Samler()
        var seed: UInt32 = 0
        ColorSyncIterateInstalledProfiles({ info, bruker in
            guard let info = info as? [String: Any], let bruker,
                  let url = info["com.apple.ColorSync.ProfileURL"] as? URL
            else { return true }
            Unmanaged<Samler>.fromOpaque(bruker).takeUnretainedValue().urler.append(url)
            return true
        }, &seed, Unmanaged.passUnretained(samler).toOpaque(), nil)
        urler.formUnion(samler.urler.map(\.standardizedFileURL))

        // Mappene rekursivt. Mapper som ikke kan leses, hoppes stille over.
        for mappe in røtter(hjem: hjem).map(\.url) {
            guard let gjennom = FileManager.default.enumerator(at: mappe, includingPropertiesForKeys: nil,
                                                                options: [.skipsHiddenFiles]) else { continue }
            for case let url as URL in gjennom where ["icc", "icm"].contains(url.pathExtension.lowercased()) {
                urler.insert(url.standardizedFileURL)
            }
        }

        var funn: [(url: URL, navn: String, klasse: InstallertProfil.Klasse?, datarom: InstallertProfil.Datarom?)] = []
        for url in urler {
            guard let data = try? Data(contentsOf: url), data.count >= 128, String(decoding: data[36..<40], as: UTF8.self) == "acsp"
            else { continue }
            let klasse = InstallertProfil.Klasse(rawValue: String(decoding: data[12..<16], as: UTF8.self))
            let rom = InstallertProfil.Datarom(rawValue: String(decoding: data[16..<20], as: UTF8.self))
            if let klasser, !(klasse.map(klasser.contains) ?? false) { continue }
            if let datarom, !(rom.map(datarom.contains) ?? false) { continue }
            let navn = ICCBeskrivelse.les(data) ?? url.deletingPathExtension().lastPathComponent
            funn.append((url, navn, klasse, rom))
        }

        var antall: [String: Int] = [:]
        for f in funn { antall[f.navn, default: 0] += 1 }
        return funn.map { f in
            let filnavn = f.url.deletingPathExtension().lastPathComponent
            let visningsnavn = antall[f.navn, default: 0] > 1 && filnavn != f.navn ? "\(f.navn) (\(filnavn))" : f.navn
            let (plassering, gruppe) = Self.plassering(for: f.url, hjem: hjem)
            return InstallertProfil(url: f.url, navn: f.navn, visningsnavn: visningsnavn, klasse: f.klasse, datarom: f.datarom,
                                    plassering: plassering, gruppe: gruppe)
        }
        .sorted { $0.visningsnavn.localizedStandardCompare($1.visningsnavn) == .orderedAscending }
    }

    /// Plassering og gruppe ut fra stien: undermappen under en av rotmappene (f.eks. «Displays»), ellers plasseringens
    /// navn.
    static func plassering(for url: URL, hjem: URL) -> (InstallertProfil.Plassering, String) {
        let sti = url.standardizedFileURL.path
        for rot in røtter(hjem: hjem) where sti.hasPrefix(rot.url.path + "/") {
            let deler = sti.dropFirst(rot.url.path.count + 1).split(separator: "/")
            return (rot.plassering, deler.count > 1 ? String(deler[0]) : rot.plassering.navn)
        }
        return (.annen, url.deletingLastPathComponent().lastPathComponent)
    }

    private static func røtter(hjem: URL) -> [(url: URL, plassering: InstallertProfil.Plassering)] {
        [(URL(fileURLWithPath: "/System/Library/ColorSync/Profiles"), .system),
         (URL(fileURLWithPath: "/Library/ColorSync/Profiles"), .maskin),
         (hjem.appending(path: "Library/ColorSync/Profiles"), .bruker)]
    }

    /// Den ekte hjemmemappen, også i sandkassen (der `NSHomeDirectory()` er appens container).
    private static var hjemmemappe: URL {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir { return URL(fileURLWithPath: String(cString: dir)) }
        return URL(fileURLWithPath: NSHomeDirectory())
    }
}
#endif
