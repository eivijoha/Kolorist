import Foundation
import Testing
@testable import FargeKjerne

@Suite("Delingsvern", .serialized)
struct DelingsvernTests {
    @Test func importertTonerDelesUtenNavnMenMedVerdier() throws {
        let tone = PalettFarge(navn: "Kartfarge 186", farge: Farge(hex: "#C8102E")!, opphav: .bibliotek,
                               representasjon: Fargerepresentasjon(rom: .modell(.cmyk), verdier: [0, 100, 81, 4], tekst: "0/100/81/4"),
                               kilde: Fargekilde(kildenavn: "Et fargekart", importert: true))
        let delt = DeltFarge(tone)
        // Koblingen mellom navn og verdi deles ikke; verdiene gjør.
        #expect(delt.navn == nil && delt.kilde == nil)
        #expect(delt.tekst == "0/100/81/4" && delt.farge.avstandOK(til: tone.farge) < 0.0001)
    }

    @Test func eldreFargerKjennesIgjenPåNavnet() {
        Delingsvern.oppdater(tonenavn: ["Kartfarge 186", "12"])
        defer { Delingsvern.oppdater(tonenavn: []) }
        let gammel = PalettFarge(navn: "Kartfarge 186", farge: Farge(hex: "#C8102E")!)
        #expect(DeltFarge(gammel).navn == nil)
        // Tallnavn (toner uten navn i ACO) og andre navn deles som før.
        #expect(DeltFarge(PalettFarge(navn: "12", farge: Farge(hex: "#123456")!)).navn == "12")
        #expect(DeltFarge(PalettFarge(navn: "Min blå", farge: Farge(hex: "#123456")!)).navn == "Min blå")
    }

    @Test func filamentfargerDelesMedKilde() throws {
        let tone = try #require(Filamentfarger.biblioteker.first?.farger.first)
        let delt = DeltFarge(tone)
        #expect(delt.navn == tone.navn)
        #expect(delt.kilde?.lenke?.hasPrefix("https://filamentcolors.xyz/") == true)
    }

    @Test func importerteBibliotekMerkerTonene() throws {
        let ase = ASEEksport.data(for: Palett(navn: "Kart", farger: [PalettFarge(navn: "Kartfarge 186", farge: Farge(hex: "#C8102E")!)]))
        let bibliotek = try Fargebibliotek(data: ase, filnavn: "kart.ase")
        #expect(!bibliotek.farger.isEmpty)
        #expect(bibliotek.farger.allSatisfy { $0.kilde?.importert == true })
        #expect(DeltFarge(bibliotek.farger[0]).navn == nil)
    }
}
