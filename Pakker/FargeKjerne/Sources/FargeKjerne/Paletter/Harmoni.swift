import Foundation

/// Klassiske fargeharmonier: farger valgt ut fra kulørvinkler rundt fargesirkelen.
public enum Harmoni: String, CaseIterable, Codable, Sendable, Identifiable {
    /// Grunnfarge + motsatt kulør (180°).
    case komplementær
    /// Grunnfarge + de to naboene til komplementærfargen (180° ± vinkel).
    case splittKomplementær
    /// Naboer på samme side av sirkelen, med `vinkel` mellom hver.
    case analog
    /// `antall` farger jevnt fordelt rundt sirkelen (3 = triade, 4 = tetrade, 5 = pentade …).
    case jevn
    /// To komplementærpar (rektangel): 0°, vinkel, 180°, 180° + vinkel.
    case dobbeltKomplementær

    public var id: String { rawValue }

    public var navn: String {
        switch self {
        case .komplementær: String(localized: "Komplementær", bundle: .module)
        case .splittKomplementær: String(localized: "Split-komplementær", bundle: .module)
        case .analog: String(localized: "Analog", bundle: .module)
        case .jevn: String(localized: "Jevn fordeling", bundle: .module)
        case .dobbeltKomplementær: String(localized: "Dobbelt komplementær", bundle: .module)
        }
    }

    /// Om harmonien bruker valgfritt antall farger.
    public var harAntall: Bool { self == .jevn || self == .analog }
    /// Om harmonien bruker en valgfri vinkel.
    public var harVinkel: Bool { self == .splittKomplementær || self == .analog || self == .dobbeltKomplementær }

    public var standardVinkel: Double {
        switch self {
        case .splittKomplementær: 30
        case .analog: 30
        case .dobbeltKomplementær: 60
        default: 0
        }
    }

    /// Kulørforskyvninger i grader relativt til grunnfargen.
    public func forskyvninger(antall: Int = 3, vinkel: Double? = nil) -> [Double] {
        let v = vinkel ?? standardVinkel
        switch self {
        case .komplementær: return [0, 180]
        case .splittKomplementær: return [0, 180 - v, 180 + v]
        case .dobbeltKomplementær: return [0, v, 180, 180 + v]
        case .jevn:
            let n = max(antall, 2)
            return (0..<n).map { Double($0) * 360 / Double(n) }
        case .analog:
            // Symmetrisk rundt grunnfargen: -v, 0, +v (og videre utover for flere farger).
            let n = max(antall, 2)
            return (0..<n).map { (Double($0) - Double(n - 1) / 2) * v }
        }
    }
}

/// Hvilken fargesirkel kulørvinklene måles i. Valget avgjør hva som er «motsatt» farge.
public enum Fargesirkel: String, CaseIterable, Codable, Sendable, Identifiable {
    /// OKLCH: perseptuelt jevne vinkler; lyshet og kroma holdes fast, så fargene veier likt.
    case okLCH
    /// CIE LCH (D50): Lab-basert, som i Photoshop og fargemålingsverktøy.
    case cieLCH
    /// HSL-sirkelen fra RGB – skjermsirkelen i de fleste designverktøy (blå ↔ gul).
    case hsl
    /// RYB – kunstnersirkelen (Itten): rød ↔ grønn, gul ↔ fiolett, blå ↔ oransje.
    case ryb
    /// Munsell: ti hovedkulører (R, YR, Y, GY, G, BG, B, PB, P, RP) i like store opplevde steg, fra
    /// renotasjonsdataene. Komplementærparene følger Munsell (5R ↔ 5BG, 5Y ↔ 5PB), ikke Lab-vinkelen.
    case munsell
    /// Herings motfargesirkel: de fire elementærfargene gul, rød, blå og grønn i hver sin kvart (0°, 90°,
    /// 180°, 270°), så gul ↔ blå og rød ↔ grønn er motfarger. Kulørene mellom dem interpoleres i OKLCH.
    case hering

    public var id: String { rawValue }

    public var navn: String {
        switch self {
        case .okLCH: String(localized: "OKLCH (perseptuell)", bundle: .module)
        case .cieLCH: String(localized: "CIE LCH (Lab)", bundle: .module)
        case .hsl: String(localized: "HSL (RGB-skjerm)", bundle: .module)
        case .ryb: String(localized: "RYB (kunstnersirkel)", bundle: .module)
        case .munsell: "Munsell"
        case .hering: String(localized: "Hering (motfarger)", bundle: .module)
        }
    }

