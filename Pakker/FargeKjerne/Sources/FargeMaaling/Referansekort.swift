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

    public init(id: UUID = UUID(), navn: String, rader: Int, kolonner: Int, felt: [Referansefelt], kilde: String? = nil) {
        self.id = id
        self.navn = navn
        self.rader = rader
        self.kolonner = kolonner
        self.felt = felt
        self.kilde = kilde
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

    /// Indeksene til de nøytrale feltene (kroma under 6 i CIELab), fra lysest til mørkest.
    public var nøytrale: [Int] {
        let lab = felt.map(\.verdi.lab)
        return lab.indices.filter { hypot(lab[$0].a, lab[$0].b) < 6 }.sorted { lab[$0].l > lab[$1].l }
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

/// CIELab mot et vilkårlig hvitpunkt.
enum Labregning {
    static func lab(_ v: XYZ, hvit: XYZ) -> CIELab {
        func f(_ t: Double) -> Double { t > 216.0 / 24389 ? cbrt(t) : (24389.0 / 27 * t + 16) / 116 }
        let (fx, fy, fz) = (f(v.x / hvit.x), f(v.y / hvit.y), f(v.z / hvit.z))
        return CIELab(l: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz))
    }

    static func xyz(_ lab: CIELab, hvit: XYZ) -> XYZ {
        let fy = (lab.l + 16) / 116, fx = fy + lab.a / 500, fz = fy - lab.b / 200
        func g(_ f: Double) -> Double { let f3 = f * f * f; return f3 > 216.0 / 24389 ? f3 : (116 * f - 16) * 27 / 24389 }
        let y = lab.l > 8 ? fy * fy * fy : lab.l * 27 / 24389
        return XYZ(x: g(fx) * hvit.x, y: y * hvit.y, z: g(fz) * hvit.z)
    }
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

    public static func sentre(hjørner: [CGPoint], rader: Int, kolonner: Int) -> [CGPoint] {
        (0..<(rader * kolonner)).compactMap { i in
            let u = (Double(i % kolonner) + 0.5) / Double(kolonner)
            let v = (Double(i / kolonner) + 0.5) / Double(rader)
            return punkt(u: u, v: v, hjørner: hjørner)
        }
    }
}
