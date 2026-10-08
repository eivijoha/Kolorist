import Foundation

// Designsystem fra en palett (fra 1.3): fargeroller (aksent, sekundær, nøytral og status) og skriftfarger, utledet til
// semantiske farger for lys og mørk modus, begge med og uten økt kontrast.
//
// Fargene ligger i sRGB (standard): WCAG-kontrasten regnes på sRGB, og nettet og Figma bruker sRGB.
//
// Lysheten styres med CIE L* (`Farge.lStjerne`), som bestemmer WCAG-kontrasten eksakt for alle kulører. Hver semantisk
// farge har et L*-område per modus; en rollefarge som allerede ligger i området, brukes uendret (merkefargen beholdes der
// den holder), ellers flyttes den til nærmeste L* i området med samme kulør og kroma (OKLCH). Områdene er valgt så alle
// kontrollpunktene (`Designtema.sjekker`) holder WCAG 2 AA mot bakgrunnene de står på.

/// En fargerolle i et designsystem.
public enum Designrolle: String, CaseIterable, Codable, CodingKeyRepresentable, Sendable, Identifiable {
    case aksent, sekundær, nøytral, feil, suksess, advarsel

    public var id: String { rawValue }

    /// Navnet i eksporterte tokens (engelsk, som er vanlig i kode).
    public var tokennavn: String {
        switch self {
        case .aksent: "accent"
        case .sekundær: "secondary"
        case .nøytral: "neutral"
        case .feil: "danger"
        case .suksess: "success"
        case .advarsel: "warning"
        }
    }

    public static let statusroller: [Designrolle] = [.feil, .suksess, .advarsel]

    /// Kuløren (OKLCH) en statusfarge fra paletten bør ligge nær for å bli valgt automatisk.
    var målkulør: Double? {
        switch self {
        case .feil: 27
        case .suksess: 148
        case .advarsel: 80
        default: nil
        }
    }

    /// Fargen rollen får når paletten ikke har en som passer.
    public var standardfarge: Farge {
        switch self {
        case .aksent, .sekundær: Farge(okLCH: OKLCH(l: 0.55, c: 0.17, h: 255))
        case .nøytral: Farge(okLCH: OKLCH(l: 0.55, c: 0.01, h: 255))
        case .feil: Farge(okLCH: OKLCH(l: 0.58, c: 0.2, h: 27))
        case .suksess: Farge(okLCH: OKLCH(l: 0.6, c: 0.15, h: 148))
        case .advarsel: Farge(okLCH: OKLCH(l: 0.82, c: 0.16, h: 80))
        }
    }
}

/// Lys eller mørk modus, med eller uten økt kontrast (tilgjengelighetsinnstillingen i iOS og macOS, `prefers-contrast` på
/// nettet).
public enum Designmodus: String, CaseIterable, Codable, Sendable, Identifiable {
    case lys, mørk, lysØktKontrast, mørkØktKontrast

    public var id: String { rawValue }
    public var erMørk: Bool { self == .mørk || self == .mørkØktKontrast }
    public var øktKontrast: Bool { self == .lysØktKontrast || self == .mørkØktKontrast }

    public init(mørk: Bool, øktKontrast: Bool) {
        switch (mørk, øktKontrast) {
        case (false, false): self = .lys
        case (true, false): self = .mørk
        case (false, true): self = .lysØktKontrast
        case (true, true): self = .mørkØktKontrast
        }
    }

    /// Navnet i eksporterte filer og tokens.
    public var tokennavn: String {
        switch self {
        case .lys: "light"
        case .mørk: "dark"
        case .lysØktKontrast: "light-ic"
        case .mørkØktKontrast: "dark-ic"
        }
    }
}

/// Tilstanden en komponent vises i.
public enum Komponenttilstand: String, CaseIterable, Sendable, Identifiable {
    case normal, trykket, fokus, deaktivert
    public var id: String { rawValue }
}

