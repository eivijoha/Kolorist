import Foundation

/// En spektralfordeling med jevne bølgelengdesteg (nm): refleksjon (0–1) for flater, eller relativ effekt for lyskilder.
public struct Spektrum: Hashable, Codable, Sendable {
    /// Første bølgelengde (nm).
    public var start: Double
    /// Avstand mellom bølgelengdene (nm).
    public var steg: Double
    public var verdier: [Double]

    public init(start: Double, steg: Double, verdier: [Double]) {
        self.start = start
        self.steg = steg
        self.verdier = verdier
    }

    /// Siste bølgelengde (nm).
    public var slutt: Double { start + steg * Double(max(verdier.count - 1, 0)) }

    /// Verdien ved en bølgelengde, lineært interpolert. Utenfor området brukes nærmeste verdi (CIE 15 anbefaler å
    /// forlenge med endeverdiene heller enn å sette 0).
    public func verdi(ved nm: Double) -> Double {
        guard let første = verdier.first, let siste = verdier.last else { return 0 }
        if nm <= start { return første }
        if nm >= slutt { return siste }
        let posisjon = (nm - start) / steg
        let i = Int(posisjon)
        let t = posisjon - Double(i)
        return verdier[i] * (1 - t) + verdier[min(i + 1, verdier.count - 1)] * t
    }

    /// Verdiene ved `antall` bølgelengder fra `start` med `steg`.
    public func samplet(start: Double, steg: Double, antall: Int) -> [Double] {
        (0..<antall).map { verdi(ved: start + Double($0) * steg) }
    }

    /// Alle verdier ganget med en faktor (f.eks. 0–100 → 0–1).
    public func skalert(_ faktor: Double) -> Spektrum {
        Spektrum(start: start, steg: steg, verdier: verdier.map { $0 * faktor })
    }
}