    public var forklaring: String {
        switch self {
        case .okLCH: String(localized: "Perseptuelt like vinkler, og lyshet og metning holdes fast, så fargene veier likt.", bundle: .module)
        case .cieLCH: String(localized: "Lab-basert sirkel, som i Photoshop og fargemåling. Lyshet og kroma holdes fast.", bundle: .module)
        case .hsl: String(localized: "Den tradisjonelle RGB-sirkelen fra skjermverden. Blå er komplementær til gul.", bundle: .module)
        case .ryb: String(localized: "Kunstnersirkelen med rød, gul og blå som primærfarger. Blå er komplementær til oransje.", bundle: .module)
        case .hering: String(localized: "Herings motfargesirkel med de fire elementærfargene gul, rød, blå og grønn i hver sin kvart. Gul er komplementær til blå og rød til grønn. Lyshet og metning holdes fast.", bundle: .module)
        case .munsell: String(localized: "Munsells sirkel med ti hovedkulører i like store opplevde steg, mye brukt i arkitektur og fargelære. Valør og kroma holdes fast; gul er komplementær til purpurblå.", bundle: .module)
        }
    }

    /// Faste kulørsteg i grader, eller `nil` for en sammenhengende sirkel. Munsell brukes i steg på 2,5
    /// (40 kulører rundt, 9°), som i Munsells fargekart – da får fargene gyldige notasjoner som 7.5PB.
    public var trinn: Double? { self == .munsell ? 9 : nil }

    /// Vinkelen rundet til nærmeste trinn (uendret for sammenhengende sirkler).
    public func avrundet(_ vinkel: Double) -> Double {
        guard let trinn else { return vinkel }
        return Harmoni.normaliser((vinkel / trinn).rounded() * trinn)
    }

    /// Fargens vinkel i denne sirkelen (grader).
    public func vinkel(for farge: Farge) -> Double {
        switch self {
        case .okLCH: farge.okLCH.h
        case .cieLCH: farge.cieLCH.h
        case .hsl: farge.hsl.h
        case .ryb: RYB.fraRGBKulør(farge.hsl.h)
        case .munsell: farge.munsell.kulør * 3.6
        case .hering: Hering.vinkel(forOKLCHKulør: farge.okLCH.h)
        }
    }

    /// Grunnfargen flyttet til en ny vinkel i denne sirkelen (lyshet/metning bevares i sirkelens rom).
    public func farge(_ grunn: Farge, vinkel: Double, gamut: Gamut = .displayP3) -> Farge {
        let v = Harmoni.normaliser(vinkel)
        switch self {
        case .okLCH:
            var lch = grunn.okLCH
            lch.h = v
            return Farge(okLCH: lch, alfa: grunn.alfa).gamutKartlagt(til: gamut)
        case .cieLCH:
            var lch = grunn.cieLCH
            lch.h = v
            return Farge(cieLCH: lch, alfa: grunn.alfa).gamutKartlagt(til: gamut)
        case .hsl:
            var hsl = grunn.hsl
            hsl.h = v
            return Farge(hsl: hsl, alfa: grunn.alfa)
        case .ryb:
            var hsl = grunn.hsl
            hsl.h = RYB.tilRGBKulør(v)
            return Farge(hsl: hsl, alfa: grunn.alfa)
        case .hering:
            var lch = grunn.okLCH
            lch.h = Hering.okLCHKulør(forVinkel: v)
            return Farge(okLCH: lch, alfa: grunn.alfa).gamutKartlagt(til: gamut)
        case .munsell:
            var m = grunn.munsell
            m.kulør = avrundet(v) / 3.6
            // Valør og kroma beholdes; kroma senkes bare der kuløren ikke når så høyt i renotasjonsdataene.
            return Farge.innenforMunsell(m, alfa: grunn.alfa, gamut: gamut) ?? grunn
        }
    }

    /// Farge for å tegne sirkelen ved en vinkel, med grunnfargens lyshet/metning der det gir mening.
    public func ringfarge(vinkel: Double, grunn: Farge) -> Farge {
        switch self {
        case .okLCH:
            let g = grunn.okLCH
            return Farge(okLCH: OKLCH(l: g.l, c: max(g.c, 0.08), h: vinkel)).gamutKartlagt(til: .displayP3)
        case .cieLCH:
            let g = grunn.cieLCH
            return Farge(cieLCH: CIELCH(l: g.l, c: max(g.c, 30), h: vinkel)).gamutKartlagt(til: .displayP3)
        case .hsl: return Farge(hsl: HSL(h: vinkel, s: 0.85, l: 0.55))
        case .ryb: return Farge(hsl: HSL(h: RYB.tilRGBKulør(vinkel), s: 0.85, l: 0.55))
        case .hering:
            let g = grunn.okLCH
            return Farge(okLCH: OKLCH(l: g.l, c: max(g.c, 0.08), h: Hering.okLCHKulør(forVinkel: vinkel))).gamutKartlagt(til: .displayP3)
        case .munsell:
            // Ekte Munsell-farger med grunnfargens valør og kroma (kroma senket der kuløren ikke når så høyt).
            var m = grunn.munsell
            m.kulør = avrundet(vinkel) / 3.6
            return Farge.innenforMunsell(m, gamut: .displayP3) ?? grunn
        }
    }
}

