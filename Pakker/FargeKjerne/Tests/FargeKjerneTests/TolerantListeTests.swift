import FargeKjerne
import Foundation
import Testing

/// Lister som synkroniseres mellom versjoner: elementer fra en nyere versjon må overleve en lagring i en eldre.
@Suite("Tolerant liste")
struct TolerantListeTests {
    struct Element: Codable, Equatable { var navn: String; var verdi: Int }

    @Test func ukjenteElementerBeholdesVedLagring() throws {
        // Lista slik en nyere versjon skrev den: ett element med en form denne versjonen ikke kan lese.
        let fraNyere = Data(#"[{"navn":"a","verdi":1},{"navn":"fremtidig","verdi":"tekst"},{"navn":"b","verdi":2}]"#.utf8)
        let lest: [Element] = TolerantListe.les(fraNyere)
        #expect(lest == [Element(navn: "a", verdi: 1), Element(navn: "b", verdi: 2)])
        // Brukeren legger til et element og lagrer – det ukjente skal fortsatt være med.
        let lagret = try #require(TolerantListe.skriv(lest + [Element(navn: "c", verdi: 3)], beholdUkjenteFra: fraNyere))
        let rå = try #require(try JSONSerialization.jsonObject(with: lagret) as? [[String: Any]])
        #expect(rå.count == 4)
        #expect(rå.contains { ($0["navn"] as? String) == "fremtidig" && ($0["verdi"] as? String) == "tekst" })
        let igjen: [Element] = TolerantListe.les(lagret)
        #expect(igjen.map(\.navn) == ["a", "b", "c"])
    }

    @Test func uleseligeDataOverskrivesIkke() {
        let ukjentFormat = Data(#"{"versjon":3,"elementer":[]}"#.utf8)
        let lest: [Element] = TolerantListe.les(ukjentFormat)
        #expect(lest.isEmpty)
        #expect(TolerantListe.skriv([Element(navn: "ny", verdi: 1)], beholdUkjenteFra: ukjentFormat) == nil)
    }

    @Test func vanligeListerSkrivesSomFør() throws {
        let liste = [Element(navn: "a", verdi: 1)]
        let data = try #require(TolerantListe.skriv(liste, beholdUkjenteFra: Data()))
        // Vanlig JSON-liste (ingen ekstra elementer) – samme innhold som en direkte koding.
        #expect(try JSONDecoder().decode([Element].self, from: data) == liste)
        #expect((TolerantListe.les(data) as [Element]) == liste)
    }
}