/// Et designsystem: fargen for hver rolle og skriftfargene. Alt annet utledes (`tema(_:)`).
public struct Designsystem: Codable, Hashable, Sendable {
    public var navn: String
    public var roller: [Designrolle: Farge]
    /// Skriftfarge nær hvit (tekst i mørk modus og på mørke flater).
    public var lysTekst: Farge
    /// Skriftfarge nær sort (tekst i lys modus og på lyse flater).
    public var mørkTekst: Farge

    public init(navn: String, roller: [Designrolle: Farge], lysTekst: Farge, mørkTekst: Farge) {
        self.navn = navn
        self.roller = roller
        self.lysTekst = lysTekst
        self.mørkTekst = mørkTekst
    }

    /// Fargen for en rolle (standardfargen når den mangler).
    public subscript(rolle: Designrolle) -> Farge {
        get { roller[rolle] ?? rolle.standardfarge }
        set { roller[rolle] = newValue }
    }

    /// Designsystemet en palett gir: roller fordelt automatisk (`automatiskeRoller`) og palettens skriftfarger (eller
    /// forslag nær hvit og sort med palettens kulørpreg).
    public init(fra palett: Palett, gamut: Gamut = .sRGB) {
        let auto = Self.automatiskeRoller(for: palett.farger)
        var roller: [Designrolle: Farge] = [:]
        let aksent = auto[.aksent]?.farge ?? Designrolle.aksent.standardfarge
        roller[.aksent] = aksent
        roller[.sekundær] = auto[.sekundær]?.farge ?? aksent
        let a = aksent.okLCH
        roller[.nøytral] = auto[.nøytral]?.farge ?? Farge(okLCH: OKLCH(l: 0.55, c: min(a.c, 0.012), h: a.h))
        for rolle in Designrolle.statusroller { roller[rolle] = auto[rolle]?.farge ?? rolle.standardfarge }
        let (lys, mørk) = Self.skriftfarger(for: palett, gamut: gamut)
        self.init(navn: palett.navn, roller: roller, lysTekst: lys, mørkTekst: mørk)
    }

    /// Skriftfargene fra paletten (den lyseste og den mørkeste), når de er lyse og mørke nok; ellers forslagene.
    static func skriftfarger(for palett: Palett, gamut: Gamut) -> (lys: Farge, mørk: Farge) {
        let forslag = Skriftfarger.forslag(for: palett.farger.map(\.farge), gamut: gamut)
        let lysest = palett.tekstfarger.max { $0.farge.lStjerne < $1.farge.lStjerne }?.farge
        let mørkest = palett.tekstfarger.min { $0.farge.lStjerne < $1.farge.lStjerne }?.farge
        let lys = lysest.flatMap { $0.lStjerne >= 85 ? $0 : nil } ?? forslag[0].farge
        let mørk = mørkest.flatMap { $0.lStjerne <= 25 ? $0 : nil } ?? forslag[1].farge
        return (lys, mørk)
    }

    /// Fordeler palettens farger på rollene: aksent er den første fargen med tydelig kulør (OKLCH C ≥ 0,04), statusrollene
    /// får en farge med kulør nær rødt, grønt og gult (innenfor 25°) når paletten har en, sekundær er den neste fargen med
    /// kulør, og nøytral den gråeste fargen under C 0,04. Roller uten farge mangler i svaret.
    public static func automatiskeRoller(for farger: [PalettFarge]) -> [Designrolle: PalettFarge] {
        let kromatiske = farger.filter { $0.farge.okLCH.c >= 0.04 }
        var r: [Designrolle: PalettFarge] = [:]
        r[.aksent] = kromatiske.first ?? farger.first
        func avstand(_ f: PalettFarge, _ mål: Double) -> Double {
            let d = abs(f.farge.okLCH.h - mål).truncatingRemainder(dividingBy: 360)
            return min(d, 360 - d)
        }
        for rolle in Designrolle.statusroller {
            guard let mål = rolle.målkulør else { continue }
            let brukt = Set(r.values.map(\.id))
            r[rolle] = kromatiske
                .filter { !brukt.contains($0.id) && $0.farge.okLCH.c >= 0.08 && avstand($0, mål) <= 25 }
                .min { avstand($0, mål) < avstand($1, mål) }
        }
        let brukt = Set(r.values.map(\.id))
        r[.sekundær] = kromatiske.first { !brukt.contains($0.id) }
        r[.nøytral] = farger.filter { $0.farge.okLCH.c < 0.04 }.min { $0.farge.okLCH.c < $1.farge.okLCH.c }
        return r
    }

