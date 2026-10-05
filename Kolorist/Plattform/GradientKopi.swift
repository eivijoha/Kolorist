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

    /// Stoppene med posisjon 0…1. Glidende: så få stopp som mulig, men nok til at programmer som blander i sRGB
    /// (Figma, Sketch, SVG) følger appens OKLab-overgang innen ΔE00 1 – ofte bare start og slutt, flere når fargene
    /// ligger langt fra hverandre. Trinnvis: harde stopp, ett bånd per tone.
    var stopp: [(farge: Farge, posisjon: Double)] {
        if trinnvis {
            let n = Double(farger.count)
            return farger.enumerated().flatMap { i, f in [(f, Double(i) / n), (f, Double(i + 1) / n)] }
        }
        return Gradientstopp.forenklet(gjennom: farger)
    }

    var css: CSSGradient { CSSGradient(farger: farger, form: form, vinkel: vinkel, trinnvis: trinnvis) }

    /// Gradienten i Overgang: endepunktene (glidende) eller tonene (trinnvis), med navn etter endepunktene.
    static func overgang(fra start: Farge, til slutt: Farge, toner: [Farge], form: CSSGradient.Form, vinkel: Double,
                         trinnvis: Bool) -> Gradientkopi {
        Gradientkopi(farger: trinnvis ? toner : [start, slutt], form: form, vinkel: vinkel, trinnvis: trinnvis,
                     navn: String(localized: "Overgang \(start.hex()) → \(slutt.hex())"))
    }

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
    case figma, sketchAffinity, illustrator, indesign, photoshop, iWork, office, css, swiftUI

    var id: String { rawValue }

    var navn: String {
        switch self {
        case .figma: "Figma"
        case .sketchAffinity: "Sketch / Affinity"
        case .illustrator: "Illustrator"
        case .indesign: "InDesign"
        case .photoshop: "Photoshop"
        case .iWork: "Pages / Keynote / Numbers"
        case .office: "Word / Excel / PowerPoint"
        case .css: "CSS"
        case .swiftUI: "SwiftUI"
        }
    }

    var forklaring: String {
        switch self {
        case .figma, .sketchAffinity: String(localized: "Som form med gradientfyll (SVG)")
        case .illustrator: String(localized: "Som redigerbar gradient (PDF) i sRGB")
        case .indesign, .office: String(localized: "Som redigerbar gradient i sRGB")
        case .photoshop: String(localized: "Som formlag eller bilde (PDF/PNG)")
        case .iWork: String(localized: "Som figur med redigerbar gradient")
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
        case .office: "rectangle.on.rectangle"
        case .css, .swiftUI: "chevron.left.forwardslash.chevron.right"
        }
    }
}

/// Undermeny «Kopier til» for en gradient – som «Kopier til» for farger.
struct GradientKopierTilMeny: View {
    let gradient: Gradientkopi
    var tittel: LocalizedStringKey = "Kopier til"
    /// Som en seksjon i menyen den står i, i stedet for en undermeny (undermenyer lukker seg selv på iOS).
    var inline = false
    @AppStorage(Kopiinnstillinger.rekkefølgeNøkkel) private var rekkefølge = ""
    @AppStorage(Kopiinnstillinger.skjultNøkkel) private var skjult = ""

    var body: some View {
        if inline {
            Section(tittel) { valg }
        } else {
            Menu(tittel, systemImage: "arrow.up.doc.on.clipboard") { valg }
        }
    }

    /// Målene som er slått på, i valgt rekkefølge (samme innstilling som for farger), og «Tilpass listen …».
    @ViewBuilder private var valg: some View {
        ForEach(Kopiinnstillinger.synlige(Gradientmål.allCases.map(\.rawValue), rekkefølge: rekkefølge, skjult: skjult)
            .compactMap(Gradientmål.init(rawValue:))) { mål in
            Button {
                Utklippstavle.kopier(gradient, til: mål)
            } label: {
                Label { Text(mål.navn); Text(mål.forklaring) } icon: { Image(systemName: mål.symbol) }
            }
        }
        TilpassKopimålKnapp()
    }
}

