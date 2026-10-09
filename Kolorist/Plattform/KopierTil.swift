import CoreGraphics
import ImageIO
import FargeKjerne
import SwiftUI
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// «Kopier til …»: farger på utklippstavlen i formatet målprogrammet tar imot ved innliming.
///
/// - Figma, Sketch, Affinity: SVG – limes inn som former med riktig fyll.
/// - Illustrator, InDesign: PDF – vektorformer i fargens eget fargerom, også CMYK med ICC-profil.
///   (Adobe har ikke noe felles utklippsformat for fargeprøver; ASE-eksporten er veien inn i
///   fargeprøvepanelet.)
/// - Photoshop: PDF (limes inn som formlag, smartobjekt eller piksler – Photoshop spør), PNG som
///   reserve, og hex uten «#» som tekst til hex-feltet i fargevelgeren.
/// - Pages, Keynote, Numbers: figurer med fargefyll i Apples felles utklippsformat (`IWorkUtklipp`), uten tekst.
/// - Word, Excel, PowerPoint: figurer med fargefyll i Offices utklippsformat (`OfficeUtklipp`), uten tekst.
/// - CSS og SwiftUI: kode.
/// - Blender: lineære verdier som `[r, g, b, a]`, formatet Blender selv kopierer et fargefelt som (⌘C/⌘V over feltet).
/// - RGB 0–255 og 0–1: verdilister i sRGB, til programmer med egne felt for hver kanal (CAD, BIM, video, spillmotorer).
/// - Macens fargevelger (bare Mac): fargeliste (.clr) i Bibliotek/Colors, så fargene finnes i fargevelgeren i alle
///   programmer som bruker den.
/// De andre målene får i tillegg tekst (hex), så innliming i et tekstfelt også gir mening.
enum Kopimål: String, CaseIterable, Identifiable {
    case figma, illustrator, indesign, photoshop, sketchAffinity, iWork, office, css, swiftUI, blender, rgb255, rgb01,
         fargevelger

    var id: String { rawValue }

    /// Målene som finnes på denne plattformen (fargevelgeren bare på Mac).
    static var tilgjengelige: [Kopimål] {
        #if os(macOS)
        allCases
        #else
        allCases.filter { $0 != .fargevelger }
        #endif
    }

    var navn: String {
        switch self {
        case .figma: "Figma"
        case .illustrator: "Illustrator"
        case .indesign: "InDesign"
        case .photoshop: "Photoshop"
        case .sketchAffinity: "Sketch / Affinity"
        case .iWork: "Pages / Keynote / Numbers"
        case .office: "Word / Excel / PowerPoint"
        case .css: "CSS"
        case .swiftUI: "SwiftUI"
        case .blender: "Blender"
        case .rgb255: String(localized: "RGB 0–255")
        case .rgb01: String(localized: "RGB 0–1")
        case .fargevelger: String(localized: "Macens fargevelger")
        }
    }

    var forklaring: String {
        switch self {
        case .figma, .sketchAffinity: String(localized: "Som former (SVG)")
        case .illustrator, .indesign: String(localized: "Som vektorformer (PDF), med fargerom og ICC")
        case .photoshop: String(localized: "Som formlag (PDF), og hex til fargevelgeren")
        case .iWork, .office: String(localized: "Som figurer med fargefyll")
        case .css: String(localized: "Som variabler")
        case .swiftUI: String(localized: "Som Color-konstanter")
        case .blender: String(localized: "Som lineære verdier til fargefelt")
        case .rgb255: String(localized: "Som verdier, f.eks. til CAD og BIM")
        case .rgb01: String(localized: "Som desimaler, f.eks. til video og spillmotorer")
        case .fargevelger: String(localized: "Som fargeliste i alle programmer")
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
        case .blender: "cube"
        case .rgb255, .rgb01: "number"
        case .fargevelger: "paintpalette"
        }
    }
}

/// Undermeny «Kopier til» for én farge eller en hel palett.
struct KopierTilMeny: View {
    let farger: [PalettFarge]
    var navn: String = ""
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

