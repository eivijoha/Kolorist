import Foundation

/// Dekoder et element og gir `nil` i stedet for å feile (for lister som skal tåle ukjente elementer).
public struct Tolerant<T: Decodable>: Decodable {
    public let verdi: T?
    public init(from decoder: Decoder) throws { verdi = try? T(from: decoder) }
}

/// Lister som synkroniseres mellom versjoner av appen (JSON i ett felt). En eldre versjon må verken miste
/// elementer den ikke forstår eller tømme lista:
/// - Lesing: hele lista når alt kan leses (vanlig, raskt); ellers elementene som kan leses.
/// - Skriving: elementer som ikke kunne leses, legges urørt til etter de kjente. Kan ikke dataene leses i det
///   hele tatt, skrives det ikke (`nil`), så de ikke overskrives.
public enum TolerantListe {
    public static func les<T: Decodable>(_ data: Data) -> [T] {
        guard !data.isEmpty else { return [] }
        if let alle = try? JSONDecoder().decode([T].self, from: data) { return alle }
        return ((try? JSONDecoder().decode([Tolerant<T>].self, from: data)) ?? []).compactMap(\.verdi)
    }

    /// Elementene som ikke kan leses som `T`, som rå JSON; `nil` når dataene ikke er en liste i det hele tatt.
    public static func ukjente<T: Decodable>(_ data: Data, som type: T.Type) -> [Any]? {
        guard !data.isEmpty else { return [] }
        if (try? JSONDecoder().decode([T].self, from: data)) != nil { return [] }
        guard let rå = (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)) as? [Any] else { return nil }
        return rå.filter { element in
            guard let d = try? JSONSerialization.data(withJSONObject: element, options: .fragmentsAllowed) else { return true }
            return (try? JSONDecoder().decode(T.self, from: d)) == nil
        }
    }

    public static func skriv<T: Codable>(_ verdier: [T], beholdUkjenteFra gammel: Data) -> Data? {
        guard let ukjente = ukjente(gammel, som: T.self) else { return nil }
        guard let ny = try? JSONEncoder().encode(verdier) else { return nil }
        guard !ukjente.isEmpty, let kjente = (try? JSONSerialization.jsonObject(with: ny)) as? [Any] else { return ny }
        return try? JSONSerialization.data(withJSONObject: kjente + ukjente)
    }
}
