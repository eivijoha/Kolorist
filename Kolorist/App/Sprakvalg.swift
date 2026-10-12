import Foundation
import SwiftUI

/// Appens språk, valgt ved oppstart før noe annet lastes: norsk på enheter som er satt opp på norsk, svensk eller dansk,
/// ellers engelsk. Uten dette faller iOS og macOS tilbake til utviklingsspråket (norsk) når enhetens språk verken er
/// norsk eller engelsk, for eksempel tysk eller fransk. Har brukeren selv valgt språk for Kolorist (Innstillinger ›
/// Kolorist › Språk), respekteres det.
nonisolated enum Språkvalg {
    private static let språknøkkel = "AppleLanguages"
    /// Språket Kolorist selv satte sist, så et valg brukeren har gjort i Innstillinger kan skilles fra det.
    private static let automatisk = "språk.automatisk"

    static func bruk() {
        let innstillinger = UserDefaults.standard
        let eget = innstillinger.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")?[språknøkkel] as? [String]
        if let eget, eget.first != innstillinger.string(forKey: automatisk) { return }
        // Fjern Kolorists eget valg først, så enhetens språkliste (det globale domenet) leses – også når den er endret.
        if eget != nil { innstillinger.removeObject(forKey: språknøkkel) }
        let enheten = innstillinger.stringArray(forKey: språknøkkel) ?? Locale.preferredLanguages
        let ønsket = språk(for: enheten.first ?? "en")
        innstillinger.set([ønsket], forKey: språknøkkel)
        innstillinger.set(ønsket, forKey: automatisk)
    }

    /// Norsk (bokmål) for norsk, nynorsk, svensk og dansk; engelsk for alle andre språk.
    static func språk(for kode: String) -> String {
        let språkdel = kode.lowercased().split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? ""
        return ["nb", "nn", "no", "sv", "da"].contains(språkdel) ? "nb" : "en"
    }
}

/// Inngangen: språket velges før appen og bundlene slår opp oversettelser.
@main
enum Oppstart {
    static func main() {
        Språkvalg.bruk()
        KoloristApp.main()
    }
}