extension Utklippstavle {
    static func kopier(_ gradient: Gradientkopi, til mål: Gradientmål) {
        guard gradient.farger.count >= 1 else { return }
        var typer: [(String, Data)] = []
        let tekst: String?
        switch mål {
        case .figma, .sketchAffinity:
            let svg = Gradientgrafikk.svg(gradient)
            typer.append(("public.svg-image", Data(svg.utf8)))
            tekst = svg   // Figma og Sketch leser SVG-koden fra teksten
        case .illustrator:
            // PDF (redigerbar gradient) og SVG-kode som tekst – det samme Illustrator selv legger på utklippstavlen.
            typer.append(("com.adobe.pdf", Gradientgrafikk.pdf(gradient)))
            let svg = Gradientgrafikk.svg(gradient)
            typer.append(("public.svg-image", Data(svg.utf8)))
            tekst = svg
        case .indesign:
            // InDesign gjør Illustrators utklippsformat (AICB, PostScript) om til en ekte, redigerbar gradient.
            // Ingen PDF ved siden av: da kunne InDesign lime inn PDF-en som bilde i tillegg til gradienten.
            typer.append(("com.adobe.illustrator.aicb", Gradientgrafikk.aicb(gradient)))
            tekst = gradient.css.moderne
        case .iWork:
            // Pages, Keynote, Numbers og Freeform leser figurer med redigerbar gradient fra Apples felles
            // utklippsformat (JSON). Bare lineær: iWork tar ikke imot radiell der (og gir den selv ut som lineær),
            // så radiell og konisk blir vektorbilde (PDF).
            if let figur = Gradientgrafikk.iWorkFigur(gradient) {
                typer.append((IWorkUtklipp.type, figur))
            } else {
                typer.append(("com.adobe.pdf", Gradientgrafikk.pdf(gradient)))
                if let png = Gradientgrafikk.png(gradient) { typer.append(("public.png", png)) }
            }
            // Uten tekst ved siden av: Numbers og Pages limer heller inn teksten enn figuren eller bildet.
            tekst = nil
        case .office:
            // Figur med redigerbar gradient (lineær eller radiell). Konisk finnes ikke i Office: da vektorbilde (PDF).
            switch gradient.form {
            case .lineær:
                typer.append((OfficeUtklipp.type, OfficeUtklipp.data([(gradient.navn, .lineær(stopp: gradient.stopp, cssVinkel: gradient.vinkel), Gradientgrafikk.flate)])))
            case .radiell:
                typer.append((OfficeUtklipp.type, OfficeUtklipp.data([(gradient.navn, .radiell(stopp: gradient.stopp), Gradientgrafikk.flate)])))
            case .konisk:
                typer.append(("com.adobe.pdf", Gradientgrafikk.pdf(gradient)))
                if let png = Gradientgrafikk.png(gradient) { typer.append(("public.png", png)) }
            }
            tekst = nil
        case .photoshop:
            typer.append(("com.adobe.pdf", Gradientgrafikk.pdf(gradient)))
            if let png = Gradientgrafikk.png(gradient) { typer.append(("public.png", png)) }
            tekst = gradient.css.moderne
        case .css:
            tekst = gradient.css.deklarasjon
        case .swiftUI:
            tekst = Gradientgrafikk.swiftUI(gradient)
        }
        #if canImport(UIKit)
        var element: [String: Any] = [:]
        if let tekst { element["public.utf8-plain-text"] = tekst }
        for (type, data) in typer { element[type] = data }
        UIPasteboard.general.items = [element]
        #elseif canImport(AppKit)
        let tavle = NSPasteboard.general
        tavle.clearContents()
        for (type, data) in typer { tavle.setData(data, forType: NSPasteboard.PasteboardType(type)) }
        if let tekst { tavle.setString(tekst, forType: .string) }
        #endif
        merkEgen()
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

    /// PDF med gradienten som PDF-skyggelegging (aksial eller radiell) der fargene er beskrevet med eksponentielle
    /// funksjoner (FunctionType 2), skjøtet sammen med FunctionType 3 når det er flere stopp – én per stopp. Da blir den
    /// en ekte, redigerbar gradient i Illustrator og InDesign. (Quartz skriver en samplet funksjon, FunctionType 0, som
    /// Illustrator ikke kjenner igjen: «An unknown shading type was encountered».) Fargene i sRGB.
    static func pdf(_ g: Gradientkopi) -> Data {
        let r = flate
        // Stopp i stigende rekkefølge; harde overganger (trinnvis) får et lite mellomrom, siden grensene må stige.
        var stopp: [(farge: SRGB, posisjon: Double)] = []
        for s in g.stopp {
            var pos = min(max(s.posisjon, 0), 1)
            if let siste = stopp.last, pos <= siste.posisjon { pos = min(siste.posisjon + 0.0001, 1) }
            stopp.append((s.farge.gamutKartlagt(til: .sRGB).sRGB, pos))
        }
        if stopp.count == 1 { stopp.append((stopp[0].farge, 1)) }
        func tall(_ v: Double) -> String { String(format: "%.4f", v) }
        func farge(_ c: SRGB) -> String { "[\(tall(c.r)) \(tall(c.g)) \(tall(c.b))]" }
        func ledd(_ a: SRGB, _ b: SRGB) -> String { "<< /FunctionType 2 /Domain [0 1] /C0 \(farge(a)) /C1 \(farge(b)) /N 1 >>" }

        // Første og siste stopp trenger ikke ligge på 0 og 1: funksjonen strekkes over hele aksen.
        let start = stopp.first!.posisjon, slutt = stopp.last!.posisjon
        let lengde = max(slutt - start, 0.0001)
        let funksjon: String
        if stopp.count == 2 {
            funksjon = ledd(stopp[0].farge, stopp[1].farge)
        } else {
            let funksjoner = zip(stopp, stopp.dropFirst()).map { ledd($0.farge, $1.farge) }.joined(separator: " ")
            let grenser = stopp.dropFirst().dropLast().map { tall(($0.posisjon - start) / lengde) }.joined(separator: " ")
            let koding = Array(repeating: "0 1", count: stopp.count - 1).joined(separator: " ")
            funksjon = "<< /FunctionType 3 /Domain [0 1] /Functions [\(funksjoner)] /Bounds [\(grenser)] /Encode [\(koding)] >>"
        }

        // Aksen i PDF-koordinater (origo nede til venstre), forkortet til første og siste stopp.
        let skyggelegging: String
        if g.form == .radiell {
            let radius = hypot(r.width, r.height) / 2
            skyggelegging = "<< /ShadingType 3 /ColorSpace /DeviceRGB /Coords [\(tall(r.midX)) \(tall(r.midY)) \(tall(radius * start)) \(tall(r.midX)) \(tall(r.midY)) \(tall(radius * slutt))] /Extend [true true] /Function \(funksjon) >>"
        } else {
            let (a, b) = g.endepunkter(i: r)
            let p0 = CGPoint(x: a.x + (b.x - a.x) * start, y: r.height - (a.y + (b.y - a.y) * start))
            let p1 = CGPoint(x: a.x + (b.x - a.x) * slutt, y: r.height - (a.y + (b.y - a.y) * slutt))
            skyggelegging = "<< /ShadingType 2 /ColorSpace /DeviceRGB /Coords [\(tall(p0.x)) \(tall(p0.y)) \(tall(p1.x)) \(tall(p1.y))] /Extend [true true] /Function \(funksjon) >>"
        }
        let innhold = "q 0 0 \(tall(r.width)) \(tall(r.height)) re W n /Sh1 sh Q"
        let objekter = [
            "<< /Type /Catalog /Pages 2 0 R >>",
            "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 \(tall(r.width)) \(tall(r.height))] /Resources << /Shading << /Sh1 5 0 R >> >> /Contents 4 0 R >>",
            "<< /Length \(innhold.utf8.count) >>\nstream\n\(innhold)\nendstream",
            skyggelegging,
        ]
        var pdf = "%PDF-1.4\n"
        var forskyvninger: [Int] = []
        for (i, objekt) in objekter.enumerated() {
            forskyvninger.append(pdf.utf8.count)
            pdf += "\(i + 1) 0 obj\n\(objekt)\nendobj\n"
        }
        let xref = pdf.utf8.count
        pdf += "xref\n0 \(objekter.count + 1)\n0000000000 65535 f \n"
        for f in forskyvninger { pdf += String(format: "%010d 00000 n \n", f) }
        pdf += "trailer\n<< /Size \(objekter.count + 1) /Root 1 0 R >>\nstartxref\n\(xref)\n%%EOF\n"
        return Data(pdf.utf8)
    }

    // MARK: AICB (InDesign)

    /// Gradienten som PostScript i Illustrators utklippsformat (AICB): en boks fylt med et skyggeleggingsmønster
    /// (PatternType 2), som InDesign gjør om til én boks med ekte gradientfyll (lineær eller radiell, med alle stoppene).
    /// Mønsteret får gradientens eget koordinatsystem (fra 0 til 1 langs x-aksen) som matrise – InDesign leser
    /// stopposisjoner, retning og lengde derfra. (Med `clip` og `shfill` la InDesign boksen inne i en ekstra ramme.)
    /// Hvert stopp er et ledd i en sammenskjøtt funksjon (FunctionType 3). Fargene i sRGB (DeviceRGB). Testet mot
    /// InDesign 2026.
    static func aicb(_ g: Gradientkopi) -> Data {
        let r = flate
        var stopp: [(farge: SRGB, posisjon: Double)] = []
        for s in g.stopp {
            var pos = min(max(s.posisjon, 0), 1)
            if let siste = stopp.last, pos <= siste.posisjon { pos = min(siste.posisjon + 0.0001, 1) }
            stopp.append((s.farge.gamutKartlagt(til: .sRGB).sRGB, pos))
        }
        if stopp.count == 1 { stopp.append((stopp[0].farge, 1)) }
        func tall(_ v: Double) -> String { String(format: "%.4f", v) }
        func farge(_ c: SRGB) -> String { "[\(tall(min(max(c.r, 0), 1))) \(tall(min(max(c.g, 0), 1))) \(tall(min(max(c.b, 0), 1)))]" }
        func ledd(_ a: SRGB, _ b: SRGB) -> String { "<< /FunctionType 2 /Domain [0 1] /C0 \(farge(a)) /C1 \(farge(b)) /N 1 >>" }
        let funksjon: String
        if stopp.count == 2 {
            funksjon = ledd(stopp[0].farge, stopp[1].farge)
        } else {
            let funksjoner = zip(stopp, stopp.dropFirst()).map { ledd($0.farge, $1.farge) }.joined(separator: " ")
            let grenser = stopp.dropFirst().dropLast().map { tall($0.posisjon) }.joined(separator: " ")
            let koding = Array(repeating: "0 1", count: stopp.count - 1).joined(separator: " ")
            funksjon = "<< /FunctionType 3 /Domain [0 1] /Functions [\(funksjoner)] /Bounds [\(grenser)] /Encode [\(koding)] >>"
        }
        // PostScript har origo nede til venstre; CSS-vinkelen er regnet med y nedover.
        let matrise: String, skyggelegging: String
        if g.form == .radiell {
            let radius = hypot(r.width, r.height) / 2
            matrise = "[\(tall(radius)) 0 0 \(tall(radius)) \(tall(r.midX)) \(tall(r.midY))]"
            skyggelegging = "<< /ShadingType 3 /ColorSpace /DeviceRGB /Coords [0 0 0 0 0 1] /Domain [0 1] /Extend [true true] /Function \(funksjon) >>"
        } else {
            let (a, b) = g.endepunkter(i: r)
            let p0 = CGPoint(x: a.x, y: r.height - a.y), p1 = CGPoint(x: b.x, y: r.height - b.y)
            let dx = p1.x - p0.x, dy = p1.y - p0.y
            matrise = "[\(tall(dx)) \(tall(dy)) \(tall(-dy)) \(tall(dx)) \(tall(p0.x)) \(tall(p0.y))]"
            skyggelegging = "<< /ShadingType 2 /ColorSpace /DeviceRGB /Coords [0 0 1 0] /Domain [0 1] /Extend [true true] /Function \(funksjon) >>"
        }
        let linjer = [
            "%!PS-Adobe-3.0 EPSF-3.0",
            "%%Creator: Kolorist",
            "%%Title: (Kolorist)",
            "%%BoundingBox: 0 0 \(Int(r.width)) \(Int(r.height))",
            "%%LanguageLevel: 3",
            "%%EndComments",
            "%%BeginProlog",
            "%%EndProlog",
            "%%Page: 1 1",
            "gsave",
            "<< /PatternType 2 /Shading \(skyggelegging) >> \(matrise) makepattern setpattern",
            "newpath 0 0 moveto 0 \(tall(r.height)) lineto \(tall(r.width)) \(tall(r.height)) lineto \(tall(r.width)) 0 lineto closepath fill",
            "grestore",
            "showpage",
            "%%Trailer",
            "%%EOF",
            "",
        ]
        return Data(linjer.joined(separator: "\r").utf8)
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

    // MARK: Pages, Keynote, Numbers og Freeform

    /// Figur med redigerbar gradient for Pages, Keynote, Numbers og Freeform (`IWorkUtklipp`). Vinkelen regnes der
    /// mot klokka fra høyre, altså 90° minus CSS-vinkelen. Nil for former formatet ikke tar imot.
    static func iWorkFigur(_ g: Gradientkopi) -> Data? {
        guard g.form == .lineær else { return nil }
        return IWorkUtklipp.data([(.lineær(stopp: g.stopp, vinkel: 90 - g.vinkel), flate)])
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
