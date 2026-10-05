import FargeKjerne
import Foundation

/// Visning av komponentverdier: CMYK, metning og lysstyrke i prosent. RGB-kanaler som 0–1, men i sRGB som 0–255 – de
/// samme tallene som i hex (#537BB0 = 83 123 176).
extension Fargemodell.Komponent {
    /// Verdien slik den vises ved glideren. `sRGB` sier om RGB-kanalen er i sRGB (0–255) eller et annet rom (0–1).
    func tekst(_ v: Double, sRGB: Bool) -> String {
        switch visning {
        case .tall: v.formatted(.number.precision(.fractionLength(desimaler)))
        case .prosent: v.formatted(.percent.precision(.fractionLength(0)))
        case .kanal: sRGB ? (v * 255).formatted(.number.precision(.fractionLength(0))) : v.formatted(.number.precision(.fractionLength(3)))
        }
    }

    /// Verdien avrundet til trinnene som vises (hele prosent, heltall 0–255 i sRGB, tre desimaler ellers), så gliderne
    /// gir nøyaktig de verdiene man ser.
    func avrundet(_ v: Double, sRGB: Bool) -> Double {
        switch visning {
        case .tall: v
        case .prosent: (v * 100).rounded() / 100
        case .kanal: sRGB ? (v * 255).rounded() / 255 : (v * 1000).rounded() / 1000
        }
    }
}
