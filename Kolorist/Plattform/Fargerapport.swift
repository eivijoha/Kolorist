import CoreGraphics
import CoreText
import FargeKjerne
import Foundation
import SwiftUI

/// En fargerapport – vanskelige fargepar, kontrast mellom flater eller ΔE – som kan kopieres som tabell, deles som lenke
/// (kolorist.no viser rapporten) og skrives ut eller lagres som PDF.
nonisolated struct Fargerapport: Sendable {
    /// Navnet på lenken og PDF-en (f.eks. palettens navn); tomt gir rapportens tittel.
    var navn: String
    var farger: [PalettFarge]
    var rapport: DeltRapport

    var tittel: String { navn.isEmpty ? rapport.tittel : "\(rapport.tittel): \(navn)" }

    var innhold: DeltInnhold {
        DeltInnhold(slag: .palett, navn: tittel, farger: farger.map(DeltFarge.init), rapport: rapport)
    }

    /// A4-PDF: tittel, fargeparene som prøver (med fargene slik avviket ser dem), og tabellen.
    var pdf: Data {
        let dato = Date.now.formatted(date: .long, time: .omitted)
        let undertittel = [String(localized: "Kolorist"), dato, rapport.undertittel].compactMap { $0 }.joined(separator: " · ")
        let par = rapport.par.map { p in
            RapportPDF.Par(a: farger[p.a].farge.cieLab, b: farger[p.b].farge.cieLab,
                           simulertA: p.simulertA.flatMap { Farge(hex: $0)?.cieLab },
                           simulertB: p.simulertB.flatMap { Farge(hex: $0)?.cieLab },
                           tekst: [farger[p.a].visningsnavn, farger[p.b].visningsnavn].joined(separator: " / ")
                               + (p.tekst.map { "\n" + $0 } ?? ""))
        }
        var matrise: RapportPDF.Matrise?
        if let rader = rapport.matriseRader, let kolonner = rapport.matriseKolonner, let godkjent = rapport.godkjent {
            matrise = RapportPDF.Matrise(rader: rader.map { (farger[$0].farge.cieLab, farger[$0].visningsnavn) },
                                         kolonner: kolonner.map { (farger[$0].farge.cieLab, farger[$0].visningsnavn) },
                                         celler: rapport.tabell.dropFirst().map { Array($0.dropFirst()) }, godkjent: godkjent)
        }
        return RapportPDF.lag(tittel: tittel, undertittel: undertittel, par: par, tabell: rapport.tabell,
                              overskrift: rapport.overskrift, matrise: matrise) { side, av in String(localized: "Side \(side) av \(av)") }
    }
}

/// Kopier, del og skriv ut en fargerapport – i menyer og som knapper under en vurdering.
struct RapportValg: View {
    let rapport: Fargerapport

    var body: some View {
        let innhold = rapport.innhold
        Button("Kopier som tabell", systemImage: "tablecells") { Utklippstavle.kopierTekst(rapport.rapport.tabulatortekst) }
        DelSomLenke(navn: rapport.tittel, tittel: "Del rapporten som lenke") { innhold }
        Button("Skriv ut rapporten …", systemImage: "printer") { PalettUtskrift.skrivUt(pdf: rapport.pdf, jobb: rapport.tittel) }
    }
}

