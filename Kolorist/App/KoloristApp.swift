import AppIntents
import FargeKI
import FargeKjerne
import SwiftData
import SwiftUI

@main
struct KoloristApp: App {
    @State private var arbeidsbenk = Arbeidsbenk.delt
    @State private var profiler = ProfilBibliotek.delt

    init() {
        #if DEBUG
        Lagring.initialiserCloudKitSkjemaOmØnsket()
        #endif
        KoloristSnarveier.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            InnholdsVisning()
                .presentasjonsmodus(arbeidsbenk.presentasjon)
                .environment(arbeidsbenk)
                .environment(profiler)
                #if os(macOS)
                // Minste vindu: sidepanel og én kolonne omtrent som på iPhone. Mindre enn dette presses innholdet sammen.
                .frame(minWidth: 640, minHeight: 600)
                #endif
                #if DEBUG
                .focusEffectDisabled(Skjermbildemodus.på)
                .task { Skjermbildemodus.forbered(Lagring.container.mainContext) }
                #endif
        }
        .modelContainer(Lagring.container)
        #if os(macOS)
        .windowResizability(.contentMinSize)
        #endif
        // ⌘P (Arkiv › Skriv ut) for paletten som er åpen – Mac, og iPad med tastatur.
        .commands { UtskriftKommando() }
        .commands { KoloristKommandoer(arbeidsbenk: arbeidsbenk) }
        #if os(macOS)
        .commands {
            CommandGroup(after: .pasteboard) {
                Button("Kopier aktiv farge som hex") { Utklippstavle.kopier(arbeidsbenk.aktivFarge) }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                Button("Kopier aktiv farge som OKLCH") { Utklippstavle.kopier(arbeidsbenk.aktivFarge, som: .okLCH) }
                    .keyboardShortcut("c", modifiers: [.command, .option])
                Button("Lim inn farge") { if let f = Utklippstavle.limInn() { arbeidsbenk.aktivFarge = f } }
                    .keyboardShortcut("v", modifiers: [.command, .option])
            }
        }
        #endif
    }
}

/// Delt arbeidstilstand på tvers av faner: fargen man jobber med nå og foretrukket modell.
@Observable
final class Arbeidsbenk {
    /// Verdiene brukeren sist skrev inn direkte i en ICC-profil (CMYK/RGB-gliderne koblet til
    /// valgt profil i Studio). Gjelder bare så lenge aktiv farge er nettopp den fargen –
    /// en rundtur gjennom profilen kan ellers gi andre (likeverdige) verdier, f.eks. annen sortgenerering.
    struct Profilverdier: Equatable {
        var profilID: String
        var verdier: [Double]
        var farge: Farge
    }
    var profilverdier: Profilverdier?

    func profilverdier(for profil: ICCProfil) -> [Double]? {
        guard let p = profilverdier, p.profilID == profil.id, p.farge == aktivFarge else { return nil }
        return p.verdier
    }

    /// Presentasjonsmodus: større tekst og kontroller (Vis-menyen, ⌥⌘P, eller en delingslenke). Gjelder økten; lagres
    /// ikke (startargumentet `-presentasjon YES` slår den på ved oppstart).
    var presentasjon = UserDefaults.standard.bool(forKey: "presentasjon")

    var aktivFarge = Arbeidsbenk.startfarge {
        didSet {
            if oldValue != aktivFarge {
                merkForAngring(fra: oldValue)
                aktivFargeEndret = .now
            }
            // Unngå løkke: begrens bare når fargen faktisk er utenfor.
            // Verdier angitt direkte i begrensningsprofilen er innenfor per definisjon (en rundtur kan
            // likevel gi små avvik, særlig i mørke CMYK-farger).
            if let bibliotek = bibliotekbegrensning {
                // Fargebibliotek: fargen låses til nærmeste tone (ingen løkke – tonen er sin egen nærmeste).
                if let n = bibliotek.nærmeste(til: aktivFarge), n.avstand > 0.001 { aktivFarge = n.tone.farge }
            } else if let profil = begrensning, profilverdier(for: profil) == nil, !aktivFarge.erInnenfor(profil) {
                aktivFarge = aktivFarge.begrenset(til: profil)
            }
        }
    }