    /// Toneskalaen for en rolle (50–950, forankret i L*, se `Toneskala.kontrastLStjerne`). Nøytral får lav kroma.
    public func skala(for rolle: Designrolle, gamut: Gamut = .sRGB) -> [Farge] {
        var grunn = self[rolle]
        if rolle == .nøytral {
            let lch = grunn.okLCH
            grunn = Farge(okLCH: OKLCH(l: lch.l, c: min(lch.c, 0.03), h: lch.h))
        }
        return Toneskala(gamut: gamut).toner(for: grunn, lStjerne: Toneskala.kontrastLStjerne)
    }

    /// Navnene på trinnene i `skala(for:)`.
    public static let trinnavn = ["50", "100", "200", "300", "400", "500", "600", "700", "800", "900", "950"]
}

// MARK: - Tema per modus

/// En statusfarge (feil, suksess, advarsel) i et varsel: tekst og ikon på en tonet flate.
public struct Statusfarger: Hashable, Sendable {
    public var tekst: Farge
    public var flate: Farge
}

/// De semantiske fargene i én modus.
public struct Designtema: Hashable, Sendable {
    public var modus: Designmodus
    /// Sidebakgrunn (grupperte lister ligger på den).
    public var bakgrunn: Farge
    /// Flater: kort, celler, felt og fanelinje.
    public var flate: Farge
    public var tekst: Farge
    public var sekundærtekst: Farge
    public var plassholder: Farge
    /// Kant som definerer en komponent (tekstfelt), minst 3:1 mot flaten.
    public var kant: Farge
    /// Dekorativ skillelinje (ingen krav).
    public var skille: Farge
    /// Fyll for hovedknapp, lenker, valgt fane og fokusring.
    public var aksent: Farge
    public var aksentTrykket: Farge
    /// Tekst på aksenten.
    public var påAksent: Farge
    /// Tonet flate for sekundærknapp, med aksenten som tekst.
    public var aksentTonet: Farge
    /// Bryter som er på.
    public var sekundær: Farge
    public var deaktivertFyll: Farge
    public var deaktivertTekst: Farge
    public var status: [Designrolle: Statusfarger]

    public func status(_ rolle: Designrolle) -> Statusfarger {
        status[rolle] ?? Statusfarger(tekst: tekst, flate: flate)
    }

    /// Semantiske tokens i fast rekkefølge, med navn som i eksporten.
    public var tokens: [(navn: String, farge: Farge)] {
        var t: [(String, Farge)] = [
            ("bg", bakgrunn), ("surface", flate), ("text", tekst), ("text-secondary", sekundærtekst),
            ("placeholder", plassholder), ("border", kant), ("separator", skille),
            ("accent", aksent), ("accent-pressed", aksentTrykket), ("on-accent", påAksent), ("accent-subtle", aksentTonet),
            ("secondary", sekundær), ("disabled-bg", deaktivertFyll), ("disabled-text", deaktivertTekst),
        ]
        for rolle in Designrolle.statusroller {
            let s = status(rolle)
            t.append(("\(rolle.tokennavn)-text", s.tekst))
            t.append(("\(rolle.tokennavn)-bg", s.flate))
        }
        return t
    }
}

