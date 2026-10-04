import Compression
import Foundation

/// Lenker som deler farger, paletter, gradienter og harmonier med andre: `https://kolorist.no/l#z…`.
///
/// Innholdet ligger etter `#`, så det sendes aldri til nettstedet. Har mottakeren Kolorist, åpner lenken appen
/// (universell lenke); ellers viser siden på kolorist.no fargene i nettleseren. `kolorist://l#z…` virker også.
///
/// Formatet er eget og versjonert – ikke appens interne typer – fordi det leses av både appen og visningssiden
/// (JavaScript): kompakt JSON med korte nøkler, komprimert med DEFLATE (rå, som `DecompressionStream("deflate-raw")`
/// i nettlesere) og kodet som base64url, med `z` foran. Endringer skal være bakoverkompatible: nye felt er valgfrie.
/// Testlenkene i `Tests/FargeKjerneTests/Testlenker.json` binder appen og visningssiden til samme tolkning.
public enum Delingslenke {
    /// Formatversjonen denne koden skriver.
    public static let versjon = 1
    public static let nettadresse = "https://kolorist.no/l"
    public static let skjema = "kolorist"

    /// Grenser for hva en lenke kan inneholde – lenker kan lages av hvem som helst.
    public static let maksFarger = 256
    public static let maksStopp = 64
    public static let maksTegn = 32_000
    static let maksUtpakket = 1 << 20
    static let maksNavn = 200

    public enum Feil: Error, Equatable {
        /// Ikke en Kolorist-lenke.
        case ikkeKoloristlenke
        /// Lenken er skadet eller avkortet.
        case skadet
        /// Lenken er lengre eller har flere farger enn tillatt.
        case forStor
        /// Lenken mangler innhold (f.eks. en palett uten farger).
        case tom
    }

    // MARK: Skriv

    public static func lenke(_ innhold: DeltInnhold) throws -> URL {
        let fragment = try kode(innhold)
        guard let url = URL(string: "\(nettadresse)#\(fragment)") else { throw Feil.skadet }
        return url
    }

    static func kode(_ innhold: DeltInnhold) throws -> String {
        let koder = JSONEncoder()
        koder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let json = try koder.encode(innhold)
        guard let pakket = komprimer(json) else { throw Feil.skadet }
        let fragment = "z" + base64url(pakket)
        guard fragment.count <= maksTegn else { throw Feil.forStor }
        return fragment
    }

    // MARK: Les

    /// Innholdet i en lenke fra Kolorist: `https://kolorist.no/l#z…` (også www) eller `kolorist://l#z…`.
    public static func les(_ url: URL) throws -> DeltInnhold {
        let erNett = (url.scheme == "https" || url.scheme == "http")
            && ["kolorist.no", "www.kolorist.no"].contains(url.host?.lowercased() ?? "")
            && ["/l", "/l/"].contains(url.path)
        let erSkjema = url.scheme == skjema && (url.host == "l" || url.path == "l" || url.path == "/l")
        guard erNett || erSkjema, let fragment = url.fragment(percentEncoded: false) else { throw Feil.ikkeKoloristlenke }
        return try dekode(fragment)
    }

    static func dekode(_ fragment: String) throws -> DeltInnhold {
        guard fragment.count <= maksTegn else { throw Feil.forStor }
        guard fragment.first == "z", let pakket = fraBase64url(String(fragment.dropFirst())),
              let json = pakkUt(pakket) else { throw Feil.skadet }
        let innhold: DeltInnhold
        do { innhold = try JSONDecoder().decode(DeltInnhold.self, from: json) } catch { throw Feil.skadet }
        return try innhold.kontrollert()
    }

    // MARK: Koding

    static func base64url(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func fraBase64url(_ tekst: String) -> Data? {
        var s = tekst.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while s.count % 4 != 0 { s += "=" }
        return Data(base64Encoded: s)
    }

    /// Rå DEFLATE (Apples `COMPRESSION_ZLIB` er DEFLATE uten zlib-hode).
    static func komprimer(_ data: Data) -> Data? {
        let kapasitet = data.count + 1024
        var ut = Data(count: kapasitet)
        let antall = ut.withUnsafeMutableBytes { mål in
            data.withUnsafeBytes { kilde in
                compression_encode_buffer(mål.bindMemory(to: UInt8.self).baseAddress!, kapasitet,
                                          kilde.bindMemory(to: UInt8.self).baseAddress!, data.count, nil, COMPRESSION_ZLIB)
            }
        }
        guard antall > 0 else { return nil }
        return ut.prefix(antall)
    }

    /// Pakker ut med et tak, så en ondsinnet lenke ikke kan blåses opp til mye minne.
    static func pakkUt(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }
        var ut = Data(count: maksUtpakket)
        let antall = ut.withUnsafeMutableBytes { mål in
            data.withUnsafeBytes { kilde in
                compression_decode_buffer(mål.bindMemory(to: UInt8.self).baseAddress!, maksUtpakket,
                                          kilde.bindMemory(to: UInt8.self).baseAddress!, data.count, nil, COMPRESSION_ZLIB)
            }
        }
        guard antall > 0, antall < maksUtpakket else { return nil }
        return ut.prefix(antall)
    }
}

