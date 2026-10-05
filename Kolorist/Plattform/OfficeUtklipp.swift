import CoreGraphics
import FargeKjerne
import Foundation

/// Figurer for Word, Excel og PowerPoint: Offices eget utklippsformat for tegninger
/// (`com.microsoft.Art--GVML-ClipFormat`) – en zip-pakke med DrawingML, som Office selv legger på utklippstavlen.
/// Limes inn som ekte figurer med fargefyll eller redigerbar gradient (lineær og radiell), ikke som bilde.
/// Office arbeider i sRGB, så fargene gamut-kartlegges dit.
enum OfficeUtklipp {
    static let type = "com.microsoft.Art--GVML-ClipFormat"

    enum Fyll {
        case farge(Farge)
        /// Lineær gradient; vinkelen som i CSS (0° = opp, 90° = mot høyre).
        case lineær(stopp: [(farge: Farge, posisjon: Double)], cssVinkel: Double)
        /// Radiell gradient fra midten.
        case radiell(stopp: [(farge: Farge, posisjon: Double)])
    }

    /// Figurene som utklippsdata. Rammene er i punkter; navnet vises i Offices utvalgsrute.
    static func data(_ figurer: [(navn: String, fyll: Fyll, ramme: CGRect)]) -> Data {
        let emu = 12_700.0  // EMU per punkt
        let bredde = Int((figurer.map(\.ramme.maxX).max() ?? 0) * emu), høyde = Int((figurer.map(\.ramme.maxY).max() ?? 0) * emu)
        let former = figurer.enumerated().map { i, f in
            let r = f.ramme
            return "<a:sp><a:nvSpPr><a:cNvPr id=\"\(i + 2)\" name=\"\(xml(f.navn))\"/><a:cNvSpPr/></a:nvSpPr><a:spPr>"
                + "<a:xfrm><a:off x=\"\(Int(r.minX * emu))\" y=\"\(Int(r.minY * emu))\"/><a:ext cx=\"\(Int(r.width * emu))\" cy=\"\(Int(r.height * emu))\"/></a:xfrm>"
                + "<a:prstGeom prst=\"rect\"><a:avLst/></a:prstGeom>\(fyll(f.fyll))<a:ln><a:noFill/></a:ln></a:spPr></a:sp>"
        }.joined()
        let tegning = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas"><lc:lockedCanvas xmlns:lc="http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas"><a:nvGrpSpPr><a:cNvPr id="0" name=""/><a:cNvGrpSpPr/></a:nvGrpSpPr><a:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="\(bredde)" cy="\(høyde)"/><a:chOff x="0" y="0"/><a:chExt cx="\(bredde)" cy="\(høyde)"/></a:xfrm></a:grpSpPr>\(former)</lc:lockedCanvas></a:graphicData></a:graphic>
            """
        let typer = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/clipboard/drawings/drawing1.xml" ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/></Types>
            """
        let relasjoner = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing" Target="clipboard/drawings/drawing1.xml"/></Relationships>
            """
        return Zip.lagret([("[Content_Types].xml", Data(typer.utf8)), ("_rels/.rels", Data(relasjoner.utf8)),
                           ("clipboard/drawings/drawing1.xml", Data(tegning.utf8))])
    }

    private static func farge(_ f: Farge) -> String {
        "<a:srgbClr val=\"\(f.gamutKartlagt(til: .sRGB).hex().dropFirst())\"/>"
    }

    private static func stoppliste(_ stopp: [(farge: Farge, posisjon: Double)]) -> String {
        "<a:gsLst>" + stopp.map { "<a:gs pos=\"\(Int((min(max($0.posisjon, 0), 1) * 100_000).rounded()))\">\(farge($0.farge))</a:gs>" }.joined()
            + "</a:gsLst>"
    }

    private static func fyll(_ fyll: Fyll) -> String {
        switch fyll {
        case .farge(let f):
            return "<a:solidFill>\(farge(f))</a:solidFill>"
        case .lineær(let stopp, let cssVinkel):
            // DrawingML: 0° = mot høyre, med klokka, i 1/60 000 grad – altså CSS-vinkelen minus 90°.
            var v = (cssVinkel - 90).truncatingRemainder(dividingBy: 360)
            if v < 0 { v += 360 }
            return "<a:gradFill rotWithShape=\"1\">\(stoppliste(stopp))<a:lin ang=\"\(Int((v * 60_000).rounded()))\" scaled=\"0\"/></a:gradFill>"
        case .radiell(let stopp):
            return "<a:gradFill rotWithShape=\"1\">\(stoppliste(stopp))<a:path path=\"circle\">"
                + "<a:fillToRect l=\"50000\" t=\"50000\" r=\"50000\" b=\"50000\"/></a:path></a:gradFill>"
        }
    }

    private static func xml(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }
}

/// Minimal zip-skriver: filer lagret uten komprimering (nok for små XML-pakker som Office-utklipp).
enum Zip {
    static func lagret(_ filer: [(navn: String, data: Data)]) -> Data {
        var ut = Data(), sentral = Data()
        for (navn, data) in filer {
            let navnedata = Data(navn.utf8)
            let crc = crc32(data), forskyvning = UInt32(ut.count)
            let størrelse = UInt32(data.count), navnelengde = UInt16(navnedata.count)
            // Lokalt filhode: signatur, versjon, flagg, metode (0 = lagret), tid, dato, CRC, størrelser, navn.
            ut.append(u32(0x0403_4B50)); ut.append(u16(20)); ut.append(u16(0)); ut.append(u16(0))
            ut.append(u16(0)); ut.append(u16(0x21))
            ut.append(u32(crc)); ut.append(u32(størrelse)); ut.append(u32(størrelse))
            ut.append(u16(navnelengde)); ut.append(u16(0))
            ut.append(navnedata); ut.append(data)
            // Oppføring i den sentrale katalogen, med plassen til det lokale hodet.
            sentral.append(u32(0x0201_4B50)); sentral.append(u16(20)); sentral.append(u16(20)); sentral.append(u16(0))
            sentral.append(u16(0)); sentral.append(u16(0)); sentral.append(u16(0x21))
            sentral.append(u32(crc)); sentral.append(u32(størrelse)); sentral.append(u32(størrelse))
            sentral.append(u16(navnelengde)); sentral.append(u16(0)); sentral.append(u16(0))
            sentral.append(u16(0)); sentral.append(u16(0)); sentral.append(u32(0)); sentral.append(u32(forskyvning))
            sentral.append(navnedata)
        }
        let start = UInt32(ut.count), antall = UInt16(filer.count)
        ut.append(sentral)
        // Slutten av den sentrale katalogen.
        ut.append(u32(0x0605_4B50)); ut.append(u16(0)); ut.append(u16(0)); ut.append(u16(antall)); ut.append(u16(antall))
        ut.append(u32(UInt32(sentral.count))); ut.append(u32(start)); ut.append(u16(0))
        return ut
    }

    private static let tabell: [UInt32] = (0..<256).map { n in
        var c = UInt32(n)
        for _ in 0..<8 { c = c & 1 == 1 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1 }
        return c
    }

    static func crc32(_ data: Data) -> UInt32 {
        var c: UInt32 = 0xFFFF_FFFF
        for b in data { c = tabell[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
        return c ^ 0xFFFF_FFFF
    }

    private static func u16(_ v: UInt16) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }
    private static func u32(_ v: UInt32) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }
}
