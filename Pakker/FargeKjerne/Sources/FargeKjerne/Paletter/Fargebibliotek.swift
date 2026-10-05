import CryptoKit
import Foundation

/// Et importert fargebibliotek (ASE, ACO eller ACB), f.eks. et fargekart med navngitte toner.
/// Brukes som «fargerom» i Studio: nærmeste tone vises ved siden av fargen, og «Begrens nye farger»
/// låser fargen til nærmeste tone. Id-en er en hash av filen, så valget er stabilt mellom enheter.
public struct Fargebibliotek: Sendable, Hashable, Identifiable {
    public let id: String
    public let navn: String
    public let farger: [PalettFarge]
    /// Tonenes CIELab, regnet ut én gang (søket etter nærmeste tone kjøres ofte, f.eks. mens man drar en glider).
    private let laber: [CIELab]

    public init(data: Data, filnavn: String) throws {
        let palett = try Bibliotekimport.les(data, filnavn: filnavn)
        self.navn = palett.navn
        // Tonene merkes som importerte, så navn og verdier fra biblioteket ikke deles i lenker.
        self.farger = palett.farger.map { pf in
            var pf = pf
            if pf.kilde == nil { pf.kilde = Fargekilde(kildenavn: palett.navn, importert: true) }
            return pf
        }
        self.id = "bib:" + SHA256.hash(data: data).prefix(12).map { String(format: "%02x", $0) }.joined()
        self.laber = farger.map(\.farge.cieLab)
    }

    /// Et bibliotek bygget i appen (f.eks. filamentfarger). `id` må begynne med «bib:».
    public init(id: String, navn: String, farger: [PalettFarge]) {
        self.id = id
        self.navn = navn
        self.farger = farger
        self.laber = farger.map(\.farge.cieLab)
    }

    public static func erBibliotekID(_ id: String) -> Bool { id.hasPrefix("bib:") }

    /// Nærmeste tone etter ΔE2000, med avstanden – nøyaktig som et fullt søk, men raskere (søket kjøres ofte, f.eks.
    /// for hver tone mens man drar en glider). Startpunktet er tonen nærmest etter enkel Lab-avstand; deretter regnes
    /// ΔE2000 bare for toner som kan slå beste treff så langt. ΔE2000 er aldri mindre enn |ΔL| / S_L: de andre leddene
    /// er ikke-negative (rotasjonsleddet R_T·ΔC·ΔH kan ikke gjøre summen negativ, siden |R_T| ≤ 2).
    public func nærmeste(til farge: Farge) -> (tone: PalettFarge, avstand: Double)? {
        guard !farger.isEmpty else { return nil }
        let lab = farge.cieLab
        var start = 0, minst = Double.infinity
        for (i, t) in laber.enumerated() {
            let (dl, da, db) = (lab.l - t.l, lab.a - t.a, lab.b - t.b)
            let d = dl * dl + da * da + db * db
            if d < minst { minst = d; start = i }
        }
        var beste = (indeks: start, avstand: Fargeavstand.deltaE2000(lab, laber[start]))
        for (i, t) in laber.enumerated() where i != start {
            let dl = abs(lab.l - t.l)
            let m = (lab.l + t.l) / 2 - 50
            let sl = 1 + 0.015 * m * m / (20 + m * m).squareRoot()
            guard dl / sl < beste.avstand else { continue }
            let d = Fargeavstand.deltaE2000(lab, t)
            if d < beste.avstand { beste = (i, d) }
        }
        return (tone: farger[beste.indeks], avstand: beste.avstand)
    }
}
