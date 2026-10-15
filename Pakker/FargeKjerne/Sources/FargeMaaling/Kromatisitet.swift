import FargeKjerne
import Foundation

/// CIE 1931-kromatisitet (xy, 2° standardobservatør) til kromatisitetsdiagram: spektralkurven, fargers xy og
/// forvirringslinjene for fargesynsavvik.
///
/// For dikromater ligger farger som ikke kan skilles fra hverandre (med passende lyshet), på rette linjer gjennom ett
/// punkt i diagrammet – kopunktet for avviket. Kopunktene er fra G. Wyszecki og W. S. Stiles, «Color Science» (2. utg.,
/// 1982), etter Pitt (1935) og Wright (1952).
public enum Kromatisitet {
    public struct Punkt: Sendable, Hashable {
        public let x: Double
        public let y: Double
        public init(x: Double, y: Double) { self.x = x; self.y = y }
    }

    /// Spektralkurven: enkeltbølgelengder 380–700 nm i steg på 5 nm.
    public static let spektralkurve: [(nm: Double, punkt: Punkt)] = stride(from: 380.0, through: 700, by: 5).map { ($0, punkt(nm: $0)) }

    /// Kromatisiteten til en enkelt bølgelengde.
    public static func punkt(nm: Double) -> Punkt {
        var verdier = [Double](repeating: 0, count: 81)
        verdier[min(max(Int(((nm - 380) / 5).rounded()), 0), 80)] = 1
        let xy = Kolorimetri.xy(Kolorimetri.xyz(lyskilde: Spektrum(start: 380, steg: 5, verdier: verdier)))
        return Punkt(x: xy.x, y: xy.y)
    }

    /// Fargens kromatisitet.
    public static func punkt(_ farge: Farge) -> Punkt {
        let xy = Kolorimetri.xy(farge.xyz)
        return Punkt(x: xy.x, y: xy.y)
    }

    /// Kopunktet forvirringslinjene for et avvik går gjennom (`nil` for akromatopsi, der bare lysheten skiller).
    public static func kopunkt(_ type: Fargesynstype) -> Punkt? {
        switch type {
        case .protan: Punkt(x: 0.7465, y: 0.2535)
        case .deutan: Punkt(x: 1.4, y: -0.4)
        case .tritan: Punkt(x: 0.1748, y: 0.0044)
        case .akromatopsi: nil
        }
    }

    /// Hjørnene (rød, grønn, blå) i et RGB-rom, til å tegne gamut-trekanten.
    public static func hjørner(_ lag: (Double, Double, Double) -> Farge) -> [Punkt] {
        [lag(1, 0, 0), lag(0, 1, 0), lag(0, 0, 1)].map(punkt)
    }

    /// Avstanden fra punktet `p` til forvirringslinjen gjennom kopunktet og `q`, målt vinkelrett på linjen. Små verdier:
    /// `p` og `q` ligger nær samme linje og kan forveksles (gitt lik lyshet).
    public static func avstandFraLinje(_ p: Punkt, gjennom q: Punkt, kopunkt k: Punkt) -> Double {
        let (dx, dy) = (q.x - k.x, q.y - k.y)
        let lengde = (dx * dx + dy * dy).squareRoot()
        guard lengde > 0 else { return 0 }
        return abs((p.x - k.x) * dy - (p.y - k.y) * dx) / lengde
    }
}
