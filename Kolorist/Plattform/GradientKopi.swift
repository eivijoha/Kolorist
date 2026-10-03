import CoreGraphics
import FargeKjerne
import ImageIO
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// En gradient som skal kopieres: endepunktene (eller tonene, når den er trinnvis), formen og vinkelen –
/// det samme som CSS-gradienten i Overgang.
struct Gradientkopi {
    var farger: [Farge]
    var form: CSSGradient.Form = .lineær
    /// Retning i grader (CSS: 0 = opp, 90 = mot høyre) for lineær, startvinkel for konisk.
    var vinkel: Double = 90
    var trinnvis = false
    var navn = ""

    /// Stoppene med posisjon 0…1. Glidende: tette stopp langs OKLab-kurven, så programmer som interpolerer
    /// i sRGB likevel følger appens overgang. Trinnvis: harde stopp, ett bånd per tone.
    var stopp: [(farge: Farge, posisjon: Double)] {
        if trinnvis {
            let n = Double(farger.count)
            return farger.enumerated().flatMap { i, f in [(f, Double(i) / n), (f, Double(i + 1) / n)] }
        }
        let prøver = Overgang.toner(gjennom: farger, stegMellom: max(1, 16 / max(farger.count - 1, 1)))
        let n = Double(max(prøver.count - 1, 1))
        return prøver.enumerated().map { ($1, Double($0) / n) }
    }

    var css: CSSGradient { CSSGradient(farger: farger, form: form, vinkel: vinkel, trinnvis: trinnvis) }

    /// Start- og sluttpunkt for lineær gradient i et rektangel (CSS-vinkel: 0° = opp, med klokka).
    func endepunkter(i rekt: CGRect) -> (CGPoint, CGPoint) {
        let a = vinkel * .pi / 180
        let dx = sin(a), dy = -cos(a)
        // Linjens halvlengde slik CSS regner den: hjørnene treffer 0 % og 100 %.
        let halv = abs(rekt.width / 2 * dx) + abs(rekt.height / 2 * dy)
        let m = CGPoint(x: rekt.midX, y: rekt.midY)
        return (CGPoint(x: m.x - dx * halv, y: m.y - dy * halv), CGPoint(x: m.x + dx * halv, y: m.y + dy * halv))
    }
}

/// Målene for «Kopier til» med gradient – de som tar imot en gradient ved innliming.
enum Gradientmål: String, CaseIterable, Identifiable {
    case figma, sketchAffinity, illustrator, indesign, photoshop, iWork, css, swiftUI

    var id: String { rawValue }

    var navn: String {
        switch self {
        case .figma: "Figma"
        case .sketchAffinity: "Sketch / Affinity"
        case .illustrator: "Illustrator"
        case .indesign: "InDesign"
        case .photoshop: "Photoshop"
        case .iWork: "Pages / Keynote / Numbers"
        case .css: "CSS"
        case .swiftUI: "SwiftUI"
        }
    }

    var forklaring: String {
        switch self {
        case .figma, .sketchAffinity: String(localized: "Som form med gradientfyll (SVG)")
        case .illustrator, .indesign: String(localized: "Som vektorgradient (PDF) i Display P3")
        case .photoshop: String(localized: "Som formlag eller bilde (PDF/PNG)")
        case .iWork: String(localized: "Som vektorbilde (PDF) med riktige farger")
        case .css: String(localized: "Som gradient med OKLab og reserve")
        case .swiftUI: String(localized: "Som gradient med Display P3-stopp")
        }
    }

    var symbol: String {
        switch self {
        case .figma, .sketchAffinity: "square.on.circle"
        case .illustrator, .indesign: "doc.richtext"
        case .photoshop: "photo"
        case .iWork: "doc.on.doc"
        case .css, .swiftUI: "chevron.left.forwardslash.chevron.right"
        }
    }
}

/// Undermeny «Kopier til» for en gradient – som «Kopier til» for farger.
struct GradientKopierTilMeny: View {
    let gradient: Gradientkopi
    var tittel: LocalizedStringKey = "Kopier til"

    var body: some View {
        Menu(tittel, systemImage: "arrow.up.doc.on.clipboard") {
            ForEach(Gradientmål.allCases) { mål in
                Button {
                    Utklippstavle.kopier(gradient, til: mål)
                } label: {
                    Label { Text(mål.navn); Text(mål.forklaring) } icon: { Image(systemName: mål.symbol) }
                }
            }
        }
    }
}

