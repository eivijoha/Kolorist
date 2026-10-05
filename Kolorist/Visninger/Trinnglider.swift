import SwiftUI

/// Glider som runder av til hele trinn, uten trinnmerker. `Slider(step:)` tegner et merke per trinn på Mac,
/// og med mange trinn blir det bare støy under gliderbanen.
struct Trinnglider: View {
    @Binding var verdi: Double
    let område: ClosedRange<Double>
    let steg: Double

    var body: some View {
        Slider(value: Binding(get: { verdi }, set: { ny in
            let avrundet = min(max((ny / steg).rounded() * steg, område.lowerBound), område.upperBound)
            if avrundet != verdi { verdi = avrundet }
        }), in: område)
    }
}
