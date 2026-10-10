import Foundation

/// Fargeharmonier: farger valgt ut fra kulørvinkler rundt fargesirkelen, eller toner av én kulør (monokrom).
/// Rekkefølgen går fra rolig til kontrastrik: én kulør, naboer, motsatte kulører og kulører jevnt rundt sirkelen
/// (se `grupper`).
public enum Harmoni: String, CaseIterable, Codable, Sendable, Identifiable {
    /// Én kulør i `antall` toner langs en strek i lyshet–metning-planet (`Monokromstrek`).
    case monokrom
    /// Som monokrom, men hvert endepunkt har sin egen kulør: tonene går i bue rundt kulørsirkelen (OKLCH), i valgt
    /// retning og opptil en hel runde, samtidig som lyshet og metning følger streken – en bane gjennom alle tre
    /// dimensjonene (`Monokromstrek.toner(fraKulør:spenn:)`).
    case tonebane
    /// Naboer på samme side av sirkelen, med `vinkel` mellom hver.
    case analog
    /// En analog gruppe (`antall` farger, `vinkel` mellom hver) og grunnfargens komplementærfarge som aksent.
    case analogMedAksent
    /// Grunnfarge + motsatt kulør (180°).
    case komplementær
    /// Grunnfarge + de to naboene til komplementærfargen (180° ± vinkel).
    case splittKomplementær
    /// To komplementærpar (rektangel): 0°, vinkel, 180°, 180° + vinkel.
    case dobbeltKomplementær
    /// Tre farger jevnt fordelt (0°, 120°, 240°).
    case triade
    /// Fire farger jevnt fordelt (0°, 90°, 180°, 270°).
    case kvadrat
    /// `antall` farger jevnt fordelt rundt sirkelen (5 = pentade …).
    case jevn

    /// Harmoniene i grupper, til valglister med skillelinjer: toner langs en strek (én kulør, eller en bue mellom to),
    /// naboer, motsatte kulører og kulører jevnt rundt sirkelen.
    public static let grupper: [[Harmoni]] = [
        [.monokrom, .tonebane],
        [.analog, .analogMedAksent],
        [.komplementær, .splittKomplementær, .dobbeltKomplementær],
        [.triade, .kvadrat, .jevn],
    ]

    public var id: String { rawValue }

    public var navn: String {
        switch self {
        case .komplementær: String(localized: "Komplementær", bundle: .module)
        case .splittKomplementær: String(localized: "Split-komplementær", bundle: .module)
        case .analog: String(localized: "Analog", bundle: .module)
        case .analogMedAksent: String(localized: "Analog med aksent", bundle: .module)
        case .triade: String(localized: "Triade", bundle: .module)
        case .kvadrat: String(localized: "Kvadrat", bundle: .module)
        case .dobbeltKomplementær: String(localized: "Dobbelt komplementær", bundle: .module)
        case .jevn: String(localized: "Jevn fordeling", bundle: .module)
        case .monokrom: String(localized: "Monokromatisk", bundle: .module)
        case .tonebane: String(localized: "Tonebane", bundle: .module)
        }
    }

    /// Om harmonien bruker valgfritt antall farger (for analog med aksent: antall i den analoge gruppen).
    public var harAntall: Bool { self == .jevn || self == .analog || self == .analogMedAksent || self == .monokrom || self == .tonebane }
    /// Om harmonien bruker en valgfri vinkel.
    public var harVinkel: Bool {
        self == .splittKomplementær || self == .analog || self == .analogMedAksent || self == .dobbeltKomplementær
    }

    /// Tillatt antall farger (se `harAntall`).
    public var antallOmråde: ClosedRange<Int> {
        switch self {
        case .jevn, .monokrom, .tonebane: 2...12
        case .analogMedAksent: 2...5
        default: 2...9
        }
    }

