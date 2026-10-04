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
    #if canImport(UIKit)
    /// `changeCount` etter siste kopiering fra Kolorist. Eget innhold kan leses uten at iOS spør «Tillat innliming?».
    private static var egenEndring = -1
    private static func merkEgen() { egenEndring = UIPasteboard.general.changeCount }
    #endif

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
        merkEgen()
        #elseif canImport(AppKit)
        let tavle = NSPasteboard.general
        tavle.clearContents()
        tavle.writeObjects([farge.plattform])
        tavle.setString(tekst, forType: .string)
        #endif
    }

    static func kopierTekst(_ tekst: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = tekst
        merkEgen()
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(tekst, forType: .string)
        #endif
    }

    /// Kopierer en hel palett som tekstlinjer (én farge per linje).
    static func kopier(_ palett: Palett, som modell: Fargemodell? = nil) {
        let linjer = palett.farger.map { f in
            let verdi = modell?.tekst(for: f.farge) ?? f.farge.hex()
            return f.navn.isEmpty ? verdi : "\(f.navn)\t\(verdi)"
        }.joined(separator: "\n")
        #if canImport(UIKit)
        UIPasteboard.general.string = linjer
        merkEgen()
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(linjer, forType: .string)
        #endif
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

/// Følger utklippstavlen (iPhone og iPad), så «Lim inn farger» bare vises når det er farger å lime inn.
@Observable
final class Utklippstavlevakt {
    static let delt = Utklippstavlevakt()
    private(set) var harFarger = false

    private init() {
        #if canImport(UIKit)
        oppdater()
        // Endringer i appen, og når man kommer tilbake fra en annen app som kan ha kopiert noe.
        for navn in [UIPasteboard.changedNotification, UIApplication.didBecomeActiveNotification] {
            NotificationCenter.default.addObserver(forName: navn, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.oppdater() }
            }
        }
        #endif
    }

    func oppdater() { harFarger = Utklippstavle.harFarger }
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