    /// «Begrens farger til …»: alle nye og redigerte farger holdes innenfor valgt ICC-profil.
    var begrensAktiv = UserDefaults.standard.bool(forKey: "kunSRGB") {
        didSet {
            UserDefaults.standard.set(begrensAktiv, forKey: "kunSRGB")
            aktivFarge = begrens(aktivFarge)
        }
    }

    /// Profilen som velges under «Vis også» og som begrensningen gjelder. Settes av Studio.
    var begrensProfil: ICCProfil = .sRGB {
        didSet { if begrensAktiv { aktivFarge = begrens(aktivFarge) } }
    }

    /// Fargebiblioteket som er valgt under «Vis også» (i stedet for en ICC-profil). Settes av Studio.
    /// Et valgt bibliotek begrenser alltid fargene – uavhengig av «Begrens farger til …».
    var begrensBibliotek: Fargebibliotek? {
        didSet { if begrensBibliotek != nil { aktivFarge = begrens(aktivFarge) } }
    }

    var begrensning: ICCProfil? { begrensAktiv && begrensBibliotek == nil ? begrensProfil : nil }

    /// Aktiv farge slik «Vis som» viser den – det som legges til med «Legg til»-feltet i paletter: nærmeste tone i et
    /// fargebibliotek (f.eks. filament, med produsent, navn og lenke), fargen gjengitt i en ICC-profil med verdiene
    /// der, eller fargen som den er (sRGB).
    /// Fargen «Legg til»-feltene legger til: den nyeste av aktiv farge og fargen på utklippstavlen (når den kan leses
    /// uten å spørre, se `Utklippstavle.fargeUtenSpørsmål`) – slik den vises i «Vis som».
    var fargeÅLeggeTil: PalettFarge {
        let vakt = Utklippstavlevakt.delt
        if let kopiert = vakt.farge, vakt.fargeEndret > aktivFargeEndret { return somVistSom(kopiert) }
        return aktivFargeSomVistSom
    }
    /// Når aktiv farge sist ble endret (se `fargeÅLeggeTil`).
    private(set) var aktivFargeEndret = Date.distantPast

    var aktivFargeSomVistSom: PalettFarge { somVistSom(aktivFarge) }

    /// En farge slik den vises i «Vis som» (nærmeste tone i et fargebibliotek, eller gjengitt i en ICC-profil).
    func somVistSom(_ farge: Farge) -> PalettFarge {
        let hensikt = UserDefaults.standard.string(forKey: "gjengivelseshensikt").flatMap(Gjengivelseshensikt.init(rawValue:))
            ?? .relativKolorimetrisk
        // Søket i et stort bibliotek (filament: over 2 200 toner) gjøres bare når fargen eller «Vis som» endres.
        let nøkkel = "\(farge.hex(medAlfa: true))|\(begrensBibliotek?.id ?? begrensProfil.id)|\(hensikt.rawValue)"
        if let lagret = vistSomMellomlager[nøkkel] { return lagret }
        let resultat = beregnSomVistSom(farge, hensikt: hensikt)
        // Noen få farger holder (aktiv farge og fargen på utklippstavlen); tøm når det blir for mange.
        if vistSomMellomlager.count > 8 { vistSomMellomlager.removeAll() }
        vistSomMellomlager[nøkkel] = resultat
        return resultat
    }
    @ObservationIgnored private var vistSomMellomlager: [String: PalettFarge] = [:]

    private func beregnSomVistSom(_ farge: Farge, hensikt: Gjengivelseshensikt) -> PalettFarge {
        if let bibliotek = begrensBibliotek, let n = bibliotek.nærmeste(til: farge) {
            return PalettFarge(navn: n.tone.navn, farge: n.tone.farge, opphav: .bibliotek,
                               representasjon: n.tone.representasjon, kilde: n.tone.kilde)
        }
        let profil = begrensProfil
        guard profil.id != ICCProfil.sRGB.id else { return PalettFarge(farge: farge) }
        guard let k = farge.komponenter(i: profil, hensikt: hensikt),
              let gjengitt = Farge(komponenter: k, i: profil, alfa: farge.alfa, hensikt: hensikt) else { return PalettFarge(farge: farge) }
        return PalettFarge(farge: gjengitt, representasjon: Fargerepresentasjon(
            rom: .icc(id: profil.id, navn: profil.navn), verdier: k, tekst: profil.formatert(k)))
    }
    var bibliotekbegrensning: Fargebibliotek? { begrensBibliotek }