/// Stykkevis lineær avbildning mellom RYB-kunstnersirkelen og RGB/HSL-kulør.
/// Ankerpunkter (RYB → RGB): rød 0→0, oransje 60→35, gul 120→60, grønn 180→120,
/// blå 240→225, fiolett 300→275.
/// Avbildning mellom Herings motfargesirkel og OKLCH-kulør. Elementærfargene (unike kulører) er omtrentlige
/// verdier fra litteraturen om unik gul, rød, blå og grønn, regnet om til OKLCH. Mellom dem er avbildningen lineær,
/// og OKLCH-kuløren synker hele veien rundt (gul → oransje → rød → purpur → blå → turkis → grønn → gul).
public enum Hering {
    /// OKLCH-kulør for unik gul, rød, blå og grønn – i den rekkefølgen, på 0°, 90°, 180° og 270°.
    static let elementærfarger: [Double] = ["#FFD300", "#C40233", "#0087BD", "#009F6B"].map { Farge(hex: $0)!.okLCH.h }

    /// Ankerpunkter (sirkelvinkel, «utrullet» OKLCH-kulør) – kuløren trekkes fra 360 der det trengs, så den synker.
    private static let anker: [(vinkel: Double, kulør: Double)] = {
        var kulører: [Double] = []
        for h in elementærfarger + [elementærfarger[0]] {
            var k = h
            while let forrige = kulører.last, k >= forrige { k -= 360 }
            kulører.append(k)
        }
        return kulører.enumerated().map { (Double($0.offset) * 90, $0.element) }
    }()

    public static func okLCHKulør(forVinkel vinkel: Double) -> Double {
        let v = Harmoni.normaliser(vinkel)
        for (a, b) in zip(anker, anker.dropFirst()) where v >= a.vinkel && v <= b.vinkel {
            return Harmoni.normaliser(a.kulør + (v - a.vinkel) / 90 * (b.kulør - a.kulør))
        }
        return elementærfarger[0]
    }

    public static func vinkel(forOKLCHKulør kulør: Double) -> Double {
        // Finn segmentet der kuløren ligger (den synker fra a til b, med samme utrulling).
        for (a, b) in zip(anker, anker.dropFirst()) {
            var k = kulør
            while k > a.kulør { k -= 360 }
            while k < b.kulør { k += 360 }
            if k <= a.kulør && k >= b.kulør {
                return Harmoni.normaliser(a.vinkel + (a.kulør - k) / (a.kulør - b.kulør) * 90)
            }
        }
        return 0
    }
}

public enum RYB {
    static let anker: [(ryb: Double, rgb: Double)] = [(0, 0), (60, 35), (120, 60), (180, 120), (240, 225), (300, 275), (360, 360)]

    public static func tilRGBKulør(_ ryb: Double) -> Double {
        interpoler(Harmoni.normaliser(ryb), fra: \.ryb, til: \.rgb)
    }

    public static func fraRGBKulør(_ rgb: Double) -> Double {
        interpoler(Harmoni.normaliser(rgb), fra: \.rgb, til: \.ryb)
    }

    private static func interpoler(_ v: Double, fra: KeyPath<(ryb: Double, rgb: Double), Double>,
                                   til: KeyPath<(ryb: Double, rgb: Double), Double>) -> Double {
        for (a, b) in zip(anker, anker.dropFirst()) where v >= a[keyPath: fra] && v <= b[keyPath: fra] {
            let t = (v - a[keyPath: fra]) / (b[keyPath: fra] - a[keyPath: fra])
            return Harmoni.normaliser(a[keyPath: til] + t * (b[keyPath: til] - a[keyPath: til]))
        }
        return v
    }
}

public extension Harmoni {
    /// Fargene i harmonien, med grunnfargen først (for analog: i midten).
    func farger(fra grunnfarge: Farge, antall: Int = 3, vinkel: Double? = nil,
                sirkel: Fargesirkel = .okLCH, gamut: Gamut = .displayP3) -> [Farge] {
        let basis = sirkel.vinkel(for: grunnfarge)
        return forskyvninger(antall: antall, vinkel: vinkel).map { d in
            d == 0 ? grunnfarge : sirkel.farge(grunnfarge, vinkel: basis + d, gamut: gamut)
        }
    }

    internal static func normaliser(_ h: Double) -> Double {
        (h.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
    }
}
