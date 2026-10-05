import FargeKjerne
import Foundation

/// Hvordan RGB-kanaler vises og angis: som heltall i en bitdybde (8 bit gir 0–255) eller som desimal 0–1 (som i
/// CSS `color()` og flyttallsbilder). Brukerens valg, felles for Studio, Fargestyring og profilkonvertering.
enum RGBSkala: String, CaseIterable, Identifiable {
    case åtteBit = "8", tiBit = "10", sekstenBit = "16", desimal = "desimal"

    static let nøkkel = "rgbSkala"
    static var gjeldende: RGBSkala {
        UserDefaults.standard.string(forKey: nøkkel).flatMap(RGBSkala.init(rawValue:)) ?? .åtteBit
    }

    var id: String { rawValue }

    /// Største verdi: 255, 1023, 65 535 – eller 1 for desimal.
    var maks: Double {
        switch self {
        case .åtteBit: 255
        case .tiBit: 1023
        case .sekstenBit: 65_535
        case .desimal: 1
        }
    }

    var desimaler: Int { self == .desimal ? 3 : 0 }

    var navn: String {
        switch self {
        case .åtteBit: String(localized: "8 bit (0–255)")
        case .tiBit: String(localized: "10 bit (0–1023)")
        case .sekstenBit: String(localized: "16 bit (0–65535)")
        case .desimal: String(localized: "Desimal (0–1)")
        }
    }

    /// En kanal (0…1) som tekst i denne skalaen.
    func tekst(_ v: Double) -> String {
        (v * maks).formatted(.number.precision(.fractionLength(desimaler)).grouping(.never))
    }

    /// Avrundet til et trinn i skalaen (ett heltall i bitdybden, eller tre desimaler).
    func avrundet(_ v: Double) -> Double {
        self == .desimal ? (v * 1000).rounded() / 1000 : (v * maks).rounded() / maks
    }
}

extension Fargemodell.Komponent {
    /// Verdien slik den vises ved glideren: prosent for CMYK, metning og lysstyrke; RGB-kanaler etter valgt skala.
    func tekst(_ v: Double, rgb: RGBSkala = .gjeldende) -> String {
        switch visning {
        case .tall: v.formatted(.number.precision(.fractionLength(desimaler)))
        case .prosent: v.formatted(.percent.precision(.fractionLength(0)))
        case .kanal: rgb.tekst(v)
        }
    }

    /// Verdien avrundet til trinnene som vises (hele prosent, ett trinn i bitdybden), så gliderne gir nøyaktig de
    /// verdiene man ser.
    func avrundet(_ v: Double, rgb: RGBSkala = .gjeldende) -> Double {
        switch visning {
        case .tall: v
        case .prosent: (v * 100).rounded() / 100
        case .kanal: rgb.avrundet(v)
        }
    }
}