/// L*-mål og -områder per modus (se typen `Designsystem`).
private struct Nivåer {
    var bakgrunn, flate, sekundærtekst, plassholder, kant, skille, deaktivertFyll, deaktivertTekst: Double
    var aksent: ClosedRange<Double>
    /// L*-endring for trykket tilstand: bort fra bakgrunnen (mørkere i lys modus, lysere i mørk).
    var trykket: Double
    var tonet: Double
    var sekundær: ClosedRange<Double>
    var statusTekst: ClosedRange<Double>
    var statusFlate: Double
    var advarselFlate: Double
    /// L* for teksten i økt kontrast (nil: skriftfargen).
    var tekst: Double?

    static func `for`(_ modus: Designmodus) -> Nivåer {
        switch modus {
        case .lys:
            Nivåer(bakgrunn: 96, flate: 100, sekundærtekst: 44, plassholder: 48, kant: 56, skille: 86, deaktivertFyll: 92,
                   deaktivertTekst: 66, aksent: 25...44, trykket: -9, tonet: 93, sekundær: 25...58, statusTekst: 25...42,
                   statusFlate: 94, advarselFlate: 84, tekst: nil)
        case .lysØktKontrast:
            Nivåer(bakgrunn: 96, flate: 100, sekundærtekst: 32, plassholder: 36, kant: 42, skille: 66, deaktivertFyll: 90,
                   deaktivertTekst: 55, aksent: 18...36, trykket: -8, tonet: 93, sekundær: 18...48, statusTekst: 15...32,
                   statusFlate: 94, advarselFlate: 86, tekst: 2)
        case .mørk:
            Nivåer(bakgrunn: 2, flate: 11, sekundærtekst: 66, plassholder: 58, kant: 46, skille: 24, deaktivertFyll: 20,
                   deaktivertTekst: 40, aksent: 60...76, trykket: 9, tonet: 15, sekundær: 46...90, statusTekst: 66...82,
                   statusFlate: 19, advarselFlate: 80, tekst: nil)
        case .mørkØktKontrast:
            Nivåer(bakgrunn: 0, flate: 9, sekundærtekst: 78, plassholder: 70, kant: 60, skille: 40, deaktivertFyll: 22,
                   deaktivertTekst: 50, aksent: 72...88, trykket: 8, tonet: 12, sekundær: 58...95, statusTekst: 76...90,
                   statusFlate: 16, advarselFlate: 84, tekst: 100)
        }
    }
}

