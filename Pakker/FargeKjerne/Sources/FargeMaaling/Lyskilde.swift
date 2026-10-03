import FargeKjerne
import Foundation

/// En lyskilde: standardlys, sortlegeme, dagslys ved en fargetemperatur, et målt spekter, eller bare et
/// hvitpunkt (når bare kromatisiteten er kjent, f.eks. fra kameraets hvitbalanse).
public enum Lyskilde: Hashable, Codable, Sendable {
    case d65
    case d50
    /// CIE standardlys A (glødelampe, 2856 K).
    case a
    /// CIE dagslysserien ved en fargetemperatur (4000–25 000 K).
    case dagslys(kelvin: Double)
    /// Plancks sortlegeme (glødelys, halogen, levende lys).
    case sortlegeme(kelvin: Double)
    /// En CIE-tabulert lyskilde (lysrør FL2/FL7/FL11, LED-B1…B5, LED-BH1, LED-RGB1, LED-V1, LED-V2).
    case cie(String)
    /// Et målt eller importert spekter.
    case spekter(Spektrum)
    /// Bare kromatisiteten er kjent.
    case hvitpunkt(x: Double, y: Double)

    /// Lyskilder brukeren kan velge mellom, med de vanligste først.
    public static let forslag: [Lyskilde] = [
        .sortlegeme(kelvin: 2700), .a, .cie("LED-B2"), .cie("FL11"), .cie("LED-B3"), .cie("FL2"), .d50,
        .cie("LED-B4"), .d65, .dagslys(kelvin: 7500),
    ]

    /// Spekteret, når det er kjent.
    public var spektrum: Spektrum? {
        switch self {
        case .d65: Kolorimetri.dagslys(kelvin: 6504)
        case .d50: Kolorimetri.dagslys(kelvin: 5003)
        case .a: Kolorimetri.standardlysA
        case .dagslys(let k): Kolorimetri.dagslys(kelvin: k)
        case .sortlegeme(let k): Kolorimetri.sortlegeme(kelvin: k)
        case .cie(let navn): CIEData.delt.lyskilder[navn].map(CIEData.delt.spektrum)
        case .spekter(let s): s
        case .hvitpunkt: nil
        }
    }

    /// Hvitpunktet, med Y = 1.
    public var hvitpunkt: XYZ {
        switch self {
        // D65 og D50 som i resten av Kolorist (CSS Color 4), så et D65-lysmiljø gir nøyaktig samme farge.
        case .d65: Kolorimetri.xyz(x: 0.3127, y: 0.3290)
        case .d50: Kolorimetri.xyz(x: 0.3457, y: 0.3585)
        case .hvitpunkt(let x, let y): Kolorimetri.xyz(x: x, y: y)
        default: spektrum.map(Kolorimetri.xyz(lyskilde:)) ?? Kolorimetri.xyz(x: 0.3127, y: 0.3290)
        }
    }

    /// Korrelert fargetemperatur og Duv.
    public var fargetemperatur: (kelvin: Double, duv: Double)? {
        let p = Kolorimetri.xy(hvitpunkt)
        return Kolorimetri.fargetemperatur(x: p.x, y: p.y)
    }

    public var navn: String {
        switch self {
        case .d65: String(localized: "Dagslys D65", bundle: .module)
        case .d50: String(localized: "Dagslys D50", bundle: .module)
        case .a: String(localized: "Glødelampe (A)", bundle: .module)
        case .dagslys(let k): String(localized: "Dagslys \(Int(k.rounded())) K", bundle: .module)
        case .sortlegeme(let k): String(localized: "Glødelys \(Int(k.rounded())) K", bundle: .module)
        case .cie(let navn): Self.cieNavn[navn] ?? navn
        case .spekter: String(localized: "Målt spekter", bundle: .module)
        case .hvitpunkt:
            if let t = fargetemperatur { String(localized: "Lys \(Int(t.kelvin.rounded())) K", bundle: .module) }
            else { String(localized: "Eget hvitpunkt", bundle: .module) }
        }
    }

    private static let cieNavn: [String: String] = [
        "FL2": String(localized: "Lysrør, kaldhvitt (FL2)", bundle: .module),
        "FL7": String(localized: "Lysrør, bredbånd (FL7)", bundle: .module),
        "FL11": String(localized: "Lysrør, trebånd (FL11)", bundle: .module),
        "LED-B1": String(localized: "LED, varmhvit 2700 K (B1)", bundle: .module),
        "LED-B2": String(localized: "LED, varmhvit 3000 K (B2)", bundle: .module),
        "LED-B3": String(localized: "LED, nøytral 4000 K (B3)", bundle: .module),
        "LED-B4": String(localized: "LED, kaldhvit 5000 K (B4)", bundle: .module),
        "LED-B5": String(localized: "LED, kaldhvit 6500 K (B5)", bundle: .module),
        "LED-BH1": String(localized: "LED, blandet (BH1)", bundle: .module),
        "LED-RGB1": String(localized: "LED, RGB (RGB1)", bundle: .module),
        "LED-V1": String(localized: "LED, fiolett-pumpet (V1)", bundle: .module),
        "LED-V2": String(localized: "LED, fiolett-pumpet (V2)", bundle: .module),
    ]
}