    /// Grov gamut for beregninger i kjernen; den nøyaktige begrensningen gjøres av `begrens`.
    var gamut: Gamut { begrensAktiv && begrensBibliotek == nil && begrensProfil.id == ICCProfil.sRGB.id ? .sRGB : .displayP3 }

    /// Brukes på alle nye og avledede farger (toner, harmonier, overganger): innenfor valgt profil,
    /// eller nærmeste tone i valgt fargebibliotek.
    func begrens(_ farge: Farge) -> Farge {
        if let bibliotek = bibliotekbegrensning { return bibliotek.nærmeste(til: farge)?.tone.farge ?? farge }
        guard let profil = begrensning else { return farge }
        return farge.begrenset(til: profil)
    }
    var modell: Fargemodell = Arbeidsbenk.startmodell
    var valgtFane: Fane = Arbeidsbenk.startfane
    /// Vinduet er bredt nok til palettkolonnen (Mac og store iPader i liggende format). Settes av rotvisningen.
    var palettkolonneMulig = false
    /// ⌘N: be palettoversikten om en ny palett.
    var nyPalettForespurt = false
    /// En åpnet delingslenke som vises i et ark (se `åpneLenke`).
    var mottattLenke: MottattLenke?
    /// Feilmelding når en delingslenke ikke kunne leses.
    var lenkefeil: String?
    /// Lysere/mørkere-innstillinger, delt mellom Studio og Overgang og husket mellom oppstarter.
    var lyshetstrinn: Lyshetstrinn = Arbeidsbenk.lastTrinn() {
        didSet {
            try? UserDefaults.standard.set(JSONEncoder().encode(lyshetstrinn), forKey: "lyshetstrinn")
            if oldValue != lyshetstrinn {
                merkEndring("lyshetstrinn", navn: String(localized: "Endre lysere og mørkere"), fra: oldValue,
                            nå: { [weak self] in self?.lyshetstrinn ?? oldValue }, sett: { [weak self] in self?.lyshetstrinn = $0 })
            }
        }
    }

    private static func lastTrinn() -> Lyshetstrinn {
        UserDefaults.standard.data(forKey: "lyshetstrinn").flatMap { try? JSONDecoder().decode(Lyshetstrinn.self, from: $0) }
            ?? Lyshetstrinn()
    }

    enum Fane: String, Hashable { case studio, paletter, overgang, utplukk, vurdering, designsystemer }

    /// Designsystemer har egen fane der palettene ligger i en spalte til høyre (Mac med bredt vindu, 13"-iPad i liggende
    /// format): der er spalten for smal til designsystemet. Ellers er de en seksjon i Paletter, som åpner i full bredde.
    var designsystemFane: Bool { palettkolonneMulig }
    /// Et designsystem som skal åpnes i Designsystemer-fanen (se `åpneDesignsystem`).
    var designsystemSomÅpnes: DesignsystemDokument?
    /// Forhåndsvisningen som er åpen i fanen og ikke lagret ennå, så fanen vises også uten lagrede designsystemer.
    var designsystemUtkast: DesignsystemDokument?

    /// Åpner et designsystem (også en forhåndsvisning) i Designsystemer-fanen.
    func åpneDesignsystem(_ d: DesignsystemDokument) {
        if d.modelContext == nil { designsystemUtkast = d }
        designsystemSomÅpnes = d
        valgtFane = .designsystemer
    }

    /// Viser et designsystem der designsystemene står: i egen fane når palettene ligger i spalten, ellers i Paletter
    /// (palettlisten åpner det, se `designsystemSomÅpnes`). Brukes når et designsystem kommer fra en lenke.
    func visDesignsystem(_ d: DesignsystemDokument) {
        if designsystemFane {
            åpneDesignsystem(d)
        } else {
            designsystemSomÅpnes = d
            valgtFane = .paletter
        }
    }

