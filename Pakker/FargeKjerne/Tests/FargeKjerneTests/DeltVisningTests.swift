import Foundation
import Testing
@testable import FargeKjerne

/// Visningstilstand i delingslenker: hvordan mottakeren åpner innholdet («Åpne i Kolorist»).
@Suite("Visningstilstand i lenker")
struct DeltVisningTests {
    let farge = Farge(hex: "#2F7FD8")!

    @Test func rundtur() throws {
        let visning = DeltVisning(fane: "vurdering", studiomodus: "harmoni", fargemodell: "cieLab", vurdering: "kontrast",
                                  bakgrunn: Farge(hex: "#F2B84B")!, bruk: true, presentasjon: true)
        let innhold = DeltInnhold(slag: .farge, farger: [DeltFarge(farge)], visning: visning)
        let lest = try Delingslenke.les(Delingslenke.lenke(innhold))
        #expect(lest.visning?.fane == "vurdering")
        #expect(lest.visning?.studiomodus == "harmoni")
        #expect(lest.visning?.fargemodell == "cieLab")
        #expect(lest.visning?.vurdering == "kontrast")
        #expect(lest.visning?.bakgrunn?.farge.hex() == "#F2B84B")
        #expect(lest.visning?.bruk == true)
        #expect(lest.visning?.presentasjon == true)
    }

    @Test func applenkeBrukerSkjemaet() throws {
        let innhold = DeltInnhold(slag: .farge, farger: [DeltFarge(farge)], visning: DeltVisning(fane: "studio", bruk: true))
        let url = try Delingslenke.appLenke(innhold)
        #expect(url.scheme == "kolorist")
        #expect(url.absoluteString.hasPrefix("kolorist://l#z"))
        #expect(try Delingslenke.les(url).visning?.fane == "studio")
        // Samme innhold som nettlenken.
        #expect(url.fragment == (try Delingslenke.lenke(innhold)).fragment)
    }

    @Test func utenVisningErLenkenUendret() throws {
        let innhold = DeltInnhold(slag: .farge, farger: [DeltFarge(farge)])
        let lest = try Delingslenke.les(Delingslenke.lenke(innhold))
        #expect(lest.visning == nil)
    }

    @Test func ukjenteVerdierLesesUtenFeil() throws {
        // En nyere versjon kan sende verdier og felt denne versjonen ikke kjenner; innholdet skal likevel komme fram.
        let json = #"{"v":1,"t":"farge","f":[{"k":[0.6,0.0,-0.13],"x":"2F7FD8"}],"vs":{"f":"ny-fane","zz":42,"p":true}}"#
        let innhold = try JSONDecoder().decode(DeltInnhold.self, from: Data(json.utf8))
        #expect(innhold.visning?.fane == "ny-fane")
        #expect(innhold.visning?.presentasjon == true)
        #expect(innhold.farger.count == 1)
    }

    @Test func skadetVisningDroppesMenInnholdetBeholdes() throws {
        let json = #"{"v":1,"t":"farge","f":[{"k":[0.6,0.0,-0.13],"x":"2F7FD8"}],"vs":{"f":42}}"#
        let innhold = try JSONDecoder().decode(DeltInnhold.self, from: Data(json.utf8))
        #expect(innhold.visning == nil)
        #expect(innhold.farger.count == 1)
    }

    @Test func forLangeVerdierDroppes() throws {
        let innhold = DeltInnhold(slag: .farge, farger: [DeltFarge(farge)],
                                  visning: DeltVisning(fane: String(repeating: "x", count: 100)))
        let lest = try Delingslenke.les(Delingslenke.lenke(innhold))
        #expect(lest.visning == nil)
        #expect(lest.farger.count == 1)
    }
}
