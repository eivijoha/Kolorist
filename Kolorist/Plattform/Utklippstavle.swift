import FargeKjerne
import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Kopiering etter plattformkonvensjon: ett element med både fargeobjekt
/// (limes inn som farge i Keynote, Pages, Figma m.fl.) og tekst (limes inn i kode).
enum Utklippstavle {
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
    }

    static func kopierTekst(_ tekst: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = tekst
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

/// «Lim inn farger»: aktiv bare når utklippstavlen har noe å lime inn.
///
/// iOS: systemets innlimingsknapp – den er aktiv når utklippstavlen har tekst, og trykket er tillatelsen, så iOS ikke
/// spør «Tillat innliming?». (Å sjekke om teksten er en farge før trykket ville utløst det spørsmålet hver gang.)
/// Mac: utklippstavlen kan leses fritt, så knappen er aktiv bare når den har gyldige farger.
struct LimInnFargerKnapp: View {
    var leggTil: ([PalettFarge]) -> Void
    @State private var ingenFarger = false
    #if os(macOS)
    @State private var harFarger = false
    @State private var endringstall = -1
    #endif

    var body: some View {
        knapp
            .alert("Ingen farger å lime inn", isPresented: $ingenFarger) {
                Button("OK") {}
            } message: {
                Text("Utklippstavlen inneholder ingen farger. Kopier hex-verdier, CSS-farger eller farger fra en annen palett.")
            }
    }

    @ViewBuilder private var knapp: some View {
        #if os(iOS)
        PasteButton(payloadType: String.self) { tekster in
            let farger = tekster.flatMap(Fargetolk.tolkListe)
            Task { @MainActor in
                if farger.isEmpty { ingenFarger = true } else { leggTil(farger) }
            }
        }
        .labelStyle(.iconOnly)
        .help("Lim inn farger")
        #else
        Button("Lim inn farger", systemImage: "doc.on.clipboard") {
            let farger = Utklippstavle.limInnListe()
            if farger.isEmpty { ingenFarger = true } else { leggTil(farger) }
        }
        .disabled(!harFarger)
        .help("Lim inn farger")
        // Sjekk utklippstavlen når den endres (billig: bare endringstallet leses hvert sekund).
        .task {
            while !Task.isCancelled {
                let tall = NSPasteboard.general.changeCount
                if tall != endringstall {
                    endringstall = tall
                    harFarger = !Utklippstavle.limInnListe().isEmpty
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
        #endif
    }
}