    /// Debug: `-startfane overgang` åpner appen på en bestemt fane (brukes til skjermbilder).
    private static var startfane: Fane {
        #if DEBUG
        UserDefaults.standard.string(forKey: "startfane").flatMap(Fane.init(rawValue:)) ?? .studio
        #else
        .studio
        #endif
    }

    /// Debug: `-startfarge "#B4674D"` gir en annen startfarge (brukes til skjermbilder).
    private static var startfarge: Farge {
        #if DEBUG
        UserDefaults.standard.string(forKey: "startfarge").flatMap { Farge(hex: $0) } ?? Farge(hex: "#2F7FD8")!
        #else
        Farge(hex: "#2F7FD8")!
        #endif
    }

    /// Debug: `-startmodell munsell` åpner Studio i en bestemt fargemodell (brukes til skjermbilder).
    private static var startmodell: Fargemodell {
        #if DEBUG
        UserDefaults.standard.string(forKey: "startmodell").flatMap(Fargemodell.init(rawValue:)) ?? .okLCH
        #else
        .okLCH
        #endif
    }

    /// Én arbeidsbenk for hele appen, så App Intents («Beskriv en farge») kan vise resultatet.
    static let delt = Arbeidsbenk()

    /// En nylig lagret enkeltfarge som skal få navn (ark i roten av appen).
    var nyEnkeltfarge: LagretFarge?
    /// Farger som venter på navnearket (lagret mens et annet ark/en annen boble var oppe).
    @ObservationIgnored private var navnekø: [LagretFarge] = []
    @ObservationIgnored private var venterPåNavneark = false

    /// Ber om navn på en nylagret enkeltfarge. Arket vises når ingen andre ark eller bobler er oppe;
    /// lagres flere farger raskt, får de navn etter tur i stedet for å avbryte hverandre.
    func navngiNy(_ farge: LagretFarge) {
        navnekø.append(farge)
        visNesteNavneark()
    }

    /// Kalles også når navnearket lukkes, så neste i køen vises.
    func visNesteNavneark() {
        guard nyEnkeltfarge == nil, !venterPåNavneark, !navnekø.isEmpty else { return }
        venterPåNavneark = true
        Task {
            defer { venterPåNavneark = false }
            // Minst en kort pause (bobler og menyer lukkes), så vent til ingen presentasjon er oppe.
            try? await Task.sleep(for: .milliseconds(350))
            for _ in 0..<50 where Self.noeErPresentert() {
                try? await Task.sleep(for: .milliseconds(100))
            }
            guard nyEnkeltfarge == nil, !navnekø.isEmpty else { return }
            nyEnkeltfarge = navnekø.removeFirst()
        }
    }

    private static func noeErPresentert() -> Bool {
        #if canImport(UIKit)
        let vinduer = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        return vinduer.contains { $0.isKeyWindow && $0.rootViewController?.presentedViewController != nil }
        #else
        return NSApp.windows.contains { $0.isVisible && ($0.attachedSheet != nil || $0.sheetParent != nil) }
        #endif
    }

    /// Viser en farge i Studio i Farge-modus, uansett hvilken modus Studio sto i (fra Utplukk).
    func visIStudio(_ farge: Farge) {
        aktivFarge = farge
        UserDefaults.standard.set("farge", forKey: "studioModus")
        valgtFane = .studio
    }

    /// Viser en beskrevet farge i Studio, i OKLCH (fargen er regnet ut der).
    func vis(_ beskrevet: BeskrevetFarge) {
        profilverdier = nil
        aktivFarge = beskrevet.farge
        modell = .okLCH
        UserDefaults.standard.set("farge", forKey: "studioModus")
        valgtFane = .studio
    }

    /// Åpner en lagret gradient i Overgang (endepunktene huskes via `@AppStorage` der).
    func åpne(_ gradient: Gradientoppsett) {
        let d = UserDefaults.standard
        d.set(OvergangVisning.lagringstekst(gradient.fra), forKey: "overgangFra")
        d.set(OvergangVisning.lagringstekst(gradient.til), forKey: "overgangTil")
        d.set(gradient.antall, forKey: "overgangAntall")
        lyshetstrinn = gradient.trinn
        valgtFane = .overgang
    }

