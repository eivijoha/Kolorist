import CoreGraphics
import FargeKjerne
@testable import FargeMaaling
import Foundation
import Testing

/// Syntetiske kort – ekte referanseverdier er rettighetsbelagt og brukes aldri i testene.
@Suite("Referansekort, import og karakterisering")
struct ReferansekortTests {
    /// 24 glatte syntetiske spektre, 380–730 nm i steg på 10 nm, med seks nøytrale felt på siste rad
    /// (hvitt til svart).
    static let spektre: [[Double]] = (0..<24).map { i in
        if i >= 18 {
            let nivå = [0.9, 0.59, 0.36, 0.19, 0.09, 0.03][i - 18]
            return Array(repeating: nivå, count: 36)
        }
        let senter = 400 + Double(i) * 17, bredde = 30 + Double(i % 4) * 15
        return (0..<36).map { j in 0.05 + 0.55 * exp(-pow((380 + Double(j) * 10 - senter) / bredde, 2)) }
    }

    func tekst(_ rader: [[Double]], skille: String = "\t") -> String {
        rader.map { $0.map { String(format: "%.4f", $0) }.joined(separator: skille) }.joined(separator: "\n")
    }

    @Test func tallmatriseRadForRad() throws {
        let kort = try Referanseimport.les(Data(tekst(Self.spektre).utf8), filnavn: "kort.txt")
        #expect(kort.rader == 4 && kort.kolonner == 6)
        #expect(kort.harSpektre)
        #expect(kort.nøytrale == [18, 19, 20, 21, 22, 23])
        #expect(kort.felt[0].navn == "A1" && kort.felt[23].navn == "D6")
        #expect(kort.navn == "kort")
    }

    /// Instrumentfiler er ofte kolonne for kolonne (nøytrale som hvert fjerde felt); de ordnes rad for rad.
    @Test func kolonneForKolonneOrdnes() throws {
        let kolonnevis = (0..<24).map { i in Self.spektre[(i % 4) * 6 + i / 4] }
        let kort = try Referanseimport.les(Data(tekst(kolonnevis).utf8), filnavn: "kort.txt")
        #expect(kort.nøytrale == [18, 19, 20, 21, 22, 23])
        let fasit = try Referanseimport.les(Data(tekst(Self.spektre).utf8), filnavn: "fasit.txt")
        #expect(kort.felt.map(\.verdi) == fasit.felt.map(\.verdi))
    }

    @Test func transponertMedBølgelengder() throws {
        let rader = (0..<36).map { j in [380 + Double(j) * 10] + Self.spektre.map { $0[j] } }
        let kort = try Referanseimport.les(Data(tekst(rader, skille: ";").replacingOccurrences(of: ".", with: ",").utf8),
                                           filnavn: "kort.csv")
        #expect(kort.felt.count == 24 && kort.harSpektre)
        if case .spekter(let s) = kort.felt[3].verdi {
            #expect(s.start == 380 && s.steg == 10 && abs(s.verdier[5] - Self.spektre[3][5]) < 1e-4)
        }
    }

