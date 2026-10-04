import CoreGraphics
import FargeKjerne
import Foundation

/// Et fargereferansekort: felt med kjente verdier, i leserekkefølge (rad for rad fra øverst til venstre, med
/// kortet liggende). Verdiene kommer fra brukerens egen fil – Kolorist har ingen kortdata innebygd.
public struct Referansekort: Hashable, Codable, Sendable, Identifiable {
    public var id: UUID
    public var navn: String
    public var rader: Int
    public var kolonner: Int
    public var felt: [Referansefelt]
    /// Filen verdiene kom fra.
    public var kilde: String?
    /// Satt når verdiene kom som tre tallkolonner uten overskrift (Lab eller XYZ kan ikke avgjøres sikkert):
    /// faktoren XYZ-verdiene er skalert med (0,01 for 0–100, 1 for 0–1).
    public var treKolonnerSkala: Double?

    public init(id: UUID = UUID(), navn: String, rader: Int, kolonner: Int, felt: [Referansefelt], kilde: String? = nil,
                treKolonnerSkala: Double? = nil) {
        self.id = id
        self.navn = navn
        self.rader = rader
        self.kolonner = kolonner
        self.felt = felt
        self.kilde = kilde
        self.treKolonnerSkala = treKolonnerSkala
    }

    /// Hvordan tre tallkolonner uten overskrift er tolket.
    public enum Tolkning: String, Hashable, Sendable, CaseIterable { case lab, xyz }

    /// Tolkningen, når den var et valg (tre kolonner uten overskrift); ellers `nil`.
    public var tolkning: Tolkning? {
        guard treKolonnerSkala != nil, let første = felt.first else { return nil }
        if case .lab = første.verdi { return .lab }
        return .xyz
    }

    /// Kortet med de samme tallene tolket på nytt som Lab (D50) eller XYZ (D50).
    public func tolket(som ny: Tolkning) -> Referansekort {
        guard let skala = treKolonnerSkala, ny != tolkning else { return self }
        var kort = self
        kort.felt = felt.map { f in
            var f = f
            switch (f.verdi, ny) {
            case (.lab(let l), .xyz):
                f.verdi = .xyz(XYZ(x: l.l * skala, y: l.a * skala, z: l.b * skala), hvit: Lyskilde.d50.hvitpunkt)
            case (.xyz(let v, _), .lab):
                f.verdi = .lab(CIELab(l: v.x / skala, a: v.y / skala, b: v.z / skala))
            default: break
            }
            return f
        }
        return kort
    }

    /// Et grått (eller hvitt) kort med jevn refleksjon, f.eks. 0,18 for et 18 %-gråkort.
    public static func gråkort(refleksjon: Double, navn: String? = nil) -> Referansekort {
        let spekter = Spektrum(start: 380, steg: 400, verdier: [refleksjon, refleksjon])
        return Referansekort(navn: navn ?? String(localized: "Gråkort \(Int((refleksjon * 100).rounded())) %", bundle: .module),
                             rader: 1, kolonner: 1, felt: [Referansefelt(navn: "A1", verdi: .spekter(spekter))])
    }

    /// Om alle feltene har spektre (da kan fasiten regnes ut i ethvert lys).
    public var harSpektre: Bool {
        felt.allSatisfy { if case .spekter = $0.verdi { true } else { false } }
    }

    /// Indeksene til de nøytrale feltene, fra lysest til mørkest.
    public var nøytrale: [Int] {
        let lab = felt.map(\.verdi.lab)
        return lab.indices.filter { Referanseverdi.erNøytral(lab[$0]) }.sorted { lab[$0].l > lab[$1].l }
    }

    /// Posisjonsnavn som «A1» (rad A, kolonne 1).
    static func posisjonsnavn(_ indeks: Int, kolonner: Int) -> String {
        let rad = indeks / max(kolonner, 1), kolonne = indeks % max(kolonner, 1)
        var bokstaver = ""
        var r = rad
        repeat {
            bokstaver = String(UnicodeScalar(UInt8(65 + r % 26))) + bokstaver
            r = r / 26 - 1
        } while r >= 0
        return "\(bokstaver)\(kolonne + 1)"
    }

    /// Sentrene til feltene i et bilde, når kortets fire hjørner er kjent (øverst til venstre, øverst til høyre,
    /// nederst til høyre, nederst til venstre). Perspektivet tas hensyn til med en homografi.
    public func feltsentre(hjørner: [CGPoint]) -> [CGPoint] {
        Kortgeometri.sentre(hjørner: hjørner, rader: rader, kolonner: kolonner)
    }
}

public struct Referansefelt: Hashable, Codable, Sendable {
    public var navn: String
    public var verdi: Referanseverdi

    public init(navn: String, verdi: Referanseverdi) {
        self.navn = navn
        self.verdi = verdi
    }
}

/// Fasiten for ett felt: et refleksjonsspekter, eller en farge målt under et kjent lys.
public enum Referanseverdi: Hashable, Codable, Sendable {
    /// Refleksjon 0–1.
    case spekter(Spektrum)
    /// CIELab under D50 (vanlig i grafisk bransje og i filer fra fargemålere).
    case lab(CIELab)
    /// XYZ under et lys med gitt hvitpunkt (hvitt har Y = 1).
    case xyz(XYZ, hvit: XYZ)

