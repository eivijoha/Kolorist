import Foundation
import SwiftData

/// Angring for verdier utenfor SwiftData (innstillinger i Overgang og Harmoni, lysere/mørkere): endringer registreres
/// som angresteg i vinduets angrehistorikk, så «Rist for å angre» (iOS) og ⌘Z (Mac, iPad med tastatur) virker også
/// for dem. Glidere gir mange små endringer; de slås sammen til ett steg når bevegelsen har stoppet.
extension Arbeidsbenk {
    /// Innstillingene som kan angres, med navnet steget får i angremenyen.
    static let angrebareInnstillinger: [String: String.LocalizationValue] = [
        "overgangFra": "Endre overgang", "overgangTil": "Endre overgang", "overgangAntall": "Endre overgang",
        "harmoni": "Endre harmoni", "harmoniAntall": "Endre harmoni", "harmoniVinkel": "Endre harmoni",
        "harmoniSirkel": "Endre harmoni", "harmoniLyshetsrekkefølge": "Endre harmoni",
    ]

    /// Merker en endring; den registreres som angresteg når endringene har roet seg (eller før neste angring).
    func merkEndring<T: Equatable>(_ nøkkel: String, navn: String, fra gammel: T, nå: @escaping () -> T, sett: @escaping (T) -> Void) {
        guard !angrer, angring != nil else { return }
        if ventendeEndringer[nøkkel] == nil {
            ventendeEndringer[nøkkel] = { [weak self] in
                let ny = nå()
                if ny != gammel { self?.registrerEndring(navn: navn, fra: gammel, til: ny, sett: sett) }
            }
        }
        endringsoppgave?.cancel()
        endringsoppgave = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            self?.fullførEndringer()
        }
    }

    /// Registrerer ventende endringer med en gang (samme angresteg når de skjedde samtidig).
    func fullførEndringer() {
        endringsoppgave?.cancel()
        endringsoppgave = nil
        let ventende = ventendeEndringer
        ventendeEndringer = [:]
        ventende.values.forEach { $0() }
    }

    private func registrerEndring<T>(navn: String, fra: T, til: T, sett: @escaping (T) -> Void) {
        guard let angring else { return }
        angring.registerUndo(withTarget: self) { benk in
            benk.angrer = true
            sett(fra)
            benk.angrer = false
            benk.registrerEndring(navn: navn, fra: til, til: fra, sett: sett)
        }
        angring.setActionName(navn)
    }

    /// Følger innstillingene i `angrebareInnstillinger` (skrevet av @AppStorage i visningene).
    func følgInnstillinger() {
        guard innstillingsvokter == nil else { return }
        innstillingsvokter = Innstillingsvokter(nøkler: Array(Self.angrebareInnstillinger.keys)) { [weak self] nøkkel, gammel in
            guard let self, let navn = Self.angrebareInnstillinger[nøkkel] else { return }
            merkEndring(nøkkel, navn: String(localized: navn), fra: Innstillingsverdi(gammel),
                        nå: { Innstillingsverdi(UserDefaults.standard.object(forKey: nøkkel)) },
                        sett: { UserDefaults.standard.set($0.verdi, forKey: nøkkel) })
        }
    }
}

/// En verdi i UserDefaults, sammenlignbar (tall, tekst, data).
struct Innstillingsverdi: Equatable {
    let verdi: Any?
    init(_ verdi: Any?) { self.verdi = verdi is NSNull ? nil : verdi }

    static func == (a: Innstillingsverdi, b: Innstillingsverdi) -> Bool {
        switch (a.verdi, b.verdi) {
        case (nil, nil): true
        case let (x?, y?): (x as AnyObject).isEqual(y)
        default: false
        }
    }
}

/// Melder endringer i UserDefaults-nøkler med gammel verdi (KVO, synkront ved skriving).
final class Innstillingsvokter: NSObject {
    private let nøkler: [String]
    nonisolated(unsafe) private let endret: (String, Any?) -> Void

    init(nøkler: [String], endret: @escaping (String, Any?) -> Void) {
        self.nøkler = nøkler
        self.endret = endret
        super.init()
        for n in nøkler { UserDefaults.standard.addObserver(self, forKeyPath: n, options: [.old], context: nil) }
    }

    nonisolated override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                           change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // Innstillingene skrives fra visningene, altså på hovedtråden.
        guard let keyPath, Thread.isMainThread else { return }
        let gammel = Overføring(verdi: change?[.oldKey])
        let melding = Overføring(verdi: endret)
        MainActor.assumeIsolated { melding.verdi(keyPath, gammel.verdi) }
    }
}

extension ModelContext {
    /// Én endring i paletter, farger eller gradienter som ett navngitt angresteg («Angre Slett palett»).
    func angresteg(_ navn: String.LocalizationValue, _ endring: () -> Void) {
        let angring = undoManager
        angring?.beginUndoGrouping()
        endring()
        processPendingChanges()
        angring?.setActionName(String(localized: navn))
        angring?.endUndoGrouping()
    }
}

/// Flytter en verdi over til hovedaktøren når vi allerede er på hovedtråden (KVO-meldingen over).
nonisolated private struct Overføring<T>: @unchecked Sendable { let verdi: T }
