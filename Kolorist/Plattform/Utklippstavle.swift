import FargeKjerne
import Foundation
import SwiftUI
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Kopiering etter plattformkonvensjon: ett element med både fargeobjekt
/// (limes inn som farge i Keynote, Pages, Figma m.fl.) og tekst (limes inn i kode).
enum Utklippstavle {
    /// `changeCount` etter siste kopiering fra Kolorist. Eget innhold kan leses uten at systemet spør om lov
    /// («Tillat innliming?» på iOS, varsel om innliming på Mac).
    private static var egenEndring = -1
    #if canImport(UIKit)
    static func merkEgen() { egenEndring = UIPasteboard.general.changeCount }
    static var endringsnummer: Int { UIPasteboard.general.changeCount }
    #elseif canImport(AppKit)
    static func merkEgen() { egenEndring = NSPasteboard.general.changeCount }
    static var endringsnummer: Int { NSPasteboard.general.changeCount }
    #endif

    /// Én farge på utklippstavlen, lest bare når det kan gjøres uten å spørre brukeren: innhold kopiert fra Kolorist,
    /// eller (Mac) når brukeren har satt Kolorist til å alltid få lime inn. Fargeformater som i «Lim inn» (`Fargetolk`).
    static var fargeUtenSpørsmål: Farge? {
        var tillatt = endringsnummer == egenEndring
        #if canImport(AppKit)
        tillatt = tillatt || NSPasteboard.general.accessBehavior == .alwaysAllow
        #endif
        guard tillatt else { return nil }
        let farger = limInnListe()
        return farger.count == 1 ? farger[0].farge : nil
    }

    /// Om utklippstavlen har farger. På iOS uten å lese innhold fra andre apper (det utløser «Tillat innliming?»):
    /// fargeobjekter (fra Kolorist, Keynote, Figma o.l.) og farger kopiert fra Kolorist. Hex-tekst fra andre apper
    /// kan ikke kjennes igjen uten å lese den.
    static var harFarger: Bool {
        #if canImport(UIKit)
        let tavle = UIPasteboard.general
        if tavle.hasColors { return true }
        return tavle.changeCount == egenEndring && !limInnListe().isEmpty
        #else
        return !limInnListe().isEmpty
        #endif
    }

    static func kopier(_ farge: Farge, som modell: Fargemodell? = nil) {
        let tekst = modell?.tekst(for: farge) ?? farge.hex(medAlfa: farge.alfa < 1)
        #if canImport(UIKit)
        let leverandør = NSItemProvider(object: farge.plattform)
        leverandør.registerObject(tekst as NSString, visibility: .all)
        UIPasteboard.general.itemProviders = [leverandør]
        #elseif canImport(AppKit)
        let tavle = NSPasteboard.general
        tavle.clearContents()
        tavle.writeObjects([farge.plattform])
        tavle.setString(tekst, forType: .string)
        #endif
        merkEgen()
    }

    static func kopierTekst(_ tekst: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = tekst
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(tekst, forType: .string)
        #endif
        merkEgen()
    }

    /// Kopierer en hel palett som tekstlinjer (én farge per linje).
    static func kopier(_ palett: Palett, som modell: Fargemodell? = nil) {
        let linjer = palett.farger.map { f in
            let verdi = modell?.tekst(for: f.farge) ?? f.farge.hex()
            return f.navn.isEmpty ? verdi : "\(f.navn)\t\(verdi)"
        }.joined(separator: "\n")
        #if canImport(UIKit)
        UIPasteboard.general.string = linjer
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(linjer, forType: .string)
        #endif
        merkEgen()
    }

    /// Leser flere farger: fargeobjekter hvis det er flere, ellers én farge per tekstlinje.
    static func limInnListe() -> [PalettFarge] {
        #if canImport(UIKit)
        let objekter = UIPasteboard.general.colors ?? []
        let tekst = UIPasteboard.general.string
        #elseif canImport(AppKit)
        let objekter = NSPasteboard.general.readObjects(forClasses: [NSColor.self]) as? [NSColor] ?? []
        let tekst = NSPasteboard.general.string(forType: .string)
        #endif
        if objekter.count > 1 {
            return objekter.compactMap { Farge(cgFarge: $0.cgColor) }.map { PalettFarge(farge: $0) }
        }
        let fraTekst = tekst.map(Fargetolk.tolkListe) ?? []
        if !fraTekst.isEmpty { return fraTekst }
        return limInn().map { [PalettFarge(farge: $0)] } ?? []
    }

