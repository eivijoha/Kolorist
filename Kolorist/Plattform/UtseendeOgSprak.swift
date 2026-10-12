#if os(macOS)
import AppKit
import SwiftUI

/// Utseende på Mac (Vis › Utseende): som systemet, lys eller mørk. Gjelder hele appen, også ark, menyer og paneler.
enum Utseende: String, CaseIterable, Identifiable {
    case system, lys, mørk

    var id: String { rawValue }

    var navn: LocalizedStringKey {
        switch self {
        case .system: "Som systemet"
        case .lys: "Lys"
        case .mørk: "Mørk"
        }
    }

    static func bruk(_ verdi: String) {
        NSApp.appearance = switch Utseende(rawValue: verdi) ?? .system {
        case .system: nil
        case .lys: NSAppearance(named: .aqua)
        case .mørk: NSAppearance(named: .darkAqua)
        }
    }
}

/// Appens språk på Mac (Vis › Språk): som systemet, norsk (bokmål) eller engelsk. macOS velger språket når appen starter,
/// så Kolorist startes på nytt etter valget (eller neste gang).
enum Appspråk: String, CaseIterable, Identifiable {
    case system, nb, en

    var id: String { rawValue }

    /// Språknavnene står på sitt eget språk, som i systemets språkvalg.
    @ViewBuilder var etikett: some View {
        switch self {
        case .system: Text("Som systemet")
        case .nb: Text(verbatim: "Norsk (bokmål)")
        case .en: Text(verbatim: "English")
        }
    }

    /// Valget som er lagret for appen (`AppleLanguages` i appens egne innstillinger, ikke systemets). Uten eget valg
    /// velger Kolorist ved hver oppstart (`Språkvalg`: norsk for norsk, svensk og dansk, ellers engelsk) – «Som systemet».
    static var gjeldende: Appspråk {
        let domene = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "") ?? [:]
        guard let første = (domene["AppleLanguages"] as? [String])?.first else { return .system }
        if første.hasPrefix("en") { return .en }
        if første.hasPrefix("nb") || første.hasPrefix("no") { return .nb }
        return .system
    }

    func velg() {
        guard self != Appspråk.gjeldende else { return }
        // «Som systemet»: uten eget valg velger Kolorist ved neste oppstart (`Språkvalg`).
        if self == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([rawValue], forKey: "AppleLanguages")
        }
        Self.tilbyOmstart()
    }

    private static func tilbyOmstart() {
        let varsel = NSAlert()
        varsel.messageText = String(localized: "Start Kolorist på nytt for å bytte språk")
        varsel.informativeText = String(localized: "Ellers brukes språket neste gang Kolorist starter.")
        varsel.addButton(withTitle: String(localized: "Start på nytt"))
        varsel.addButton(withTitle: String(localized: "Senere"))
        guard varsel.runModal() == .alertFirstButtonReturn else { return }
        let oppsett = NSWorkspace.OpenConfiguration()
        oppsett.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: oppsett) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
}

/// Vis › Utseende og Vis › Språk.
struct UtseendeOgSpråkKommandoer: Commands {
    @AppStorage("utseende") private var utseende = Utseende.system.rawValue

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Divider()
            Picker("Utseende", selection: $utseende) {
                ForEach(Utseende.allCases) { Text($0.navn).tag($0.rawValue) }
            }
            Picker("Språk", selection: Binding(get: { Appspråk.gjeldende }, set: { $0.velg() })) {
                ForEach(Appspråk.allCases) { $0.etikett.tag($0) }
            }
        }
    }
}
#endif