    /// Siste målte farger (kamera, bilde, pipette), nyeste sist – brukes i sammenligning.
    private(set) var målinger: [Farge] = Arbeidsbenk.startmålinger

    /// Debug: `-plukkedeFarger "#1B3A6B,#F2B84B"` starter med plukkede farger (til test og skjermbilder).
    private static var startmålinger: [Farge] {
        #if DEBUG
        (UserDefaults.standard.string(forKey: "plukkedeFarger") ?? "").split(separator: ",").compactMap { Farge(hex: String($0)) }
        #else
        []
        #endif
    }
    /// Åpent sammenligningsark (A/B med ΔE2000), hvis noe.
    var sammenligning: Sammenligningspar?

    struct Sammenligningspar: Identifiable {
        let id = UUID()
        var a: Farge
        var b: Farge
    }

    /// Tømmer de plukkede fargene; kan angres (de er ikke lagret noe annet sted).
    func tømMålinger() {
        guard !målinger.isEmpty else { return }
        let før = målinger
        målinger.removeAll()
        merkEndring("målinger", navn: String(localized: "Tøm plukkede farger"), fra: før,
                    nå: { [weak self] in self?.målinger ?? [] }, sett: { [weak self] in self?.målinger = $0 })
    }
    /// Fjerner én måling (indeks i `målinger`, nyeste sist).
    func fjernMåling(_ indeks: Int) { if målinger.indices.contains(indeks) { målinger.remove(at: indeks) } }

    // MARK: - Angre (⌘Z)

    /// Vinduets angrehåndterer. Settes av rotvisningen; deles med SwiftData, så endringer i paletter,
    /// enkeltfarger og gradienter og endringer i aktiv farge ligger i samme angrehistorikk.
    @ObservationIgnored weak var angring: UndoManager?
    @ObservationIgnored private var angreStart: Farge?
    @ObservationIgnored private var angreOppgave: Task<Void, Never>?
    @ObservationIgnored var angrer = false
    /// Endringer i innstillinger som venter på å bli angresteg (se Angring.swift), og vokteren som melder dem.
    @ObservationIgnored var ventendeEndringer: [String: () -> Void] = [:]
    @ObservationIgnored var endringsoppgave: Task<Void, Never>?
    @ObservationIgnored var innstillingsvokter: Innstillingsvokter?

    /// Samler endringer i aktiv farge som kommer tett (en glider som dras) til ett angresteg.
    private func merkForAngring(fra gammel: Farge) {
        guard !angrer, angring != nil else { return }
        if angreStart == nil { angreStart = gammel }
        angreOppgave?.cancel()
        angreOppgave = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            self?.fullførAngresteg()
        }
    }

    /// Registrerer en ventende fargeendring som angresteg med en gang (f.eks. før ⌘Z).
    func fullførAngresteg() {
        angreOppgave?.cancel()
        angreOppgave = nil
        guard let start = angreStart else { return }
        angreStart = nil
        if start != aktivFarge { registrerFargeendring(fra: start, til: aktivFarge) }
    }

    private func registrerFargeendring(fra: Farge, til: Farge) {
        guard let angring else { return }
        angring.registerUndo(withTarget: self) { benk in
            benk.angreOppgave?.cancel()
            benk.angreStart = nil
            benk.angrer = true
            benk.aktivFarge = fra
            benk.angrer = false
            // Registrert mens det angres, havner dette som «Gjør om».
            benk.registrerFargeendring(fra: til, til: fra)
        }
        angring.setActionName(String(localized: "Endre farge"))
    }


    func registrerMåling(_ farge: Farge, ukalibrert: Bool = false) {
        målinger.append(farge)
        if målinger.count > 20 { målinger.removeFirst(målinger.count - 20) }
        if ukalibrert {
            let nøkkel = farge.hex(medAlfa: true)
            ukalibrerte.removeAll { $0 == nøkkel }
            ukalibrerte.append(nøkkel)
            if ukalibrerte.count > 50 { ukalibrerte.removeFirst(ukalibrerte.count - 50) }
            UserDefaults.standard.set(ukalibrerte, forKey: "ukalibrerteMålinger")
        }
    }

    /// Farger plukket med kamera eller fra bilde uten gråkort eller referansekort (hex med alfa). Lysrefleksjonsverdien
    /// (LRV) for dem er bare veiledende: kameraets eksponering og hvitbalanse bestemmer hvor lys fargen blir. Huskes
    /// mellom oppstarter, siden bakgrunnen i kontrastsjekken også gjør det.
    private(set) var ukalibrerte: [String] = UserDefaults.standard.stringArray(forKey: "ukalibrerteMålinger") ?? []

    /// Om fargen er plukket med kamera eller fra bilde uten referanse (se `ukalibrerte`).
    func erUkalibrert(_ farge: Farge) -> Bool { ukalibrerte.contains(farge.hex(medAlfa: true)) }

    /// Åpner sammenligning; uten argumenter brukes de to siste målingene (eller aktiv farge).
    func sammenlign(_ a: Farge? = nil, _ b: Farge? = nil) {
        let siste = målinger.suffix(2)
        let fa = a ?? (siste.count == 2 ? siste.first! : aktivFarge)
        let fb = b ?? siste.last ?? Farge(hex: "#FFFFFF")!
        sammenligning = Sammenligningspar(a: fa, b: fb)
    }
}

