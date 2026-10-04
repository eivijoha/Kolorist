import FargeKjerne
import Foundation
import SwiftUI

/// Deling som lenke (`https://kolorist.no/l#…`): fra appens typer til lenkeformatet i FargeKjerne, og tilbake.
/// Innholdet bygges først når brukeren deler (se `DelSomLenke`), ikke hver gang en meny tegnes.
nonisolated enum Lenkedeling {
    static func farge(_ pf: PalettFarge) -> DeltInnhold {
        DeltInnhold(slag: .farge, farger: [DeltFarge(pf)])
    }

    static func palett(navn: String, farger: [PalettFarge], gradienter: [PalettGradient]) -> DeltInnhold {
        DeltInnhold(slag: .palett, navn: navn, farger: farger.map(DeltFarge.init),
                    gradienter: gradienter.map { gradient($0.oppsett, navn: $0.navn) })
    }

    static func gradient(_ oppsett: Gradientoppsett, navn: String) -> DeltInnhold {
        DeltInnhold(slag: .gradient, gradienter: [gradient(oppsett, navn: navn)])
    }

    static func harmoni(_ harmoni: Harmoni, sirkel: Fargesirkel, grunn: Farge, farger: [Farge], antall: Int, vinkel: Double,
                        lyshetsrekkefølge: Lyshetsrekkefølge, grunnIndeks: Int?) -> DeltInnhold {
        DeltInnhold(slag: .harmoni, navn: harmoni.navn, farger: farger.map { DeltFarge($0) },
                    harmoni: DeltHarmoni(harmoni: harmoni, sirkel: sirkel, grunn: grunn,
                                         antall: harmoni.harAntall ? antall : nil, vinkel: harmoni.harVinkel ? vinkel : nil,
                                         lyshetsrekkefølge: lyshetsrekkefølge, grunnIndeks: grunnIndeks))
    }

    private static func gradient(_ oppsett: Gradientoppsett, navn: String) -> DeltGradient {
        DeltGradient(navn: navn, stopp: [DeltStopp(DeltFarge(oppsett.fra)), DeltStopp(DeltFarge(oppsett.til))],
                     antall: oppsett.antall, trinn: oppsett.trinn)
    }

    // MARK: Mottak

    /// Gradienter i appen har to stopp: første og siste brukes (flere stopp vises i forhåndsvisningen).
    static func oppsett(_ g: DeltGradient, standardtrinn: Lyshetstrinn) -> Gradientoppsett {
        Gradientoppsett(fra: g.stopp.first?.farge.farge ?? Farge(hex: "#808080")!,
                        til: g.stopp.last?.farge.farge ?? Farge(hex: "#808080")!,
                        antall: min(max(g.antall ?? 7, 2), 64), trinn: g.trinn?.lyshetstrinn ?? standardtrinn)
    }

    @MainActor static func harProfil(_ id: String) -> Bool { ProfilBibliotek.delt.profil(id: id) != nil }

    /// Fargene i en gradient med flere stopp, for forhåndsvisning: stoppene på sine plasser (eller jevnt fordelt).
    @MainActor static func stopp(_ g: DeltGradient) -> [Gradient.Stop] {
        let n = g.stopp.count
        return g.stopp.enumerated().map { i, s in
            Gradient.Stop(color: s.farge.farge.swiftUI, location: s.posisjon ?? (n > 1 ? Double(i) / Double(n - 1) : 0))
        }
    }
}

/// En mottatt lenke som venter på at brukeren bestemmer seg.
struct MottattLenke: Identifiable {
    let id = UUID()
    let innhold: DeltInnhold
}

extension Arbeidsbenk {
    /// Åpner en lenke fra Kolorist (universell lenke eller `kolorist://`): viser innholdet i et ark, lagrer ingenting.
    func åpneLenke(_ url: URL) {
        do {
            mottattLenke = MottattLenke(innhold: try Delingslenke.les(url))
        } catch Delingslenke.Feil.ikkeKoloristlenke {
            return
        } catch {
            lenkefeil = String(localized: "Lenken kunne ikke leses. Den kan være avkortet, eller laget med en nyere versjon av Kolorist.")
        }
    }
}