    /// Målene som er slått på, i valgt rekkefølge (se `KopimålArk`), og til slutt «Tilpass listen …».
    @ViewBuilder private var valg: some View {
        ForEach(Kopiinnstillinger.synlige(Kopimål.tilgjengelige.map(\.rawValue), rekkefølge: rekkefølge, skjult: skjult)
            .compactMap(Kopimål.init(rawValue:))) { mål in
            Button {
                Utklippstavle.kopier(farger, navn: navn, til: mål)
            } label: {
                Label { Text(mål.navn); Text(mål.forklaring) } icon: { Image(systemName: mål.symbol) }
            }
        }
        TilpassKopimålKnapp()
    }
}

extension Utklippstavle {
    static func kopier(_ farger: [PalettFarge], navn: String, til mål: Kopimål) {
        guard !farger.isEmpty else { return }
        #if os(macOS)
        if mål == .fargevelger {
            Fargeliste.leggTil(farger, navn: navn)
            return
        }
        #endif
        let palett = Palett(navn: navn.isEmpty ? String(localized: "Kolorist") : navn, farger: farger)
        let hex = farger.map { $0.farge.hex(medAlfa: $0.farge.alfa < 1) }.joined(separator: "\n")
        var typer: [(String, Data)] = []
        let tekst: String?
        switch mål {
        case .figma, .sketchAffinity:
            let svg = Eksportformat.svg.data(for: palett)
            typer.append(("public.svg-image", svg))
            // Figma og Sketch leser SVG-koden fra teksten på utklippstavlen.
            tekst = String(decoding: svg, as: UTF8.self)
        case .illustrator, .indesign:
            typer.append(("com.adobe.pdf", Fargeprøvepdf.data(for: farger)))
            tekst = hex
        case .photoshop:
            // Photoshop limer inn grafikk fra utklippstavlen: PDF gir valget «Formlag» (vektor med
            // riktig fyll), PNG er reserve. Teksten (hex uten #) brukes når man limer i hex-feltet.
            typer.append(("com.adobe.pdf", Fargeprøvepdf.data(for: farger)))
            if let png = Fargeprøvepdf.png(for: farger) { typer.append(("public.png", png)) }
            tekst = farger.map { String($0.farge.hex().dropFirst()) }.joined(separator: "\n")
        case .iWork:
            // Figurer med fargefyll i Apples felles utklippsformat, som i Pages, Keynote og Numbers selv. Uten tekst
            // ved siden av: Numbers limer heller inn teksten (i en markert celle) enn figurene.
            let r = Fargeprøvepdf.rute, m = Fargeprøvepdf.mellomrom
            let figurer = farger.enumerated().map { i, pf in
                (IWorkUtklipp.Fyll.farge(pf.farge), CGRect(x: CGFloat(i) * (r + m), y: 0, width: r, height: r))
            }
            if let data = IWorkUtklipp.data(figurer) { typer.append((IWorkUtklipp.type, data)) }
            tekst = nil
        case .office:
            // Figurer med fargefyll og fargens navn (vises i Offices utvalgsrute). Uten tekst, som i Office selv.
            let r = Fargeprøvepdf.rute, m = Fargeprøvepdf.mellomrom
            let figurer = farger.enumerated().map { i, pf in
                (pf.navn.isEmpty ? pf.farge.hex() : pf.navn, OfficeUtklipp.Fyll.farge(pf.farge),
                 CGRect(x: CGFloat(i) * (r + m), y: 0, width: r, height: r))
            }
            typer.append((OfficeUtklipp.type, OfficeUtklipp.data(figurer)))
            tekst = nil
        case .css:
            tekst = String(decoding: Eksportformat.css.data(for: palett), as: UTF8.self)
        case .swiftUI:
            tekst = String(decoding: Eksportformat.swiftUI.data(for: palett), as: UTF8.self)
        case .blender:
            tekst = farger.map { Verdiliste.blender($0.farge) }.joined(separator: "\n")
        case .rgb255:
            tekst = farger.map { Verdiliste.rgb255($0.farge) }.joined(separator: "\n")
        case .rgb01:
            tekst = farger.map { Verdiliste.rgb01($0.farge) }.joined(separator: "\n")
        case .fargevelger:
            // Håndtert over (Mac); finnes ikke i menyene ellers.
            tekst = hex
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

/// Fargeverdier som tekst, én farge per linje. Farger utenfor sRGB gamut-kartlegges først; alfa tas med bare når
/// fargen ikke er dekkende (Blender har alltid fire verdier). Alltid punktum som desimaltegn.
enum Verdiliste {
    /// `[r, g, b, a]` i lineær sRGB med seks desimaler, som Blender kopierer fargefelt (scene linear, Rec. 709-primærer).
    static func blender(_ farge: Farge) -> String {
        let f = farge.gamutKartlagt(til: .sRGB)
        return "[" + [f.r, f.g, f.b, f.alfa].map { tall($0.klampet01, desimaler: 6) }.joined(separator: ", ") + "]"
    }

    /// `47, 127, 216` – gammakodet sRGB i heltall.
    static func rgb255(_ farge: Farge) -> String {
        let s = farge.gamutKartlagt(til: .sRGB).sRGB
        var verdier = [s.r, s.g, s.b].map { String(Int(($0.klampet01 * 255).rounded())) }
        if farge.alfa < 1 { verdier.append(tall(farge.alfa, desimaler: 2)) }
        return verdier.joined(separator: ", ")
    }

    /// `0.1843, 0.4980, 0.8471` – gammakodet sRGB i desimaler.
    static func rgb01(_ farge: Farge) -> String {
        let s = farge.gamutKartlagt(til: .sRGB).sRGB
        var verdier = [s.r, s.g, s.b].map { tall($0.klampet01, desimaler: 4) }
        if farge.alfa < 1 { verdier.append(tall(farge.alfa, desimaler: 4)) }
        return verdier.joined(separator: ", ")
    }

    private static func tall(_ v: Double, desimaler: Int) -> String {
        String(format: "%.\(desimaler)f", locale: Locale(identifier: "en_US_POSIX"), v)
    }
}

private extension Double {
    var klampet01: Double { Swift.min(Swift.max(self, 0), 1) }
}

#if os(macOS)
/// Macens fargevelger: fargene som en fargeliste (.clr) i Bibliotek/Colors i hjemmemappa, som fargevelgeren i alle
/// programmer leser. En liste med samme navn byttes ut. Går det ikke å skrive dit, får brukeren velge plassering.
enum Fargeliste {
    /// Listene som er lagt ved fargevelgeren i denne økten, etter navn.
    private static var vedlagt: [String: NSColorList] = [:]

    static func leggTil(_ farger: [PalettFarge], navn: String) {
        let listenavn = LagreSomArk.rentFilnavn(navn.isEmpty ? String(localized: "Kolorist") : navn)
        let liste = liste(farger, navn: listenavn)
        let mappe = URL(fileURLWithPath: hjemmemappe).appendingPathComponent("Library/Colors", isDirectory: true)
        let fil = mappe.appendingPathComponent("\(listenavn).clr")
        do {
            try FileManager.default.createDirectory(at: mappe, withIntermediateDirectories: true)
            try liste.write(to: fil)
        } catch {
            // Sandkassen kan stenge mappa: la brukeren lagre fila selv (fargevelgeren åpner den med «Åpne …»).
            let panel = NSSavePanel()
            panel.directoryURL = mappe
            panel.nameFieldStringValue = fil.lastPathComponent
            panel.allowedContentTypes = [.init(filenameExtension: "clr") ?? .data]
            panel.message = String(localized: "Lagre fargelista i Bibliotek/Colors, så finnes den i fargevelgeren i alle programmer.")
            guard panel.runModal() == .OK, let url = panel.url, (try? liste.write(to: url)) != nil else { return }
        }
        // Vis lista i fargevelgeren som bekreftelse (en tidligere utgave med samme navn tas ut først).
        let panel = NSColorPanel.shared
        if let forrige = vedlagt[listenavn] { panel.detachColorList(forrige) }
        vedlagt[listenavn] = liste
        panel.attachColorList(liste)
        panel.mode = .colorList
        panel.orderFront(nil)
    }

    /// Fargelista: én farge per navn (fargens navn, ellers hex; like navn får nummer).
    static func liste(_ farger: [PalettFarge], navn: String) -> NSColorList {
        let liste = NSColorList(name: navn)
        var brukt: [String: Int] = [:]
        for pf in farger {
            let grunn = pf.navn.isEmpty ? pf.farge.hex() : pf.navn
            let antall = brukt[grunn, default: 0] + 1
            brukt[grunn] = antall
            let nøkkel = antall == 1 ? grunn : "\(grunn) (\(antall))"
            liste.setColor(NSColor(cgColor: Fargeprøvepdf.cgFarge(pf)) ?? .black, forKey: nøkkel)
        }
        return liste
    }

    /// Den ekte hjemmemappa (ikke sandkassens container).
    private static var hjemmemappe: String {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir { return String(cString: dir) }
        return NSHomeDirectory()
    }
}
#endif

/// Fargeprøver som PDF (vektor): én flate per farge, i fargens eget fargerom. Farger lagret i en
/// ICC-profil (f.eks. CMYK) tegnes med de lagrede verdiene i den profilen; ellers sRGB, eller
/// Display P3 for farger utenfor sRGB.
enum Fargeprøvepdf {
    static let rute: CGFloat = 96, mellomrom: CGFloat = 8

    static func data(for farger: [PalettFarge]) -> Data {
        let data = NSMutableData()
        var boks = CGRect(x: 0, y: 0, width: CGFloat(farger.count) * (rute + mellomrom) - mellomrom, height: rute)
        guard let forbruker = CGDataConsumer(data: data as CFMutableData),
              let ctx = CGContext(consumer: forbruker, mediaBox: &boks, nil)
        else { return Data() }
        ctx.beginPDFPage(nil)
        for (i, pf) in farger.enumerated() {
            ctx.setFillColor(cgFarge(pf))
            ctx.fill(CGRect(x: CGFloat(i) * (rute + mellomrom), y: 0, width: rute, height: rute))
        }
        ctx.endPDFPage()
        ctx.closePDF()
        return data as Data
    }

    /// Samme fargeprøver som PNG (for programmer som bare tar imot punktgrafikk).
    static func png(for farger: [PalettFarge], skala: CGFloat = 2) -> Data? {
        let b = Int((CGFloat(farger.count) * (rute + mellomrom) - mellomrom) * skala), h = Int(rute * skala)
        guard let rom = CGColorSpace(name: CGColorSpace.displayP3),
              let ctx = CGContext(data: nil, width: b, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: rom,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.scaleBy(x: skala, y: skala)
        for (i, pf) in farger.enumerated() {
            ctx.setFillColor(cgFarge(pf))
            ctx.fill(CGRect(x: CGFloat(i) * (rute + mellomrom), y: 0, width: rute, height: rute))
        }
        guard let bilde = ctx.makeImage() else { return nil }
        let data = NSMutableData()
        guard let mål = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(mål, bilde, nil)
        return CGImageDestinationFinalize(mål) ? data as Data : nil
    }

    static func cgFarge(_ pf: PalettFarge) -> CGColor {
        let alfa = CGFloat(pf.farge.alfa)
        if let rep = pf.representasjon, case .icc(let id, _) = rep.rom,
           let rom = ProfilBibliotek.delt.profil(id: id)?.fargerom, rom.numberOfComponents == rep.verdier.count,
           let c = CGColor(colorSpace: rom, components: rep.verdier.map { CGFloat($0) } + [alfa]) {
            return c
        }
        if pf.farge.erISRGB {
            let v = pf.farge.sRGB
            return CGColor(srgbRed: v.r, green: v.g, blue: v.b, alpha: alfa)
        }
        let v = pf.farge.gamutKartlagt(til: .displayP3).displayP3
        return CGColor(colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!, components: [v.r, v.g, v.b, alfa])!
    }
}
