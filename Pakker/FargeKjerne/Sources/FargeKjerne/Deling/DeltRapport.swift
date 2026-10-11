import Foundation

/// En fargerapport i en lenke (fra 1.4): vurderingen av fargepar – vanskelige par med fargesynsavvik, kontrast mellom
/// flater (LRV) eller fargeforskjell (ΔE). Lenken er en palett med fargene i rapporten, så eldre versjoner og visningssider
/// uten rapportstøtte viser fargene. Tekstene er ferdig formatert hos avsenderen (på språket i `DeltInnhold.språk`), så
/// visningssiden viser rapporten uten å regne.
public struct DeltRapport: Codable, Equatable, Sendable {
    /// `fargesyn`, `flater` eller `deltaE`. Et ukjent slag vises likevel, som tittel, par og tabell.
    public var slag: String
    public var tittel: String
    public var undertittel: String?
    /// Fargeparene som vises som prøver.
    public var par: [DeltRapportpar]
    /// Tabellen rad for rad (tekst i hver celle). Med `overskrift` er første rad kolonneoverskrifter.
    public var tabell: [[String]]
    public var overskrift: Bool
    /// Skriftkontrast som matrise: fargene i radene (tekst) og kolonnene (bakgrunn) som plasser i `DeltInnhold.farger`,
    /// og om hver celle holder kravet. Tabellen har da en overskriftsrad og én rad per tekstfarge med forholdene.
    public var matriseRader: [Int]?
    public var matriseKolonner: [Int]?
    public var godkjent: [[Bool]]?

    enum CodingKeys: String, CodingKey {
        case slag = "s", tittel = "t", undertittel = "u", par = "p", tabell = "r", overskrift = "o"
        case matriseRader = "mr", matriseKolonner = "mk", godkjent = "g"
    }

    static let maksRader = 160
    static let maksKolonner = 10
    static let maksPar = 160
    static let maksMatrise = 24

    public init(slag: String, tittel: String, undertittel: String? = nil, par: [DeltRapportpar] = [],
                tabell: [[String]], overskrift: Bool = false,
                matrise: (rader: [Int], kolonner: [Int], godkjent: [[Bool]])? = nil) {
        self.slag = slag
        self.tittel = tittel
        self.undertittel = undertittel
        self.par = par
        self.tabell = tabell
        self.overskrift = overskrift
        matriseRader = matrise?.rader
        matriseKolonner = matrise?.kolonner
        godkjent = matrise?.godkjent
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        slag = try c.decode(String.self, forKey: .slag)
        tittel = try c.decode(String.self, forKey: .tittel)
        undertittel = try c.decodeIfPresent(String.self, forKey: .undertittel)
        par = try c.decodeIfPresent([DeltRapportpar].self, forKey: .par) ?? []
        tabell = try c.decodeIfPresent([[String]].self, forKey: .tabell) ?? []
        overskrift = try c.decodeIfPresent(Bool.self, forKey: .overskrift) ?? false
        matriseRader = try? c.decodeIfPresent([Int].self, forKey: .matriseRader)
        matriseKolonner = try? c.decodeIfPresent([Int].self, forKey: .matriseKolonner)
        godkjent = try? c.decodeIfPresent([[Bool]].self, forKey: .godkjent)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(slag, forKey: .slag)
        try c.encode(tittel, forKey: .tittel)
        try c.encodeIfPresent(undertittel, forKey: .undertittel)
        if !par.isEmpty { try c.encode(par, forKey: .par) }
        try c.encode(tabell, forKey: .tabell)
        if overskrift { try c.encode(true, forKey: .overskrift) }
        try c.encodeIfPresent(matriseRader, forKey: .matriseRader)
        try c.encodeIfPresent(matriseKolonner, forKey: .matriseKolonner)
        try c.encodeIfPresent(godkjent, forKey: .godkjent)
    }

    /// Tabellen som tekst med tabulator mellom kolonnene, så den kan limes inn i regneark og tabeller.
    public var tabulatortekst: String {
        tabell.map { $0.joined(separator: "\t") }.joined(separator: "\n")
    }

    /// Innenfor grensene og med par som peker på fargene; ellers `nil` (lenken vises da bare som palett).
    func kontrollert(antallFarger: Int) -> DeltRapport? {
        guard tabell.count <= Self.maksRader, tabell.allSatisfy({ $0.count <= Self.maksKolonner }), par.count <= Self.maksPar,
              par.allSatisfy({ (0..<antallFarger).contains($0.a) && (0..<antallFarger).contains($0.b) }) else { return nil }
        var r = self
        // En matrise må peke på fargene og ha én godkjenning per celle; ellers vises bare tabellen.
        if let rader = matriseRader, let kolonner = matriseKolonner, let godkjent,
           rader.count <= Self.maksMatrise, kolonner.count <= Self.maksMatrise,
           (rader + kolonner).allSatisfy({ (0..<antallFarger).contains($0) }),
           godkjent.count == rader.count, godkjent.allSatisfy({ $0.count == kolonner.count }) {
        } else {
            r.matriseRader = nil
            r.matriseKolonner = nil
            r.godkjent = nil
        }
        r.slag = DeltInnhold.rensket(slag)
        r.tittel = DeltInnhold.rensket(tittel)
        r.undertittel = undertittel.map(DeltInnhold.rensket)
        r.tabell = tabell.map { $0.map(DeltInnhold.rensket) }
        r.par = par.map { $0.rensket }
        return r
    }
}

/// Et fargepar i en rapport: plassene i `DeltInnhold.farger`, fargene slik de ser ut med et fargesynsavvik (sRGB-hex
/// uten «#») med etiketten for den raden («Deuteranopi»), en kort tekst ved paret («ΔE00 22,4 → 7,1») og vurderingen
/// («Nesten like»), med `alvorlig` når paret ikke holder.
public struct DeltRapportpar: Codable, Equatable, Sendable {
    public var a: Int
    public var b: Int
    public var simulertA: String?
    public var simulertB: String?
    public var etikett: String?
    public var tekst: String?
    public var merke: String?
    public var alvorlig: Bool?

    enum CodingKeys: String, CodingKey {
        case a, b, simulertA = "sa", simulertB = "sb", etikett = "e", tekst = "t", merke = "m", alvorlig = "al"
    }

    public init(a: Int, b: Int, simulert: (Farge, Farge)? = nil, etikett: String? = nil, tekst: String? = nil,
                merke: String? = nil, alvorlig: Bool? = nil) {
        self.a = a
        self.b = b
        simulertA = simulert.map { String($0.0.hex().dropFirst()) }
        simulertB = simulert.map { String($0.1.hex().dropFirst()) }
        self.etikett = etikett
        self.tekst = tekst
        self.merke = merke
        self.alvorlig = alvorlig
    }

    var rensket: DeltRapportpar {
        func hex(_ s: String?) -> String? { s.flatMap { $0.count == 6 && $0.allSatisfy(\.isHexDigit) ? $0 : nil } }
        var p = self
        p.simulertA = hex(simulertA)
        p.simulertB = hex(simulertB)
        p.tekst = tekst.map(DeltInnhold.rensket)
        p.etikett = etikett.map(DeltInnhold.rensket)
        p.merke = merke.map(DeltInnhold.rensket)
        return p
    }
}
