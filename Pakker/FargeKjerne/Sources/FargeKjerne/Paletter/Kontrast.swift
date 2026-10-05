import Foundation

public extension Farge {
    /// WCAG 2.x kontrastforhold (1…21), beregnet på sRGB-klippet luminans.
    func wcagKontrast(mot annen: Farge) -> Double {
        let a = klippet(til: .sRGB).luminans, b = annen.klippet(til: .sRGB).luminans
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// APCA-lyshetskontrast (Lc, ca. −108…106) for tekst i `tekst` oppå denne fargen (APCA 0.0.98G-4g, grunnlaget for
    /// WCAG 3). Positiv for mørk tekst på lys bakgrunn, negativ for lys tekst på mørk. Fargene gamut-kartlegges til sRGB.
    func apcaKontrast(tekst: Farge) -> Double {
        let ybg = Self.apcaLuminans(self), ytekst = Self.apcaLuminans(tekst)
        guard abs(ybg - ytekst) >= 0.0005 else { return 0 }
        if ybg > ytekst {
            let s = (pow(ybg, 0.56) - pow(ytekst, 0.57)) * 1.14
            return s < 0.1 ? 0 : (s - 0.027) * 100
        } else {
            let s = (pow(ybg, 0.65) - pow(ytekst, 0.62)) * 1.14
            return s > -0.1 ? 0 : (s + 0.027) * 100
        }
    }

    /// Passende tekstfarge (sort/hvit) oppå denne fargen: den med størst APCA-kontrast. APCA følger opplevd
    /// lesbarhet bedre enn WCAG 2, som velger sort tekst på for mange mellomtoner (skiller ved grått rundt #767676
    /// i stedet for rundt #9E9E9E).
    var lesbarTekstfarge: Farge {
        let hvit = Farge(lineærR: 1, g: 1, b: 1), sort = Farge(lineærR: 0, g: 0, b: 0)
        return abs(apcaKontrast(tekst: hvit)) >= abs(apcaKontrast(tekst: sort)) ? hvit : sort
    }

    /// APCAs skjermluminans: sRGB-verdier med enkel gamma 2,4, og myk klemming nær sort.
    private static func apcaLuminans(_ f: Farge) -> Double {
        let v = f.gamutKartlagt(til: .sRGB).sRGB
        let k = [v.r, v.g, v.b].map { pow(min(max($0, 0), 1), 2.4) }
        let y = 0.2126729 * k[0] + 0.7151522 * k[1] + 0.0721750 * k[2]
        return y < 0.022 ? y + pow(0.022 - y, 1.414) : y
    }
}
