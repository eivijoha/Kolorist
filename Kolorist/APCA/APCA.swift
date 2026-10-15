// APCA – Accessible Perceptual Contrast Algorithm
//
// Implementation in Kolorist (iOS, iPadOS, macOS), used with permission from the copyright holder, Andrew Somers /
// Myndex Research. APCA™ is a trademark of Myndex. The implementation follows the base algorithm 0.0.98G-4g with the
// output clamp at approximately ±Lc 10, as in apca-w3 0.1.9 (https://github.com/Myndex/apca-w3), with the constants
// unchanged. We keep it in step with the current available version of APCA and update it regularly when a new version
// is published.
//
// This folder (Kolorist/APCA/) holds the complete implementation: this file is the algorithm itself, with reference
// values from apca-w3 that are checked in every debug build (`APCA.kontroller()`), and APCA+Kolorist.swift is how
// Kolorist uses it. The two files can be shared as they are for review.
//
// Norsk: APCA brukes med tillatelse fra rettighetshaver (Andrew Somers / Myndex Research). Implementasjonen følger
// gjeldende tilgjengelige versjon av APCA og oppdateres jevnlig når en ny versjon publiseres.

import Foundation

/// APCA 0.0.98G-4g (apca-w3 0.1.9): lightness contrast Lc for text on a background, about −108 … 106. Positive for dark
/// text on a light background, negative for light text on a dark background; 0 below the output clamp (|Lc| < 10).
nonisolated enum APCA {
    /// The APCA version this implementation follows. Checked against apca-w3 when a new version is published.
    static let versjon = "0.0.98G-4g (apca-w3 0.1.9)"

    // Constants from apca-w3 0.1.9 (SA98G), unchanged.
    static let mainTRC = 2.4
    static let sRco = 0.2126729, sGco = 0.7151522, sBco = 0.0721750
    static let normBG = 0.56, normTXT = 0.57, revTXT = 0.62, revBG = 0.65
    static let blkThrs = 0.022, blkClmp = 1.414
    static let scaleBoW = 1.14, scaleWoB = 1.14
    static let loBoWoffset = 0.027, loWoBoffset = 0.027
    static let deltaYmin = 0.0005, loClip = 0.1

    /// Screen luminance Y from sRGB components 0 … 1 (as `sRGBtoY` in apca-w3: simple exponent, no linear segment).
    static func y(r: Double, g: Double, b: Double) -> Double {
        func kanal(_ c: Double) -> Double { pow(min(max(c, 0), 1), mainTRC) }
        return sRco * kanal(r) + sGco * kanal(g) + sBco * kanal(b)
    }

    /// Lc for text with luminance `tekst` on a background with luminance `bakgrunn` (as `APCAcontrast` in apca-w3).
    static func lc(tekst: Double, bakgrunn: Double) -> Double {
        // Soft clamp near black.
        let txtY = tekst > blkThrs ? tekst : tekst + pow(blkThrs - tekst, blkClmp)
        let bgY = bakgrunn > blkThrs ? bakgrunn : bakgrunn + pow(blkThrs - bakgrunn, blkClmp)
        guard abs(bgY - txtY) >= deltaYmin else { return 0 }
        if bgY > txtY {
            // Normal polarity: dark text on a light background (BoW).
            let sapc = (pow(bgY, normBG) - pow(txtY, normTXT)) * scaleBoW
            return sapc < loClip ? 0 : (sapc - loBoWoffset) * 100
        } else {
            // Reverse polarity: light text on a dark background (WoB).
            let sapc = (pow(bgY, revBG) - pow(txtY, revTXT)) * scaleWoB
            return sapc > -loClip ? 0 : (sapc + loWoBoffset) * 100
        }
    }

    /// Lc for sRGB hex colours, e.g. `lc(tekst: "#888888", bakgrunn: "#FFFFFF")` = 63.056… (8-bit, as in apca-w3).
    static func lc(tekst: String, bakgrunn: String) -> Double? {
        guard let t = komponenter(tekst), let b = komponenter(bakgrunn) else { return nil }
        return lc(tekst: y(r: t.0, g: t.1, b: t.2), bakgrunn: y(r: b.0, g: b.1, b: b.2))
    }

    private static func komponenter(_ hex: String) -> (Double, Double, Double)? {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        return (Double(v >> 16 & 0xFF) / 255, Double(v >> 8 & 0xFF) / 255, Double(v & 0xFF) / 255)
    }

    /// Reference values (text, background, Lc) from the apca-w3 documentation.
    static let referanser: [(tekst: String, bakgrunn: String, lc: Double)] = [
        ("#888888", "#FFFFFF", 63.056469930209424),
        ("#FFFFFF", "#888888", -68.54146436644962),
        ("#000000", "#AAAAAA", 58.146262578561334),
        ("#AAAAAA", "#000000", -56.24113336839742),
        ("#112233", "#DDEEFF", 91.66830811481631),
        ("#DDEEFF", "#112233", -93.06770049484275),
    ]

    /// True when every reference value is reproduced (to 1e-9). Asserted at launch in debug builds.
    static func kontroller() -> Bool {
        referanser.allSatisfy { r in lc(tekst: r.tekst, bakgrunn: r.bakgrunn).map { abs($0 - r.lc) < 1e-9 } ?? false }
    }
}
