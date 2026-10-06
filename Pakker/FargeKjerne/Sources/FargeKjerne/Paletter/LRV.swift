import Foundation

// Lysrefleksjonsverdi (LRV) og flatekontrast, slik arkitekter og universell utforming bruker det.
// LRV er CIE-luminansen Y i prosent (0 = sort, 100 = referansehvitt), som på malingskart og i
// NS 11001 / BS 8300. Kontrasten mellom to flater regnes ulikt i ulike land og standarder, hver med egne krav
// (se `Flatekontrastmetode`): forskjell i LRV-poeng (BS 8300), Weber-kontrast med bakgrunnen som referanse
// (TEK17, NS 11001, Byggforsk 220.114) og Michelson-kontrast (ISO 21542). Tallene kan ikke sammenlignes på tvers.

public extension Farge {
    /// Lysrefleksjonsverdi 0…100: CIE Y relativt til referansehvitt, for fargen slik den vises i sRGB.
    var lrv: Double { klippet(til: .sRGB).luminans * 100 }
}

/// Hvordan kontrasten mellom to flater regnes ut. Hver metode har sine egne krav (`krav`).
public enum Flatekontrastmetode: String, CaseIterable, Codable, Sendable, Identifiable {
    /// Forskjell i LRV-poeng, |Y₁ − Y₂| (BS 8300-2:2018, Approved Document M).
    case lrvForskjell
    /// Weber-kontrast |Yo − Yb| / Yb, med bakgrunnen (hovedflaten) som referanse (TEK17, NS 11001, Byggforsk 220.114).
    /// Kan bli over 1 når en lys flate står mot en mørk bakgrunn.
    case weber
    /// Michelson-kontrast |Y₁ − Y₂| / (Y₁ + Y₂), 0…1 (ISO 21542:2021; kravene etter CAN-ASC-2.4).
    case michelson

    public var id: String { rawValue }

    public var navn: String {
        switch self {
        case .lrvForskjell: String(localized: "LRV-forskjell (BS 8300)", bundle: .module)
        case .weber: String(localized: "Luminanskontrast, Weber (TEK17, NS 11001)", bundle: .module)
        case .michelson: String(localized: "Luminanskontrast, Michelson (ISO 21542)", bundle: .module)
        }
    }

    public var formel: String {
        switch self {
        case .lrvForskjell: "|Y₁ − Y₂|"
        case .weber: "|Yo − Yb| / Yb"
        case .michelson: "|Y₁ − Y₂| / (Y₁ + Y₂)"
        }
    }

    /// Kravene som hører til metoden, mildeste først.
    public var krav: [Flatekrav] { Flatekrav.allCases.filter { $0.metode == self } }
}

/// Kontrast mellom to flater: `a` er flaten som vurderes (dør, list, ledelinje), `b` bakgrunnen eller hovedflaten.
public struct Flatekontrast: Sendable, Hashable {
    public let a: Farge
    public let b: Farge

    public init(_ a: Farge, _ b: Farge) {
        self.a = a
        self.b = b
    }

    /// Forskjell i LRV-poeng (0…100).
    public var lrvForskjell: Double { abs(a.lrv - b.lrv) }

    /// Michelson-kontrast (Y₁ − Y₂)/(Y₁ + Y₂), 0…1.
    public var michelson: Double { Self.michelson(a.lrv, b.lrv) }

    /// Weber-kontrast |Yo − Yb| / Yb med bakgrunnen `b` som referanse (norsk praksis etter TEK17 og NS 11001).
    public var weber: Double { Self.weber(objekt: a.lrv, bakgrunn: b.lrv) }

    /// Kontrasten etter valgt metode (LRV-poeng, eller Weber/Michelson som forholdstall).
    public func verdi(_ metode: Flatekontrastmetode) -> Double {
        switch metode {
        case .lrvForskjell: lrvForskjell
        case .weber: weber
        case .michelson: michelson
        }
    }

    /// Weber-kontrast for luminans- eller refleksjonsverdier. Bakgrunnen regnes som minst 0,5 (LRV), så helt sort
    /// bakgrunn ikke gir uendelig kontrast.
    public static func weber(objekt yo: Double, bakgrunn yb: Double) -> Double { abs(yo - yb) / max(yb, 0.5) }

    /// Michelson-kontrast for luminans- eller refleksjonsverdier.
    public static func michelson(_ y1: Double, _ y2: Double) -> Double { y1 + y2 > 0 ? abs(y1 - y2) / (y1 + y2) : 0 }

    public func består(_ krav: Flatekrav) -> Bool { verdi(krav.metode) >= krav.minimum }