struct InnholdsVisning: View {
    @Environment(Arbeidsbenk.self) private var arbeidsbenk
    @Environment(\.undoManager) private var undoManager
    @Environment(\.modelContext) private var kontekst
    @State private var observertAngring: ObjectIdentifier?
    @Query private var designsystemer: [DesignsystemDokument]

    /// Designsystemer-fanen: der palettene ligger i spalten, og bare når det finnes et designsystem eller en
    /// forhåndsvisning (funksjonen skal ikke presses på noen).
    private var visDesignsystemFane: Bool {
        arbeidsbenk.designsystemFane && (!designsystemer.isEmpty || arbeidsbenk.designsystemUtkast != nil)
    }

    private func kobleAngring() {
        kontekst.undoManager = undoManager
        arbeidsbenk.angring = undoManager
        arbeidsbenk.følgInnstillinger()
        // Fullfør en ventende fargeendring før et angresteg, så ⌘Z rett etter en dragning angrer den.
        if let undoManager, observertAngring != ObjectIdentifier(undoManager) {
            observertAngring = ObjectIdentifier(undoManager)
            NotificationCenter.default.addObserver(forName: .NSUndoManagerWillUndoChange, object: undoManager, queue: .main) { _ in
                MainActor.assumeIsolated {
                    Arbeidsbenk.delt.fullførAngresteg()
                    Arbeidsbenk.delt.fullførEndringer()
                }
            }
        }
    }
    @AppStorage("visPalettkolonne") private var visPalettkolonne = true

    /// Minste vindusbredde for palettkolonnen på iPad: 13"-iPad i liggende format.
    static let palettkolonneBredde: CGFloat = 1300
    /// Mac: palettkolonnen (ca. 380 pt) kommer når det fortsatt er plass til to kolonner i innholdet ved siden av den
    /// (sidepanel ca. 200 + 820 + 380), og går først når vinduet er klart smalere, så den ikke blinker av og på ved
    /// grensen og får innholdet til å hoppe mellom én og to kolonner.
    static let palettkolonneInnMac: CGFloat = 1440
    static let palettkolonneUtMac: CGFloat = 1380

    /// Mac med bredt nok vindu: Paletter ligger fast til høyre og er tatt ut av menyen.
    private var paletterTilHøyre: Bool {
        #if os(macOS)
        arbeidsbenk.palettkolonneMulig
        #else
        false
        #endif
    }

