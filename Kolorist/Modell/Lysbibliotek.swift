import FargeKjerne
import FargeMaaling
import Foundation
import Observation

/// Brukerens lysmiljøer, referansekort og kamerakarakteriseringer. Små mengder data, så de lagres som JSON i
/// iCloud (nøkkel–verdi) og synkroniseres mellom enhetene, med en lokal kopi – uten endringer i SwiftData-skjemaet.
@MainActor
@Observable
final class Lysbibliotek {
    static let delt = Lysbibliotek()

    private(set) var lysmiljøer: [Lysmiljø] = []
    private(set) var referansekort: [Referansekort] = []
    /// Siste karakterisering per kort (kortets id). En karakterisering gjelder lyset den ble laget i.
    private(set) var karakteriseringer: [UUID: LagretKarakterisering] = [:]
    /// Lysmiljøet «Se i lys» viser (id fra `alleLysmiljøer`).
    var valgtLysmiljø: UUID? {
        didSet { lokalt.set(valgtLysmiljø?.uuidString, forKey: Nøkkel.valgt) }
    }

    struct LagretKarakterisering: Codable, Hashable {
        var karakterisering: Kamerakarakterisering
        var dato: Date
        /// Kameraet som ble brukt (karakteriseringen gjelder bare det).
        var kamera: String
    }

    /// Standard betraktningsforhold: belysningsstyrken følger standardene; lysets spekter er et typisk valg
    /// (D50 for grafisk vurdering, nøytral LED for arbeidsplasser og skoler, varmt lys i museer). Faste id-er.
    static let standarder: [Lysmiljø] = [
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000050002")!,
                 navn: String(localized: "Grafisk vurdering, kritisk (ISO 3664 P1)"), lyskilde: .d50, lux: 2000),
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000050005")!,
                 navn: String(localized: "Grafisk vurdering, praktisk (ISO 3664 P2)"), lyskilde: .d50, lux: 500),
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000004000")!,
                 navn: String(localized: "Kontor og arbeidsplass (NS-EN 12464-1)"), lyskilde: .cie("LED-B3"), lux: 500),
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000040003")!,
                 navn: String(localized: "Klasserom (NS-EN 12464-1)"), lyskilde: .cie("LED-B3"), lux: 300),
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000040001")!,
                 navn: String(localized: "Korridor (NS-EN 12464-1)"), lyskilde: .cie("LED-B3"), lux: 100),
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000030002")!,
                 navn: String(localized: "Museum, malerier (CIE 157)"), lyskilde: .sortlegeme(kelvin: 3000), lux: 200),
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000030005")!,
                 navn: String(localized: "Museum, lysfølsomme gjenstander (CIE 157)"), lyskilde: .sortlegeme(kelvin: 3000), lux: 50),
    ]

    /// Ferdige eksempler på hverdagslys, med faste id-er.
    static let innebygde: [Lysmiljø] = [
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000002700")!,
                 navn: String(localized: "Stue om kvelden"), lyskilde: .sortlegeme(kelvin: 2700), lux: 100),
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000003000")!,
                 navn: String(localized: "Varmhvit LED"), lyskilde: .cie("LED-B2"), lux: 200),
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000004001")!,
                 navn: String(localized: "Lysrør"), lyskilde: .cie("FL11"), lux: 400),
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000006500")!,
                 navn: String(localized: "Dagslys inne"), lyskilde: .d65, lux: 1000),
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000007500")!,
                 navn: String(localized: "Overskyet ute"), lyskilde: .dagslys(kelvin: 7500), lux: 10000),
    ]

    var alleLysmiljøer: [Lysmiljø] { lysmiljøer + Self.standarder + Self.innebygde }

    func erInnebygd(_ miljø: Lysmiljø) -> Bool { (Self.standarder + Self.innebygde).contains { $0.id == miljø.id } }

    var gjeldendeLysmiljø: Lysmiljø {
        alleLysmiljøer.first { $0.id == valgtLysmiljø } ?? Self.innebygde[0]
    }

    private let sky = NSUbiquitousKeyValueStore.default
    private let lokalt = UserDefaults.standard
    private enum Nøkkel {
        static let miljøer = "lys.miljøer"
        static let kort = "lys.referansekort"
        static let karakteriseringer = "lys.karakteriseringer"
        static let valgt = "lys.valgtMiljø"
    }

    private let skjermbilder: Bool = {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "skjermbilde")
        #else
        false
        #endif
    }()

    private init() {
        valgtLysmiljø = lokalt.string(forKey: Nøkkel.valgt).flatMap(UUID.init(uuidString:))
        guard !skjermbilder else { return }
        last()
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: sky, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.last() }
        }
    }

    // MARK: Lysmiljøer

    func lagre(_ miljø: Lysmiljø) {
        guard !erInnebygd(miljø) else { return }
        if let i = lysmiljøer.firstIndex(where: { $0.id == miljø.id }) { lysmiljøer[i] = miljø } else { lysmiljøer.append(miljø) }
        skriv()
    }

    func slett(_ miljø: Lysmiljø) {
        lysmiljøer.removeAll { $0.id == miljø.id }
        if valgtLysmiljø == miljø.id { valgtLysmiljø = nil }
        skriv()
    }

    // MARK: Referansekort

    func leggTil(_ kort: Referansekort) {
        referansekort.append(kort)
        skriv()
    }

    func slett(_ kort: Referansekort) {
        referansekort.removeAll { $0.id == kort.id }
        karakteriseringer[kort.id] = nil
        skriv()
    }

    func lagre(_ k: Kamerakarakterisering, for kort: Referansekort, kamera: String) {
        karakteriseringer[kort.id] = LagretKarakterisering(karakterisering: k, dato: .now, kamera: kamera)
        skriv()
    }

    // MARK: Lagring

    /// Leser hver liste for seg; en liste som ikke kan leses (fra en nyere versjon) beholdes urørt i lageret.
    private var ulesbare: Set<String> = []

    private func last() {
        func les<T: Decodable>(_ nøkkel: String, som: T.Type) -> T? {
            guard let data = sky.data(forKey: nøkkel) ?? lokalt.data(forKey: nøkkel) else { return nil }
            do {
                ulesbare.remove(nøkkel)
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                ulesbare.insert(nøkkel)
                return nil
            }
        }
        lysmiljøer = les(Nøkkel.miljøer, som: [Lysmiljø].self) ?? []
        referansekort = les(Nøkkel.kort, som: [Referansekort].self) ?? []
        karakteriseringer = les(Nøkkel.karakteriseringer, som: [UUID: LagretKarakterisering].self) ?? [:]
    }

    private func skriv() {
        guard !skjermbilder else { return }
        let koder = JSONEncoder()
        let verdier: [(String, Data?)] = [
            (Nøkkel.miljøer, try? koder.encode(lysmiljøer)),
            (Nøkkel.kort, try? koder.encode(referansekort)),
            (Nøkkel.karakteriseringer, try? koder.encode(karakteriseringer)),
        ]
        for (nøkkel, data) in verdier where !ulesbare.contains(nøkkel) {
            guard let data else { continue }
            sky.set(data, forKey: nøkkel)
            lokalt.set(data, forKey: nøkkel)
        }
        sky.synchronize()
    }
}
