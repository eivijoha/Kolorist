import CoreGraphics
import FargeKjerne
import Foundation

/// Figurer i Apples felles utklippsformat for Pages, Keynote, Numbers og Freeform
/// (`com.apple.apps.content-language.canvas-object-1.0`): en JSON-liste med figurer, som programmene selv legger
/// på utklippstavlen. Limes inn som ekte figurer med fargefyll eller redigerbar gradient, ikke som bilde.
enum IWorkUtklipp {
    static let type = "com.apple.apps.content-language.canvas-object-1.0"

    /// Fyllet i en figur.
    enum Fyll {
        case farge(Farge)
        /// Lineær gradient. Vinkelen regnes mot klokka fra høyre (0° = mot høyre, 90° = opp).
        case lineær(stopp: [(farge: Farge, posisjon: Double)], vinkel: Double)
    }

    /// Figurene som utklippsdata. Posisjonene beholdes innbyrdes; programmet plasserer gruppen selv.
    static func data(_ figurer: [(fyll: Fyll, ramme: CGRect)]) -> Data? {
        try? JSONSerialization.data(withJSONObject: figurer.map { figur($0.fyll, ramme: $0.ramme) })
    }

    private static func objekt(_ type: String, _ felt: [String: Any]) -> [String: Any] {
        felt.merging(["type_identifier": "com.apple.apps.content-language.\(type)", "version": "1.0"]) { a, _ in a }
    }

    /// Fargen i sRGB når den ligger der, ellers i Display P3 (gamut-kartlagt), så den ikke klippes.
    private static func farge(_ f: Farge) -> [String: Any] {
        let (rom, r, g, b): (String, Double, Double, Double)
        if f.erISRGB {
            let v = f.sRGB
            (rom, r, g, b) = ("srgb", v.r, v.g, v.b)
        } else {
            let v = f.gamutKartlagt(til: .displayP3).displayP3
            (rom, r, g, b) = ("p3", v.r, v.g, v.b)
        }
        let rgba = objekt("color.rgba", ["version": "1.1", "color_space": rom, "red": r, "green": g, "blue": b,
                                         "alpha": f.alfa, "headroom": 1])
        return objekt("color", ["primary_case": "rgba", "rgba": rgba])
    }

    private static func fyll(_ fyll: Fyll) -> [String: Any] {
        switch fyll {
        case .farge(let f):
            return objekt("fill", ["primary_case": "color", "color": farge(f)])
        case .lineær(let stopp, let vinkel):
            let stopp = stopp.map {
                objekt("fill.gradient.stop", ["fraction": $0.posisjon, "inflection": 0.5, "color": farge($0.farge)])
            }
            var v = vinkel.truncatingRemainder(dividingBy: 360)
            if v < 0 { v += 360 }
            let flavor = objekt("fill.gradient.flavor", ["primary_case": "linear",
                                                         "linear": objekt("fill.gradient.flavor.linear", ["angle": v])])
            return objekt("fill", ["primary_case": "gradient",
                                   "gradient": objekt("fill.gradient", ["opacity": 1, "stops": stopp, "flavor": flavor])])
        }
    }

    private static func figur(_ f: Fyll, ramme: CGRect) -> [String: Any] {
        objekt("shape", [
            "identifier": UUID().uuidString,
            "geometry": objekt("geometry", [
                "angle": 0, "flip_horizontally": false, "width_valid": true, "height_valid": true,
                "size": objekt("size", ["width": ramme.width, "height": ramme.height]),
                "position": objekt("position", ["x": ramme.minX, "y": ramme.minY]),
            ]),
            "fill": fyll(f),
            "stroke": "empty", "opacity": 1, "aspect_ratio_locked": false, "head": "none", "tail": "none",
            "comments": [Any](),
        ])
    }
}
