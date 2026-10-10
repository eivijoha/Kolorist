import FargeKjerne
import Foundation

/// Anslår et glatt refleksjonsspekter for en farge, slik at en farge uten målt spekter likevel kan «ses» under
/// lyskilder med ujevnt spekter (lysrør, LED). Metoden er Burns' minste kvadrerte stigning (LLSS, 2015):
/// det glatteste spekteret som gir nøyaktig fargen under D65.
///
/// Skrevet for Kolorist fra metoden i S. A. Burns, «Numerical methods for smoothest reflectance reconstruction», Color
/// Research & Application 45(1), 2020 – ikke fra Burns' egen kode (som er CC BY-SA). Metoden krever bare kildehenvisning.
///
/// Spekteret er et anslag – to farger som er like på skjermen, kan ha ulike spektre i virkeligheten (metameri).
public enum Refleksjonsestimat {
    /// 81×3: refleksjon = B · XYZ(D65, Y = 1).
    private static let b: [[Double]] = {
        let cie = CIEData.delt
        let n = cie.antall
        let d65 = Lyskilde.d65.spektrum!
        var normering = 0.0
        var t = Array(repeating: Array(repeating: 0.0, count: n), count: 3)
        for i in 0..<n {
            let e = d65.verdi(ved: cie.bølgelengde(i))
            t[0][i] = e * cie.observatør.x[i]; t[1][i] = e * cie.observatør.y[i]; t[2][i] = e * cie.observatør.z[i]
            normering += t[1][i]
        }
        t = t.map { $0.map { $0 / normering } }
        // KKT-systemet [2DᵀD Tᵀ; T 0] [r; λ] = [0; xyz], der D er førstedifferanser.
        let m = n + 3
        var a = Array(repeating: Array(repeating: 0.0, count: m), count: m)
        for i in 0..<n {
            // DᵀD er tridiagonal med 1, 2, …, 2, 1 på diagonalen og −1 ved siden av.
            a[i][i] = 2 * ((i == 0 || i == n - 1) ? 1 : 2)
            if i > 0 { a[i][i - 1] = -2 }
            if i < n - 1 { a[i][i + 1] = -2 }
            for k in 0..<3 { a[i][n + k] = t[k][i]; a[n + k][i] = t[k][i] }
        }
        var høyre = Array(repeating: Array(repeating: 0.0, count: 3), count: m)
        for k in 0..<3 { høyre[n + k][k] = 1 }
        guard let løsning = Lineær.løs(a, høyre) else { fatalError("LLSS-systemet er singulært") }
        return Array(løsning.prefix(n))
    }()

    /// Et glatt refleksjonsspekter (380–780 nm, 5 nm) som gir fargen under D65. Kan gå litt utenfor 0–1 for
    /// svært mettede farger; det klippes ikke, for da ville fargen under D65 endres.
    public static func spektrum(for farge: Farge) -> Spektrum {
        let v = farge.xyz
        let verdier = b.map { $0[0] * v.x + $0[1] * v.y + $0[2] * v.z }
        return CIEData.delt.spektrum(verdier)
    }
}