// MARK: - Innholdet

/// Det en lenke deler. Nøklene er korte for å holde lenkene korte; visningssiden leser de samme nøklene.
public struct DeltInnhold: Codable, Equatable, Sendable {
    public enum Slag: String, Codable, Sendable { case farge, palett, gradient, harmoni }

    /// Formatversjonen lenken ble skrevet med (en nyere versjon kan ha felt som ignoreres).
    public var versjon: Int
    /// Ukjent slag (fra en nyere versjon) leses som `nil`.
    public var slag: Slag?
    public var navn: String?
    /// Fargene: én for en farge, palettens farger, eller harmoniens farger.
    public var farger: [DeltFarge]
    /// Gradientene: én for en gradient, eller palettens gradienter.
    public var gradienter: [DeltGradient]
    public var harmoni: DeltHarmoni?

    public init(slag: Slag, navn: String? = nil, farger: [DeltFarge] = [], gradienter: [DeltGradient] = [],
                harmoni: DeltHarmoni? = nil) {
        self.versjon = Delingslenke.versjon
        self.slag = slag
        self.navn = navn
        self.farger = farger
        self.gradienter = gradienter
        self.harmoni = harmoni
    }

    enum CodingKeys: String, CodingKey {
        case versjon = "v", slag = "t", navn = "n", farger = "f", gradienter = "g", harmoni = "h"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        versjon = try c.decode(Int.self, forKey: .versjon)
        slag = try? c.decodeIfPresent(Slag.self, forKey: .slag)
        navn = try c.decodeIfPresent(String.self, forKey: .navn)
        farger = try c.decodeIfPresent([DeltFarge].self, forKey: .farger) ?? []
        gradienter = try c.decodeIfPresent([DeltGradient].self, forKey: .gradienter) ?? []
        harmoni = try c.decodeIfPresent(DeltHarmoni.self, forKey: .harmoni)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(versjon, forKey: .versjon)
        try c.encodeIfPresent(slag, forKey: .slag)
        try c.encodeIfPresent(navn.flatMap { $0.isEmpty ? nil : $0 }, forKey: .navn)
        if !farger.isEmpty { try c.encode(farger, forKey: .farger) }
        if !gradienter.isEmpty { try c.encode(gradienter, forKey: .gradienter) }
        try c.encodeIfPresent(harmoni, forKey: .harmoni)
    }

    /// Sjekker grensene og rydder tekst, så innholdet trygt kan vises og lagres.
    func kontrollert() throws -> DeltInnhold {
        guard let slag else { throw Delingslenke.Feil.skadet }
        let alleFarger = farger.count + gradienter.reduce(0) { $0 + $1.stopp.count } + (harmoni == nil ? 0 : 1)
        guard alleFarger <= Delingslenke.maksFarger, gradienter.count <= Delingslenke.maksFarger,
              gradienter.allSatisfy({ $0.stopp.count <= Delingslenke.maksStopp }) else { throw Delingslenke.Feil.forStor }
        guard farger.allSatisfy(\.erGyldig), gradienter.allSatisfy(\.erGyldig), harmoni?.grunn.erGyldig ?? true
        else { throw Delingslenke.Feil.skadet }
        switch slag {
        case .farge, .palett, .harmoni: if farger.isEmpty && gradienter.isEmpty { throw Delingslenke.Feil.tom }
        case .gradient: if gradienter.isEmpty { throw Delingslenke.Feil.tom }
        }
        var ny = self
        ny.navn = navn.map(Self.rensket)
        ny.farger = farger.map { var f = $0; f.rens(); return f }
        ny.gradienter = gradienter.map { g in
            var g = g
            g.navn = g.navn.map(Self.rensket)
            g.stopp = g.stopp.map { s in var s = s; s.farge.rens(); return s }
            return g
        }
        return ny
    }

