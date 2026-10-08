import Foundation
import Testing
@testable import FargeKjerne

@Suite("Skriftfarger")
struct SkriftfargerTests {
    @Test func lStjerneTreffesForAlleKulører() {
        for h in stride(from: 0.0, to: 360, by: 30) {
            for mål in [14.0, 48, 61, 97] {
                let f = Farge.medLStjerne(mål, kroma: 0.1, kulør: h, gamut: .sRGB)
                #expect(abs(f.cieLab.l - mål) < 0.05, "kulør \(h), L* \(mål): \(f.cieLab.l)")
            }
        }
    }

    @Test func forslagErNærHvitOgSortMedKulørpreg() {
        let blå = Farge(hex: "#1F3A8A")!, lyseblå = Farge(hex: "#8FB3C7")!
        let forslag = Skriftfarger.forslag(for: [blå, lyseblå], gamut: .sRGB)
        #expect(forslag.count == 2)
        #expect(abs(forslag[0].farge.cieLab.l - 97) < 0.1 && abs(forslag[1].farge.cieLab.l - 14) < 0.1)
        // Kuløren følger paletten (blå, ~260° i OKLCH).
        #expect(abs(forslag[1].farge.okLCH.h - 260) < 25)
        // Grå palett: nøytrale skriftfarger.
        let grå = Skriftfarger.forslag(for: [Farge(hex: "#808080")!], gamut: .sRGB)
        #expect(grå[1].farge.okLCH.c < 0.002)
    }

    @Test func besteVelgerLesbarOgHolderWCAG() {
        let lys = PalettFarge(navn: "Lys", farge: Farge(hex: "#F7F7F5")!)
        let mørk = PalettFarge(navn: "Mørk", farge: Farge(hex: "#1A1C1E")!)
        let kandidater = [lys, mørk]
        #expect(Skriftfarger.beste(for: Farge(hex: "#1F3A8A")!, blant: kandidater)?.id == lys.id)
        #expect(Skriftfarger.beste(for: Farge(hex: "#F2E6C8")!, blant: kandidater)?.id == mørk.id)
        // Mellomtone der APCA foretrekker hvit, men bare mørk når 4,5:1 etter WCAG: WCAG-gulvet vinner.
        let midt = Farge(hex: "#7A7A7A")!
        let valgt = Skriftfarger.beste(for: midt, blant: kandidater)!
        #expect(Skriftfarger.vurdering(tekst: valgt.farge, på: midt) != .feiler)
        #expect(Skriftfarger.vurdering(tekst: Farge(hex: "#FFFFFF")!, på: Farge(hex: "#767676")!) == .tekst)
        #expect(Skriftfarger.vurdering(tekst: Farge(hex: "#FFFFFF")!, på: Farge(hex: "#949494")!) == .storTekst)
    }

    @Test func valgtSkriftfargeOgTolerantLagring() throws {
        let lys = PalettFarge(navn: "Lys", farge: Farge(hex: "#FFFFFF")!)
        let mørk = PalettFarge(navn: "Mørk", farge: Farge(hex: "#000000")!)
        var gul = PalettFarge(navn: "Gul", farge: Farge(hex: "#F9D71C")!)
        var p = Palett(navn: "P", farger: [gul], tekstfarger: [lys, mørk])
        #expect(p.skriftfarge(for: gul)?.id == mørk.id)
        gul.tekstfarge = lys.id
        p.farger = [gul]
        #expect(p.skriftfarge(for: gul)?.id == lys.id)
        // Rundtur, og eldre data uten feltene leses fortsatt.
        let data = try JSONEncoder().encode(p)
        let tilbake = try JSONDecoder().decode(Palett.self, from: data)
        #expect(tilbake == p)
        let gammel = #"{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","navn":"Gammel","farger":[]}"#.data(using: .utf8)!
        #expect(try JSONDecoder().decode(Palett.self, from: gammel).tekstfarger.isEmpty)
        #expect(Palett(navn: "Uten").skriftfarge(for: gul) == nil)
    }
}

@Suite("Skriftfarger i eksport")
struct SkriftfargerEksportTests {
    static var palett: Palett {
        let lys = PalettFarge(navn: "Lys tekst", farge: Farge(hex: "#F7F7F5")!)
        let mørk = PalettFarge(navn: "Mørk tekst", farge: Farge(hex: "#1A1C1E")!)
        return Palett(navn: "Kyst", farger: [PalettFarge(navn: "Hav", farge: Farge(hex: "#1F3A8A")!),
                                            PalettFarge(navn: "Sand", farge: Farge(hex: "#F2E6C8")!)],
                      tekstfarger: [lys, mørk])
    }

    @Test func cssHarSkriftfargerOgOn() {
        let css = String(decoding: Eksportformat.css.data(for: Self.palett), as: UTF8.self)
        #expect(css.contains("--lys-tekst: #F7F7F5;"))
        #expect(css.contains("--hav-on: var(--lys-tekst);"))
        #expect(css.contains("--sand-on: var(--mork-tekst);") || css.contains("--mørk-tekst"))
    }

    @Test func dtcgHarAliasTilSkriftfarge() throws {
        let data = Eksportformat.designTokens.data(for: Self.palett)
        let rot = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let tekst = try #require(rot["kyst-tekst"] as? [String: Any])
        let on = try #require(tekst["on"] as? [String: Any])
        let hav = try #require(on["hav"] as? [String: Any])
        #expect((hav["$value"] as? String)?.hasPrefix("{kyst-tekst.") == true)
        #expect(rot["kyst"] != nil)
    }

    @Test func swiftUIHarOnEgenskaper() {
        let swift = String(decoding: Eksportformat.swiftUI.data(for: Self.palett), as: UTF8.self)
        #expect(swift.contains("static let havOn = "))
        #expect(swift.contains("static let lysTekst = Color("))
    }

    @Test func utenSkriftfargerErEksportenSomFør() {
        var p = Self.palett
        p.tekstfarger = []
        let css = String(decoding: Eksportformat.css.data(for: p), as: UTF8.self)
        #expect(!css.contains("-on:"))
        let rot = try? JSONSerialization.jsonObject(with: Eksportformat.designTokens.data(for: p)) as? [String: Any]
        #expect(rot?.keys.sorted() == ["kyst"])
    }
}
