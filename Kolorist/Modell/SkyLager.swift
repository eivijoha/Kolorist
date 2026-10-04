import Foundation

/// Små innstillinger og lister i iCloud (nøkkel–verdi), synkronisert mellom enhetene, med en lokal kopi når iCloud
/// ikke er tilgjengelig. Brukes av `Panelinnstillinger` og `Lysbibliotek`.
@MainActor
final class SkyLager {
    static let delt = SkyLager()

    private let sky = NSUbiquitousKeyValueStore.default
    private let lokalt = UserDefaults.standard

    /// Skjermbilder (Debug): standardoppsettet, uten å lese eller endre brukerens synkroniserte data.
    let skjermbildemodus: Bool = {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "skjermbilde")
        #else
        false
        #endif
    }()

    private init() {}

    func verdi(_ nøkkel: String) -> Any? { sky.object(forKey: nøkkel) ?? lokalt.object(forKey: nøkkel) }

    func data(_ nøkkel: String) -> Data? { sky.data(forKey: nøkkel) ?? lokalt.data(forKey: nøkkel) }

    /// Skriver verdiene til iCloud og den lokale kopien (ikke i skjermbildemodus).
    func skriv(_ verdier: [(nøkkel: String, verdi: Any)]) {
        guard !skjermbildemodus else { return }
        for (nøkkel, verdi) in verdier {
            sky.set(verdi, forKey: nøkkel)
            lokalt.set(verdi, forKey: nøkkel)
        }
        sky.synchronize()
    }

    /// Kaller `handling` når andre enheter har endret verdiene, og ber iCloud hente endringer nå.
    func vedEndring(_ handling: @escaping @MainActor () -> Void) {
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: sky, queue: .main) { _ in
            MainActor.assumeIsolated { handling() }
        }
        sky.synchronize()
    }
}