    /// Uten kontrolltegn og ikke lengre enn `maksNavn`.
    static func rensket(_ s: String) -> String {
        String(String(s.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }).prefix(Delingslenke.maksNavn))
    }
}

/// En farge i en lenke: OKLab (kanonisk, og direkte brukbar som `oklab()` i CSS), med navn, fargemodellen den ble
/// laget i, og Munsell-notasjonen ferdig utregnet for visningssiden.
public struct DeltFarge: Codable, Equatable, Sendable {
    /// OKLab: L, a, b.
    public var okLab: [Double]
    public var alfa: Double?
    public var navn: String?
    /// Rommet fargen ble laget i: `modell:<Fargemodell>` eller `icc:<profil-id>`.
    public var rom: String?
    /// Visningsnavnet til rommet («Munsell», «Generisk CMYK»).
    public var romnavn: String?
    public var verdier: [Double]?
    /// Verdiene slik de ble vist («78 / 41 / 0 / 15 %»).
    public var tekst: String?
    /// Munsell-notasjonen, for visningssiden (som ikke regner Munsell selv).
    public var munsell: String?
    /// sRGB-hex uten «#», gamut-kartlagt som i appen (CSS Color 4), så visningssiden viser samme verdi.
    public var hex: String?

    enum CodingKeys: String, CodingKey {
        case okLab = "k", alfa = "a", navn = "n", rom = "r", romnavn = "rn", verdier = "rv", tekst = "rt", munsell = "mu", hex = "x"
    }

    public init(_ farge: Farge, navn: String? = nil, representasjon: Fargerepresentasjon? = nil) {
        let lab = farge.okLab
        okLab = [lab.l, lab.a, lab.b].map { Self.avrundet($0, 5) }
        alfa = farge.alfa < 1 ? Self.avrundet(farge.alfa, 3) : nil
        self.navn = navn.flatMap { $0.isEmpty ? nil : $0 }
        if let r = representasjon {
            switch r.rom {
            case .modell(let m): rom = "modell:\(m.rawValue)"; romnavn = m.navn
            case .icc(let id, let n): rom = "icc:\(id)"; romnavn = n
            }
            verdier = r.verdier.map { Self.avrundet($0, 4) }
            tekst = r.tekst
        }
        munsell = farge.munsell.notasjon
        hex = String(farge.hex().dropFirst())
    }

    public init(_ pf: PalettFarge) {
        self.init(pf.farge, navn: pf.navn, representasjon: pf.representasjon)
    }

    public var farge: Farge {
        Farge(okLab: OKLab(l: okLab[0], a: okLab[1], b: okLab[2]), alfa: alfa ?? 1)
    }

    /// Representasjonen, når rommet er kjent: fargemodeller alltid, ICC-profiler bare når mottakeren har profilen.
    public func representasjon(harProfil: (String) -> Bool) -> Fargerepresentasjon? {
        guard let rom, let verdier, let tekst else { return nil }
        if rom.hasPrefix("modell:"), let m = Fargemodell(rawValue: String(rom.dropFirst(7))) {
            return Fargerepresentasjon(rom: .modell(m), verdier: verdier, tekst: tekst)
        }
        if rom.hasPrefix("icc:") {
            let id = String(rom.dropFirst(4))
            guard harProfil(id) else { return nil }
            return Fargerepresentasjon(rom: .icc(id: id, navn: romnavn ?? id), verdier: verdier, tekst: tekst)
        }
        return nil
    }

    public func palettFarge(opphav: PalettFarge.Opphav = .manuell, harProfil: (String) -> Bool) -> PalettFarge {
        PalettFarge(navn: navn ?? "", farge: farge, opphav: opphav, representasjon: representasjon(harProfil: harProfil))
    }

    var erGyldig: Bool {
        okLab.count == 3 && okLab.allSatisfy(\.isFinite)
            && (-0.5...1.5).contains(okLab[0]) && abs(okLab[1]) <= 1 && abs(okLab[2]) <= 1
            && (alfa.map { (0...1).contains($0) } ?? true)
            && (verdier?.count ?? 0) <= 8 && (verdier?.allSatisfy(\.isFinite) ?? true)
    }

    mutating func rens() {
        navn = navn.map(DeltInnhold.rensket)
        romnavn = romnavn.map(DeltInnhold.rensket)
        tekst = tekst.map(DeltInnhold.rensket)
        munsell = munsell.map(DeltInnhold.rensket)
        hex = hex.flatMap { $0.count == 6 && $0.allSatisfy(\.isHexDigit) ? $0 : nil }
        rom = rom.map(DeltInnhold.rensket)
    }

