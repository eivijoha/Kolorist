import FargeKjerne
import Foundation
import Observation
import SwiftUI

/// Brukerens oppsett av panelene: rekkefølge per skjerm, hvilke paneler som er lagt sammen, og hvilke
/// fargeverdier som er skjult under «Verdier». Lagres i iCloud (nøkkel–verdi) og synkroniseres mellom
/// enhetene, med en lokal kopi når iCloud ikke er tilgjengelig.
@MainActor
@Observable
final class Panelinnstillinger {
    static let delt = Panelinnstillinger()

    /// Skjermene som har tilpassbare paneler, med panelene i standardrekkefølge.
    enum Skjerm: String, CaseIterable {
        case studioFarge, kontrast, overgang

        var paneler: [Panel] {
            switch self {
            case .studioFarge: [.fargemodell, .verdier, .fargestyring, .lys]
            case .kontrast: [.wcag, .lrv]
            case .overgang: [.overgangstoner, .lysereMørkere, .gradient]
            }
        }
    }

    enum Panel: String, CaseIterable, Identifiable {
        case fargemodell, verdier, fargestyring, lys, wcag, lrv, overgangstoner, lysereMørkere, gradient
        var id: String { rawValue }

        var navn: String {
            switch self {
            case .fargemodell: String(localized: "Fargemodell")
            case .verdier: String(localized: "Verdier")
            case .fargestyring: String(localized: "Fargestyring (ICC)")
            case .lys: String(localized: "Se i lys")
            case .wcag: String(localized: "Tekst og grafikk (WCAG 2.2)")
            case .lrv: String(localized: "Flater (LRV)")
            case .overgangstoner: String(localized: "Overgang")
            case .lysereMørkere: String(localized: "Lysere og mørkere toner")
            case .gradient: String(localized: "Gradient")
            }
        }
    }

    /// Radene under «Verdier» som kan skjules.
    enum Verdi: Hashable, Identifiable {
        case hex, modell(Fargemodell), lrv, gamut
        var id: String {
            switch self {
            case .hex: "hex"
            case .modell(let m): m.rawValue
            case .lrv: "lrv"
            case .gamut: "gamut"
            }
        }
        var navn: String {
            switch self {
            case .hex: "Hex"
            case .modell(let m): m.navn
            case .lrv: "LRV"
            case .gamut: String(localized: "Gamut")
            }
        }
        static var alle: [Verdi] { [.hex] + Fargemodell.allCases.map { .modell($0) } + [.lrv, .gamut] }
    }

    private(set) var rekkefølger: [String: [String]] = [:]
    private(set) var lagtSammen: Set<String> = []
    private(set) var skjulteVerdier: Set<String> = []
    private(set) var verdirekkefølge: [String] = []

    private let lager = SkyLager.delt
    private enum Nøkkel {
        static let rekkefølge = "paneler.rekkefølge"
        static let lagtSammen = "paneler.lagtSammen"
        static let skjulteVerdier = "verdier.skjult"
        static let verdirekkefølge = "verdier.rekkefølge"
    }

    private init() {
        // Skjermbilder (Debug): standardoppsettet, uten å lese brukerens synkroniserte oppsett.
        guard !lager.skjermbildemodus else { return }
        last()
        lager.vedEndring { [weak self] in self?.last() }
    }

    // MARK: - Oppslag

    /// Panelene i brukerens rekkefølge. Nye paneler (fra en nyere versjon) legges til sist.
    func paneler(for skjerm: Skjerm) -> [Panel] {
        let lagret = (rekkefølger[skjerm.rawValue] ?? []).compactMap(Panel.init(rawValue:)).filter(skjerm.paneler.contains)
        var paneler = lagret + skjerm.paneler.filter { !lagret.contains($0) }
        #if DEBUG
        // Skjermbilder: `-panelFørst lys` legger et panel øverst.
        if let først = UserDefaults.standard.string(forKey: "panelFørst").flatMap(Panel.init(rawValue:)),
           let i = paneler.firstIndex(of: først) {
            paneler.insert(paneler.remove(at: i), at: 0)
        }
        #endif
        return paneler
    }

    /// Alle verdiene (viste og skjulte) i brukerens rekkefølge. Nye verdier legges til sist.
    var verdier: [Verdi] {
        let alle = Verdi.alle
        let lagret = verdirekkefølge.compactMap { id in alle.first { $0.id == id } }
        return lagret + alle.filter { !lagret.contains($0) }
    }

    func flyttVerdier(fra kilde: IndexSet, til mål: Int) {
        var v = verdier.map(\.id)
        v.move(fromOffsets: kilde, toOffset: mål)
        verdirekkefølge = v
        lagre()
    }

    func erLagtSammen(_ panel: Panel) -> Bool { lagtSammen.contains(panel.rawValue) }
    func viser(_ verdi: Verdi) -> Bool { !skjulteVerdier.contains(verdi.id) }

    // MARK: - Endringer

    func flytt(_ skjerm: Skjerm, fra kilde: IndexSet, til mål: Int) {
        var p = paneler(for: skjerm).map(\.rawValue)
        p.move(fromOffsets: kilde, toOffset: mål)
        rekkefølger[skjerm.rawValue] = p
        lagre()
    }

    func veksle(_ panel: Panel) { settLagtSammen(panel, !erLagtSammen(panel)) }

    func settLagtSammen(_ panel: Panel, _ sammen: Bool) {
        if sammen { lagtSammen.insert(panel.rawValue) } else { lagtSammen.remove(panel.rawValue) }
        lagre()
    }

    func settViser(_ verdi: Verdi, _ vis: Bool) {
        if vis { skjulteVerdier.remove(verdi.id) } else { skjulteVerdier.insert(verdi.id) }
        lagre()
    }

    func tilbakestill(_ skjerm: Skjerm) {
        rekkefølger[skjerm.rawValue] = nil
        for p in skjerm.paneler { lagtSammen.remove(p.rawValue) }
        if skjerm == .studioFarge { skjulteVerdier = []; verdirekkefølge = [] }
        lagre()
    }

    // MARK: - Lagring

    private func last() {
        func les<T>(_ nøkkel: String) -> T? { lager.verdi(nøkkel) as? T }
        rekkefølger = les(Nøkkel.rekkefølge) ?? [:]
        lagtSammen = Set(les(Nøkkel.lagtSammen) as [String]? ?? [])
        skjulteVerdier = Set(les(Nøkkel.skjulteVerdier) as [String]? ?? [])
        verdirekkefølge = les(Nøkkel.verdirekkefølge) ?? []
    }

    private func lagre() {
        lager.skriv([
            (Nøkkel.rekkefølge, rekkefølger),
            (Nøkkel.lagtSammen, Array(lagtSammen).sorted()),
            (Nøkkel.skjulteVerdier, Array(skjulteVerdier).sorted()),
            (Nøkkel.verdirekkefølge, verdirekkefølge),
        ])
    }
}