    public var standardVinkel: Double {
        switch self {
        case .splittKomplementær, .analog, .analogMedAksent: 30
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
        case .triade: return Self.jevnt(3)
        case .kvadrat: return Self.jevnt(4)
        case .jevn: return Self.jevnt(antall)
        case .analog: return Self.analog(antall, v)
        case .analogMedAksent: return Self.analog(antall, v) + [180]
        // Samme kulør for alle; tonene kommer fra `Monokromstrek`.
        case .monokrom, .tonebane: return Array(repeating: 0, count: max(antall, 2))
        }
    }

    private static func jevnt(_ antall: Int) -> [Double] {
        let n = max(antall, 2)
        return (0..<n).map { Double($0) * 360 / Double(n) }
    }

    /// Symmetrisk rundt grunnfargen: -v, 0, +v (og videre utover for flere farger).
    private static func analog(_ antall: Int, _ v: Double) -> [Double] {
        let n = max(antall, 2)
        return (0..<n).map { (Double($0) - Double(n - 1) / 2) * v }
    }
}

/// Lysheten i en harmoni. Med lik lyshet veier fargene likt; med naturlig rekkefølge følger lysheten kulørenes
/// egen lyshet slik vi kjenner den fra naturen – gult lysest, blått og fiolett mørkest (Judds prinsipp om
/// naturlig fargeorden) – noe som ofte oppleves som harmonisk. Omvendt rekkefølge gir bevisst spenning.
public enum Lyshetsrekkefølge: String, CaseIterable, Codable, Sendable, Identifiable {
    case lik, naturlig, omvendt

    public var id: String { rawValue }

    public var navn: String {
        switch self {
        case .lik: String(localized: "Lik", bundle: .module)
        case .naturlig: String(localized: "Naturlig", bundle: .module)
        case .omvendt: String(localized: "Omvendt", bundle: .module)
        }
    }

    /// Hvor mye av forskjellen i kulørenes egen lyshet som overføres (1 = hele, som de mest mettede fargene).
    static let styrke = 0.6