    /// Leser en farge fra utklippstavlen: fargeobjekt først, deretter hex/CSS-tekst.
    static func limInn() -> Farge? {
        #if canImport(UIKit)
        if let c = UIPasteboard.general.color { return Farge(cgFarge: c.cgColor) }
        return UIPasteboard.general.string.flatMap(Fargetolk.tolk)
        #elseif canImport(AppKit)
        if let c = NSColor(from: .general) { return Farge(cgFarge: c.cgColor) }
        return NSPasteboard.general.string(forType: .string).flatMap(Fargetolk.tolk)
        #endif
    }
}

/// Følger utklippstavlen, så «Lim inn farger» bare vises når det er farger å lime inn (iPhone og iPad), og «Legg til»-
/// feltene kan vise fargen som ligger der (`farge`, se `Utklippstavle.fargeUtenSpørsmål`).
@Observable
final class Utklippstavlevakt {
    static let delt = Utklippstavlevakt()
    private(set) var harFarger = false
    /// Fargen på utklippstavlen, når den kan leses uten å spørre brukeren.
    private(set) var farge: Farge?
    /// Når `farge` sist ble endret.
    private(set) var fargeEndret = Date.distantPast
    @ObservationIgnored private var sistSett = -1

    private init() {
        oppdater()
        #if canImport(UIKit)
        // Endringer i appen, og når man kommer tilbake fra en annen app som kan ha kopiert noe.
        for navn in [UIPasteboard.changedNotification, UIApplication.didBecomeActiveNotification] {
            NotificationCenter.default.addObserver(forName: navn, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.oppdater() }
            }
        }
        #elseif canImport(AppKit)
        // Mac varsler ikke om endringer: sjekk endringsnummeret (uten å lese innholdet) når appen blir aktiv og
        // jevnlig mens den er det.
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.oppdater() }
        }
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { if NSApp.isActive { self?.oppdater() } }
        }
        #endif
    }

    func oppdater() {
        let nummer = Utklippstavle.endringsnummer
        guard nummer != sistSett else { return }
        sistSett = nummer
        #if canImport(UIKit)
        harFarger = Utklippstavle.harFarger
        #endif
        let ny = Utklippstavle.fargeUtenSpørsmål
        if ny != farge {
            farge = ny
            fargeEndret = .now
        }
    }
}

/// «Lim inn farger» på iPhone og iPad: vises bare når utklippstavlen har farger (se `Utklippstavle.harFarger`).
/// På Mac brukes ⌘V i stedet (se `fargetastatur`).
struct LimInnFargerKnapp: View {
    var leggTil: ([PalettFarge]) -> Void
    @State private var vakt = Utklippstavlevakt.delt

    var body: some View {
        #if os(iOS)
        if vakt.harFarger {
            Button("Lim inn farger", systemImage: "doc.on.clipboard") {
                let farger = Utklippstavle.limInnListe()
                if !farger.isEmpty { leggTil(farger) }
            }
            .help("Lim inn farger")
        }
        #endif
    }
}

extension View {
    /// Mac: ⌘C kopierer fargene som hex og ⌘V limer inn farger (Rediger-menyen) – i stedet for knapper.
    func fargetastatur(kopier: @escaping () -> [PalettFarge], limInn: @escaping ([PalettFarge]) -> Void) -> some View {
        #if os(macOS)
        modifier(Fargetastatur(kopier: kopier, limInn: limInn))
        #else
        self
        #endif
    }
}

#if os(macOS)
private struct Fargetastatur: ViewModifier {
    let kopier: () -> [PalettFarge]
    let limInn: ([PalettFarge]) -> Void
    @FocusState private var fokus: Bool

    func body(content: Content) -> some View {
        content
            // Visningen må kunne ha fokus for å få ⌘C og ⌘V; den får fokus når den åpnes.
            .focusable()
            .focusEffectDisabled()
            .focused($fokus)
            .onAppear { fokus = true }
            .onCopyCommand {
                let farger = kopier()
                guard !farger.isEmpty else { return [] }
                return [NSItemProvider(object: farger.map { $0.farge.hex() }.joined(separator: "\n") as NSString)]
            }
            .onPasteCommand(of: [.plainText, .utf8PlainText, .text]) { _ in
                let farger = Utklippstavle.limInnListe()
                if !farger.isEmpty { limInn(farger) }
            }
    }
}
#endif
