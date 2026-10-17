import Foundation
import Testing
import simd
@testable import FargeKjerne

@Suite("Fargerom i 3D og USDZ")
struct Fargerom3DTests {
    @Test func gråttLiggerPåAksen() {
        let p = Fargerom3D.kuleposisjon(Farge(hex: "#777777")!)
        #expect(abs(p.x) < 1e-3 && abs(p.z) < 1e-3)
        #expect(p.y > -1 && p.y < 1)
    }

    @Test func mettetFargePåOverflaten() {
        // Ren sRGB-rød er så mettet som kuløren kan bli ved sin lyshet: på overflaten av kula.
        let p = Fargerom3D.kuleposisjon(Farge(hex: "#FF0000")!, gamut: .sRGB)
        #expect(abs(simd_length(p) - 1) < 0.02)
    }

    @Test func kulørenGårFraAMotB() {
        // Kuløren regnes som i CIELab: rød (a* > 0) mot +x, gul (b* > 0) mot −z, i begge rom.
        let rød = Fargerom3D.kuleposisjon(Farge(hex: "#FF0000")!), gul = Fargerom3D.kuleposisjon(Farge(hex: "#FFD800")!)
        #expect(rød.x > 0)
        #expect(gul.z < 0)
        #expect(Fargerom3D.labposisjon(Farge(hex: "#FFD800")!).z < 0)
    }

    @Test func gamutskallForSRGB() throws {
        let skall = try #require(Fargerom3D.gamutskall(.sRGB, oppløsning: 4))
        #expect(skall.count == 6)
        let alle = skall.flatMap(\.punkter)
        // Hvitt øverst (L* 100) og sort nederst (L* 0).
        #expect(abs((alle.map(\.y).max() ?? 0) - 1) < 0.01)
        #expect(abs((alle.map(\.y).min() ?? 0) + 1) < 0.01)
        #expect(skall[0].trekanter.count == 4 * 4 * 2)
    }

    @Test func usdzErGyldigPakket() {
        let scene = Fargerom3D.Scene(flater: [(Fargerom3D.kuleflate(kolonner: 9, rader: 5), 0.4)],
                                     punkter: [(Fargerom3D.kuleposisjon(Farge(hex: "#2F7FD8")!), Farge(hex: "#2F7FD8")!, 0.05)],
                                     streker: [([.init(0, -1, 0), .init(0, 1, 0)], Farge(hex: "#808080")!, 0.01)])
        let data = scene.usdz(navn: "Tonebane")
        // Zip: lokal filhode først, og den første filen er scenen.
        #expect(data.prefix(4) == Data([0x50, 0x4B, 0x03, 0x04]))
        let navnLengde = Int(data[26]) | Int(data[27]) << 8, ekstraLengde = Int(data[28]) | Int(data[29]) << 8
        #expect(String(data: data[30..<(30 + navnLengde)], encoding: .utf8) == "scene.usda")
        // Dataene starter på en 64-byte-grense.
        #expect((30 + navnLengde + ekstraLengde) % 64 == 0)
        let usda = scene.flater.isEmpty ? "" : String(decoding: data[(30 + navnLengde + ekstraLengde)...].prefix(400), as: UTF8.self)
        #expect(usda.hasPrefix("#usda 1.0"))
    }

    @Test func roterendeModell() {
        let mesh = USDScene.Mesh(navn: "Flate", punkter: [[0, 0, 0], [1, 0, 0], [0, 1, 0]], trekanter: [[0, 1, 2]])
        let stille = USDScene(navn: "Modell", mesher: [mesh]).usda()
        #expect(!stille.contains("timeSamples") && !stille.contains("TimeCode"))
        let roterer = USDScene(navn: "Modell", mesher: [mesh], rundetid: 30).usda()
        #expect(roterer.contains("endTimeCode = 720"))
        #expect(roterer.contains("timeCodesPerSecond = 24"))
        #expect(roterer.contains("xformOp:rotateY.timeSamples"))
        #expect(roterer.contains("720: 360"))
        #expect(roterer.contains("uniform token[] xformOpOrder = [\"xformOp:rotateY\"]"))
    }

    @Test func flaterVisesFraBeggeSiderOgHeldekkendeErUgjennomsiktige() {
        let heldekkende = USDScene.Mesh(navn: "Skall", punkter: [[0, 0, 0], [1, 0, 0], [0, 1, 0]], trekanter: [[0, 1, 2]])
        var glass = heldekkende
        glass.navn = "Glass"
        glass.opasitet = 0.3
        let usda = USDScene(navn: "Modell", mesher: [heldekkende, glass]).usda()
        // Begge retninger (AR Quick Look skjuler baksidene), og doubleSided av så bare én av dem vises om gangen.
        #expect(usda.contains("int[] faceVertexIndices = [0, 1, 2, 0, 2, 1]"))
        #expect(usda.contains("uniform bool doubleSided = 0"))
        // Opasitet bare på det gjennomsiktige materialet.
        #expect(usda.components(separatedBy: "inputs:opacity").count == 2)
        #expect(usda.contains("float inputs:opacity = 0.3"))
    }

    @Test func crc32() {
        #expect(USDZPakke.crc32(Data("123456789".utf8)) == 0xCBF4_3926)
    }

    @Test func rørMedLikePunkterHarIngenNaN() {
        let rør = USDScene.Mesh.rør(navn: "Linje", langs: [[0, 0, 0], [0, 0, 0], [0.5, 0, 0], [0.5, 0.9, 0]], radius: 0.01,
                                    farge: [1, 1, 1])
        #expect(!rør.punkter.isEmpty)
        #expect(rør.punkter.allSatisfy { !$0.x.isNaN && !$0.y.isNaN && !$0.z.isNaN })
        #expect(Fargerom3D.Flate(kolonner: 0, rader: 0, punkter: [], farger: [], lukket: false).trekanter.isEmpty)
    }

    @Test func storRapportKuttesIStedetForÅForkastes() {
        let rader = (0..<500).map { r in (0..<80).map { "\(r)-\($0)" } }
        let rapport = DeltRapport(slag: "skriftkontrast", tittel: "T", tabell: rader)
        let r = rapport.kontrollert(antallFarger: 1)
        #expect(r?.tabell.count == DeltRapport.maksRader)
        #expect(r?.tabell.first?.count == DeltRapport.maksKolonner)
    }
}