public extension Designsystem {
    /// De semantiske fargene i en modus.
    func tema(_ modus: Designmodus, gamut: Gamut = .sRGB) -> Designtema {
        let n = Nivåer.for(modus)
        let nøytral = self[.nøytral].okLCH
        let k = min(nøytral.c, 0.03)
        func grå(_ l: Double, _ andel: Double = 1) -> Farge {
            Farge.medLStjerne(l, kroma: k * andel, kulør: nøytral.h, gamut: gamut)
        }
        /// Fargen selv når L* ligger i området, ellers samme kulør og kroma på nærmeste L* i området.
        func iOmråde(_ f: Farge, _ område: ClosedRange<Double>) -> Farge {
            var g = f.gamutKartlagt(til: gamut)
            g.alfa = 1
            let l = g.lStjerne
            if område.contains(l) { return g }
            let lch = f.okLCH
            return Farge.medLStjerne(min(max(l, område.lowerBound), område.upperBound), kroma: lch.c, kulør: lch.h, gamut: gamut)
        }
        func flytt(_ f: Farge, til l: Double, kroma: Double? = nil) -> Farge {
            let lch = f.okLCH
            return Farge.medLStjerne(min(max(l, 0), 100), kroma: kroma ?? lch.c, kulør: lch.h, gamut: gamut)
        }

        let lys = modus.øktKontrast ? grå(100, 0) : lysTekst.gamutKartlagt(til: gamut)
        let mørk = modus.øktKontrast ? grå(2, 0.3) : mørkTekst.gamutKartlagt(til: gamut)
        let tekst = n.tekst.map { grå($0, 0.3) } ?? (modus.erMørk ? lys : mørk)
        let aksent = iOmråde(self[.aksent], n.aksent)
        let a = aksent.okLCH
        let skrift = [PalettFarge(farge: lys), PalettFarge(farge: mørk)]
        let påAksent = Skriftfarger.beste(for: aksent, blant: skrift)?.farge ?? lys

        var status: [Designrolle: Statusfarger] = [:]
        for rolle in Designrolle.statusroller {
            let grunn = self[rolle]
            if rolle == .advarsel {
                // Gult holder ikke som tekst på lyst: advarselen er en gul flate med mørk tekst i begge moduser.
                status[rolle] = Statusfarger(tekst: mørk, flate: flytt(grunn, til: n.advarselFlate))
            } else {
                let c = grunn.okLCH.c
                status[rolle] = Statusfarger(tekst: iOmråde(grunn, n.statusTekst),
                                             flate: flytt(grunn, til: n.statusFlate, kroma: min(c * 0.3, 0.045)))
            }
        }

        return Designtema(
            modus: modus,
            bakgrunn: grå(n.bakgrunn, 0.5),
            flate: grå(n.flate, modus.erMørk ? 0.6 : 0.2),
            tekst: tekst,
            sekundærtekst: grå(n.sekundærtekst, 0.8),
            plassholder: grå(n.plassholder, 0.6),
            kant: grå(n.kant),
            skille: grå(n.skille, 0.6),
            aksent: aksent,
            aksentTrykket: flytt(aksent, til: aksent.lStjerne + n.trykket),
            påAksent: påAksent,
            aksentTonet: Farge.medLStjerne(n.tonet, kroma: min(a.c * 0.35, 0.05), kulør: a.h, gamut: gamut),
            sekundær: iOmråde(self[.sekundær], n.sekundær),
            deaktivertFyll: grå(n.deaktivertFyll, 0.5),
            deaktivertTekst: grå(n.deaktivertTekst, 0.5),
            status: status
        )
    }
}

// MARK: - Kontrollpunkter

/// Kravet et fargepar i en komponent må holde etter WCAG 2 (AA).
public enum Komponentkrav: Sendable, Hashable {
    /// Tekst: 4,5:1 (1.4.3, i WCAG 2.0 og nyere).
    case tekst
    /// Grafikk og komponentgrenser: 3:1 (1.4.11, fra WCAG 2.1).
    case ikkeTekst
    /// Deaktiverte komponenter er unntatt.
    case unntatt

    public var minimum: Double? {
        switch self {
        case .tekst: 4.5
        case .ikkeTekst: 3
        case .unntatt: nil
        }
    }

    public var suksesskriterium: String? {
        switch self {
        case .tekst: "1.4.3"
        case .ikkeTekst: "1.4.11"
        case .unntatt: nil
        }
    }
}

/// Fargeparene i komponentvisningen som kontrolleres.
public enum Komponentpar: String, CaseIterable, Sendable, Identifiable {
    case tekst, sekundærtekst, plassholder, lenke, destruktiv, knappetekst, tonetKnapp, feltkant, bryter, fokusring
    case feilvarsel, suksessvarsel, advarselvarsel
    public var id: String { rawValue }
}

/// Ett kontrollert fargepar.
public struct Komponentsjekk: Identifiable, Hashable, Sendable {
    public let par: Komponentpar
    public let forgrunn: Farge
    public let bakgrunn: Farge
    public let krav: Komponentkrav

    public var id: String { par.rawValue }
    /// WCAG-kontrastforhold.
    public var forhold: Double { forgrunn.lagtOver(bakgrunn).wcagKontrast(mot: bakgrunn) }
    /// APCA-lesekontrast (Lc).
    public var lc: Double { bakgrunn.apcaKontrast(tekst: forgrunn.lagtOver(bakgrunn)) }
    /// Holder kravet (unntatte par holder alltid). Forholdet avrundes ikke opp.
    public var består: Bool { krav.minimum.map { forhold >= $0 } ?? true }
}