extension Utklippstavle {
    static func kopier(_ gradient: Gradientkopi, til mål: Gradientmål) {
        guard gradient.farger.count >= 1 else { return }
        var typer: [(String, Data)] = []
        let tekst: String
        switch mål {
        case .figma, .sketchAffinity:
            let svg = Gradientgrafikk.svg(gradient)
            typer.append(("public.svg-image", Data(svg.utf8)))
            tekst = svg   // Figma og Sketch leser SVG-koden fra teksten
        case .illustrator, .indesign:
            typer.append(("com.adobe.pdf", Gradientgrafikk.pdf(gradient)))
            tekst = gradient.css.moderne
        case .photoshop, .iWork:
            typer.append(("com.adobe.pdf", Gradientgrafikk.pdf(gradient)))
            if let png = Gradientgrafikk.png(gradient) { typer.append(("public.png", png)) }
            tekst = gradient.css.moderne
        case .css:
            tekst = gradient.css.deklarasjon
        case .swiftUI:
            tekst = Gradientgrafikk.swiftUI(gradient)
        }
        #if canImport(UIKit)
        var element: [String: Any] = ["public.utf8-plain-text": tekst]
        for (type, data) in typer { element[type] = data }
        UIPasteboard.general.items = [element]
        #elseif canImport(AppKit)
        let tavle = NSPasteboard.general
        tavle.clearContents()
        for (type, data) in typer { tavle.setData(data, forType: NSPasteboard.PasteboardType(type)) }
        tavle.setString(tekst, forType: .string)
        #endif
    }
}

/// Gradienten som SVG, PDF, PNG og SwiftUI-kode. Flaten er 480 × 240 pt.
enum Gradientgrafikk {
    static let flate = CGRect(x: 0, y: 0, width: 480, height: 240)

    // MARK: SVG

    /// SVG med `linearGradient`/`radialGradient` (sRGB-hex, tette stopp langs OKLab-kurven). Konisk
    /// gradient finnes ikke i SVG og blir lineær.
    static func svg(_ g: Gradientkopi) -> String {
        let r = flate
        let stopp = g.stopp.map { s in
            let f = s.farge.gamutKartlagt(til: .sRGB)
            let alfa = s.farge.alfa < 1 ? " stop-opacity=\"\(String(format: "%.3f", s.farge.alfa))\"" : ""
            return "    <stop offset=\"\(String(format: "%.4f", s.posisjon))\" stop-color=\"\(f.hex())\"\(alfa)/>"
        }.joined(separator: "\n")
        let definisjon: String
        if g.form == .radiell {
            definisjon = "  <radialGradient id=\"g\" cx=\"\(r.midX)\" cy=\"\(r.midY)\" r=\"\(hypot(r.width, r.height) / 2)\" gradientUnits=\"userSpaceOnUse\">\n\(stopp)\n  </radialGradient>"
        } else {
            let (a, b) = g.endepunkter(i: r)
            definisjon = "  <linearGradient id=\"g\" x1=\"\(fmt(a.x))\" y1=\"\(fmt(a.y))\" x2=\"\(fmt(b.x))\" y2=\"\(fmt(b.y))\" gradientUnits=\"userSpaceOnUse\">\n\(stopp)\n  </linearGradient>"
        }
        let tittel = g.navn.isEmpty ? "Kolorist" : g.navn.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
        return """
        <svg xmlns="http://www.w3.org/2000/svg" width="\(Int(r.width))" height="\(Int(r.height))" viewBox="0 0 \(Int(r.width)) \(Int(r.height))">
          <title>\(tittel)</title>
          <defs>
        \(definisjon)
          </defs>
          <rect x="0" y="0" width="\(Int(r.width))" height="\(Int(r.height))" fill="url(#g)"/>
        </svg>
        """
    }

    private static func fmt(_ v: CGFloat) -> String { String(format: "%.2f", v) }

    // MARK: PDF og PNG

    /// Fargerom for stoppene: sRGB når alle er innenfor, ellers Display P3.
    private static func rom(_ g: Gradientkopi) -> CGColorSpace {
        g.farger.allSatisfy(\.erISRGB) ? CGColorSpace(name: CGColorSpace.sRGB)! : CGColorSpace(name: CGColorSpace.displayP3)!
    }

    private static func cgGradient(_ g: Gradientkopi, i rom: CGColorSpace) -> CGGradient? {
        let erP3 = rom.name == CGColorSpace.displayP3
        let farger = g.stopp.map { s -> CGColor in
            let a = CGFloat(s.farge.alfa)
            if erP3 {
                let v = s.farge.gamutKartlagt(til: .displayP3).displayP3
                return CGColor(colorSpace: rom, components: [v.r, v.g, v.b, a])!
            }
            let v = s.farge.gamutKartlagt(til: .sRGB).sRGB
            return CGColor(colorSpace: rom, components: [v.r, v.g, v.b, a])!
        }
        return CGGradient(colorsSpace: rom, colors: farger as CFArray, locations: g.stopp.map { CGFloat($0.posisjon) })
    }