    var body: some View {
        @Bindable var arbeidsbenk = arbeidsbenk
        TabView(selection: $arbeidsbenk.valgtFane) {
            Tab("Studio", systemImage: "slider.horizontal.3", value: .studio) {
                NavigationStack { FargeEditor().palettkolonneKnapp() }
            }
            // På Mac med bredt vindu ligger Paletter fast til høyre i stedet for i menyen.
            if !paletterTilHøyre {
                Tab("Paletter", systemImage: "swatchpalette", value: .paletter) {
                    PalettListe()
                }
            }
            Tab("Overgang", systemImage: "square.stack.3d.forward.dottedline", value: .overgang) {
                NavigationStack { OvergangVisning().palettkolonneKnapp() }
            }
            Tab("Utplukk", systemImage: "eyedropper.halffull", value: .utplukk) {
                NavigationStack { UtplukkVisning().palettkolonneKnapp() }
            }
            Tab("Vurdering", systemImage: "checkmark.seal", value: .vurdering) {
                NavigationStack { VurderingVisning().palettkolonneKnapp() }
            }
            if visDesignsystemFane {
                Tab("Designsystemer", systemImage: "square.stack.3d.up", value: .designsystemer) {
                    DesignsystemFane()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        // Paletter til høyre når vinduet er bredt nok. Mac: hele palettvisningen, fast (ikke i menyen).
        // Store iPader i liggende format: en kompakt kolonne som kan vises og skjules.
        .inspector(isPresented: Binding(
            get: { paletterTilHøyre || (arbeidsbenk.palettkolonneMulig && visPalettkolonne && arbeidsbenk.valgtFane != .paletter) },
            set: { ny in if arbeidsbenk.palettkolonneMulig && !paletterTilHøyre { visPalettkolonne = ny } }
        )) {
            #if os(macOS)
            PalettListe(iKolonne: true)
                .inspectorColumnWidth(min: 320, ideal: 380, max: 560)
            #else
            PalettKolonne()
                .inspectorColumnWidth(min: 240, ideal: 300, max: 420)
            #endif
        }
        .onChange(of: paletterTilHøyre) { _, til in
            // Paletter-fanen forsvinner fra menyen: gå til Studio i stedet.
            if til, arbeidsbenk.valgtFane == .paletter { arbeidsbenk.valgtFane = .studio }
        }
        .onChange(of: visDesignsystemFane) { _, vis in
            // Fanen forsvinner (smalere vindu, eller siste designsystem slettet): designsystemene er i Paletter.
            if !vis, arbeidsbenk.valgtFane == .designsystemer {
                arbeidsbenk.valgtFane = paletterTilHøyre ? .studio : .paletter
            }
        }
        // ⌘Z: én angrehistorikk for paletter, lagrede farger og aktiv farge.
        .onAppear { kobleAngring() }
        .onChange(of: undoManager) { kobleAngring() }
        // Hele vinduets bredde (palettkolonnen medregnet).
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { bredde in
            #if os(iOS)
            let stor = UIDevice.current.userInterfaceIdiom == .pad && bredde >= Self.palettkolonneBredde
            #else
            let stor = bredde >= (arbeidsbenk.palettkolonneMulig ? Self.palettkolonneUtMac : Self.palettkolonneInnMac)
            #endif
            if arbeidsbenk.palettkolonneMulig != stor { arbeidsbenk.palettkolonneMulig = stor }
        }
        // Delingslenker (https://kolorist.no/l#… og kolorist://l#…): vises i et ark, lagres ikke av seg selv.
        .onOpenURL { arbeidsbenk.åpneLenke($0) }
        #if DEBUG
        // Test: `-åpneLenke <lenke>` åpner en delingslenke ved oppstart (uten systemets «Åpne i»-spørsmål).
        .task {
            if let tekst = UserDefaults.standard.string(forKey: "åpneLenke"), let url = URL(string: tekst) { arbeidsbenk.åpneLenke(url) }
        }
        #endif
        #if os(macOS)
        .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
        #endif
        .sheet(item: $arbeidsbenk.mottattLenke) { MottattLenkeArk(innhold: $0.innhold) }
        // «Tilpass listen …» i «Kopier til»-menyene.
        .sheet(isPresented: Binding(get: { Kopitilpasning.delt.vises }, set: { Kopitilpasning.delt.vises = $0 })) { KopimålArk() }
        .alert("Kunne ikke åpne lenken", isPresented: Binding(get: { arbeidsbenk.lenkefeil != nil },
                                                              set: { if !$0 { arbeidsbenk.lenkefeil = nil } })) {
            Button("OK") {}
        } message: { Text(arbeidsbenk.lenkefeil ?? "") }
        .sheet(item: $arbeidsbenk.sammenligning) { par in
            SammenligningVisning(a: par.a, b: par.b)
        }
        .sheet(item: $arbeidsbenk.nyEnkeltfarge, onDismiss: { arbeidsbenk.visNesteNavneark() }) { lagret in
            NavngiArk(farge: lagret.palettFarge, tittel: "Ny enkeltfarge", avbryt: "Hopp over") { navn in
                var f = lagret.palettFarge
                f.navn = navn
                lagret.palettFarge = f
            }
        }
    }
}

extension Color {
    /// Sekundærtekst med minst 4,5:1 kontrast mot lyse og mørke bakgrunner (se Assets).
    static let sekundærTekst = Color("SekundaerTekst")
    static let tertiærTekst = Color("TertiaerTekst")
    // Statusfargene .advarsel, .suksess og .feil genereres fra Assets (minst 4,5:1 i lys og mørk modus;
    // systemets .orange/.green er ca. 2,2:1 mot hvit).
}

/// Arkiv › Skriv ut (⌘P): erstatter systemets punkt og skriver ut den åpne paletten.
struct UtskriftKommando: Commands {
    @FocusedValue(\.palettutskrift) private var utskrift

    var body: some Commands {
        CommandGroup(replacing: .printItem) {
            Button(utskrift.map { String(localized: "Skriv ut «\($0.navn)» …") } ?? String(localized: "Skriv ut …")) {
                utskrift?.skrivUt()
            }
            .keyboardShortcut("p", modifiers: .command)
            .disabled(utskrift == nil)
        }
    }
}

/// Tastatursnarveier (Mac, og iPad med tastatur): ny palett, «Lagre som …» og fanene.
struct KoloristKommandoer: Commands {
    let arbeidsbenk: Arbeidsbenk
    @FocusedValue(\.palettlagring) private var lagring

    /// Paletter ligger fast til høyre på Mac med bredt vindu, og er da ikke en fane.
    private var palettfane: Bool {
        #if os(macOS)
        !arbeidsbenk.palettkolonneMulig
        #else
        true
        #endif
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Ny palett") {
                if palettfane { arbeidsbenk.valgtFane = .paletter }
                arbeidsbenk.nyPalettForespurt = true
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        CommandGroup(after: .saveItem) {
            Button("Lagre som …") { lagring?.lagreSom() }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(lagring == nil)
        }
        #if os(macOS)
        // Rediger › Pipette (⌘I): plukk en farge fra hvor som helst på skjermen og gjør den til aktiv farge, som
        // pipetteknappen i Studio. Fargen havner også blant de plukkede fargene.
        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Plukk farge fra skjermen", systemImage: "eyedropper") {
                Task {
                    if let f = await Pipette.plukkFraSkjerm() {
                        arbeidsbenk.aktivFarge = f
                        arbeidsbenk.registrerMåling(f)
                    }
                }
            }
            .keyboardShortcut("i", modifiers: .command)
        }
        #endif
        CommandGroup(before: .toolbar) {
            Button("Studio") { arbeidsbenk.valgtFane = .studio }.keyboardShortcut("1", modifiers: .command)
            Button("Paletter") { arbeidsbenk.valgtFane = .paletter }.keyboardShortcut("2", modifiers: .command).disabled(!palettfane)
            Button("Overgang") { arbeidsbenk.valgtFane = .overgang }.keyboardShortcut("3", modifiers: .command)
            Button("Utplukk") { arbeidsbenk.valgtFane = .utplukk }.keyboardShortcut("4", modifiers: .command)
            Button("Vurdering") { arbeidsbenk.valgtFane = .vurdering }.keyboardShortcut("5", modifiers: .command)
            // Presentasjonsmodus har ikke eget valg i appen: den slås på fra delingslenker (Kolorist underviser) eller med
            // startargumentet `-presentasjon YES`.
            Divider()
        }
    }
}