public extension Designtema {
    /// Fargeparene i komponentene i en tilstand, med kravet hvert par skal holde.
    func sjekker(_ tilstand: Komponenttilstand) -> [Komponentsjekk] {
        let av = tilstand == .deaktivert
        var s: [Komponentsjekk] = [
            Komponentsjekk(par: .tekst, forgrunn: tekst, bakgrunn: flate, krav: .tekst),
            Komponentsjekk(par: .sekundærtekst, forgrunn: sekundærtekst, bakgrunn: bakgrunn, krav: .tekst),
            av ? Komponentsjekk(par: .plassholder, forgrunn: deaktivertTekst, bakgrunn: flate, krav: .unntatt)
               : Komponentsjekk(par: .plassholder, forgrunn: plassholder, bakgrunn: flate, krav: .tekst),
            Komponentsjekk(par: .lenke, forgrunn: aksent, bakgrunn: bakgrunn, krav: .tekst),
            av ? Komponentsjekk(par: .destruktiv, forgrunn: deaktivertTekst, bakgrunn: bakgrunn, krav: .unntatt)
               : Komponentsjekk(par: .destruktiv, forgrunn: status(.feil).tekst, bakgrunn: bakgrunn, krav: .tekst),
        ]
        switch tilstand {
        case .deaktivert:
            s.append(Komponentsjekk(par: .knappetekst, forgrunn: deaktivertTekst, bakgrunn: deaktivertFyll, krav: .unntatt))
            s.append(Komponentsjekk(par: .tonetKnapp, forgrunn: deaktivertTekst, bakgrunn: deaktivertFyll, krav: .unntatt))
            s.append(Komponentsjekk(par: .feltkant, forgrunn: skille, bakgrunn: flate, krav: .unntatt))
            s.append(Komponentsjekk(par: .bryter, forgrunn: deaktivertFyll, bakgrunn: flate, krav: .unntatt))
        case .trykket:
            s.append(Komponentsjekk(par: .knappetekst, forgrunn: påAksent, bakgrunn: aksentTrykket, krav: .tekst))
            s.append(Komponentsjekk(par: .tonetKnapp, forgrunn: aksentTrykket, bakgrunn: aksentTonet, krav: .tekst))
            s.append(Komponentsjekk(par: .feltkant, forgrunn: kant, bakgrunn: flate, krav: .ikkeTekst))
            s.append(Komponentsjekk(par: .bryter, forgrunn: sekundær, bakgrunn: flate, krav: .ikkeTekst))
        case .normal, .fokus:
            s.append(Komponentsjekk(par: .knappetekst, forgrunn: påAksent, bakgrunn: aksent, krav: .tekst))
            s.append(Komponentsjekk(par: .tonetKnapp, forgrunn: aksent, bakgrunn: aksentTonet, krav: .tekst))
            s.append(Komponentsjekk(par: .feltkant, forgrunn: kant, bakgrunn: flate, krav: .ikkeTekst))
            s.append(Komponentsjekk(par: .bryter, forgrunn: sekundær, bakgrunn: flate, krav: .ikkeTekst))
        }
        if tilstand == .fokus {
            s.append(Komponentsjekk(par: .fokusring, forgrunn: aksent, bakgrunn: flate, krav: .ikkeTekst))
        }
        let varsler: [(Komponentpar, Designrolle)] = [(.feilvarsel, .feil), (.suksessvarsel, .suksess), (.advarselvarsel, .advarsel)]
        for (par, rolle) in varsler {
            let st = status(rolle)
            s.append(Komponentsjekk(par: par, forgrunn: st.tekst, bakgrunn: st.flate, krav: .tekst))
        }
        return s
    }
}