    /// Tegner gradienten i `rekt` (koordinater med origo nede til venstre, som i PDF/CGContext).
    private static func tegn(_ g: Gradientkopi, i ctx: CGContext, rekt: CGRect) {
        let rom = rom(g)
        guard let gradient = cgGradient(g, i: rom) else { return }
        ctx.saveGState()
        ctx.clip(to: rekt)
        switch g.form {
        case .radiell:
            let m = CGPoint(x: rekt.midX, y: rekt.midY)
            ctx.drawRadialGradient(gradient, startCenter: m, startRadius: 0, endCenter: m,
                                   endRadius: hypot(rekt.width, rekt.height) / 2, options: [.drawsAfterEndLocation])
        case .lineær, .konisk:
            // Konisk finnes ikke som PDF-skyggelegging; den blir lineær. CSS-vinkelen måles med y nedover.
            let (a, b) = g.endepunkter(i: CGRect(x: 0, y: 0, width: rekt.width, height: rekt.height))
            let snu = { (p: CGPoint) in CGPoint(x: rekt.minX + p.x, y: rekt.maxY - p.y) }
            ctx.drawLinearGradient(gradient, start: snu(a), end: snu(b), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }
        ctx.restoreGState()
    }

    /// PDF med jevn skyggelegging (vektor), i sRGB eller Display P3.
    static func pdf(_ g: Gradientkopi) -> Data {
        let data = NSMutableData()
        var boks = flate
        guard let forbruker = CGDataConsumer(data: data as CFMutableData),
              let ctx = CGContext(consumer: forbruker, mediaBox: &boks, nil) else { return Data() }
        ctx.beginPDFPage(nil)
        tegn(g, i: ctx, rekt: flate)
        ctx.endPDFPage()
        ctx.closePDF()
        return data as Data
    }

    /// PNG i Display P3 (2×), for programmer som bare tar imot punktgrafikk.
    static func png(_ g: Gradientkopi, skala: CGFloat = 2) -> Data? {
        let b = Int(flate.width * skala), h = Int(flate.height * skala)
        guard let p3 = CGColorSpace(name: CGColorSpace.displayP3),
              let ctx = CGContext(data: nil, width: b, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: p3,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.scaleBy(x: skala, y: skala)
        tegn(g, i: ctx, rekt: flate)
        guard let bilde = ctx.makeImage() else { return nil }
        let data = NSMutableData()
        guard let mål = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(mål, bilde, nil)
        return CGImageDestinationFinalize(mål) ? data as Data : nil
    }

    // MARK: SwiftUI

    static func swiftUI(_ g: Gradientkopi) -> String {
        let stopp = g.stopp.map { s in
            let v = s.farge.gamutKartlagt(til: .displayP3).displayP3
            let alfa = s.farge.alfa < 1 ? ", opacity: \(String(format: "%.3f", s.farge.alfa))" : ""
            return "        .init(color: Color(.displayP3, red: \(String(format: "%.4f", v.r)), green: \(String(format: "%.4f", v.g)), blue: \(String(format: "%.4f", v.b))\(alfa)), location: \(String(format: "%.4f", s.posisjon)))"
        }.joined(separator: ",\n")
        let navn = g.navn.isEmpty ? "" : "// \(g.navn)\n"
        switch g.form {
        case .radiell:
            return "\(navn)RadialGradient(\n    stops: [\n\(stopp)\n    ],\n    center: .center, startRadius: 0, endRadius: \(Int((hypot(flate.width, flate.height) / 2).rounded()))\n)"
        case .konisk:
            return "\(navn)AngularGradient(\n    stops: [\n\(stopp)\n    ],\n    center: .center, angle: .degrees(\(Int(g.vinkel.rounded())) - 90)\n)"
        case .lineær:
            let a = g.vinkel * .pi / 180
            // Som CSS: gradientlinjen når hjørnene (halv lengde (|sin| + |cos|) / 2 i en kvadratisk ramme).
            let h = (abs(sin(a)) + abs(cos(a))) / 2
            let start = "UnitPoint(x: \(String(format: "%.3f", 0.5 - sin(a) * h)), y: \(String(format: "%.3f", 0.5 + cos(a) * h)))"
            let slutt = "UnitPoint(x: \(String(format: "%.3f", 0.5 + sin(a) * h)), y: \(String(format: "%.3f", 0.5 - cos(a) * h)))"
            return "\(navn)LinearGradient(\n    stops: [\n\(stopp)\n    ],\n    startPoint: \(start), endPoint: \(slutt)\n)"
        }
    }
}