/// A4-PDF av en fargerapport, tegnet med CoreGraphics og CoreText som palettene (`PalettPDF`), med fargeflatene i CIELab.
nonisolated enum RapportPDF {
    struct Par: Sendable {
        var a: CIELab
        var b: CIELab
        var simulertA: CIELab?
        var simulertB: CIELab?
        var tekst: String
    }

    /// Skriftkontrast: hver tekstfarge (rad) på hver bakgrunn (kolonne), med forholdet og om cellen holder kravet.
    struct Matrise: Sendable {
        var rader: [(lab: CIELab, navn: String)]
        var kolonner: [(lab: CIELab, navn: String)]
        var celler: [[String]]
        var godkjent: [[Bool]]
    }

    private static let side = PalettPDF.side
    private static let marg = PalettPDF.marg
    private static let parPerRad = 3
    private static let prøvehøyde: CGFloat = 26
    private static let celleluft: CGFloat = 4

    static func lag(tittel: String, undertittel: String, par: [Par], tabell: [[String]], overskrift: Bool,
                    matrise: Matrise? = nil, sidetekst: (Int, Int) -> String) -> Data {
        // To gjennomganger: først for å telle sidene (til «Side n av m»), så den som blir PDF-en.
        func tegnet(totalt: Int) -> (data: Data, sider: Int) {
            let data = NSMutableData()
            guard let mottaker = CGDataConsumer(data: data as CFMutableData) else { return (Data(), 0) }
            var boks = side
            let info: [CFString: Any] = [kCGPDFContextTitle: tittel, kCGPDFContextCreator: "Kolorist"]
            guard let ctx = CGContext(consumer: mottaker, mediaBox: &boks, info as CFDictionary) else { return (Data(), 0) }
            let sider = tegn(i: ctx, tittel: tittel, undertittel: undertittel, par: par, tabell: tabell, overskrift: overskrift,
                             matrise: matrise) {
                sidetekst($0, totalt)
            }
            ctx.closePDF()
            return (data as Data, sider)
        }
        return tegnet(totalt: tegnet(totalt: 1).sider).data
    }

    private static func tegn(i ctx: CGContext, tittel: String, undertittel: String, par: [Par], tabell: [[String]],
                             overskrift: Bool, matrise: Matrise?, sidetall: (Int) -> String) -> Int {
        let lab = CGColorSpace(labWhitePoint: [0.9642, 1.0, 0.8249], blackPoint: [0, 0, 0], range: [-128, 127, -128, 127])
        let fullBredde = side.width - 2 * marg
        let bunn = side.height - marg - 14
        var sidenr = 0
        var y: CGFloat = 0

        func avsluttSide() {
            PalettPDF.tegn(sidetall(sidenr), font: PalettPDF.font(7.5), farge: 0.5, i: ctx,
                           x: marg, topp: side.height - marg, bredde: fullBredde, høyrestilt: true)
            ctx.endPDFPage()
        }
        func nySide() {
            if sidenr > 0 { avsluttSide() }
            ctx.beginPDFPage(nil)
            sidenr += 1
            if sidenr == 1 {
                PalettPDF.tegn(tittel, font: PalettPDF.font(18, fet: true), farge: 0, i: ctx, x: marg, topp: marg, bredde: fullBredde)
                PalettPDF.tegn(undertittel, font: PalettPDF.font(8.5), farge: 0.4, i: ctx, x: marg, topp: marg + 28, bredde: fullBredde)
                y = marg + 28 + 16 + 18
            } else {
                PalettPDF.tegn(tittel, font: PalettPDF.font(11, fet: true), farge: 0, i: ctx, x: marg, topp: marg, bredde: fullBredde)
                y = marg + 24
            }
        }
        func fyll(_ l: CIELab, _ rekt: CGRect) {
            if let lab, let farge = CGColor(colorSpace: lab, components: [CGFloat(l.l), CGFloat(l.a), CGFloat(l.b), 1]) {
                ctx.setFillColor(farge)
                ctx.fill(rekt)
            }
        }

        nySide()
        // Fargeparene: to flater side om side, og under dem fargene slik avviket ser dem.
        let mellomrom: CGFloat = 14
        let parbredde = (fullBredde - CGFloat(parPerRad - 1) * mellomrom) / CGFloat(parPerRad)
        let teksthøyde: (String) -> CGFloat = { PalettPDF.høyde(av: tekst($0), bredde: parbredde) }
        for start in stride(from: 0, to: par.count, by: parPerRad) {
            let rad = Array(par[start..<min(par.count, start + parPerRad)])
            let medSimulert = rad.contains { $0.simulertA != nil }
            let høyde = prøvehøyde * (medSimulert ? 2 : 1) + 2 + 6 + (rad.map { teksthøyde($0.tekst) }.max() ?? 0)
            if y + høyde > bunn { nySide() }
            for (k, p) in rad.enumerated() {
                let x = marg + CGFloat(k) * (parbredde + mellomrom)
                let halv = parbredde / 2
                var topp = y
                for (venstre, høyre) in [(p.a, p.b)] + (p.simulertA.flatMap { a in p.simulertB.map { (a, $0) } }.map { [$0] } ?? []) {
                    let yPDF = side.height - topp - prøvehøyde
                    fyll(venstre, CGRect(x: x, y: yPDF, width: halv, height: prøvehøyde))
                    fyll(høyre, CGRect(x: x + halv, y: yPDF, width: halv, height: prøvehøyde))
                    ctx.setStrokeColor(gray: 0, alpha: 0.18)
                    ctx.setLineWidth(0.5)
                    ctx.stroke(CGRect(x: x, y: yPDF, width: parbredde, height: prøvehøyde).insetBy(dx: 0.25, dy: 0.25))
                    topp += prøvehøyde + 2
                }
                PalettPDF.tegn(tekst(p.tekst), i: ctx, x: x, topp: y + prøvehøyde * (medSimulert ? 2 : 1) + 2 + 6, bredde: parbredde)
            }
            y += høyde + 16
        }

        if let m = matrise {
            tegnMatrise(m)
            avsluttSide()
            return sidenr
        }

        /// Matrisen: kolonnenes bakgrunner øverst, tekstfargene til venstre, og i hver celle «Aa» og forholdet i
        /// tekstfargen på bakgrunnen, med en grønn eller rød prikk for kravet.
        func tegnMatrise(_ m: Matrise) {
            let radkolonne: CGFloat = 78
            let cellebredde = min(58, (fullBredde - radkolonne) / CGFloat(max(m.kolonner.count, 1)))
            let cellehøyde: CGFloat = 38
            let navnefont = PalettPDF.font(6.5)
            func labfarge(_ l: CIELab) -> CGColor? {
                lab.flatMap { CGColor(colorSpace: $0, components: [CGFloat(l.l), CGFloat(l.a), CGFloat(l.b), 1]) }
            }
            func overskrift() {
                for (k, kol) in m.kolonner.enumerated() {
                    let x = marg + radkolonne + CGFloat(k) * cellebredde
                    fyll(kol.lab, CGRect(x: x + 1, y: side.height - y - 12, width: cellebredde - 2, height: 12))
                    PalettPDF.tegn(kol.navn, font: navnefont, farge: 0.3, i: ctx, x: x + 1, topp: y + 14, bredde: cellebredde - 2)
                }
                y += 34
            }
            overskrift()
            for (r, rad) in m.rader.enumerated() {
                if y + cellehøyde > bunn { nySide(); overskrift() }
                fyll(rad.lab, CGRect(x: marg, y: side.height - y - cellehøyde + 1, width: 10, height: cellehøyde - 2))
                PalettPDF.tegn(rad.navn, font: navnefont, farge: 0.2, i: ctx, x: marg + 14, topp: y + 4, bredde: radkolonne - 18)
                for (k, kol) in m.kolonner.enumerated() {
                    let x = marg + radkolonne + CGFloat(k) * cellebredde
                    let celle = CGRect(x: x + 1, y: side.height - y - cellehøyde + 1, width: cellebredde - 2, height: cellehøyde - 2)
                    let tekst = r < m.celler.count && k + 0 < m.celler[r].count ? m.celler[r][k] : ""
                    if tekst == "—" {
                        ctx.setFillColor(gray: 0.94, alpha: 1)
                        ctx.fill(celle)
                        PalettPDF.tegn("—", font: PalettPDF.font(8), farge: 0.5, i: ctx, x: x + 6, topp: y + 12, bredde: cellebredde - 8)
                        continue
                    }
                    fyll(kol.lab, celle)
                    if let tf = labfarge(rad.lab) {
                        let a: [NSAttributedString.Key: Any] = [NSAttributedString.Key(kCTFontAttributeName as String): PalettPDF.font(11, fet: true),
                                                                NSAttributedString.Key(kCTForegroundColorAttributeName as String): tf]
                        let b: [NSAttributedString.Key: Any] = [NSAttributedString.Key(kCTFontAttributeName as String): PalettPDF.font(6.5),
                                                                NSAttributedString.Key(kCTForegroundColorAttributeName as String): tf]
                        let t = NSMutableAttributedString(string: "Aa\n", attributes: a)
                        t.append(NSAttributedString(string: tekst, attributes: b))
                        PalettPDF.tegn(t, i: ctx, x: x + 5, topp: y + 5, bredde: cellebredde - 8)
                    }
                    let ok = r < m.godkjent.count && k < m.godkjent[r].count ? m.godkjent[r][k] : false
                    ctx.setFillColor(red: ok ? 0.2 : 0.8, green: ok ? 0.6 : 0.2, blue: ok ? 0.3 : 0.2, alpha: 1)
                    ctx.fillEllipse(in: CGRect(x: celle.maxX - 8, y: celle.maxY - 8, width: 5, height: 5))
                    ctx.setStrokeColor(gray: 1, alpha: 0.9)
                    ctx.setLineWidth(0.6)
                    ctx.strokeEllipse(in: CGRect(x: celle.maxX - 8, y: celle.maxY - 8, width: 5, height: 5))
                }
                y += cellehøyde
            }
        }

        // Tabellen: kolonnebredder etter innholdet, tekst brytes i cellene.
        let kolonner = tabell.map(\.count).max() ?? 0
        if kolonner > 0 {
            let lengder = (0..<kolonner).map { k in tabell.map { $0.indices.contains(k) ? min($0[k].count, 40) : 0 }.max() ?? 0 }
            let sum = CGFloat(max(lengder.reduce(0, +), 1))
            let bredder = lengder.map { fullBredde * max(CGFloat($0), 4) / max(sum, 4 * CGFloat(kolonner)) }
            let skala = fullBredde / bredder.reduce(0, +)
            let kolonnebredder = bredder.map { $0 * skala }
            for (r, rad) in tabell.enumerated() {
                let fet = overskrift && r == 0
                let celler = (0..<kolonner).map { k in
                    NSAttributedString(string: rad.indices.contains(k) ? rad[k] : "",
                                       attributes: PalettPDF.attributter(PalettPDF.font(8, fet: fet), grå: fet ? 0 : 0.1))
                }
                let høyde = zip(celler, kolonnebredder).map { PalettPDF.høyde(av: $0, bredde: $1 - 2 * celleluft) }.max() ?? 10
                if y + høyde + 2 * celleluft > bunn { nySide() }
                var x = marg
                for (celle, bredde) in zip(celler, kolonnebredder) {
                    PalettPDF.tegn(celle, i: ctx, x: x + celleluft, topp: y + celleluft, bredde: bredde - 2 * celleluft)
                    x += bredde
                }
                y += høyde + 2 * celleluft
                ctx.setStrokeColor(gray: 0, alpha: fet ? 0.5 : 0.15)
                ctx.setLineWidth(fet ? 0.75 : 0.5)
                ctx.move(to: CGPoint(x: marg, y: side.height - y))
                ctx.addLine(to: CGPoint(x: marg + fullBredde, y: side.height - y))
                ctx.strokePath()
            }
        }

        avsluttSide()
        return sidenr
    }

    private static func tekst(_ s: String) -> NSAttributedString {
        let linjer = s.components(separatedBy: "\n")
        let t = NSMutableAttributedString(string: linjer[0], attributes: PalettPDF.attributter(PalettPDF.font(8.5, fet: true), grå: 0))
        for linje in linjer.dropFirst() {
            t.append(NSAttributedString(string: "\n" + linje, attributes: PalettPDF.attributter(PalettPDF.font(8), grå: 0.35)))
        }
        return t
    }
}
