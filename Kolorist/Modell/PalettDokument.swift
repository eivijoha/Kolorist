import FargeKjerne
import Foundation
import SwiftData

/// Persistert palett. Fargene lagres som JSON-kodet `[PalettFarge]` i ett felt:
/// det er robust mot modellendringer og kompatibelt med CloudKit-synk senere
/// (alle felt har standardverdier, ingen unike begrensninger).
@Model
final class PalettDokument {
    var id: UUID = UUID()
    var navn: String = ""
    var opprettet: Date = Date.now
    var endret: Date = Date.now
    private var fargeData: Data = Data()
    /// Gruppen paletten ligger i (`PalettGruppe.id`), eller `nil` (fra 1.3). En id i stedet for en relasjon: en
    /// gruppe slettet på en annen enhet gir bare en palett uten gruppe, og eldre versjoner lar feltet være i fred.
    var gruppeID: UUID?
    /// Plassen i gruppen (eller blant paletter uten gruppe) når brukeren har ordnet dem selv (fra 1.3). `nil`: etter
    /// opprettelse, nyeste først. Navn uten «ø», siden feltet også er et CloudKit-felt.
    var sortering: Double?

    /// Sorteringsnøkkel: egen plass, ellers nyeste først (negativt tidspunkt, så nye paletter havner øverst).
    var sorteringsnøkkel: Double { sortering ?? -opprettet.timeIntervalSince1970 }

    init(navn: String, farger: [PalettFarge] = []) {
        self.id = UUID()
        self.navn = navn
        self.farger = farger
    }

    convenience init(_ palett: Palett) {
        self.init(navn: palett.navn, farger: palett.farger)
        if !palett.tekstfarger.isEmpty { tekstfarger = palett.tekstfarger }
    }

    /// Fargene i rekkefølge. Farger som ikke kan leses (fra en nyere versjon), beholdes urørt ved lagring
    /// (se `TolerantListe`), så en eldre versjon ikke sletter dem fra alle enhetene.
    var farger: [PalettFarge] {
        get { TolerantListe.les(fargeData) }
        set {
            guard let data = TolerantListe.skriv(newValue, beholdUkjenteFra: fargeData) else { return }
            fargeData = data
            endret = .now
        }
    }

    var palett: Palett { Palett(id: id, navn: navn, farger: farger, tekstfarger: tekstfarger) }

    /// Skriftfarger (fra 1.3, valgfritt): eget felt, så eldre versjoner som ikke kjenner det, lar det være i fred.
    private var tekstfargeData: Data = Data()

    /// Skriftfargene i rekkefølge (tom = ingen definert), lest og skrevet som `farger`.
    var tekstfarger: [PalettFarge] {
        get { TolerantListe.les(tekstfargeData) }
        set {
            guard let data = TolerantListe.skriv(newValue, beholdUkjenteFra: tekstfargeData) else { return }
            tekstfargeData = data
            endret = .now
        }
    }

    /// Gradienter i paletten (fra 1.1). Eget felt, så eldre versjoner som ikke kjenner det, lar det være i fred.
    private var gradientData: Data = Data()

    /// Gradientene i rekkefølge, lest og skrevet som `farger` (ukjente gradienter beholdes).
    var gradienter: [PalettGradient] {
        get { TolerantListe.les(gradientData) }
        set {
            guard let data = TolerantListe.skriv(newValue, beholdUkjenteFra: gradientData) else { return }
            gradientData = data
            endret = .now
        }
    }
}

/// En palettgruppe (mappe, ett nivå) under Paletter (fra 1.3). Palettene peker hit med `PalettDokument.gruppeID`.
@Model
final class PalettGruppe {
    var id: UUID = UUID()
    var navn: String = ""
    var opprettet: Date = Date.now

    init(navn: String) {
        self.id = UUID()
        self.navn = navn
    }
}

/// Et designsystem laget fra en palett (fra 1.3): rollene og skriftfargene som JSON (`Designsystem`), resten utledes.
/// Nytt felt i CloudKit-skjemaet (må publiseres til produksjon).
@Model
final class DesignsystemDokument {
    var id: UUID = UUID()
    var navn: String = ""
    var opprettet: Date = Date.now
    var endret: Date = Date.now
    /// Paletten designsystemet ble laget fra (rollene kan velges blant fargene der), eller `nil`.
    var palettID: UUID?
    private var data: Data = Data()

    init(_ designsystem: Designsystem, palettID: UUID?) {
        self.id = UUID()
        self.navn = designsystem.navn
        self.palettID = palettID
        self.designsystem = designsystem
    }

