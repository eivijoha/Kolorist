import Foundation

/// Et designsystem i en delingslenke (fra 1.3). Rollefargene ligger i `DeltInnhold.farger` (med rollenavnet som navn),
/// så lenken også er en vanlig palett. Her står hva hver farge er, skriftfargene, malen for egne roller – og de ferdige
/// fargene i hver modus, så visningssiden kan vise designsystemet uten å regne det ut selv. Appen regner alltid ut fargene
/// på nytt fra rollene (`designsystem(navn:farger:)`); de ferdige fargene brukes bare til visning på nettet.
public struct DeltDesignsystem: Codable, Equatable, Sendable {
    /// Rollen til hver farge i `DeltInnhold.farger`, i samme rekkefølge: `Designrolle.rawValue`, eller `egen` for en egen
    /// rolle (se `egne`).
    public var roller: [String]
    /// Skriftfargene: nær hvit og nær sort.
    public var lysTekst: DeltFarge
    public var mørkTekst: DeltFarge
    /// Egne roller: fargens plass i `farger`, navnet og malen (`Rollemal.rawValue`).
    public var egne: [DeltEgenRolle]
    /// Tokennavnene (`color.text.secondary` …), i samme rekkefølge som hex-verdiene i `moduser`.
    public var tokennavn: [String]
    /// sRGB-hex uten «#» for hvert token, per modus (`light`, `dark`, `light-ic`, `dark-ic`).
    public var moduser: [String: [String]]

    enum CodingKeys: String, CodingKey {
        case roller = "r", lysTekst = "lt", mørkTekst = "mt", egne = "e", tokennavn = "tn", moduser = "tm"
    }

    static let maksTokens = 64

    /// Designsystemet med fargene i rekkefølgen lenken skal ha (se `Delingslenke`-bruk i appen): først de faste rollene,
    /// så de egne.
    public init(_ ds: Designsystem) {
        roller = Designrolle.allCases.map(\.rawValue) + ds.egneRoller.map { _ in "egen" }
        lysTekst = DeltFarge(ds.lysTekst)
        mørkTekst = DeltFarge(ds.mørkTekst)
        egne = zip(ds.egneRoller, ds.egneTokennavn).enumerated().map { i, par in
            DeltEgenRolle(indeks: Designrolle.allCases.count + i, navn: par.0.navn, mal: par.0.mal.rawValue, token: par.1)
        }
        let temaer = Designmodus.allCases.map { ds.tema($0) }
        tokennavn = temaer.first?.tokens.map(\.navn) ?? []
        moduser = Dictionary(uniqueKeysWithValues: temaer.map { t in
            (t.modus.tokennavn, t.tokens.map { String($0.farge.hex().dropFirst()) })
        })
    }

    /// Fargene lenken skal ha for designsystemet: rollene med navn, i samme rekkefølge som `roller`.
    public static func farger(_ ds: Designsystem, rollenavn: (Designrolle) -> String) -> [DeltFarge] {
        Designrolle.allCases.map { DeltFarge(ds[$0], navn: rollenavn($0)) } + ds.egneRoller.map { DeltFarge($0.farge, navn: $0.navn) }
    }

    /// Designsystemet igjen, fra rollene og fargene i lenken. Fargene i hver modus regnes ut på nytt.
    public func designsystem(navn: String, farger: [DeltFarge]) -> Designsystem {
        var r: [Designrolle: Farge] = [:]
        for (rolle, f) in zip(roller, farger) {
            if let rolle = Designrolle(rawValue: rolle) { r[rolle] = f.farge }
        }
        let egneRoller = egne.compactMap { e -> EgenRolle? in
            guard farger.indices.contains(e.indeks) else { return nil }
            return EgenRolle(navn: e.navn, farge: farger[e.indeks].farge, mal: Rollemal(rawValue: e.mal) ?? .status)
        }
        return Designsystem(navn: navn, roller: r, lysTekst: lysTekst.farge, mørkTekst: mørkTekst.farge,
                            egneRoller: Array(egneRoller.prefix(EgenRolle.maksAntall)))
    }

    /// Sjekker at designsystemet passer til fargene og holder seg innenfor grensene. `nil` når det ikke gjør det.
    func kontrollert(antallFarger: Int) -> DeltDesignsystem? {
        guard roller.count <= antallFarger, roller.allSatisfy({ $0.count <= 40 }),
              lysTekst.erGyldig, mørkTekst.erGyldig,
              egne.count <= EgenRolle.maksAntall, egne.allSatisfy({ (0..<antallFarger).contains($0.indeks) }),
              tokennavn.count <= Self.maksTokens, moduser.count <= 8,
              moduser.values.allSatisfy({ $0.count == tokennavn.count && $0.allSatisfy(Self.erHex) })
        else { return nil }
        var ny = self
        ny.tokennavn = tokennavn.map(DeltInnhold.rensket)
        ny.egne = egne.map { e in
            var e = e
            e.navn = DeltInnhold.rensket(e.navn)
            e.mal = DeltInnhold.rensket(e.mal)
            e.token = e.token.map(DeltInnhold.rensket)
            return e
        }
        ny.lysTekst.rens()
        ny.mørkTekst.rens()
        return ny
    }

    static func erHex(_ s: String) -> Bool { s.count == 6 && s.allSatisfy(\.isHexDigit) }
}

/// En egen rolle i en delingslenke.
public struct DeltEgenRolle: Codable, Equatable, Sendable {
    /// Fargens plass i `DeltInnhold.farger`.
    public var indeks: Int
    public var navn: String
    /// `Rollemal.rawValue`.
    public var mal: String
    /// Navnet i tokenene (`info` i `color.text.info`), for visningssiden.
    public var token: String?

    enum CodingKeys: String, CodingKey { case indeks = "i", navn = "n", mal = "m", token = "t" }
}