    static func avrundet(_ x: Double, _ desimaler: Int) -> Double {
        let f = pow(10, Double(desimaler))
        return (x * f).rounded() / f
    }
}

/// En gradient: to eller flere fargestopp (med valgfri plassering 0–1; uten plassering fordeles de jevnt),
/// antall toner og lysere/mørkere trinn.
public struct DeltGradient: Codable, Equatable, Sendable {
    public var navn: String?
    public var stopp: [DeltStopp]
    public var antall: Int?
    public var trinn: DeltTrinn?

    enum CodingKeys: String, CodingKey { case navn = "n", stopp = "s", antall = "a", trinn = "l" }

    public init(navn: String? = nil, stopp: [DeltStopp], antall: Int? = nil, trinn: Lyshetstrinn? = nil) {
        self.navn = navn.flatMap { $0.isEmpty ? nil : $0 }
        self.stopp = stopp
        self.antall = antall
        self.trinn = trinn.map(DeltTrinn.init)
    }

    var erGyldig: Bool {
        stopp.count >= 2 && stopp.allSatisfy { $0.farge.erGyldig && ($0.posisjon.map { (0...1).contains($0) } ?? true) }
            && (antall.map { (2...64).contains($0) } ?? true) && (trinn?.erGyldig ?? true)
    }
}

public struct DeltStopp: Codable, Equatable, Sendable {
    public var farge: DeltFarge
    /// Plassering 0–1 (nil = jevnt fordelt).
    public var posisjon: Double?

    enum CodingKeys: String, CodingKey { case farge = "f", posisjon = "p" }

    public init(_ farge: DeltFarge, posisjon: Double? = nil) {
        self.farge = farge
        self.posisjon = posisjon.map { DeltFarge.avrundet($0, 4) }
    }
}

public struct DeltTrinn: Codable, Equatable, Sendable {
    public var lysere: Int
    public var mørkere: Int
    public var lysereSteg: Double
    public var mørkereSteg: Double
    public var modus: String

    enum CodingKeys: String, CodingKey { case lysere = "l", mørkere = "m", lysereSteg = "ls", mørkereSteg = "ms", modus = "mo" }

    public init(_ t: Lyshetstrinn) {
        lysere = t.antallLysere
        mørkere = t.antallMørkere
        lysereSteg = DeltFarge.avrundet(t.lysereSteg, 4)
        mørkereSteg = DeltFarge.avrundet(t.mørkereSteg, 4)
        modus = t.modus.rawValue
    }

    public var lyshetstrinn: Lyshetstrinn {
        Lyshetstrinn(antallLysere: lysere, antallMørkere: mørkere, lysereSteg: lysereSteg, mørkereSteg: mørkereSteg,
                     modus: Lyshetstrinn.Modus(rawValue: modus) ?? .fast)
    }

    var erGyldig: Bool {
        (0...10).contains(lysere) && (0...10).contains(mørkere)
            && (0...1).contains(lysereSteg) && (0...1).contains(mørkereSteg)
    }
}

/// Oppsettet bak en harmoni, så mottakeren kan jobbe videre med den. Fargene selv ligger i `DeltInnhold.farger`.
public struct DeltHarmoni: Codable, Equatable, Sendable {
    public var harmoni: String
    public var sirkel: String
    public var grunn: DeltFarge
    public var antall: Int?
    public var vinkel: Double?
    public var lyshetsrekkefølge: String?
    /// Grunnfargens plass blant fargene.
    public var grunnIndeks: Int?

    enum CodingKeys: String, CodingKey {
        case harmoni = "h", sirkel = "s", grunn = "g", antall = "a", vinkel = "w", lyshetsrekkefølge = "o", grunnIndeks = "i"
    }

    public init(harmoni: Harmoni, sirkel: Fargesirkel, grunn: Farge, antall: Int?, vinkel: Double?,
                lyshetsrekkefølge: Lyshetsrekkefølge, grunnIndeks: Int?) {
        self.harmoni = harmoni.rawValue
        self.sirkel = sirkel.rawValue
        self.grunn = DeltFarge(grunn)
        self.antall = antall
        self.vinkel = vinkel.map { DeltFarge.avrundet($0, 2) }
        self.lyshetsrekkefølge = lyshetsrekkefølge == .lik ? nil : lyshetsrekkefølge.rawValue
        self.grunnIndeks = grunnIndeks
    }
}