    var designsystem: Designsystem {
        get {
            var ds = (try? JSONDecoder().decode(Designsystem.self, from: data))
                ?? Designsystem(navn: navn, roller: [:], lysTekst: Farge(lineærR: 1, g: 1, b: 1), mørkTekst: Farge(lineærR: 0, g: 0, b: 0))
            ds.navn = navn
            return ds
        }
        set {
            data = (try? JSONEncoder().encode(newValue)) ?? data
            endret = .now
        }
    }
}

/// En enkeltfarge lagret uten palett («Enkeltfarger»).
@Model
final class LagretFarge {
    var id: UUID = UUID()
    var opprettet: Date = Date.now
    private var data: Data = Data()

    init(_ farge: PalettFarge) {
        self.id = farge.id
        self.palettFarge = farge
    }

    var palettFarge: PalettFarge {
        get { (try? JSONDecoder().decode(PalettFarge.self, from: data)) ?? PalettFarge(id: id, farge: Farge(lineærR: 0, g: 0, b: 0)) }
        set { data = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}

/// En gradient i en palett: navn og oppsettet fra Overgang.
nonisolated struct PalettGradient: Codable, Hashable, Identifiable, Sendable {
    var id = UUID()
    var navn: String
    var oppsett: Gradientoppsett
}

/// Innstillingene som definerer en gradient i Overgang: endepunkter, antall toner og
/// lysere/mørkere rader.
nonisolated struct Gradientoppsett: Codable, Hashable, Sendable {
    var fra: Farge
    var til: Farge
    var antall: Int
    var trinn: Lyshetstrinn

    var toner: [Farge] { Overgang.toner(fra: fra, til: til, antall: antall) }

    /// Rader fra lysest til mørkest; midtraden er selve overgangen.
    var rader: [[Farge]] {
        let variasjoner = toner.map { trinn.toner(for: $0) }
        return (0..<(trinn.antallLysere + trinn.antallMørkere + 1)).map { rad in variasjoner.map { $0[rad] } }
    }

    var css: String { CSSGradient(farger: [fra, til]).deklarasjon }
}

/// En lagret gradient («Gradienter» i Paletter). Kan åpnes igjen i Overgang.
@Model
final class LagretGradient {
    var id: UUID = UUID()
    var navn: String = ""
    var opprettet: Date = Date.now
    var endret: Date = Date.now
    private var data: Data = Data()

    init(navn: String, oppsett: Gradientoppsett) {
        self.id = UUID()
        self.navn = navn
        self.oppsett = oppsett
    }

    var oppsett: Gradientoppsett? {
        get { try? JSONDecoder().decode(Gradientoppsett.self, from: data) }
        set {
            data = (try? JSONEncoder().encode(newValue)) ?? Data()
            endret = .now
        }
    }
}

/// Felles lagring for app og App Intents (intents kjører i appens prosess).
///
/// Paletter, gradienter og enkeltfarger synkroniseres via iCloud (CloudKit, privat database) når brukeren er
/// logget inn i iCloud. Ellers lagres de lokalt. Modellene oppfyller CloudKit-kravene: alle felt
/// har standardverdier, ingen unike begrensninger og ingen påkrevde relasjoner.
enum Lagring {
    static let containerID = "iCloud.no.engenett.Kolorist"
    private static let skjema = Schema([PalettDokument.self, LagretFarge.self, LagretGradient.self, PalettGruppe.self,
                                        DesignsystemDokument.self])

    /// Om lageret synkroniseres via iCloud (for visning i appen).
    private(set) static var synkroniserer = false

    static let container: ModelContainer = {
        #if DEBUG
        // Skjermbilder: eget lager i minnet med eksempelpaletter (Skjermbildemodus), så brukerens egne
        // paletter ikke havner i bildene og ikke endres. Teksten om iCloud vises som ved vanlig bruk.
        if UserDefaults.standard.bool(forKey: "skjermbilde") {
            synkroniserer = true
            let oppsett = ModelConfiguration(schema: skjema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            return try! ModelContainer(for: skjema, configurations: oppsett)
        }
        #endif
        if kanBrukeICloud {
            do {
                let oppsett = ModelConfiguration(schema: skjema, cloudKitDatabase: .private(containerID))
                let c = try ModelContainer(for: skjema, configurations: oppsett)
                synkroniserer = true
                return c
            } catch {
                print("iCloud-synk utilgjengelig, bruker lokal lagring: \(error)")
            }
        }
        do {
            return try ModelContainer(for: skjema, configurations: ModelConfiguration(schema: skjema, cloudKitDatabase: .none))
        } catch {
            fatalError("Kunne ikke åpne palettlageret: \(error)")
        }
    }()

    private static var kanBrukeICloud: Bool {
        #if targetEnvironment(simulator)
        // Simulatorbygg er ikke signert med CloudKit-rettighet, og CloudKit stopper appen da.
        return false
        #else
        return FileManager.default.ubiquityIdentityToken != nil
        #endif
    }
}
