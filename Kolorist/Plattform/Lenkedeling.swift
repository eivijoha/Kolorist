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
    /// Åpner en lenke fra Kolorist (universell lenke eller `kolorist://`). Uten visningstilstand: innholdet vises i et ark.
    /// Med visningstilstand: appen åpnes i fanen og modusen lenken ber om, og innholdet tas i bruk direkte hvis lenken sier
    /// det (aktiv farge, harmoni, overgang) – paletter vises alltid i ark. Ingenting lagres av seg selv.
    func åpneLenke(_ url: URL) {
        do {
            let innhold = try Delingslenke.les(url)
            guard let visning = innhold.visning else {
                mottattLenke = MottattLenke(innhold: innhold)
                return
            }
            if visning.bruk == true, innhold.slag != .palett {
                bruk(innhold)
            } else {
                mottattLenke = MottattLenke(innhold: innhold)
            }
            anvend(visning)
        } catch Delingslenke.Feil.ikkeKoloristlenke {
            return
        } catch {
            lenkefeil = String(localized: "Lenken kunne ikke leses. Den kan være avkortet, eller laget med en nyere versjon av Kolorist.")
        }
    }

    /// Tar delt innhold i bruk uten å lagre: en farge blir aktiv farge i Studio, en harmoni åpnes i Harmoni, en gradient i
    /// Overgang.
    func bruk(_ innhold: DeltInnhold) {
        switch innhold.slag {
        case .harmoni:
            if let h = innhold.harmoni { åpneHarmoni(h) }
        case .gradient:
            if let g = innhold.gradienter.first { åpne(Lenkedeling.oppsett(g, standardtrinn: lyshetstrinn)) }
        case .farge, .palett:
            if let f = innhold.farger.first {
                aktivFarge = f.farge
                valgtFane = .studio
            }
        case nil:
            break
        }
    }

    /// Åpner en delt harmoni i Studio › Harmoni med samme oppsett (harmoni, sirkel, antall, vinkel, lyshetsrekkefølge).
    func åpneHarmoni(_ h: DeltHarmoni) {
        let d = UserDefaults.standard
        if let harmoni = Harmoni(rawValue: h.harmoni) { d.set(harmoni.rawValue, forKey: "harmoni") }
        if let sirkel = Fargesirkel(rawValue: h.sirkel) { d.set(sirkel.rawValue, forKey: "harmoniSirkel") }
        if let antall = h.antall { d.set(antall, forKey: "harmoniAntall") }
        if let vinkel = h.vinkel { d.set(vinkel, forKey: "harmoniVinkel") }
        d.set((h.lyshetsrekkefølge.flatMap(Lyshetsrekkefølge.init(rawValue:)) ?? .lik).rawValue, forKey: "harmoniLyshetsrekkefølge")
        d.set("harmoni", forKey: "studioModus")
        aktivFarge = h.grunn.farge
        valgtFane = .studio
    }

    /// Visningstilstanden fra en lenke: fane, modus i Studio, fargemodell, del av Vurdering (med bakgrunn i
    /// kontrastsjekken; forgrunnen er aktiv farge) og presentasjonsmodus. Verdier appen ikke kjenner, ignoreres.
    func anvend(_ v: DeltVisning) {
        let d = UserDefaults.standard
        if let m = v.studiomodus.flatMap(FargeEditor.Modus.init(rawValue:)) { d.set(m.rawValue, forKey: "studioModus") }
        if let modell = v.fargemodell.flatMap(Fargemodell.init(rawValue:)), Fargemodell.redigerbare.contains(modell) { self.modell = modell }
        if let del = v.vurdering.flatMap(VurderingVisning.Del.init(rawValue:)) { d.set(del.rawValue, forKey: "vurderingDel") }
        if let b = v.bakgrunn?.farge { d.set(Kontrastbakgrunn.tekst(b), forKey: "kontrastBakgrunn") }
        if let fane = v.fane.flatMap(Fane.init(rawValue:)) { valgtFane = fane }
        if let p = v.presentasjon { presentasjon = p }
    }
}
