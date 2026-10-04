import CoreGraphics
import FargeKjerne
import Foundation
import Vision

/// Finner et referansekort i et bilde: Vision finner rektangelet, og lysheten i feltene avgjør retningen
/// (hvilket hjørne som er øverst til venstre), så de grå feltene havner på riktig rad.
public enum Kortgjenkjenning {
    /// Foreslåtte hjørner (0–1, origo øverst til venstre: øverst til venstre, øverst til høyre, nederst til høyre,
    /// nederst til venstre), eller `nil` hvis kortet ikke ble funnet.
    public static func foreslå(kort: Referansekort, i bilde: CGImage, prøve: Bildeprøve) -> [CGPoint]? {
        let forhold = Double(min(kort.rader, kort.kolonner)) / Double(max(kort.rader, kort.kolonner))
        guard let rektangel = rektangel(i: bilde, forhold: forhold) else { return nil }
        let (w, h) = (Double(prøve.bredde), Double(prøve.høyde))
        let fasit = kort.felt.map { $0.verdi.xyz(under: .d65).y }
        let i = rektangel.map { CGPoint(x: $0.x * w, y: $0.y * h) }
        let valgt = Kortgeometri.besteRetning(hjørner: i, rader: kort.rader, kolonner: kort.kolonner, fasitY: fasit) { sentre in
            sentre.map { prøve.farge(x: min(max(Int($0.x), 0), prøve.bredde - 1), y: min(max(Int($0.y), 0), prøve.høyde - 1), radius: 2).xyz.y }
        }
        return valgt.map { CGPoint(x: $0.x / w, y: $0.y / h) }
    }

    /// Hjørnene (0–1, origo øverst til venstre) til det største rektangelet med omtrent riktig sideforhold.
    static func rektangel(i bilde: CGImage, forhold: Double) -> [CGPoint]? {
        let forespørsel = VNDetectRectanglesRequest()
        forespørsel.maximumObservations = 10
        forespørsel.minimumAspectRatio = 0.3
        forespørsel.maximumAspectRatio = 1
        forespørsel.minimumSize = 0.15
        forespørsel.minimumConfidence = 0.4
        forespørsel.quadratureTolerance = 30
        try? VNImageRequestHandler(cgImage: bilde).perform([forespørsel])
        guard let funn = forespørsel.results, !funn.isEmpty else { return nil }
        func areal(_ o: VNRectangleObservation) -> Double { Double(o.boundingBox.width * o.boundingBox.height) }
        func sideforhold(_ o: VNRectangleObservation) -> Double {
            let b = hypot(o.topRight.x - o.topLeft.x, o.topRight.y - o.topLeft.y) * CGFloat(bilde.width)
            let h = hypot(o.bottomLeft.x - o.topLeft.x, o.bottomLeft.y - o.topLeft.y) * CGFloat(bilde.height)
            return Double(min(b, h) / max(max(b, h), 1))
        }
        // Største rektangel, med straff for sideforhold langt fra kortets.
        guard let beste = funn.max(by: { a, b in
            areal(a) * exp(-4 * abs(sideforhold(a) - forhold)) < areal(b) * exp(-4 * abs(sideforhold(b) - forhold))
        }) else { return nil }
        // Vision har origo nede til venstre.
        return [beste.topLeft, beste.topRight, beste.bottomRight, beste.bottomLeft].map { CGPoint(x: $0.x, y: 1 - $0.y) }
    }
}
