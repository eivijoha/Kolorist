import FargeKjerne
import Foundation
import Observation
import SwiftUI

/// Brukerens oppsett av panelene: rekkefølge per skjerm, hvilke paneler som er lagt sammen eller åpnet, og hvilke
/// fargeverdier som er skjult under «Verdier». Lagres i iCloud (nøkkel–verdi) og synkroniseres mellom
/// enhetene, med en lokal kopi når iCloud ikke er tilgjengelig.
@MainActor
@Observable
final class Panelinnstillinger {
    static let delt = Panelinnstillinger()

    /// Skjermene som har tilpassbare paneler, med panelene i standardrekkefølge.
    enum Skjerm: String, CaseIterable {
        case studioFarge, kontrast, overgang, lys

        var paneler: [Panel] {
            switch self {
            case .studioFarge: [.fargemodell, .verdier, .fargestyring]
            case .kontrast: [.wcag, .lrv]
            case .overgang: [.overgangstoner, .lysereMørkere, .gradient]
            case .lys: [.fargeILys, .mineLysmiljøer, .lysmiljøer, .lysstandarder, .skjulteLysmiljøer]
            }
        }

        /// Studio/Farge har mange paneler: som standard er bare det øverste åpent, så panelene under synes.
        var bareØversteÅpent: Bool { self == .studioFarge }

        /// Paneler som er lagt sammen til brukeren åpner dem: i Lys de lange listene med innebygde lysmiljøer.
        var standardLagtSammen: Set<Panel> { self == .lys ? [.lysmiljøer, .lysstandarder, .skjulteLysmiljøer] : [] }
    }

    enum Panel: String, CaseIterable, Identifiable {
        case fargemodell, verdier, fargestyring, wcag, lrv, overgangstoner, lysereMørkere, gradient
        case fargeILys, mineLysmiljøer, lysmiljøer, lysstandarder, skjulteLysmiljøer
        var id: String { rawValue }

        var navn: String {
            switch self {
            case .fargemodell: String(localized: "Fargemodell")
            case .verdier: String(localized: "Verdier")
            case .fargestyring: String(localized: "Fargestyring (ICC)")
            case .wcag: String(localized: "Tekst og grafikk (WCAG 2.2)")
            case .lrv: String(localized: "Flater (LRV)")
            case .overgangstoner: String(localized: "Overgang")
            case .lysereMørkere: String(localized: "Lysere og mørkere toner")
            case .gradient: String(localized: "Gradient")
            case .fargeILys: String(localized: "Flere lysmiljøer")
            case .mineLysmiljøer: String(localized: "Mine lysmiljøer")
            case .lysmiljøer: String(localized: "Lysmiljøer")
            case .lysstandarder: String(localized: "Standarder")
            case .skjulteLysmiljøer: String(localized: "Skjulte lysmiljøer")
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
    /// Paneler brukeren har lagt sammen eller åpnet; andre følger skjermens standard.
    private(set) var lagtSammen: Set<String> = []
    private(set) var åpnet: Set<String> = []
    private(set) var skjulteVerdier: Set<String> = []
    private(set) var verdirekkefølge: [String] = []

    private let lager = SkyLager.delt
    private enum Nøkkel {
        static let rekkefølge = "paneler.rekkefølge"
        static let lagtSammen = "paneler.lagtSammen"
        static let åpnet = "paneler.åpnet"
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
        // Skjermbilder: `-panelFørst fargestyring` legger et panel øverst.
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

    func erLagtSammen(_ panel: Panel) -> Bool {
        if lagtSammen.contains(panel.rawValue) { return true }
        if åpnet.contains(panel.rawValue) { return false }
        guard let skjerm = Skjerm.allCases.first(where: { $0.paneler.contains(panel) }) else { return false }
        if skjerm.standardLagtSammen.contains(panel) { return true }
        return skjerm.bareØversteÅpent && paneler(for: skjerm).first != panel
    }
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
        if sammen {
            lagtSammen.insert(panel.rawValue); åpnet.remove(panel.rawValue)
        } else {
            lagtSammen.remove(panel.rawValue); åpnet.insert(panel.rawValue)
        }
        lagre()
    }

    func settViser(_ verdi: Verdi, _ vis: Bool) {
        if vis { skjulteVerdier.remove(verdi.id) } else { skjulteVerdier.insert(verdi.id) }
        lagre()
    }

    func tilbakestill(_ skjerm: Skjerm) {
        rekkefølger[skjerm.rawValue] = nil
        for p in skjerm.paneler { lagtSammen.remove(p.rawValue); åpnet.remove(p.rawValue) }
        if skjerm == .studioFarge { skjulteVerdier = []; verdirekkefølge = [] }
        lagre()
    }

    // MARK: - Lagring

    private func last() {
        func les<T>(_ nøkkel: String) -> T? { lager.verdi(nøkkel) as? T }
        rekkefølger = les(Nøkkel.rekkefølge) ?? [:]
        lagtSammen = Set(les(Nøkkel.lagtSammen) as [String]? ?? [])
        åpnet = Set(les(Nøkkel.åpnet) as [String]? ?? [])
        skjulteVerdier = Set(les(Nøkkel.skjulteVerdier) as [String]? ?? [])
        verdirekkefølge = les(Nøkkel.verdirekkefølge) ?? []
    }

    private func lagre() {
        lager.skriv([
            (Nøkkel.rekkefølge, rekkefølger),
            (Nøkkel.lagtSammen, Array(lagtSammen).sorted()),
            (Nøkkel.åpnet, Array(åpnet).sorted()),
            (Nøkkel.skjulteVerdier, Array(skjulteVerdier).sorted()),
            (Nøkkel.verdirekkefølge, verdirekkefølge),
        ])
    }
}
