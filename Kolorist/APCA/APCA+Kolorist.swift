// How Kolorist uses APCA (see APCA.swift for the algorithm, the licence note and the update policy).
//
// Identifiers and user-facing strings are in Norwegian, the app's source language; the English translations are in the
// app's string catalog and are given in comments here. Glossary: Farge = colour, tekst = text, bakgrunn = background,
// mål = target, minst = at least, nivå = level, bruk = use, retning = polarity, formatert = formatted,
// kobleInn = connect, lesbarhet = readability, Tekstvalg = text colour choice, Komponentsjekk = design-system check.
//
// - Assess › Contrast (Vurdering › Kontrast): Lc for the colour as text on the background, with APCA's guidance levels
//   (`APCANivå`) and «Fix» (Rett opp), which changes only the lightness (OKLCH) until a level is reached
//   (`Farge.medAPCA`).
// - Text and icons on colour fields (e.g. the [+] button): black or white, whichever has the higher |Lc|
//   (`APCA.kobleInn()` connects APCA to `Farge.lesbarTekstfarge` and `Skriftfarger.beste` in FargeKjerne). Where a
//   requirement applies (button text in the design system), WCAG 2 remains the floor.
// - The design system and tone scales show Lc next to the WCAG ratio.
//
// Colours are gamut-mapped to sRGB (CSS Color 4) before APCA is calculated, so wide-gamut colours get the Lc of the
// colour the screen shows in sRGB.

import FargeKjerne
import Foundation

nonisolated extension APCA {
    /// Lc for `tekst` on `bakgrunn` (both gamut-mapped to sRGB; a translucent text colour is composited first).
    static func lc(tekst: Farge, bakgrunn: Farge) -> Double {
        let t = tekst.lagtOver(bakgrunn).gamutKartlagt(til: .sRGB).sRGB
        let b = bakgrunn.gamutKartlagt(til: .sRGB).sRGB
        return lc(tekst: y(r: t.r, g: t.g, b: t.b), bakgrunn: y(r: b.r, g: b.g, b: b.b))
    }

    /// Lets FargeKjerne choose text colours on colour fields by APCA (higher |Lc| is better). Called once at launch.
    static func kobleInn() {
        Tekstvalg.lesbarhet = { tekst, bakgrunn in abs(APCA.lc(tekst: tekst, bakgrunn: bakgrunn)) }
    }
}

nonisolated extension Farge {
    /// Lc for `tekst` on this colour as background.
    func apcaKontrast(tekst: Farge) -> Double { APCA.lc(tekst: tekst, bakgrunn: self) }

    /// Adjusts the lightness (OKLCH) until |Lc| for this colour as text on `bakgrunn` reaches at least `mål`, in the
    /// direction that needs the smallest change. Hue and chroma are kept as far as the gamut allows. When the target can't
    /// be reached (e.g. Lc 90 on a mid tone), the result is black or white, whichever gives the most contrast.
    func medAPCA(mot bakgrunn: Farge, minst mål: Double) -> Farge {
        func lc(_ f: Farge) -> Double { abs(APCA.lc(tekst: f, bakgrunn: bakgrunn)) }
        if lc(self) >= mål { return self }
        let lch = okLCH
        var beste: Farge?
        var minsteAvstand = Double.infinity
        for retning in [1.0, -1.0] {
            var l = lch.l
            for _ in 0..<200 {
                l += retning * 0.005
                guard (0...1).contains(l) else { break }
                let kandidat = Farge(okLCH: OKLCH(l: l, c: lch.c, h: lch.h), alfa: alfa).gamutKartlagt(til: .displayP3)
                if lc(kandidat) >= mål {
                    let avstand = abs(l - lch.l)
                    if avstand < minsteAvstand { minsteAvstand = avstand; beste = kandidat }
                    break
                }
            }
        }
        if let beste { return beste }
        let hvit = Farge(lineærR: 1, g: 1, b: 1), sort = Farge(lineærR: 0, g: 0, b: 0)
        return lc(sort) >= lc(hvit) ? sort : hvit
    }
}

nonisolated extension Komponentsjekk {
    /// Lc for the pair in the design system.
    var lc: Double { APCA.lc(tekst: forgrunn, bakgrunn: bakgrunn) }
}

/// APCA's guidance levels for reading contrast (|Lc|), for text of normal weight.
enum APCANivå: Double, CaseIterable, Identifiable {
    case lc90 = 90, lc75 = 75, lc60 = 60, lc45 = 45, lc30 = 30, lc15 = 15
    var id: Double { rawValue }

    var bruk: String {
        switch self {
        case .lc90: String(localized: "Godt nok for all tekst, også brødtekst")   // Good enough for all text, including body text
        case .lc75: String(localized: "Brødtekst (minimum)")                       // Body text (minimum)
        case .lc60: String(localized: "Større tekst, ikke brødtekst")              // Larger text, not body text
        case .lc45: String(localized: "Store eller fete overskrifter")             // Large or bold headings
        case .lc30: String(localized: "Ikke-viktig tekst, som plassholdere")       // Non-essential text, such as placeholders
        case .lc15: String(localized: "Ikoner og grafikk, ikke tekst")             // Icons and graphics, not text
        }
    }

    /// The highest level Lc reaches, or nil when it is too low for text and graphics.
    static func nådd(_ lc: Double) -> APCANivå? { allCases.first { abs(lc) >= $0.rawValue } }

    /// «dark text on a light background» or «light text on a dark background».
    static func retning(_ lc: Double) -> String {
        lc >= 0 ? String(localized: "mørk tekst på lys bakgrunn") : String(localized: "lys tekst på mørk bakgrunn")
    }

    /// «Lc 75» – truncated towards zero, so the figure never shows a level that isn't reached (like the WCAG ratio).
    static func formatert(_ lc: Double) -> String {
        "Lc " + lc.rounded(.towardZero).formatted(.number.precision(.fractionLength(0)))
    }
}