    /// Fargen under et lys (hvitt har Y = 1). Med spekter er dette nøyaktig; ellers en kromatisk tilpasning (CAT16)
    /// fra lyset verdien ble målt i.
    public func xyz(under lys: Lyskilde) -> XYZ {
        switch self {
        case .spekter(let r):
            if let s = lys.spektrum { return Kolorimetri.xyz(refleksjon: r, under: s) }
            let d65 = Kolorimetri.xyz(refleksjon: r, under: Lyskilde.d65.spektrum!)
            return CAT16.tilpass(d65, fra: Lyskilde.d65.hvitpunkt, til: lys.hvitpunkt)
        case .lab(let lab):
            let d50 = Lyskilde.d50.hvitpunkt
            return CAT16.tilpass(Labregning.xyz(lab, hvit: d50), fra: d50, til: lys.hvitpunkt)
        case .xyz(let v, let hvit):
            return CAT16.tilpass(v, fra: hvit, til: lys.hvitpunkt)
        }
    }

    /// Nøytral (grå) når kroma i CIELab er under 6.
    static func erNøytral(_ lab: CIELab) -> Bool { hypot(lab.a, lab.b) < 6 }

    /// CIELab under D50.
    public var lab: CIELab {
        switch self {
        case .lab(let lab): lab
        default: Labregning.lab(xyz(under: .d50), hvit: Lyskilde.d50.hvitpunkt)
        }
    }

    /// Fargen slik den ser ut i dagslys (D65), for visning.
    public var farge: Farge { Farge(xyz: xyz(under: .d65)) }
}

/// Plassering av felt på et kort i et bilde.
public enum Kortgeometri {
    /// Homografien som sender enhetskvadratet (0,0), (1,0), (1,1), (0,1) til de fire hjørnene.
    static func homografi(_ p: [CGPoint]) -> [[Double]]? {
        guard p.count == 4 else { return nil }
        let (x0, y0, x1, y1) = (Double(p[0].x), Double(p[0].y), Double(p[1].x), Double(p[1].y))
        let (x2, y2, x3, y3) = (Double(p[2].x), Double(p[2].y), Double(p[3].x), Double(p[3].y))
        let dx1 = x1 - x2, dx2 = x3 - x2, dy1 = y1 - y2, dy2 = y3 - y2
        let sx = x0 - x1 + x2 - x3, sy = y0 - y1 + y2 - y3
        let det = dx1 * dy2 - dx2 * dy1
        guard abs(det) > 1e-12 else { return nil }
        let g = (sx * dy2 - dx2 * sy) / det, h = (dx1 * sy - sx * dy1) / det
        return [[x1 - x0 + g * x1, x3 - x0 + h * x3, x0],
                [y1 - y0 + g * y1, y3 - y0 + h * y3, y0],
                [g, h, 1]]
    }

    /// Punktet ved (u, v) i kortets egne koordinater (0–1), sett i bildet.
    public static func punkt(u: Double, v: Double, hjørner: [CGPoint]) -> CGPoint? {
        guard let m = homografi(hjørner) else { return nil }
        let w = m[2][0] * u + m[2][1] * v + m[2][2]
        return CGPoint(x: (m[0][0] * u + m[0][1] * v + m[0][2]) / w, y: (m[1][0] * u + m[1][1] * v + m[1][2]) / w)
    }

    /// De åtte måtene å tilordne fire hjørner på: fire rotasjoner, med og uten speiling.
    public static func retninger(_ h: [CGPoint]) -> [[CGPoint]] {
        guard h.count == 4 else { return [h] }
        let rotasjoner = (0..<4).map { r in (0..<4).map { h[($0 + r) % 4] } }
        return rotasjoner + rotasjoner.map { [$0[1], $0[0], $0[3], $0[2]] }
    }

    /// Velger retningen der lysheten i feltene best stemmer med fasiten (korrelasjon mellom logaritmene).
    /// `måling` gir målt luminans for feltsentrene.
    public static func besteRetning(hjørner: [CGPoint], rader: Int, kolonner: Int, fasitY: [Double],
                                    måling: ([CGPoint]) -> [Double]) -> [CGPoint] {
        func korrelasjon(_ a: [Double], _ b: [Double]) -> Double {
            let n = Double(min(a.count, b.count))
            guard n > 2 else { return -1 }
            let (la, lb) = (a.map { log(max($0, 1e-4)) }, b.map { log(max($0, 1e-4)) })
            let (ma, mb) = (la.reduce(0, +) / n, lb.reduce(0, +) / n)
            var sab = 0.0, saa = 0.0, sbb = 0.0
            for (x, y) in zip(la, lb) { sab += (x - ma) * (y - mb); saa += (x - ma) * (x - ma); sbb += (y - mb) * (y - mb) }
            return saa > 0 && sbb > 0 ? sab / (saa * sbb).squareRoot() : -1
        }
        return retninger(hjørner).max { a, b in
            korrelasjon(måling(sentre(hjørner: a, rader: rader, kolonner: kolonner)), fasitY)
                < korrelasjon(måling(sentre(hjørner: b, rader: rader, kolonner: kolonner)), fasitY)
        } ?? hjørner
    }

    public static func sentre(hjørner: [CGPoint], rader: Int, kolonner: Int) -> [CGPoint] {
        (0..<(rader * kolonner)).compactMap { i in
            let u = (Double(i % kolonner) + 0.5) / Double(kolonner)
            let v = (Double(i / kolonner) + 0.5) / Double(rader)
            return punkt(u: u, v: v, hjørner: hjørner)
        }
    }
}
