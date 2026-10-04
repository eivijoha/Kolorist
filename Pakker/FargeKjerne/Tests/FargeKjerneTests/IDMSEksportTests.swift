import Foundation
import Testing
@testable import FargeKjerne

@Suite("InDesign-utklipp")
struct IDMSEksportTests {
    @Test func gradientOgFarger() throws {
        let a = Farge(hex: "#1B3A6B")!, b = Farge(hex: "#F2B84B")!
        let tekst = IDMSEksport.snippet(
            farger: [PalettFarge(navn: "Natt", farge: a), PalettFarge(farge: b)],
            gradienter: [.init(navn: "Skumring", stopp: Gradientstopp.forenklet(gjennom: [a, b]))])
        #expect(tekst.contains("<Gradient Self=\"Gradient/Skumring\" Type=\"Linear\""))
        #expect(tekst.contains("Name=\"Natt #1B3A6B\""))
        #expect(tekst.contains("FillColor=\"Gradient/Skumring\""))
        _ = try XMLDocument(xmlString: tekst)
        if let ut = ProcessInfo.processInfo.environment["IDMS_UT"] {
            try tekst.write(toFile: ut, atomically: true, encoding: .utf8)
            for (v, navn) in [(135.0, "135"), (180.0, "180"), (0.0, "0")] {
                let t = IDMSEksport.snippet(farger: [], gradienter: [.init(navn: "Vinkel \(navn)", stopp: Gradientstopp.forenklet(gjennom: [a, b]), vinkel: v)])
                try t.write(toFile: ut.replacingOccurrences(of: ".idms", with: "-\(navn).idms"), atomically: true, encoding: .utf8)
            }
            let r = IDMSEksport.snippet(farger: [], gradienter: [.init(navn: "Radiell", stopp: Gradientstopp.forenklet(gjennom: [a, b]), radiell: true)])
            try r.write(toFile: ut.replacingOccurrences(of: ".idms", with: "-radiell.idms"), atomically: true, encoding: .utf8)
        }
    }

    @Test func spesialtegnEscapes() throws {
        let tekst = IDMSEksport.snippet(farger: [PalettFarge(navn: "Rød & \"blå\" <x>", farge: Farge(hex: "#FF0000")!)], gradienter: [])
        _ = try XMLDocument(xmlString: tekst)
    }
}