    /// Justerer `a` i lyshet (OKLCH) til kravet er oppfylt, i retningen som krever minst endring.
    public func rettet(for krav: Flatekrav, gamut: Gamut = .displayP3) -> Farge {
        if består(krav) { return a }
        let lch = a.okLCH
        var beste: Farge?
        var minsteAvstand = Double.infinity
        for retning in [1.0, -1.0] {
            var l = lch.l
            for _ in 0..<80 {
                l += retning * 0.0125
                guard (0...1).contains(l) else { break }
                let kandidat = Farge(okLCH: OKLCH(l: l, c: lch.c, h: lch.h), alfa: a.alfa).gamutKartlagt(til: gamut)
                if Flatekontrast(kandidat, b).består(krav) {
                    let avstand = abs(l - lch.l)
                    if avstand < minsteAvstand { minsteAvstand = avstand; beste = kandidat }
                    break
                }
            }
        }
        return beste ?? (b.lrv > 50 ? Farge(lineærR: 0, g: 0, b: 0) : Farge(lineærR: 1, g: 1, b: 1))
    }
}

/// Krav til kontrast mellom flater i bygg, hvert knyttet til sin beregningsmetode.
public enum Flatekrav: String, CaseIterable, Sendable, Identifiable {
    /// BS 8300: 20 LRV-poeng kan godtas for store flater, eller der belysningen er over 200 lux.
    case lrv20
    /// BS 8300 / Approved Document M: minst 30 LRV-poeng mellom tilstøtende flater.
    case lrv30
    /// TEK17 (§ 12-6, § 12-9, § 12-13) og NS 11001: Weber-kontrast minst 0,4 for orientering og veifinning
    /// (ledelinjer, dør mot vegg, gulv og vegg i toalettrom).
    case luminans04
    /// TEK17 (§ 12-14) og NS 11001: Weber-kontrast minst 0,8 for fare: trappeneser, håndløper, fare- og
    /// oppmerksomhetsfelt.
    case luminans08
    /// Michelson-kontrast minst 30 % for store flater og orientering (ISO 21542, verdier etter CAN-ASC-2.4, matte flater).
    case michelson30
    /// Michelson-kontrast minst 60 % for fare, små elementer og tekst (ISO 21542, verdier etter CAN-ASC-2.4).
    case michelson60

    public var id: String { rawValue }

    public var metode: Flatekontrastmetode {
        switch self {
        case .lrv20, .lrv30: .lrvForskjell
        case .luminans04, .luminans08: .weber
        case .michelson30, .michelson60: .michelson
        }
    }

    /// Minsteverdien i metodens enhet (LRV-poeng, eller forholdstall 0…1 for Weber og Michelson).
    public var minimum: Double {
        switch self {
        case .lrv20: 20
        case .lrv30: 30
        case .luminans04: 0.4
        case .luminans08: 0.8
        case .michelson30: 0.3
        case .michelson60: 0.6
        }
    }

    public var navn: String {
        switch self {
        case .lrv20: String(localized: "Store flater eller over 200 lux, 20 LRV-poeng", bundle: .module)
        case .lrv30: String(localized: "Flater, 30 LRV-poeng", bundle: .module)
        case .luminans04: String(localized: "Orientering og veifinning, 0,4", bundle: .module)
        case .luminans08: String(localized: "Trapp, håndløper og farefelt, 0,8", bundle: .module)
        case .michelson30: String(localized: "Store flater og orientering, 30 %", bundle: .module)
        case .michelson60: String(localized: "Fare, små elementer og tekst, 60 %", bundle: .module)
        }
    }

    public var kilde: String {
        switch self {
        case .lrv20, .lrv30: "BS 8300"
        case .luminans04, .luminans08: "TEK17 · NS 11001"
        case .michelson30, .michelson60: "ISO 21542 · CAN-ASC-2.4"
        }
    }

    public var kravtekst: String {
        switch self {
        case .lrv20: String(localized: "minst 20 poeng forskjell i LRV", bundle: .module)
        case .lrv30: String(localized: "minst 30 poeng forskjell i LRV", bundle: .module)
        case .luminans04: String(localized: "luminanskontrast minst 0,4 mot bakgrunnen", bundle: .module)
        case .luminans08: String(localized: "luminanskontrast minst 0,8 mot bakgrunnen", bundle: .module)
        case .michelson30: String(localized: "luminanskontrast minst 30 %", bundle: .module)
        case .michelson60: String(localized: "luminanskontrast minst 60 %", bundle: .module)
        }
    }
}
