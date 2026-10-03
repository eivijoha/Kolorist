import FargeKjerne
import Foundation

/// Hvor godt et lys gjengir farger, anslått fra prøveflater med kjente spektre (f.eks. feltene på et
/// referansekort). Samme idé som CIE-fargegjengivelsesindeksen (Ra): prøvene sammenlignes under lyset og under et
/// referanselys med samme fargetemperatur (sortlegeme under 5000 K, dagslys over), etter full kromatisk
/// tilpasning. Indeksen er 100 − 9 · snitt-ΔE2000, skalert så den havner nær Ra for vanlige lyskilder med et
/// 24-felts kort (FL2 ≈ 68 mot Ra 64, FL11 ≈ 82 mot Ra 83). Den er **ikke** en offisiell Ra – prøvene og
/// fargeavstanden er andre – men den skiller godt mellom bredbåndet lys og lys med smale topper.
public enum Fargegjengivelse {
    public struct Resultat: Hashable, Sendable {
        public var indeks: Double
        public var snittΔE: Double
        public var maksΔE: Double
        public var kelvin: Double
        /// ΔE2000 for hver prøve, i samme rekkefølge.
        public var avvik: [Double]
    }

    /// Referanselyset for en fargetemperatur.
    public static func referanselys(kelvin: Double) -> Spektrum {
        kelvin < 5000 ? Kolorimetri.sortlegeme(kelvin: kelvin) : Kolorimetri.dagslys(kelvin: kelvin)
    }

    /// Fra lysets spekter (når det er kjent).
    public static func anslag(lys: Spektrum, prøver: [Spektrum]) -> Resultat? {
        let hvit = Kolorimetri.xyz(lyskilde: lys)
        return anslag(målt: prøver.map { Kolorimetri.xyz(refleksjon: $0, under: lys) }, hvit: hvit, prøver: prøver)
    }

    /// Fra målte farger (XYZ under lyset, hvitt har Y = 1) når bare kameraet har sett lyset.
    public static func anslag(målt: [XYZ], hvit: XYZ, prøver: [Spektrum]) -> Resultat? {
        guard målt.count == prøver.count, !prøver.isEmpty else { return nil }
        let p = Kolorimetri.xy(hvit)
        guard let (kelvin, _) = Kolorimetri.fargetemperatur(x: p.x, y: p.y) else { return nil }
        let referanse = referanselys(kelvin: kelvin)
        let refHvit = Kolorimetri.xyz(lyskilde: referanse)
        let d65 = Lyskilde.d65.hvitpunkt
        let avvik = zip(målt, prøver).map { m, r -> Double in
            let iLyset = CAT16.tilpass(m, fra: hvit, til: d65)
            let iRef = CAT16.tilpass(Kolorimetri.xyz(refleksjon: r, under: referanse), fra: refHvit, til: d65)
            return Fargeavstand.deltaE2000(Farge(xyz: iLyset).cieLab, Farge(xyz: iRef).cieLab)
        }
        let snitt = avvik.reduce(0, +) / Double(avvik.count)
        return Resultat(indeks: 100 - 9 * snitt, snittΔE: snitt, maksΔE: avvik.max() ?? 0, kelvin: kelvin, avvik: avvik)
    }
}

/// Et grovt anslag av lystypen ut fra fargetemperatur, Duv og (når den finnes) fargegjengivelse.
public enum Lystype: String, Hashable, Codable, Sendable, CaseIterable {
    case levendeLys, glødelys, varmhvitLED, nøytraltKunstlys, dagslys, overskyet, grønnstikk, rødlillaStikk, ukjent

    public static func anslå(kelvin: Double, duv: Double, fargegjengivelse: Double? = nil) -> Lystype {
        if duv > 0.006 { return .grønnstikk }
        if duv < -0.008 { return .rødlillaStikk }
        switch kelvin {
        case ..<2200: return .levendeLys
        case ..<3300:
            if let r = fargegjengivelse { return r >= 95 ? .glødelys : .varmhvitLED }
            return abs(duv) < 0.002 ? .glødelys : .varmhvitLED
        case ..<4800: return .nøytraltKunstlys
        case ..<7000: return .dagslys
        case ..<20000: return .overskyet
        default: return .ukjent
        }
    }

    public var navn: String {
        switch self {
        case .levendeLys: String(localized: "Levende lys", bundle: .module)
        case .glødelys: String(localized: "Glødelys eller halogen", bundle: .module)
        case .varmhvitLED: String(localized: "Varmhvitt LED- eller sparelys", bundle: .module)
        case .nøytraltKunstlys: String(localized: "Nøytralt kunstlys", bundle: .module)
        case .dagslys: String(localized: "Dagslys", bundle: .module)
        case .overskyet: String(localized: "Overskyet eller skygge", bundle: .module)
        case .grønnstikk: String(localized: "Lys med grønnstikk (lysrør eller billig LED)", bundle: .module)
        case .rødlillaStikk: String(localized: "Lys med rødlilla stikk", bundle: .module)
        case .ukjent: String(localized: "Ukjent lys", bundle: .module)
        }
    }
}