    @Test func cgatsMedSpektreOgNavn() throws {
        var linjer = ["CGATS.17", "ORIGINATOR \"Test\"", "NUMBER_OF_FIELDS 38", "BEGIN_DATA_FORMAT",
                      "SAMPLE_ID SAMPLE_NAME " + (0..<36).map { "SPECTRAL_NM\(380 + $0 * 10)" }.joined(separator: " "),
                      "END_DATA_FORMAT", "NUMBER_OF_SETS 24", "BEGIN_DATA"]
        for (i, s) in Self.spektre.enumerated() {
            linjer.append("\(i + 1) \"Felt \(i + 1)\" " + s.map { String(format: "%.2f", $0 * 100) }.joined(separator: " "))
        }
        linjer.append("END_DATA")
        let kort = try Referanseimport.les(Data(linjer.joined(separator: "\r\n").utf8), filnavn: "kort.cgats")
        #expect(kort.felt.count == 24 && kort.harSpektre)
        #expect(kort.felt[0].navn == "Felt 1")
        if case .spekter(let s) = kort.felt[18].verdi { #expect(abs(s.verdier[0] - 0.9) < 1e-6) }
    }

    @Test func cgatsMedLab() throws {
        let cgats = """
        CGATS.17
        BEGIN_DATA_FORMAT
        SAMPLE_ID LAB_L LAB_A LAB_B
        END_DATA_FORMAT
        BEGIN_DATA
        1 37.99 13.56 14.06
        2 65.71 18.13 17.81
        3 96.00 -0.10 0.20
        END_DATA
        """
        let kort = try Referanseimport.les(Data(cgats.utf8), filnavn: "lab.txt")
        #expect(kort.felt.count == 3)
        #expect(kort.felt[0].verdi == .lab(CIELab(l: 37.99, a: 13.56, b: 14.06)))
        #expect(kort.nøytrale == [2])
    }

    @Test func csvMedOverskrifter() throws {
        let csv = """
        Navn,L*,a*,b*
        Rød,41.2,58.1,30.0
        Hvit,95.1,0.2,-0.5
        """
        let kort = try Referanseimport.les(Data(csv.utf8), filnavn: "farger.csv")
        #expect(kort.felt.map(\.navn) == ["Rød", "Hvit"])
        #expect(kort.felt[0].verdi == .lab(CIELab(l: 41.2, a: 58.1, b: 30)))
    }

    @Test func cxf3() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <cc:CxF xmlns:cc="http://colorexchangeformat.com/CxF3-core">
          <cc:Resources>
            <cc:ObjectCollection>
              <cc:Object ObjectType="Standard" Name="Blå" Id="1">
                <cc:ColorValues>
                  <cc:ReflectanceSpectrum ColorSpecification="CS1" StartWL="400">0.10 0.20 0.30 0.20</cc:ReflectanceSpectrum>
                </cc:ColorValues>
              </cc:Object>
              <cc:Object ObjectType="Standard" Name="Lab-felt" Id="2">
                <cc:ColorValues>
                  <cc:ColorCIELab ColorSpecification="CS2"><cc:L>50</cc:L><cc:A>10</cc:A><cc:B>-20</cc:B></cc:ColorCIELab>
                </cc:ColorValues>
              </cc:Object>
            </cc:ObjectCollection>
            <cc:ColorSpecificationCollection>
              <cc:ColorSpecification Id="CS1">
                <cc:MeasurementSpec><cc:WavelengthRange StartWL="400" Increment="20"/></cc:MeasurementSpec>
              </cc:ColorSpecification>
            </cc:ColorSpecificationCollection>
          </cc:Resources>
        </cc:CxF>
        """
        let kort = try Referanseimport.les(Data(xml.utf8), filnavn: "kort.cxf")
        #expect(kort.felt.map(\.navn) == ["Blå", "Lab-felt"])
        #expect(kort.felt[1].verdi == .lab(CIELab(l: 50, a: 10, b: -20)))
        if case .spekter(let s) = kort.felt[0].verdi { #expect(s.start == 400 && s.verdier.count == 4) }
    }

    @Test func fargebibliotekSomReferanse() throws {
        let palett = Palett(navn: "Kort", farger: [PalettFarge(navn: "Grå", farge: Farge(hex: "#777777")!)])
        let kort = try Referanseimport.les(Eksportformat.ase.data(for: palett), filnavn: "kort.ase")
        #expect(kort.felt.count == 1 && kort.felt[0].navn == "Grå")
    }

    @Test func ukjentInnholdGirFeil() {
        #expect(throws: Referanseimport.Feil.self) { try Referanseimport.les(Data("hei og hå".utf8), filnavn: "x.txt") }
    }

    @Test func labOgXYZErKonsistente() {
        let lab = CIELab(l: 62, a: -18, b: 33)
        let v = Labregning.xyz(lab, hvit: Lyskilde.d50.hvitpunkt)
        let tilbake = Labregning.lab(v, hvit: Lyskilde.d50.hvitpunkt)
        #expect(abs(tilbake.l - lab.l) < 1e-9 && abs(tilbake.a - lab.a) < 1e-9 && abs(tilbake.b - lab.b) < 1e-9)
        // Samme Lab som Kolorist ellers bruker (D50, men Bradford i stedet for CAT16 – nesten likt).
        let farge = Referanseverdi.lab(lab).farge
        #expect(Fargeavstand.deltaE2000(farge.cieLab, lab) < 0.5)
    }

    @Test func feltsentreMedPerspektiv() {
        let rett = Kortgeometri.sentre(hjørner: [CGPoint(x: 0, y: 0), CGPoint(x: 600, y: 0), CGPoint(x: 600, y: 400),
                                                 CGPoint(x: 0, y: 400)], rader: 4, kolonner: 6)
        #expect(rett.count == 24)
        #expect(abs(rett[0].x - 50) < 1e-9 && abs(rett[0].y - 50) < 1e-9)
        #expect(abs(rett[23].x - 550) < 1e-9 && abs(rett[23].y - 350) < 1e-9)
        let skrå = [CGPoint(x: 10, y: 20), CGPoint(x: 500, y: 60), CGPoint(x: 520, y: 380), CGPoint(x: 30, y: 400)]
        let midt = Kortgeometri.punkt(u: 0, v: 0, hjørner: skrå)!
        #expect(abs(midt.x - 10) < 1e-9 && abs(midt.y - 20) < 1e-9)
        let hjørne = Kortgeometri.punkt(u: 1, v: 1, hjørner: skrå)!
        #expect(abs(hjørne.x - 520) < 1e-6 && abs(hjørne.y - 380) < 1e-6)
    }

    // MARK: Karakterisering

    func kort() throws -> Referansekort {
        try Referanseimport.les(Data(tekst(Self.spektre).utf8), filnavn: "kort.txt")
    }

    /// Et simulert kamera: lyset i bildet, en blanding av kanalene og en tonekurve.
    func kamerabilde(_ kort: Referansekort, lys: Lyskilde) -> [Farge] {
        kort.felt.map { felt in
            let v = felt.verdi.xyz(under: lys)
            let f = Farge(xyz: v)
            let blandet = (0.9 * f.r + 0.1 * f.g, 0.05 * f.r + 0.9 * f.g + 0.05 * f.b, 0.1 * f.g + 0.9 * f.b)
            return Farge(lineærR: 0.8 * pow(max(blandet.0, 0), 0.9), g: 0.8 * pow(max(blandet.1, 0), 0.9),
                         b: 0.8 * pow(max(blandet.2, 0), 0.9))
        }
    }

    @Test func karakteriseringKompensererForLyset() throws {
        let kort = try kort()
        let bilde = kamerabilde(kort, lys: .cie("LED-B2"))
        for modell in Kamerakarakterisering.Modell.allCases {
            let k = try #require(Kamerakarakterisering.tilpass(kamera: bilde, referanse: kort, modell: modell))
            #expect(k.statistikk.antallFelt == 24)
            // Tonekurven gjenfinnes; lysskiftet er ikke helt lineært for spektrale flater, så matrisen bommer litt.
            #expect(k.gamma.allSatisfy { abs($0 - 1 / 0.9) < 0.01 })
            #expect(k.statistikk.snittΔE < (modell == .matrise ? 3.5 : 2))
            #expect(k.statistikk.kryssvalidertSnittΔE >= k.statistikk.snittΔE)
            // Det kompenserte bildet ligner fasiten i dagslys.
            let komp = Lyskompensasjon.referansekort(k).kompensert(bilde[3])
            #expect(Fargeavstand.deltaE2000(komp.cieLab, kort.felt[3].verdi.farge.cieLab) < 5)
        }
    }

    @Test func karakteriseringLagresOgTrengerNokFelt() throws {
        let kort = try kort()
        let bilde = kamerabilde(kort, lys: .d65)
        let k = try #require(Kamerakarakterisering.tilpass(kamera: bilde, referanse: kort))
        #expect(try JSONDecoder().decode(Kamerakarakterisering.self, from: JSONEncoder().encode(k)) == k)
        #expect(Kamerakarakterisering.tilpass(kamera: Array(bilde.prefix(3)), referanse: kort) == nil)
    }

    @Test func gråkort() {
        let kort = Referansekort.gråkort(refleksjon: 0.18)
        #expect(kort.nøytrale == [0])
        #expect(abs(kort.felt[0].verdi.xyz(under: .a).y - 0.18) < 1e-9)
    }
}

@Suite("Kameraprofil, tolkning og retning")
struct KameraprofilTests {
    let kort = try! Referanseimport.les(Data(ReferansekortTests().tekst(ReferansekortTests.spektre).utf8), filnavn: "kort.txt")

    /// Et fast kamera (hvitbalansen låst): lyset i bildet, en kanalblanding og en tonekurve, uten automatikk.
    func kamera(_ v: XYZ, eksponering: Double = 1) -> Farge {
        let f = Farge(xyz: XYZ(x: v.x * eksponering, y: v.y * eksponering, z: v.z * eksponering))
        let b = (0.9 * f.r + 0.1 * f.g, 0.05 * f.r + 0.9 * f.g + 0.05 * f.b, 0.1 * f.g + 0.9 * f.b)
        return Farge(lineærR: 0.8 * pow(max(b.0, 0), 0.9), g: 0.8 * pow(max(b.1, 0), 0.9), b: 0.8 * pow(max(b.2, 0), 0.9))
    }

    /// Profil laget én gang under glødelys; senere gråkort under kald LED gir dagslysfargene tilbake.
    @Test func kameraprofilMedGråkortINyttLys() throws {
        let opplæring = Lyskilde.a
        let profil = try #require(Kamerakarakterisering.beste(
            kamera: kort.felt.map { kamera($0.verdi.xyz(under: opplæring)) }, referanse: kort, lys: opplæring))
        let nytt = Lyskilde.cie("LED-B4")
        let grå = Referansekort.gråkort(refleksjon: 0.18).felt[0].verdi
        let komp = Lyskompensasjon.kameraprofil(profil, gråkort: kamera(grå.xyz(under: nytt), eksponering: 0.5), refleksjon: 0.18)
        let avvik = kort.felt.map { felt in
            Fargeavstand.deltaE2000(komp.kompensert(kamera(felt.verdi.xyz(under: nytt), eksponering: 0.5)).cieLab,
                                    felt.verdi.farge.cieLab)
        }
        #expect(avvik.reduce(0, +) / Double(avvik.count) < 4)
        let t = try #require(komp.fargetemperatur)
        #expect(abs(t.kelvin - 5000) < 400)
    }

    @Test func treKolonnerKanTolkesPåNytt() throws {
        let tekst = "38.0 13.6 14.1\n65.7 18.1 17.8\n96.0 0.1 0.2"
        let lab = try Referanseimport.les(Data(tekst.utf8), filnavn: "x.txt")
        #expect(lab.tolkning == .lab)
        let xyz = lab.tolket(som: .xyz)
        #expect(xyz.tolkning == .xyz)
        if case .xyz(let v, _) = xyz.felt[0].verdi { #expect(abs(v.x - 0.38) < 1e-9) }
        for (a, b) in zip(xyz.tolket(som: .lab).felt, lab.felt) {
            #expect(abs(a.verdi.lab.l - b.verdi.lab.l) < 1e-9 && abs(a.verdi.lab.b - b.verdi.lab.b) < 1e-9)
        }
        let cgats = try Referanseimport.les(Data("BEGIN_DATA_FORMAT\nLAB_L LAB_A LAB_B\nEND_DATA_FORMAT\nBEGIN_DATA\n50 0 0\nEND_DATA".utf8), filnavn: "c.txt")
        #expect(cgats.tolkning == nil)
    }

    @Test func retningVelgesFraLyshet() {
        let fasit = kort.felt.map { $0.verdi.xyz(under: .d65).y }
        // Et «bilde» der kortet ligger opp-ned: målingen slår opp fasiten for feltet som faktisk ligger der.
        let riktig = [CGPoint(x: 600, y: 400), CGPoint(x: 0, y: 400), CGPoint(x: 0, y: 0), CGPoint(x: 600, y: 0)]
        let senterTilFelt = Dictionary(uniqueKeysWithValues: Kortgeometri.sentre(hjørner: riktig, rader: 4, kolonner: 6)
            .enumerated().map { ("\(Int($1.x.rounded())),\(Int($1.y.rounded()))", $0) })
        let start = [CGPoint(x: 0, y: 0), CGPoint(x: 600, y: 0), CGPoint(x: 600, y: 400), CGPoint(x: 0, y: 400)]
        let valgt = Kortgeometri.besteRetning(hjørner: start, rader: 4, kolonner: 6, fasitY: fasit) { sentre in
            sentre.map { p in senterTilFelt["\(Int(p.x.rounded())),\(Int(p.y.rounded()))"].map { fasit[$0] } ?? 0.5 }
        }
        #expect(valgt == riktig)
    }
}
