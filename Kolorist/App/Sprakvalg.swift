import Foundation
import SwiftUI

/// Appens språk, valgt ved hver oppstart før noe annet lastes: norsk på enheter som er satt opp på norsk, svensk eller
/// dansk, ellers engelsk. Uten dette faller iOS og macOS tilbake til utviklingsspråket (norsk) når enhetens språk verken
/// er norsk eller engelsk, for eksempel tysk eller fransk.
///
/// Valget lagres ikke: det settes i argumentdomenet for denne kjøringen (som `-AppleLanguages` ved oppstart), så det
/// alltid følger enhetens språk. Et språk brukeren har valgt for Kolorist selv – i Innstillinger › Kolorist › Språk,
/// Systeminnstillinger › Språk og region › Programmer, eller Vis › Språk på Mac – ligger i appens egne innstillinger
/// og går foran.
nonisolated enum Språkvalg {
    private static let språknøkkel = "AppleLanguages"
    /// Fra testbygg av 1.3.2 som lagret språket; ryddes bort.
    private static let gammelMerke = "språk.automatisk"

    static func bruk() {
        let innstillinger = UserDefaults.standard
        let id = Bundle.main.bundleIdentifier ?? ""
        var eget = innstillinger.persistentDomain(forName: id)?[språknøkkel] as? [String]
        if let gammelt = innstillinger.string(forKey: gammelMerke) {
            if eget?.first == gammelt {
                innstillinger.removeObject(forKey: språknøkkel)
                eget = nil
            }
            innstillinger.removeObject(forKey: gammelMerke)
        }
        // Brukerens eget valg for Kolorist går foran.
        guard eget == nil else { return }
        var argumenter = innstillinger.volatileDomain(forName: UserDefaults.argumentDomain)
        // Språk gitt ved oppstart (Xcode, skjermbilder) går også foran.
        guard argumenter[språknøkkel] == nil else { return }
        let enheten = innstillinger.stringArray(forKey: språknøkkel) ?? Locale.preferredLanguages
        argumenter[språknøkkel] = [språk(for: enheten.first ?? "en")]
        innstillinger.setVolatileDomain(argumenter, forName: UserDefaults.argumentDomain)
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
        // APCA for tekst på fargeflater (se Kolorist/APCA); referanseverdiene kontrolleres i Debug.
        APCA.kobleInn()
        assert(APCA.kontroller(), "APCA gir ikke referanseverdiene fra apca-w3")
        KoloristApp.main()
    }
}
