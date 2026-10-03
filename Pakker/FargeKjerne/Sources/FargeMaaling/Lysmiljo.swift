import FargeKjerne
import Foundation

/// Et lagret lysmiljø – «stua om kvelden», «kontoret», «utstillingslokalet» – som farger kan ses i.
public struct Lysmiljø: Hashable, Codable, Sendable, Identifiable {
    public var id: UUID
    public var navn: String
    public var lyskilde: Lyskilde
    /// Belysningsstyrken på flatene (lux). Påvirker hvor fargerike og kontrastrike fargene oppleves.
    public var lux: Double
    /// Når og hvordan miljøet ble målt (valgfritt).
    public var måling: Lysmåling?

    public init(id: UUID = UUID(), navn: String, lyskilde: Lyskilde, lux: Double = 300, måling: Lysmåling? = nil) {
        self.id = id
        self.navn = navn
        self.lyskilde = lyskilde
        self.lux = lux
        self.måling = måling
    }

    /// Visningsforholdene for flater i miljøet.
    public var visningsforhold: Visningsforhold { .rom(hvit: lyskilde.hvitpunkt, lux: lux) }

    /// Hvordan en farge (slik den ser ut på skjermen, eller som en flate i dagslys) oppleves i dette lysmiljøet,
    /// vist på skjermen.
    ///
    /// 1. Flaten under miljøets lys: spektralt når lysets spekter er kjent (med målt eller anslått refleksjon),
    ///    ellers med full CAT16 fra D65 til miljøets hvitpunkt.
    /// 2. Inntrykket i miljøet (CAM16 med miljøets hvitpunkt og lysstyrke; øyet tilpasser seg bare delvis).
    /// 3. Den skjermfargen som gir samme inntrykk (CAM16 baklengs med `skjerm`).
    public func sett(_ farge: Farge, refleksjon: Spektrum? = nil, skjerm: Visningsforhold = .skjerm) -> Farge {
        let iLyset = xyzUnderLyset(farge, refleksjon: refleksjon)
        let inntrykk = CAM16(visningsforhold).korrelater(iLyset)
        return Farge(xyz: CAM16(skjerm).xyz(inntrykk), alfa: farge.alfa)
    }

    /// Fargen slik et foto med dagslys-hvitbalanse ville vist den: lysets fulle fargestikk, uten at øyet har tilpasset
    /// seg. Lysstyrken skaleres så hvitt under lyset har samme luminans som hvitt på skjermen.
    public func somFoto(_ farge: Farge, refleksjon: Spektrum? = nil) -> Farge {
        Farge(xyz: xyzUnderLyset(farge, refleksjon: refleksjon), alfa: farge.alfa)
    }

    /// Flatens XYZ under miljøets lys (hvitt har Y = 1).
    public func xyzUnderLyset(_ farge: Farge, refleksjon: Spektrum? = nil) -> XYZ {
        if let lys = lyskilde.spektrum {
            let r = refleksjon ?? Refleksjonsestimat.spektrum(for: farge)
            return Kolorimetri.xyz(refleksjon: r, under: lys)
        }
        return CAT16.tilpass(farge.xyz, fra: Lyskilde.d65.hvitpunkt, til: lyskilde.hvitpunkt)
    }

    /// Hvor mye fargen endrer seg fra dagslys til dette miljøet, når øyet har tilpasset seg fullt (ΔE2000).
    /// Store verdier betyr at fargen skifter karakter i lyset, ikke bare blir varmere eller kaldere.
    public func fargeskift(_ farge: Farge, refleksjon: Spektrum? = nil) -> Double {
        let iLyset = xyzUnderLyset(farge, refleksjon: refleksjon)
        let tilbake = CAT16.tilpass(iLyset, fra: lyskilde.hvitpunkt, til: Lyskilde.d65.hvitpunkt)
        return Fargeavstand.deltaE2000(Farge(xyz: tilbake).cieLab, farge.cieLab)
    }
}

/// Hva som ble målt da et lysmiljø ble registrert.
public struct Lysmåling: Hashable, Codable, Sendable {
    public var tidspunkt: Date
    /// Korrelert fargetemperatur (K).
    public var kelvin: Double
    /// Avstand fra Plancks kurve (positiv mot grønt).
    public var duv: Double
    public var lux: Double?
    /// Estimert fargegjengivelse (0–100), når et referansekort med spektre var med i bildet.
    public var fargegjengivelse: Double?
    /// Hvordan målingen ble gjort.
    public var metode: Metode

    public enum Metode: String, Hashable, Codable, Sendable {
        /// Kameraets hvitbalanse alene.
        case kamera
        /// Et grått eller hvitt kort i bildet.
        case gråkort
        /// Et referansekort med kjente verdier i bildet.
        case referansekort
    }

    public init(tidspunkt: Date = .now, kelvin: Double, duv: Double, lux: Double? = nil, fargegjengivelse: Double? = nil,
                metode: Metode) {
        self.tidspunkt = tidspunkt
        self.kelvin = kelvin
        self.duv = duv
        self.lux = lux
        self.fargegjengivelse = fargegjengivelse
        self.metode = metode
    }
}