    /// Fargene med lysheten forskjøvet etter kulør, relativt til grunnfargens kulør: farger med grunnfargens kulør
    /// står urørt, også når grunnfargen selv ikke er med (analog med partall). Metningen beholdes som andel av det
    /// gamut tillater ved den nye lysheten.
    public func anvendt(på farger: [Farge], grunn: Farge, gamut: Gamut = .displayP3) -> [Farge] {
        guard self != .lik else { return farger }
        let retning = self == .naturlig ? 1.0 : -1.0
        let grunnKulørL = Farge.toppunktLyshet(kulør: grunn.okLCH.h, i: gamut)
        return farger.map { f in
            let lch = f.okLCH
            let forskyvning = retning * Self.styrke * (Farge.toppunktLyshet(kulør: lch.h, i: gamut) - grunnKulørL)
            guard abs(forskyvning) > 0.001 else { return f }
            let maks = Farge.maksKroma(lyshet: lch.l, kulør: lch.h, i: gamut)
            let andel = maks > 0 ? min(lch.c / maks, 1) : 0
            let l = min(max(lch.l + forskyvning, 0.15), 0.97)
            return Farge(okLCH: OKLCH(l: l, c: andel * Farge.maksKroma(lyshet: l, kulør: lch.h, i: gamut), h: lch.h), alfa: f.alfa)
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
    /// Herings motfargesirkel: de fire elementærfargene gul, rød, blå og grønn i hver sin kvart (0°, 90°,
    /// 180°, 270°), så gul ↔ blå og rød ↔ grønn er motfarger. Kulørene mellom dem interpoleres i OKLCH.
    case hering
    /// Goethes sirkel fra *Zur Farbenlehre* (1810): purpur, oransje, gul, grønn, blå og fiolett i hver sin sjettedel,
    /// så gul ↔ fiolett, blå ↔ oransje og purpur ↔ grønn er motfarger. Kulørene mellom dem interpoleres i OKLCH.
    case goethe

    public var id: String { rawValue }

    public var navn: String {
        switch self {
        case .okLCH: String(localized: "OKLCH (perseptuell)", bundle: .module)
        case .cieLCH: String(localized: "CIE LCH (Lab)", bundle: .module)
        case .hsl: String(localized: "HSL (RGB-skjerm)", bundle: .module)
        case .ryb: String(localized: "RYB (kunstnersirkel)", bundle: .module)
        case .hering: String(localized: "Hering (motfarger)", bundle: .module)
        case .goethe: String(localized: "Goethe (Farbenlehre)", bundle: .module)
        }
    }

    public var forklaring: String {
        switch self {
        case .okLCH: String(localized: "Perseptuelt like vinkler, og lyshet og metning holdes fast, så fargene veier likt.", bundle: .module)
        case .cieLCH: String(localized: "Lab-basert sirkel, som i Photoshop og fargemåling. Lyshet og kroma holdes fast.", bundle: .module)
        case .hsl: String(localized: "Den tradisjonelle RGB-sirkelen fra skjermverden. Blå er komplementær til gul.", bundle: .module)
        case .ryb: String(localized: "Kunstnersirkelen med rød, gul og blå som primærfarger. Blå er komplementær til oransje.", bundle: .module)
        case .hering: String(localized: "Herings motfargesirkel med de fire elementærfargene gul, rød, blå og grønn i hver sin kvart. Gul er komplementær til blå og rød til grønn. Lyshet og metning holdes fast.", bundle: .module)
        case .goethe: String(localized: "Goethes sirkel fra Farbenlehre (1810) med seks farger: purpur, oransje, gul, grønn, blå og fiolett. Gul er komplementær til fiolett, blå til oransje og purpur til grønn. Lyshet og metning holdes fast.", bundle: .module)
        }
    }

    /// Fargens plass i denne sirkelen som kort tekst, for fargefeltene i en harmoni: «OKLCH 59% 0.156 254°»,
    /// «LCH 55 48 254°», «HSL 254° 60% 52%», «RYB 210°» eller «70% gul, 30% rød» (Hering).
    /// Prosent skrives inntil tallet, som i fargefeltene ellers.
    public func verditekst(for farge: Farge) -> String {
        switch self {
        case .okLCH: return Fargemodell.okLCH.kortTekst(for: farge)
        case .cieLCH: return Fargemodell.cieLCH.kortTekst(for: farge)
        case .hsl: return Fargemodell.hsl.kortTekst(for: farge)
        case .ryb: return "RYB \(String(format: "%.0f", vinkel(for: farge)))°"
        case .hering: return Hering.sammensetning(vinkel: vinkel(for: farge))
        case .goethe: return Goethe.sammensetning(vinkel: vinkel(for: farge))
        }
    }

    /// Fargens vinkel i denne sirkelen (grader).
    public func vinkel(for farge: Farge) -> Double {
        switch self {
        case .okLCH: farge.okLCH.h
        case .cieLCH: farge.cieLCH.h
        case .hsl: farge.hsl.h
        case .ryb: RYB.fraRGBKulør(farge.hsl.h)
        case .hering: Hering.vinkel(forOKLCHKulør: farge.okLCH.h)
        case .goethe: Goethe.vinkel(forOKLCHKulør: farge.okLCH.h)
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
        case .goethe:
            var lch = grunn.okLCH
            lch.h = Goethe.okLCHKulør(forVinkel: v)
            return Farge(okLCH: lch, alfa: grunn.alfa).gamutKartlagt(til: gamut)
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
        case .goethe:
            let g = grunn.okLCH
            return Farge(okLCH: OKLCH(l: g.l, c: max(g.c, 0.08), h: Goethe.okLCHKulør(forVinkel: vinkel))).gamutKartlagt(til: .displayP3)
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

    /// Kuløren som andeler av de to nærmeste elementærfargene, f.eks. «70% gul, 30% rød».
    public static func sammensetning(vinkel: Double) -> String {
        let navn = [String(localized: "gul", bundle: .module), String(localized: "rød", bundle: .module),
                    String(localized: "blå", bundle: .module), String(localized: "grønn", bundle: .module)]
        let v = Harmoni.normaliser(vinkel)
        let i = Int(v / 90) % 4
        let andel = Int(((v - Double(i) * 90) / 90 * 100).rounded())
        if andel < 5 { return navn[i].capitalized }
        if andel > 95 { return navn[(i + 1) % 4].capitalized }
        return String(localized: "\(100 - andel)% \(navn[i]), \(andel)% \(navn[(i + 1) % 4])", bundle: .module)
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

/// Goethes sirkel (*Zur Farbenlehre*, 1810): seks farger i like store sjettedeler – purpur (0°), oransje («gelbrot»,
/// 60°), gul (120°), grønn (180°), blå (240°) og fiolett («blaurot», 300°). Motfargene står rett overfor hverandre.
/// Kulørene er tolket som OKLCH-kulører for typiske utgaver av de seks fargene, og kulørene mellom dem interpoleres
/// stykkevis lineært – en avbildning laget for appen, ikke målt fra Goethes egne akvareller.
public enum Goethe {
    /// OKLCH-kulør for purpur, oransje, gul, grønn, blå og fiolett – i den rekkefølgen, på 0°, 60° … 300°.
    static let farger: [Double] = ["#C2185B", "#EF6C00", "#F9D71C", "#2E9E44", "#1E63B5", "#6A3D9A"].map { Farge(hex: $0)!.okLCH.h }

    /// Ankerpunkter (sirkelvinkel, «utrullet» OKLCH-kulør) – kuløren legges til 360 der det trengs, så den stiger.
    private static let anker: [(vinkel: Double, kulør: Double)] = {
        var kulører: [Double] = []
        for h in farger + [farger[0]] {
            var k = h
            while let forrige = kulører.last, k <= forrige { k += 360 }
            kulører.append(k)
        }
        return kulører.enumerated().map { (Double($0.offset) * 60, $0.element) }
    }()

    public static func okLCHKulør(forVinkel vinkel: Double) -> Double {
        let v = Harmoni.normaliser(vinkel)
        for (a, b) in zip(anker, anker.dropFirst()) where v >= a.vinkel && v <= b.vinkel {
            return Harmoni.normaliser(a.kulør + (v - a.vinkel) / 60 * (b.kulør - a.kulør))
        }
        return farger[0]
    }

    public static func vinkel(forOKLCHKulør kulør: Double) -> Double {
        for (a, b) in zip(anker, anker.dropFirst()) {
            var k = kulør
            while k < a.kulør { k += 360 }
            while k > b.kulør { k -= 360 }
            if k >= a.kulør && k <= b.kulør {
                return Harmoni.normaliser(a.vinkel + (k - a.kulør) / (b.kulør - a.kulør) * 60)
            }
        }
        return 0
    }

    /// Kuløren som andeler av de to nærmeste av de seks fargene, f.eks. «70% gul, 30% grønn».
    public static func sammensetning(vinkel: Double) -> String {
        let navn = [String(localized: "purpur", bundle: .module), String(localized: "oransje", bundle: .module),
                    String(localized: "gul", bundle: .module), String(localized: "grønn", bundle: .module),
                    String(localized: "blå", bundle: .module), String(localized: "fiolett", bundle: .module)]
        let v = Harmoni.normaliser(vinkel)
        let i = Int(v / 60) % 6
        let andel = Int(((v - Double(i) * 60) / 60 * 100).rounded())
        if andel < 5 { return navn[i].capitalized }
        if andel > 95 { return navn[(i + 1) % 6].capitalized }
        return String(localized: "\(100 - andel)% \(navn[i]), \(andel)% \(navn[(i + 1) % 6])", bundle: .module)
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
