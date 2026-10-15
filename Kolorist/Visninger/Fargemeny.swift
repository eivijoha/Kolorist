import FargeKjerne
import SwiftData
import SwiftUI

/// Menyen for én farge (trykk og hold / høyreklikk), lik overalt. Valgene står i fast rekkefølge, og de som ikke gjelder,
/// utelates:
///
/// 1. Vis farge · Endre i Studio … · Gi navn … · i palett: Lag toneskala, Skriftfarge · valg som bare gjelder her
///    (`ekstraMeny`)
/// 2. Lagre som enkeltfarge · Legg i palett … · Flytt til (etter `Fargeplass`)
/// 3. Kopier til · Del som lenke · Kopier verdier · Kopier hex · Kopier som · Del · kilden
/// 4. Vis i 3D …
/// 5. Slett farge
///
/// Med `boble` vises valgene i en boble ved prøven i stedet (lister på iPhone og iPad, se `FargeRute.valgBoble`).
struct Fargemeny: ViewModifier {
    let farge: Farge
    var navn: String? = nil
    var palettFarge: PalettFarge? = nil
    var plass: Fargeplass = .løs
    var lagre: ((Farge) -> Void)? = nil
    var leggIPalett: ((Farge) -> Void)? = nil
    var åpneIStudio: ((Farge) -> Void)? = { Arbeidsbenk.delt.visIStudio($0) }
    var endre: ((Farge) -> Void)? = nil
    var endreTittel: String? = nil
    var navngi: (() -> Void)? = nil
    var fjern: (() -> Void)? = nil
    var kopierVerdier: String? = nil
    var ekstraMeny: AnyView? = nil
    var vis3D: (() -> Void)? = nil
    var boble = false
    var bobleEkstra: ((@escaping () -> Void) -> AnyView)? = nil

    @Environment(\.modelContext) private var kontekst
    @State private var visValg = false
    @State private var endrerIStudio = false
    @State private var leggesIPalett: [PalettFarge]?
    @State private var navngis: PalettFarge?
    @State private var visSkala: PalettFarge?

    /// Fargen som palettfarge (med navn og opphav når den har det).
    private func somPalettFarge(_ f: Farge) -> PalettFarge {
        var pf = palettFarge ?? PalettFarge(navn: navn ?? "", farge: f)
        if pf.farge != f { pf = PalettFarge(navn: pf.navn, farge: f, opphav: pf.opphav) }
        return pf
    }

    /// «Lagre som enkeltfarge»: egen handling, ellers for farger som ikke er lagret.
    private var lagreHandling: ((Farge) -> Void)? {
        if let lagre { return lagre }
        guard case .løs = plass else { return nil }
        return { f in lagreEnkeltfarger([somPalettFarge(f)], i: kontekst) }
    }

    /// «Legg i palett …»: egen handling, ellers for farger som ikke er lagret og for enkeltfarger.
    private var leggIPalettHandling: ((Farge) -> Void)? {
        if let leggIPalett { return leggIPalett }
        switch plass {
        case .løs, .enkeltfarge: return { f in leggesIPalett = [somPalettFarge(f)] }
        case .palett, .lagret: return nil
        }
    }

    /// «Endre i Studio …»: egen handling, ellers for lagrede farger (i palett eller som enkeltfarge).
    private var endreHandling: ((Farge) -> Void)? {
        if let endre { return endre }
        guard let pf = palettFarge else { return nil }
        switch plass {
        case .palett(let dokument): return { ny in dokument.endreFarge(pf.id, til: ny, i: kontekst) }
        case .enkeltfarge: return { ny in endreEnkeltfarge(pf.id, til: ny, i: kontekst) }
        case .løs, .lagret: return nil
        }
    }

    /// «Gi navn …»: egen handling, ellers for lagrede farger.
    private var navngiHandling: (() -> Void)? {
        if let navngi { return navngi }
        guard let pf = palettFarge else { return nil }
        switch plass {
        case .palett, .enkeltfarge: return { navngis = pf }
        case .løs, .lagret: return nil
        }
    }

    /// «Slett farge»: egen handling, ellers for lagrede farger (med angresteg).
    private var fjernHandling: (() -> Void)? {
        if let fjern { return fjern }
        guard let pf = palettFarge else { return nil }
        switch plass {
        case .palett(let dokument):
            return { kontekst.angresteg("Slett farge") { dokument.farger.removeAll { $0.id == pf.id } } }
        case .enkeltfarge:
            return { kontekst.angresteg("Slett farge") { slettEnkeltfarge(pf.id, i: kontekst) } }
        case .løs, .lagret: return nil
        }
    }

    private func giNavn(_ navn: String, til pf: PalettFarge) {
        switch plass {
        case .palett(let dokument):
            var f = dokument.farger
            if let i = f.firstIndex(where: { $0.id == pf.id }) { f[i].navn = navn }
            dokument.farger = f
        case .enkeltfarge:
            navngiEnkeltfarge(pf.id, navn: navn, i: kontekst)
        case .løs, .lagret:
            break
        }
    }

