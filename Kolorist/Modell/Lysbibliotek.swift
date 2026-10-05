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
    /// Kameraprofiler per kamera (enhetsmodell og kameratype, se `KameraFargeplukker.kameranøkkel`): en
    /// karakterisering som beskriver kameraet, ikke lyset, så et gråkort holder i nytt lys. Gjelder bare med
    /// hvitbalansen låst til dagslys (iPhone/iPad). Synkroniseres, men brukes bare på samme enhetsmodell.
    private(set) var kameraprofiler: [String: LagretKarakterisering] = [:]
    /// Eksempler og standarder brukeren har skjult fra velgerne.
    private(set) var skjulte: Set<UUID> = []
    /// Lysmiljøene «Se i lys» i Studio viser samtidig, i den rekkefølgen de ble merket.
    private(set) var viste: [UUID] = []
    /// Lysmiljøet «Se i lys» viser (id fra `alleLysmiljøer`).
    var valgtLysmiljø: UUID? {
        didSet { UserDefaults.standard.set(valgtLysmiljø?.uuidString, forKey: Nøkkel.valgt) }
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
        museumLysfølsomme,
    ]

    static let museumLysfølsomme = Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000030005")!,
        navn: String(localized: "Museum, lysfølsomme gjenstander (CIE 157)"), lyskilde: .sortlegeme(kelvin: 3000), lux: 50)

    /// Visningslys i Studio (Fargestyring): D50 er ICC-standarden og standardvalget (ingen omregning); D65 og
    /// lysmiljøene viser fargen til høyre i fargefeltet slik den oppleves i lyset.
    static let d65Visning = Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-0000000D6500")!,
                                     navn: String(localized: "D65 (dagslys)"), lyskilde: .d65, lux: 1000)

    /// Visningslyset for en lagret id; `nil` er D50 (ICC-standarden, ingen omregning).
    func visningslys(id: String) -> Lysmiljø? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        if uuid == Self.d65Visning.id { return Self.d65Visning }
        return alleLysmiljøer.first { $0.id == uuid }
    }

    /// Ferdige eksempler på hverdagslys, med faste id-er.
    static let innebygde: [Lysmiljø] = [
        stueOmKvelden, varmhvitLED, lysrør,
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000006500")!,
                 navn: String(localized: "Dagslys inne"), lyskilde: .d65, lux: 1000),
        Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000007500")!,
                 navn: String(localized: "Overskyet ute"), lyskilde: .dagslys(kelvin: 7500), lux: 10000),
    ]

    static let stueOmKvelden = Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000002700")!,
        navn: String(localized: "Stue om kvelden"), lyskilde: .sortlegeme(kelvin: 2700), lux: 100)
    static let varmhvitLED = Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000003000")!,
        navn: String(localized: "Varmhvit LED"), lyskilde: .cie("LED-B2"), lux: 200)
    static let lysrør = Lysmiljø(id: UUID(uuidString: "6C1E0000-0000-4000-8000-000000004001")!,
        navn: String(localized: "Lysrør"), lyskilde: .cie("FL11"), lux: 400)

    /// Et utvalg typiske lys for vurderingen av paletter: varmt kveldslys, varmhvit LED, lysrør og museumslys.
    static let typiske = [stueOmKvelden, varmhvitLED, lysrør, museumLysfølsomme]

    var alleLysmiljøer: [Lysmiljø] { lysmiljøer + Self.innebygde + Self.standarder }

    func erInnebygd(_ miljø: Lysmiljø) -> Bool { (Self.innebygde + Self.standarder).contains { $0.id == miljø.id } }

    // MARK: Skjulte eksempler og standarder

    var synligeEksempler: [Lysmiljø] { Self.innebygde.filter { !skjulte.contains($0.id) } }
    var synligeStandarder: [Lysmiljø] { Self.standarder.filter { !skjulte.contains($0.id) } }
    var skjulteLysmiljøer: [Lysmiljø] { (Self.innebygde + Self.standarder).filter { skjulte.contains($0.id) } }
    /// Lysmiljøene som kan velges: egne, så synlige eksempler, så synlige standarder.
    var valgbare: [Lysmiljø] { lysmiljøer + synligeEksempler + synligeStandarder }
    /// De typiske lysene for palettvurderingen, uten dem brukeren har skjult.
    var synligeTypiske: [Lysmiljø] { Self.typiske.filter { !skjulte.contains($0.id) } }

    func settSkjult(_ miljø: Lysmiljø, _ skjult: Bool) {
        guard erInnebygd(miljø) else { return }
        if skjult { skjulte.insert(miljø.id) } else { skjulte.remove(miljø.id) }
        skriv()
    }

    /// Merkede lysmiljøer som kan vises (ikke skjulte eller slettede), i rekkefølgen de ble merket.
    var visteLysmiljøer: [Lysmiljø] {
        let valgbare = self.valgbare
        return viste.compactMap { id in valgbare.first { $0.id == id } }
    }

    func erVist(_ miljø: Lysmiljø) -> Bool { viste.contains(miljø.id) }

    func veksleVist(_ miljø: Lysmiljø) {
        if let i = viste.firstIndex(of: miljø.id) { viste.remove(at: i) } else { viste.append(miljø.id) }
        skriv()
    }

    var gjeldendeLysmiljø: Lysmiljø {
        valgbare.first { $0.id == valgtLysmiljø } ?? valgbare.first ?? Self.stueOmKvelden
    }

    private let lager = SkyLager.delt
    private enum Nøkkel {
        static let miljøer = "lys.miljøer"
        static let kort = "lys.referansekort"
        static let karakteriseringer = "lys.karakteriseringer"
        static let kameraprofiler = "lys.kameraprofiler"
        static let skjulte = "lys.skjulte"
        static let viste = "lys.viste"
        static let valgt = "lys.valgtMiljø"
    }

    private init() {
        valgtLysmiljø = UserDefaults.standard.string(forKey: Nøkkel.valgt).flatMap(UUID.init(uuidString:))
        guard !lager.skjermbildemodus else {
            // Skjermbilder: noen typiske lys vist samtidig i «Se i lys».
            viste = [Self.stueOmKvelden.id, Self.varmhvitLED.id, Self.lysrør.id, Self.standarder[2].id,
                     Self.museumLysfølsomme.id, Self.innebygde[3].id]
            return
        }
        last()
        lager.vedEndring { [weak self] in self?.last() }
    }

    // MARK: Lysmiljøer

    func lagre(_ miljø: Lysmiljø) {
        guard !erInnebygd(miljø) else { return }
        if let i = lysmiljøer.firstIndex(where: { $0.id == miljø.id }) { lysmiljøer[i] = miljø } else { lysmiljøer.append(miljø) }
        skriv()
    }

    /// Sletter et eget lysmiljø; kan angres (rist eller ⌘Z) via vinduets angrehistorikk.
    func slett(_ miljø: Lysmiljø) {
        guard let plass = lysmiljøer.firstIndex(where: { $0.id == miljø.id }) else { return }
        let varValgt = valgtLysmiljø == miljø.id
        lysmiljøer.remove(at: plass)
        if varValgt { valgtLysmiljø = nil }
        skriv()
        if let angring = Arbeidsbenk.delt.angring {
            angring.registerUndo(withTarget: self) { bibliotek in
                bibliotek.lysmiljøer.insert(miljø, at: min(plass, bibliotek.lysmiljøer.count))
                if varValgt { bibliotek.valgtLysmiljø = miljø.id }
                bibliotek.skriv()
                angring.registerUndo(withTarget: bibliotek) { $0.slett(miljø) }
                angring.setActionName(String(localized: "Slett lysmiljø"))
            }
            angring.setActionName(String(localized: "Slett lysmiljø"))
        }
    }

    // MARK: Referansekort

    func leggTil(_ kort: Referansekort) {
        referansekort.append(kort)
        skriv()
    }

    /// Sletter et referansekort (og karakteriseringen for det); kan angres.
    func slett(_ kort: Referansekort) {
        guard let plass = referansekort.firstIndex(where: { $0.id == kort.id }) else { return }
        let karakterisering = karakteriseringer[kort.id]
        referansekort.remove(at: plass)
        karakteriseringer[kort.id] = nil
        skriv()
        if let angring = Arbeidsbenk.delt.angring {
            angring.registerUndo(withTarget: self) { bibliotek in
                bibliotek.referansekort.insert(kort, at: min(plass, bibliotek.referansekort.count))
                bibliotek.karakteriseringer[kort.id] = karakterisering
                bibliotek.skriv()
                angring.registerUndo(withTarget: bibliotek) { $0.slett(kort) }
                angring.setActionName(String(localized: "Slett referansekort"))
            }
            angring.setActionName(String(localized: "Slett referansekort"))
        }
    }

    func oppdater(_ kort: Referansekort) {
        guard let i = referansekort.firstIndex(where: { $0.id == kort.id }) else { return }
        referansekort[i] = kort
        skriv()
    }

    func kameraprofil(for kamera: String) -> LagretKarakterisering? { kameraprofiler[kamera] }

    func lagreKameraprofil(_ k: Kamerakarakterisering, kamera: String) {
        kameraprofiler[kamera] = LagretKarakterisering(karakterisering: k, dato: .now, kamera: kamera)
        skriv()
    }

    func fjernKameraprofil(for kamera: String) {
        kameraprofiler[kamera] = nil
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
            guard let data = lager.data(nøkkel) else { return nil }
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
        kameraprofiler = les(Nøkkel.kameraprofiler, som: [String: LagretKarakterisering].self) ?? [:]
        skjulte = les(Nøkkel.skjulte, som: Set<UUID>.self) ?? []
        viste = les(Nøkkel.viste, som: [UUID].self) ?? []
    }

    private func skriv() {
        let koder = JSONEncoder()
        let verdier: [(String, Data?)] = [
            (Nøkkel.miljøer, try? koder.encode(lysmiljøer)),
            (Nøkkel.kort, try? koder.encode(referansekort)),
            (Nøkkel.karakteriseringer, try? koder.encode(karakteriseringer)),
            (Nøkkel.kameraprofiler, try? koder.encode(kameraprofiler)),
            (Nøkkel.skjulte, try? koder.encode(skjulte)),
            (Nøkkel.viste, try? koder.encode(viste)),
        ]
        lager.skriv(verdier.compactMap { nøkkel, data in
            guard let data, !ulesbare.contains(nøkkel) else { return nil }
            return (nøkkel, data)
        })
    }
}
