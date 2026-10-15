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

    @Test func crc32() {
        #expect(USDZPakke.crc32(Data("123456789".utf8)) == 0xCBF4_3926)
    }
}
