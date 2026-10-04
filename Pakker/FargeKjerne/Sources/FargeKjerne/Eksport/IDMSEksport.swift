import Foundation

/// InDesign-utklipp (.idms): fargene som fargeprøver og ruter, og gradientene som ekte, redigerbare gradienter
/// (fargeprøve og boks med gradientfyll). Formatet er InDesigns XML for utklipp (IDML); filen dras inn i et dokument
/// eller plasseres (⌘D). InDesign limer ikke inn dette formatet fra utklippstavlen, bare fra fil.
public enum IDMSEksport {
    public struct Gradient: Sendable {
        public var navn: String
        public var stopp: [(farge: Farge, posisjon: Double)]
        public var radiell: Bool
        /// Retning som i CSS: 0 = opp, 90 = mot høyre.
        public var vinkel: Double

        public init(navn: String, stopp: [(farge: Farge, posisjon: Double)], radiell: Bool = false, vinkel: Double = 90) {
            self.navn = navn; self.stopp = stopp; self.radiell = radiell; self.vinkel = vinkel
        }
    }

    static let rute = 48.0, mellomrom = 6.0, perRad = 10
    static let gradientbredde = 300.0, gradienthøyde = 60.0

    public static func snippet(farger: [PalettFarge], gradienter: [Gradient]) -> String {
        var fargeelementer: [String] = []
        var kjente = Set<String>()
        /// Fargeprøve for en farge (gjenbrukes når samme navn kommer igjen); gir referansen.
        func fargeprøve(_ f: Farge, navn: String) -> String {
            let s = f.gamutKartlagt(til: .sRGB).sRGB
            let verdi = [s.r, s.g, s.b].map { String(Int(($0 * 255).rounded())) }.joined(separator: " ")
            let id = "Color/\(navn)"
            if kjente.insert(navn).inserted {
                fargeelementer.append("\t<Color Self=\"\(xml(id))\" Model=\"Process\" Space=\"RGB\" ColorValue=\"\(verdi)\" ColorOverride=\"Normal\" AlternateSpace=\"NoAlternateColor\" AlternateColorValue=\"\" Name=\"\(xml(navn))\" ColorEditable=\"true\" ColorRemovable=\"true\" Visible=\"true\" SwatchCreatorID=\"7937\"/>")
            }
            return id
        }

        var elementer: [String] = []
        var y = 0.0
        // Fargene som ruter, ti i bredden.
        for (i, pf) in farger.enumerated() {
            let hex = pf.farge.hex()
            let navn = pf.navn.isEmpty ? hex : "\(pf.navn) \(hex)"
            let id = fargeprøve(pf.farge, navn: navn)
            let x = Double(i % perRad) * (rute + mellomrom)
            let ry = Double(i / perRad) * (rute + mellomrom)
            elementer.append(rektangel(navn: navn, fyll: id, x: x, y: ry, bredde: rute, høyde: rute))
        }
        if !farger.isEmpty { y = Double((farger.count - 1) / perRad + 1) * (rute + mellomrom) + 12 }

        // Gradientene som fargeprøver og bokser under fargene.
        var gradientelementer: [String] = []
        for (i, g) in gradienter.enumerated() {
            let navn = g.navn.isEmpty ? "Kolorist-gradient \(i + 1)" : g.navn
            let id = "Gradient/\(navn)"
            let stopp = g.stopp.enumerated().map { j, s -> String in
                let ref = fargeprøve(s.farge, navn: s.farge.hex())
                let posisjon = String(format: "%.2f", min(max(s.posisjon, 0), 1) * 100)
                let midtpunkt = j == 0 ? "" : " Midpoint=\"50\""
                return "\t\t<GradientStop Self=\"\(xml(id))/s\(j)\" StopColor=\"\(xml(ref))\" Location=\"\(posisjon)\"\(midtpunkt)/>"
            }.joined(separator: "\n")
            gradientelementer.append("""
            \t<Gradient Self="\(xml(id))" Type="\(g.radiell ? "Radial" : "Linear")" Name="\(xml(navn))" ColorEditable="true" ColorRemovable="true" Visible="true" SwatchCreatorID="7937">
            \(stopp)
            \t</Gradient>
            """)
            let (start, lengde, vinkel) = fyllgeometri(g, bredde: gradientbredde, høyde: gradienthøyde)
            elementer.append(rektangel(navn: navn, fyll: id, x: 0, y: y, bredde: gradientbredde, høyde: gradienthøyde,
                                       gradient: (start, lengde, vinkel)))
            y += gradienthøyde + 12
        }

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <?aid style="50" type="snippet" readerVersion="6.0" featureSet="257" product="21.0(0)" ?>
        <?aid SnippetType="PageItem"?>
        <Document DOMVersion="21.0" Self="d">
        \(fargeelementer.joined(separator: "\n"))
        \(gradientelementer.joined(separator: "\n"))
        \t<Spread Self="kolorist">
        \(elementer.joined(separator: "\n"))
        \t</Spread>
        </Document>

        """
    }

    /// Start (i boksens koordinater, y nedover), lengde og vinkel for gradientfyllet. InDesigns vinkel måles mot
    /// klokka fra x-aksen; CSS-vinkelen med klokka fra opp, så InDesign-vinkelen er 90 − CSS-vinkelen.
    static func fyllgeometri(_ g: Gradient, bredde: Double, høyde: Double) -> (start: (Double, Double), lengde: Double, vinkel: Double) {
        if g.radiell { return ((bredde / 2, høyde / 2), hypot(bredde, høyde) / 2, 0) }
        let a = g.vinkel * .pi / 180
        let dx = sin(a), dy = -cos(a)
        let halv = abs(bredde / 2 * dx) + abs(høyde / 2 * dy)
        let start = (bredde / 2 - dx * halv, høyde / 2 - dy * halv)
        var vinkel = 90 - g.vinkel
        vinkel = (vinkel + 180).truncatingRemainder(dividingBy: 360)
        if vinkel < 0 { vinkel += 360 }
        return (start, halv * 2, vinkel - 180)
    }

    static func rektangel(navn: String, fyll: String, x: Double, y: Double, bredde: Double, høyde: Double,
                          gradient: (start: (Double, Double), lengde: Double, vinkel: Double)? = nil) -> String {
        func t(_ v: Double) -> String { String(format: "%.3f", v) }
        let punkter = [(0.0, 0.0), (0.0, høyde), (bredde, høyde), (bredde, 0.0)].map { p in
            "\t\t\t\t\t\t<PathPointType Anchor=\"\(t(p.0)) \(t(p.1))\" LeftDirection=\"\(t(p.0)) \(t(p.1))\" RightDirection=\"\(t(p.0)) \(t(p.1))\"/>"
        }.joined(separator: "\n")
        let gradientfyll = gradient.map {
            " GradientFillStart=\"\(t($0.start.0)) \(t($0.start.1))\" GradientFillLength=\"\(t($0.lengde))\" GradientFillAngle=\"\(t($0.vinkel))\""
        } ?? ""
        return """
        \t\t<Rectangle Self="r\(abs(navn.hashValue))\(Int(x))\(Int(y))" ContentType="Unassigned" StoryTitle="$ID/" Visible="true" Name="\(xml(navn))" FillColor="\(xml(fyll))" StrokeWeight="0" StrokeColor="Swatch/None"\(gradientfyll) ItemTransform="1 0 0 1 \(t(x)) \(t(y))">
        \t\t\t<Properties>
        \t\t\t\t<PathGeometry>
        \t\t\t\t\t<GeometryPathType PathOpen="false">
        \t\t\t\t\t\t<PathPointArray>
        \(punkter)
        \t\t\t\t\t\t</PathPointArray>
        \t\t\t\t\t</GeometryPathType>
        \t\t\t\t</PathGeometry>
        \t\t\t</Properties>
        \t\t</Rectangle>
        """
    }

    static func xml(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
    }
}
