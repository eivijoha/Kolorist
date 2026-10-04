import FargeKjerne
import Foundation

/// Kompenserer farger plukket med kameraet for lyset de ble fotografert i, så de blir slik flatene ser ut i
/// dagslys (D65). Tre nivåer, fra enklest til mest nøyaktig:
///
/// - **Hvitpunkt** (nivå A): lysets kromatisitet fra kameraets hvitbalanse eller en valgt lyskilde. Full CAT16.
/// - **Gråkort** (nivå B): et nøytralt kort med kjent refleksjon i bildet gir både hvitpunkt og eksponering,
///   så lysheten også blir riktig.
/// - **Referansekort** (nivå C): en `Kamerakarakterisering` fra et kort med kjente verdier i samme lys.
public enum Lyskompensasjon: Hashable, Codable, Sendable {
    /// Kameraets farge for hvitt/grått er ukjent; bare lysets kromatisitet er kjent.
    case hvitpunkt(Lyskilde)
    /// En nøytral flate med kjent refleksjon (f.eks. 0,18 for et 18 %-gråkort) slik kameraet så den.
    case gråkort(målt: Farge, refleksjon: Double)
    /// Full karakterisering fra et referansekort i samme lys.
    case referansekort(Kamerakarakterisering)
    /// En kameraprofil (karakterisering laget én gang med referansekort) og et gråkort i lyset nå: profilen gir
    /// kameraets farger som XYZ, og gråkortet gir lysets farge og eksponeringen.
    case kameraprofil(Kamerakarakterisering, gråkort: Farge, refleksjon: Double)

    /// Den kompenserte fargen (slik flaten ser ut i dagslys).
    public func kompensert(_ farge: Farge) -> Farge {
        switch self {
        case .hvitpunkt(let lys):
            return Farge(xyz: CAT16.tilpass(farge.xyz, fra: lys.hvitpunkt, til: Lyskilde.d65.hvitpunkt), alfa: farge.alfa)
        case .gråkort(let målt, let refleksjon):
            return Self.medGråkort(farge.xyz, grå: målt.xyz, refleksjon: refleksjon).map { Farge(xyz: $0, alfa: farge.alfa) } ?? farge
        case .referansekort(let karakterisering):
            return karakterisering.farge(fraKamera: farge)
        case .kameraprofil(let profil, let gråkort, let refleksjon):
            return Self.medGråkort(profil.xyz(fraKamera: farge), grå: profil.xyz(fraKamera: gråkort), refleksjon: refleksjon)
                .map { Farge(xyz: $0, alfa: farge.alfa) } ?? farge
        }
    }

    /// Kortets farge skalert til Y = 1 er lysets hvitpunkt; lysheten skaleres så kortet får sin kjente refleksjon.
    private static func medGråkort(_ v: XYZ, grå: XYZ, refleksjon: Double) -> XYZ? {
        guard grå.y > 0 else { return nil }
        return CAT16.tilpass(v, fra: grå.normalisert, til: Lyskilde.d65.hvitpunkt).skalert(refleksjon / grå.y)
    }

    /// Lysets fargetemperatur slik kompensasjonen anslår den.
    public var fargetemperatur: (kelvin: Double, duv: Double)? {
        switch self {
        case .hvitpunkt(let lys): lys.fargetemperatur
        case .gråkort(let målt, _): Kolorimetri.fargetemperatur(målt.xyz)
        case .referansekort(let k): Kolorimetri.fargetemperatur(k.kameraHvit)
        case .kameraprofil(let profil, let gråkort, _): Kolorimetri.fargetemperatur(profil.xyz(fraKamera: gråkort))
        }
    }
}

/// Belysningsstyrke fra kameraets eksponering. Kameraets lysmåler er kalibrert så et midtgrått motiv (≈ 18 %)
/// gir en bestemt pikselverdi; med kjent refleksjon på kortet gir det lux. Grovt (±20–30 %) uten kalibrering.
public enum Eksponeringsmåling {
    /// Kalibreringskonstanten K for reflektert lys (ISO 2720; 12,5 for de fleste kameraprodusenter).
    public static let standardK = 12.5

    /// Luminansen (cd/m²) til et motiv som gir en gitt lineær pikselverdi (0–1, der 0,18 er «riktig eksponert»).
    public static func luminans(lineærVerdi: Double, blender: Double, lukkertid: Double, iso: Double,
                                k: Double = standardK) -> Double {
        let eksponert = k * blender * blender / (lukkertid * iso)
        return eksponert * lineærVerdi / 0.18
    }

    /// Belysningsstyrken (lux) på en matt flate med kjent refleksjon og luminans: E = π · L / ρ.
    public static func lux(luminans: Double, refleksjon: Double) -> Double {
        .pi * luminans / max(refleksjon, 0.01)
    }
}