    private var tilbyEnkeltfarger: Bool {
        if case .løs = plass { true } else { false }
    }

    func body(content: Content) -> some View {
        Group {
            if boble {
                content
                    .onLongPressGesture(minimumDuration: 0.35) { visValg = true }
                    .sensoryFeedback(.impact(weight: .medium), trigger: visValg) { _, ny in ny }
                    // Lukk boblen når ruten forsvinner, så den ikke blir hengende uten ruten den hørte til.
                    .onDisappear { visValg = false }
                    .popover(isPresented: $visValg, arrowEdge: .bottom) {
                        FargeValgBoble(farge: farge, navn: navn ?? "", palettFarge: somPalettFarge(farge),
                                       lagre: lagreHandling, leggIPalett: leggIPalettHandling,
                                       åpneIStudio: åpneIStudio, kilde: palettFarge?.kilde,
                                       ekstra: bobleEkstra?({ visValg = false })) { visValg = false }
                            .presentationCompactAdaptation(.popover)
                    }
                    .accessibilityAction(named: "Valg for fargen") { visValg = true }
            } else {
                content.contextMenu { menyvalg }
            }
        }
        .sheet(isPresented: Binding(get: { leggesIPalett != nil }, set: { if !$0 { leggesIPalett = nil } })) {
            VelgPalettArk(farger: leggesIPalett ?? [], tilbyEnkeltfarger: tilbyEnkeltfarger)
        }
        .sheet(item: $visSkala) { pf in
            if case .palett(let dokument) = plass {
                ToneskalaArk(grunnfarge: pf) { nye in dokument.farger += nye }
            }
        }
        .sheet(item: $navngis) { pf in
            NavngiArk(farge: pf) { navn in giNavn(navn, til: pf) }
        }
        .endreIStudio(tittel: endreTittel ?? navn.flatMap { $0.isEmpty ? nil : $0 } ?? farge.hex(), vises: $endrerIStudio,
                      farge: farge) { endreHandling?($0) }
    }

    @ViewBuilder private var menyvalg: some View {
        // 1. Se og endre.
        Section {
            if let åpneIStudio {
                Button("Vis farge", systemImage: "slider.horizontal.3") { åpneIStudio(farge) }
            }
            if endreHandling != nil {
                Button("Endre i Studio …", systemImage: "slider.horizontal.3") { endrerIStudio = true }
            }
            if let navngi = navngiHandling {
                Button("Gi navn …", systemImage: "character.cursor.ibeam", action: navngi)
            }
            // Fargene i en palett: toneskala (legges i paletten) og skriftfarge.
            if case .palett(let dokument) = plass, let palettFarge {
                Button("Lag toneskala", systemImage: "square.3.layers.3d") { visSkala = palettFarge }
                if !dokument.tekstfarger.isEmpty { SkriftfargeValgMeny(dokument: dokument, farge: palettFarge) }
            }
            if let ekstraMeny { ekstraMeny }
        }
        // 2. Lagre og ordne.
        Section {
            if let lagre = lagreHandling {
                Button("Lagre som enkeltfarge", systemImage: "plus.square") { lagre(farge) }
            }
            if let leggIPalett = leggIPalettHandling {
                Button("Legg i palett …", systemImage: "plus.square.on.square") { leggIPalett(farge) }
            }
            if case .palett(let dokument) = plass, let palettFarge {
                FlyttMeny(farge: palettFarge, fra: dokument)
            }
        }
        // 3. Kopiere og dele.
        Section {
            // Kopier til først (primærhandling), så deling, så øvrig kopiering. Enkeltfarger lagres ikke som fil.
            let pf = somPalettFarge(farge)
            KopierTilMeny(farger: [pf], navn: navn ?? "")
            DelSomLenke(navn: pf.navn.isEmpty ? farge.hex() : pf.navn) { Lenkedeling.farge(pf) }
            if let kopierVerdier {
                Button("Kopier verdier", systemImage: "doc.on.doc") { Utklippstavle.kopierTekst(kopierVerdier) }
            }
            KopierMeny(farge: farge)
            if let palettFarge { KildeMeny(farger: [palettFarge]) }
        }
        // 4. Vis i 3D (alltid sist før sletting).
        if let vis3D {
            Section { Button("Vis i 3D …", systemImage: "rotate.3d", action: vis3D) }
        }
        // 5. Slette.
        if let fjern = fjernHandling {
            Section {
                Button("Slett farge", systemImage: "trash", role: .destructive, action: fjern)
            }
        }
    }
}

extension View {
    /// Den felles fargemenyen på en visning som ikke er en `FargeRute` (f.eks. en hel rad med en farge).
    func fargemeny(_ farge: Farge, navn: String? = nil, palettFarge: PalettFarge? = nil, plass: Fargeplass = .løs,
                   kopierVerdier: String? = nil) -> some View {
        modifier(Fargemeny(farge: farge, navn: navn, palettFarge: palettFarge, plass: plass, kopierVerdier: kopierVerdier))
    }
}
